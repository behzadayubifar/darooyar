package nats

import (
	"log"
	"os"
	"time"

	"github.com/nats-io/nats.go"
)

var (
	// NatsConn is the global NATS connection
	NatsConn *nats.Conn
)

// InitNATS initializes the NATS connection
func InitNATS() error {
	// Get NATS URL from environment variable or use default
	natsURL := os.Getenv("NATS_URL")
	if natsURL == "" {
		natsURL = nats.DefaultURL // localhost:4222
	}

	// Connect to NATS with options
	var err error
	NatsConn, err = nats.Connect(natsURL,
		nats.Name("darooyar-server"),
		nats.Timeout(10*time.Second),
		nats.ReconnectWait(5*time.Second),
		nats.MaxReconnects(10),
		nats.DisconnectErrHandler(func(nc *nats.Conn, err error) {
			log.Printf("NATS disconnected: %v", err)
		}),
		nats.ReconnectHandler(func(nc *nats.Conn) {
			log.Printf("NATS reconnected to %s", nc.ConnectedUrl())
		}),
		nats.ClosedHandler(func(nc *nats.Conn) {
			log.Printf("NATS connection closed")
		}),
	)

	if err != nil {
		return err
	}

	log.Printf("Connected to NATS server at %s", NatsConn.ConnectedUrl())
	return nil
}

// CloseNATS closes the NATS connection
func CloseNATS() {
	if NatsConn != nil {
		NatsConn.Close()
		log.Println("NATS connection closed")
	}
}

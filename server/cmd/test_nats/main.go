package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/joho/godotenv"
	"github.com/nats-io/nats.go"
)

// CompletionRequest represents a request for AI text completion
type CompletionRequest struct {
	Prompt string `json:"prompt"`
}

// CompletionResponse represents the response from the AI text completion
type CompletionResponse struct {
	Status     string `json:"status"`
	Completion string `json:"completion"`
}

func main() {
	// Load environment variables from .env file
	if err := godotenv.Load("../../.env"); err != nil {
		log.Println("Warning: No .env file found, using system environment variables")
	}

	// Get NATS URL from environment variable or use default
	natsURL := os.Getenv("NATS_URL")
	if natsURL == "" {
		natsURL = nats.DefaultURL // localhost:4222
	}

	// Connect to NATS
	nc, err := nats.Connect(natsURL,
		nats.Name("darooyar-test-client"),
		nats.Timeout(10*time.Second),
	)
	if err != nil {
		log.Fatalf("Failed to connect to NATS: %v", err)
	}
	defer nc.Close()

	fmt.Println("Connected to NATS server at", nc.ConnectedUrl())

	// Create a request
	request := CompletionRequest{
		Prompt: "سلام، حالت چطوره؟",
	}

	// Convert request to JSON
	requestData, err := json.Marshal(request)
	if err != nil {
		log.Fatalf("Error marshaling request: %v", err)
	}

	// Create a unique inbox subject for the response
	inbox := nc.NewInbox()

	// Subscribe to the inbox for the response
	sub, err := nc.SubscribeSync(inbox)
	if err != nil {
		log.Fatalf("Error subscribing to inbox: %v", err)
	}
	defer sub.Unsubscribe()

	fmt.Println("Sending request to ai.completion...")

	// Publish the request to the AI completion subject with reply
	if err := nc.PublishRequest("ai.completion", inbox, requestData); err != nil {
		log.Fatalf("Error publishing request: %v", err)
	}

	fmt.Println("Waiting for response...")

	// Wait for the response with a timeout
	msg, err := sub.NextMsg(30 * time.Second)
	if err != nil {
		if err == nats.ErrTimeout {
			log.Fatalf("Timeout waiting for AI completion response")
		} else {
			log.Fatalf("Error receiving response: %v", err)
		}
	}

	// Parse the response
	var response CompletionResponse
	if err := json.Unmarshal(msg.Data, &response); err != nil {
		log.Fatalf("Error unmarshaling response: %v", err)
	}

	fmt.Println("Received response:")
	fmt.Println("Status:", response.Status)
	fmt.Println("Completion:", response.Completion)
}

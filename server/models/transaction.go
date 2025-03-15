package models

import (
	"time"
)

// Transaction represents a payment transaction
type Transaction struct {
	ID            int64     `json:"id"`
	UserID        int64     `json:"user_id"`
	Amount        float64   `json:"amount"`
	PaymentMethod string    `json:"payment_method"`
	ReferenceID   string    `json:"reference_id"`
	Status        string    `json:"status"`
	CreatedAt     time.Time `json:"created_at"`
	Metadata      string    `json:"metadata"`
}

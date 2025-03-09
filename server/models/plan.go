package models

import (
	"time"
)

// PlanType defines the type of subscription plan
type PlanType string

const (
	PlanTypeTimeBased  PlanType = "time_based"  // Based on duration
	PlanTypeUsageBased PlanType = "usage_based" // Based on number of uses
	PlanTypeBoth       PlanType = "both"        // Both time and usage limits apply
)

// SubscriptionStatus defines the status of a user subscription
type SubscriptionStatus string

const (
	SubscriptionStatusActive    SubscriptionStatus = "active"
	SubscriptionStatusExpired   SubscriptionStatus = "expired"
	SubscriptionStatusCancelled SubscriptionStatus = "cancelled"
)

// GiftType defines the type of gift
type GiftType string

const (
	GiftTypePlan   GiftType = "plan"   // Gift a plan
	GiftTypeCredit GiftType = "credit" // Gift credit
)

// Plan represents a subscription plan
type Plan struct {
	ID           int64     `json:"id"`
	Title        string    `json:"title"`
	Description  string    `json:"description"`
	Price        float64   `json:"price"`
	DurationDays *int      `json:"duration_days"` // Nil means unlimited/not applicable
	MaxUses      *int      `json:"max_uses"`      // Nil means unlimited
	PlanType     PlanType  `json:"plan_type"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// UserSubscription represents a user's subscription to a plan
type UserSubscription struct {
	ID            int64              `json:"id"`
	UserID        int64              `json:"user_id"`
	PlanID        int64              `json:"plan_id"`
	Plan          *Plan              `json:"plan,omitempty"`
	PurchaseDate  time.Time          `json:"purchase_date"`
	ExpiryDate    *time.Time         `json:"expiry_date"`
	Status        SubscriptionStatus `json:"status"`
	UsesCount     int                `json:"uses_count"`
	RemainingUses *int               `json:"remaining_uses"`
	CreatedAt     time.Time          `json:"created_at"`
	UpdatedAt     time.Time          `json:"updated_at"`
}

// CreditTransaction represents a transaction affecting user credit
type CreditTransaction struct {
	ID                    int64     `json:"id"`
	UserID                int64     `json:"user_id"`
	Amount                float64   `json:"amount"`
	Description           string    `json:"description"`
	TransactionType       string    `json:"transaction_type"`
	RelatedSubscriptionID *int64    `json:"related_subscription_id"`
	CreatedAt             time.Time `json:"created_at"`
}

// GiftTransaction represents a gift from an admin to a user
type GiftTransaction struct {
	ID           int64     `json:"id"`
	AdminID      int64     `json:"admin_id"`
	UserID       int64     `json:"user_id"`
	GiftType     GiftType  `json:"gift_type"`
	PlanID       *int64    `json:"plan_id,omitempty"`
	CreditAmount *float64  `json:"credit_amount,omitempty"`
	Message      string    `json:"message"`
	CreatedAt    time.Time `json:"created_at"`
}

// GiftPlanRequest represents a request to gift a plan to a user
type GiftPlanRequest struct {
	UserID  int64  `json:"user_id"`
	PlanID  int64  `json:"plan_id"`
	Message string `json:"message"`
}

// GiftCreditRequest represents a request to gift credit to a user
type GiftCreditRequest struct {
	UserID  int64   `json:"user_id"`
	Amount  float64 `json:"amount"`
	Message string  `json:"message"`
}

// PlanCreate represents data required to create a new plan
type PlanCreate struct {
	Title        string   `json:"title"`
	Description  string   `json:"description"`
	Price        float64  `json:"price"`
	DurationDays *int     `json:"duration_days"`
	MaxUses      *int     `json:"max_uses"`
	PlanType     PlanType `json:"plan_type"`
}

// UserSubscriptionCreate represents data required to create a new user subscription
type UserSubscriptionCreate struct {
	UserID int64 `json:"user_id"`
	PlanID int64 `json:"plan_id"`
}

// IsExpired checks if a subscription is expired
func (s *UserSubscription) IsExpired() bool {
	if s.Status != SubscriptionStatusActive {
		return true
	}

	// Check time-based expiration
	if s.ExpiryDate != nil && !s.ExpiryDate.IsZero() && time.Now().After(*s.ExpiryDate) {
		return true
	}

	// Check usage-based expiration
	if s.RemainingUses != nil && *s.RemainingUses <= 0 {
		return true
	}

	return false
}

// CheckAndUpdateStatus updates the status based on expiration
func (s *UserSubscription) CheckAndUpdateStatus() bool {
	if s.Status != SubscriptionStatusActive {
		return false // Already inactive
	}

	if s.IsExpired() {
		s.Status = SubscriptionStatusExpired
		return true // Status changed
	}

	return false // No change
}

// UserSubscriptionResponse is a simplified response structure for subscriptions
type UserSubscriptionResponse struct {
	ID            int64              `json:"id"`
	Plan          *Plan              `json:"plan"`
	PurchaseDate  time.Time          `json:"purchase_date"`
	ExpiryDate    *time.Time         `json:"expiry_date"`
	Status        SubscriptionStatus `json:"status"`
	UsesCount     int                `json:"uses_count"`
	RemainingUses *int               `json:"remaining_uses"`
}

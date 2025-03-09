package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/darooyar/server/db"
	"github.com/darooyar/server/models"
	"github.com/gorilla/mux"
)

// GetAllPlans handles retrieving all available plans
func GetAllPlans(w http.ResponseWriter, r *http.Request) {
	// Get all plans from database
	plans, err := db.GetAllPlans()
	if err != nil {
		http.Error(w, "Error retrieving plans: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Return response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"plans": plans,
	})
}

// GetPlanByID handles retrieving a specific plan
func GetPlanByID(w http.ResponseWriter, r *http.Request) {
	// Get plan ID from URL
	vars := mux.Vars(r)
	planID, err := strconv.ParseInt(vars["id"], 10, 64)
	if err != nil {
		http.Error(w, "Invalid plan ID", http.StatusBadRequest)
		return
	}

	// Get plan from database
	plan, err := db.GetPlanByID(planID)
	if err != nil {
		http.Error(w, "Error retrieving plan: "+err.Error(), http.StatusInternalServerError)
		return
	}

	if plan == nil {
		http.Error(w, "Plan not found", http.StatusNotFound)
		return
	}

	// Return response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(plan)
}

// CreatePlan handles creating a new plan (admin only)
func CreatePlan(w http.ResponseWriter, r *http.Request) {
	// Parse request body
	var planCreate models.PlanCreate
	if err := json.NewDecoder(r.Body).Decode(&planCreate); err != nil {
		http.Error(w, "Invalid request body: "+err.Error(), http.StatusBadRequest)
		return
	}

	// Create plan in database
	plan, err := db.CreatePlan(&planCreate)
	if err != nil {
		http.Error(w, "Error creating plan: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Return response
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(plan)
}

// PurchasePlan handles user purchasing a plan
func PurchasePlan(w http.ResponseWriter, r *http.Request) {
	// Get user ID from context (set during authentication)
	userID := r.Context().Value("user_id").(int64)

	// Parse request body
	var request struct {
		PlanID int64 `json:"plan_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		http.Error(w, "Invalid request body: "+err.Error(), http.StatusBadRequest)
		return
	}

	// Verify plan exists
	plan, err := db.GetPlanByID(request.PlanID)
	if err != nil {
		http.Error(w, "Error retrieving plan: "+err.Error(), http.StatusInternalServerError)
		return
	}
	if plan == nil {
		http.Error(w, "Plan not found", http.StatusNotFound)
		return
	}

	// Verify user has enough credit
	user, err := db.GetUserByID(userID)
	if err != nil {
		http.Error(w, "Error retrieving user: "+err.Error(), http.StatusInternalServerError)
		return
	}
	if user.Credit < plan.Price {
		http.Error(w, "Insufficient credit to purchase this plan", http.StatusPaymentRequired)
		return
	}

	// Create subscription
	subscription, err := db.CreateUserSubscription(userID, request.PlanID)
	if err != nil {
		http.Error(w, "Error creating subscription: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Return response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"message":          "Plan purchased successfully",
		"subscription":     subscription,
		"remaining_credit": user.Credit - plan.Price,
	})
}

// GetUserSubscriptions handles retrieving all subscriptions for a user
func GetUserSubscriptions(w http.ResponseWriter, r *http.Request) {
	// Get user ID from context (set during authentication)
	userID := r.Context().Value("user_id").(int64)

	// Get all subscriptions from database
	subscriptions, err := db.GetUserSubscriptions(userID)
	if err != nil {
		http.Error(w, "Error retrieving subscriptions: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Return response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"subscriptions": subscriptions,
	})
}

// GetActiveUserSubscriptions handles retrieving active subscriptions for a user
func GetActiveUserSubscriptions(w http.ResponseWriter, r *http.Request) {
	// Get user ID from context (set during authentication)
	userID := r.Context().Value("user_id").(int64)

	// Get active subscriptions from database
	subscriptions, err := db.GetActiveUserSubscriptions(userID)
	if err != nil {
		http.Error(w, "Error retrieving subscriptions: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Return response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"subscriptions": subscriptions,
	})
}

// UseSubscription handles recording usage of a subscription
func UseSubscription(w http.ResponseWriter, r *http.Request) {
	// Get user ID from context (set during authentication)
	userID := r.Context().Value("user_id").(int64)

	// Parse request body
	var request struct {
		SubscriptionID int64 `json:"subscription_id"`
		Count          int   `json:"count"`
	}
	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		http.Error(w, "Invalid request body: "+err.Error(), http.StatusBadRequest)
		return
	}

	// Verify user owns the subscription
	// This is a security check to prevent users from using others' subscriptions
	query := `SELECT id FROM user_subscriptions WHERE id = $1 AND user_id = $2`
	var id int64
	err := db.DB.QueryRow(query, request.SubscriptionID, userID).Scan(&id)
	if err != nil {
		http.Error(w, "Subscription not found or does not belong to user", http.StatusNotFound)
		return
	}

	// Record usage
	err = db.RecordSubscriptionUsage(request.SubscriptionID, request.Count)
	if err != nil {
		http.Error(w, "Error recording usage: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Return response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"message": "Usage recorded successfully",
	})
}

// GetCreditTransactions handles retrieving credit transactions for a user
func GetCreditTransactions(w http.ResponseWriter, r *http.Request) {
	// Get user ID from context (set during authentication)
	userID := r.Context().Value("user_id").(int64)

	// Parse query parameters
	limit := 20 // Default limit
	offset := 0 // Default offset

	limitParam := r.URL.Query().Get("limit")
	if limitParam != "" {
		parsedLimit, err := strconv.Atoi(limitParam)
		if err == nil && parsedLimit > 0 {
			limit = parsedLimit
		}
	}

	offsetParam := r.URL.Query().Get("offset")
	if offsetParam != "" {
		parsedOffset, err := strconv.Atoi(offsetParam)
		if err == nil && parsedOffset >= 0 {
			offset = parsedOffset
		}
	}

	// Get transactions from database
	transactions, err := db.GetCreditTransactions(userID, limit, offset)
	if err != nil {
		http.Error(w, "Error retrieving transactions: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Return response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"transactions": transactions,
	})
}

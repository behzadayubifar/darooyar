package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"

	"github.com/darooyar/server/db"
	"github.com/darooyar/server/models"
	"github.com/gorilla/mux"
)

type GiftHandler struct{}

func NewGiftHandler() *GiftHandler {
	return &GiftHandler{}
}

// GiftPlanToUser handles an admin gifting a plan to a user
func (h *GiftHandler) GiftPlanToUser(w http.ResponseWriter, r *http.Request) {
	// Get admin ID from context
	adminID, ok := r.Context().Value("user_id").(int64)
	if !ok {
		sendErrorResponse(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Parse request body
	var req models.GiftPlanRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, "Invalid request body: "+err.Error(), http.StatusBadRequest)
		return
	}

	// Validate request
	if req.UserID <= 0 {
		sendErrorResponse(w, "Invalid user ID", http.StatusBadRequest)
		return
	}
	if req.PlanID <= 0 {
		sendErrorResponse(w, "Invalid plan ID", http.StatusBadRequest)
		return
	}

	// Check if user exists
	user, err := db.GetUserByID(req.UserID)
	if err != nil {
		sendErrorResponse(w, "User not found", http.StatusNotFound)
		return
	}

	// Check if plan exists
	plan, err := db.GetPlanByID(req.PlanID)
	if err != nil {
		sendErrorResponse(w, "Error retrieving plan", http.StatusInternalServerError)
		return
	}
	if plan == nil {
		sendErrorResponse(w, "Plan not found", http.StatusNotFound)
		return
	}

	// Gift the plan to the user
	err = db.GiftPlanToUser(adminID, req.UserID, req.PlanID, req.Message)
	if err != nil {
		log.Printf("Error gifting plan: %v", err)
		sendErrorResponse(w, "Error gifting plan: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Return success response
	response := map[string]interface{}{
		"status":  "success",
		"message": "Plan gifted successfully",
		"user":    user.Username,
		"plan":    plan.Title,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// GiftCreditToUser handles an admin gifting credit to a user
func (h *GiftHandler) GiftCreditToUser(w http.ResponseWriter, r *http.Request) {
	// Get admin ID from context
	adminID, ok := r.Context().Value("user_id").(int64)
	if !ok {
		sendErrorResponse(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Parse request body
	var req models.GiftCreditRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, "Invalid request body: "+err.Error(), http.StatusBadRequest)
		return
	}

	// Validate request
	if req.UserID <= 0 {
		sendErrorResponse(w, "Invalid user ID", http.StatusBadRequest)
		return
	}
	if req.Amount <= 0 {
		sendErrorResponse(w, "Amount must be positive", http.StatusBadRequest)
		return
	}

	// Check if user exists
	user, err := db.GetUserByID(req.UserID)
	if err != nil {
		sendErrorResponse(w, "User not found", http.StatusNotFound)
		return
	}

	// Gift credit to the user
	err = db.GiftCreditToUser(adminID, req.UserID, req.Amount, req.Message)
	if err != nil {
		log.Printf("Error gifting credit: %v", err)
		sendErrorResponse(w, "Error gifting credit: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Get updated user credit
	updatedUser, err := db.GetUserByID(req.UserID)
	if err != nil {
		log.Printf("Error getting updated user: %v", err)
	}

	// Return success response
	response := map[string]interface{}{
		"status":       "success",
		"message":      "Credit gifted successfully",
		"user":         user.Username,
		"amount":       req.Amount,
		"total_credit": updatedUser.Credit,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// GetUserGiftTransactions handles retrieving all gift transactions for a user
func (h *GiftHandler) GetUserGiftTransactions(w http.ResponseWriter, r *http.Request) {
	// Get user ID from URL
	vars := mux.Vars(r)
	userID, err := strconv.ParseInt(vars["id"], 10, 64)
	if err != nil {
		sendErrorResponse(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	// Get gift transactions
	gifts, err := db.GetUserGiftTransactions(userID)
	if err != nil {
		log.Printf("Error getting gift transactions: %v", err)
		sendErrorResponse(w, "Error retrieving gift transactions", http.StatusInternalServerError)
		return
	}

	// Return response
	response := map[string]interface{}{
		"status": "success",
		"gifts":  gifts,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// GetAdminGiftTransactions handles retrieving all gift transactions made by an admin
func (h *GiftHandler) GetAdminGiftTransactions(w http.ResponseWriter, r *http.Request) {
	// Get admin ID from context
	adminID, ok := r.Context().Value("user_id").(int64)
	if !ok {
		sendErrorResponse(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Get gift transactions
	gifts, err := db.GetAdminGiftTransactions(adminID)
	if err != nil {
		log.Printf("Error getting gift transactions: %v", err)
		sendErrorResponse(w, "Error retrieving gift transactions", http.StatusInternalServerError)
		return
	}

	// Return response
	response := map[string]interface{}{
		"status": "success",
		"gifts":  gifts,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

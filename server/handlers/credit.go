package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"

	"github.com/darooyar/server/db"
)

type CreditHandler struct{}

func NewCreditHandler() *CreditHandler {
	return &CreditHandler{}
}

// GetUserCredit returns the current credit balance of the authenticated user
func (h *CreditHandler) GetUserCredit(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from context
	userID, ok := r.Context().Value("user_id").(int64)
	if !ok {
		sendErrorResponse(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Get user by ID
	user, err := db.GetUserByID(userID)
	if err != nil {
		log.Printf("Error getting user by ID: %v", err)
		sendErrorResponse(w, "User not found", http.StatusNotFound)
		return
	}

	// Return credit info
	response := struct {
		Credit float64 `json:"credit"`
	}{
		Credit: user.Credit,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// AddCredit adds credit to a user's account (admin only)
func (h *CreditHandler) AddCredit(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get admin user ID from context
	adminID, ok := r.Context().Value("user_id").(int64)
	if !ok {
		sendErrorResponse(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// TODO: Add proper admin check here
	// For now, we'll assume all users can add credit to any account
	// In a real application, you would check if the user has admin privileges

	// Parse request body
	var req struct {
		UserID int64   `json:"user_id"`
		Amount float64 `json:"amount"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate amount
	if req.Amount <= 0 {
		sendErrorResponse(w, "Amount must be positive", http.StatusBadRequest)
		return
	}

	// Add credit to user
	err := db.AddUserCredit(req.UserID, req.Amount)
	if err != nil {
		log.Printf("Error adding credit: %v", err)
		sendErrorResponse(w, "Error adding credit", http.StatusInternalServerError)
		return
	}

	// Get updated user
	user, err := db.GetUserByID(req.UserID)
	if err != nil {
		log.Printf("Error getting updated user: %v", err)
		sendErrorResponse(w, "Error getting updated user", http.StatusInternalServerError)
		return
	}

	// Return success response
	response := struct {
		Message string  `json:"message"`
		UserID  int64   `json:"user_id"`
		Credit  float64 `json:"credit"`
		AdminID int64   `json:"admin_id"`
	}{
		Message: "Credit added successfully",
		UserID:  req.UserID,
		Credit:  user.Credit,
		AdminID: adminID,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// SubtractCredit subtracts credit from a user's account (admin only)
func (h *CreditHandler) SubtractCredit(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get admin user ID from context
	adminID, ok := r.Context().Value("user_id").(int64)
	if !ok {
		sendErrorResponse(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// TODO: Add proper admin check here
	// For now, we'll assume all users can subtract credit from any account
	// In a real application, you would check if the user has admin privileges

	// Parse request body
	var req struct {
		UserID int64   `json:"user_id"`
		Amount float64 `json:"amount"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate amount
	if req.Amount <= 0 {
		sendErrorResponse(w, "Amount must be positive", http.StatusBadRequest)
		return
	}

	// Subtract credit from user
	err := db.SubtractUserCredit(req.UserID, req.Amount)
	if err != nil {
		log.Printf("Error subtracting credit: %v", err)
		sendErrorResponse(w, "Error subtracting credit", http.StatusInternalServerError)
		return
	}

	// Get updated user
	user, err := db.GetUserByID(req.UserID)
	if err != nil {
		log.Printf("Error getting updated user: %v", err)
		sendErrorResponse(w, "Error getting updated user", http.StatusInternalServerError)
		return
	}

	// Return success response
	response := struct {
		Message string  `json:"message"`
		UserID  int64   `json:"user_id"`
		Credit  float64 `json:"credit"`
		AdminID int64   `json:"admin_id"`
	}{
		Message: "Credit subtracted successfully",
		UserID:  req.UserID,
		Credit:  user.Credit,
		AdminID: adminID,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// GetUserCreditByID returns the credit balance of a specific user (admin only)
func (h *CreditHandler) GetUserCreditByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get admin user ID from context
	_, ok := r.Context().Value("user_id").(int64)
	if !ok {
		sendErrorResponse(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// TODO: Add proper admin check here
	// For now, we'll assume all users can view any account's credit
	// In a real application, you would check if the user has admin privileges

	// Get user ID from query parameter
	userIDStr := r.URL.Query().Get("user_id")
	if userIDStr == "" {
		sendErrorResponse(w, "User ID is required", http.StatusBadRequest)
		return
	}

	userID, err := strconv.ParseInt(userIDStr, 10, 64)
	if err != nil {
		sendErrorResponse(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	// Get user by ID
	user, err := db.GetUserByID(userID)
	if err != nil {
		log.Printf("Error getting user by ID: %v", err)
		sendErrorResponse(w, "User not found", http.StatusNotFound)
		return
	}

	// Return credit info
	response := struct {
		UserID int64   `json:"user_id"`
		Credit float64 `json:"credit"`
	}{
		UserID: user.ID,
		Credit: user.Credit,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

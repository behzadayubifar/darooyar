package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/darooyar/server/db"
	"github.com/darooyar/server/models"
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

// ProcessUserPayment handles payment transactions from users and adds credit to their account
func (h *CreditHandler) ProcessUserPayment(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from context
	userID, ok := r.Context().Value("user_id").(int64)
	if !ok {
		sendErrorResponse(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Parse request body
	var req struct {
		Amount      float64                `json:"amount"`
		Transaction map[string]interface{} `json:"transaction"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("Error decoding request body: %v", err)
		sendErrorResponse(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate amount
	if req.Amount <= 0 {
		sendErrorResponse(w, "Amount must be positive", http.StatusBadRequest)
		return
	}

	// Extract transaction details
	transactionData, err := json.Marshal(req.Transaction)
	if err != nil {
		log.Printf("Error marshaling transaction data: %v", err)
		sendErrorResponse(w, "Invalid transaction data", http.StatusBadRequest)
		return
	}

	// Get payment method and reference ID
	paymentMethod := "myket"
	referenceID := ""

	if sku, ok := req.Transaction["sku"].(string); ok {
		referenceID = sku
	} else if orderId, ok := req.Transaction["orderId"].(string); ok {
		referenceID = orderId
	} else {
		// Generate a unique reference ID if none provided
		referenceID = "tx_" + strconv.FormatInt(time.Now().UnixNano(), 10)
	}

	// Check if this transaction has already been processed
	existingTx, err := db.GetTransactionByReferenceID(referenceID)
	if err == nil && existingTx.ID > 0 {
		// Transaction already exists
		log.Printf("Transaction already processed: %s", referenceID)

		// Return success but with a different status code
		response := struct {
			Message     string  `json:"message"`
			Credit      float64 `json:"credit"`
			Transaction struct {
				ID          int64  `json:"id"`
				ReferenceID string `json:"reference_id"`
				Status      string `json:"status"`
			} `json:"transaction"`
			AlreadyProcessed bool `json:"already_processed"`
		}{}

		// Get user's current credit
		user, err := db.GetUserByID(userID)
		if err != nil {
			log.Printf("Error getting user by ID: %v", err)
			sendErrorResponse(w, "Error getting user information", http.StatusInternalServerError)
			return
		}

		response.Message = "Transaction already processed"
		response.Credit = user.Credit
		response.Transaction.ID = existingTx.ID
		response.Transaction.ReferenceID = existingTx.ReferenceID
		response.Transaction.Status = existingTx.Status
		response.AlreadyProcessed = true

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusConflict) // 409 Conflict
		json.NewEncoder(w).Encode(response)
		return
	}

	// Create a new transaction
	transaction := models.Transaction{
		UserID:        userID,
		Amount:        req.Amount,
		PaymentMethod: paymentMethod,
		ReferenceID:   referenceID,
		Status:        "completed",
		CreatedAt:     time.Now(),
		Metadata:      string(transactionData),
	}

	// Save transaction to database
	txID, err := db.CreateTransaction(transaction)
	if err != nil {
		log.Printf("Error creating transaction: %v", err)
		sendErrorResponse(w, "Error processing payment", http.StatusInternalServerError)
		return
	}

	// Add credit to user
	err = db.AddUserCredit(userID, req.Amount)
	if err != nil {
		log.Printf("Error adding credit: %v", err)

		// Update transaction status to failed
		db.UpdateTransactionStatus(txID, "failed")

		sendErrorResponse(w, "Error adding credit to account", http.StatusInternalServerError)
		return
	}

	// Get updated user
	user, err := db.GetUserByID(userID)
	if err != nil {
		log.Printf("Error getting updated user: %v", err)
		sendErrorResponse(w, "Error getting updated user information", http.StatusInternalServerError)
		return
	}

	// Return success response
	response := struct {
		Message     string  `json:"message"`
		Credit      float64 `json:"credit"`
		Transaction struct {
			ID          int64  `json:"id"`
			ReferenceID string `json:"reference_id"`
			Status      string `json:"status"`
		} `json:"transaction"`
	}{
		Message: "Payment processed successfully",
		Credit:  user.Credit,
	}

	response.Transaction.ID = txID
	response.Transaction.ReferenceID = referenceID
	response.Transaction.Status = "completed"

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated) // 201 Created
	json.NewEncoder(w).Encode(response)
}

// GetUserTransactions returns the transaction history for the authenticated user
func (h *CreditHandler) GetUserTransactions(w http.ResponseWriter, r *http.Request) {
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

	// Get pagination parameters
	limitStr := r.URL.Query().Get("limit")
	offsetStr := r.URL.Query().Get("offset")

	limit := 10 // Default limit
	offset := 0 // Default offset

	if limitStr != "" {
		parsedLimit, err := strconv.Atoi(limitStr)
		if err == nil && parsedLimit > 0 {
			limit = parsedLimit
		}
	}

	if offsetStr != "" {
		parsedOffset, err := strconv.Atoi(offsetStr)
		if err == nil && parsedOffset >= 0 {
			offset = parsedOffset
		}
	}

	// Get transactions from database
	transactions, err := db.GetUserTransactions(userID, limit, offset)
	if err != nil {
		log.Printf("Error getting user transactions: %v", err)
		sendErrorResponse(w, "Error retrieving transaction history", http.StatusInternalServerError)
		return
	}

	// Return transactions
	response := struct {
		Transactions []models.Transaction `json:"transactions"`
		Count        int                  `json:"count"`
		Limit        int                  `json:"limit"`
		Offset       int                  `json:"offset"`
	}{
		Transactions: transactions,
		Count:        len(transactions),
		Limit:        limit,
		Offset:       offset,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// AddCreditSelf handles adding credit to the authenticated user's account
func (h *CreditHandler) AddCreditSelf(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from context
	userID, ok := r.Context().Value("user_id").(int64)
	if !ok {
		sendErrorResponse(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Parse request body
	var req struct {
		Amount float64 `json:"amount"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.Amount <= 0 {
		sendErrorResponse(w, "Amount must be greater than zero", http.StatusBadRequest)
		return
	}

	// Add credit to user
	err := db.AddUserCredit(userID, req.Amount)
	if err != nil {
		log.Printf("Error adding credit: %v", err)
		sendErrorResponse(w, "Failed to add credit", http.StatusInternalServerError)
		return
	}

	// Get updated user credit
	user, err := db.GetUserByID(userID)
	if err != nil {
		log.Printf("Error getting user by ID: %v", err)
		sendErrorResponse(w, "User not found", http.StatusNotFound)
		return
	}

	// Return success response
	sendJSONResponse(w, map[string]interface{}{
		"success": true,
		"message": "Credit added successfully",
		"credit":  user.Credit,
	})
}

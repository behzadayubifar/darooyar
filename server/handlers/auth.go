package handlers

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/darooyar/server/auth"
	"github.com/darooyar/server/db"
	"github.com/darooyar/server/models"
)

type AuthHandler struct{}

func NewAuthHandler() *AuthHandler {
	return &AuthHandler{}
}

// Register handles user registration
func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var userCreate models.UserCreate
	if err := json.NewDecoder(r.Body).Decode(&userCreate); err != nil {
		log.Printf("Error decoding request body: %v", err)
		sendErrorResponse(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	log.Printf("Registering user: %v", userCreate)

	// Hash the password
	hashedPassword, err := auth.HashPassword(userCreate.Password)
	if err != nil {
		log.Printf("Error hashing password: %v", err)
		sendErrorResponse(w, "Error processing password", http.StatusInternalServerError)
		return
	}

	// Create user with hashed password
	userCreate.Password = hashedPassword
	user, err := db.CreateUser(&userCreate)
	if err != nil {
		log.Printf("Error creating user: %v", err)
		sendErrorResponse(w, "Error creating user", http.StatusInternalServerError)
		return
	}

	// Generate JWT token
	token, err := auth.GenerateToken(user)
	if err != nil {
		log.Printf("Error generating token: %v", err)
		sendErrorResponse(w, "Error generating token", http.StatusInternalServerError)
		return
	}

	// Return user info and token
	response := struct {
		User  models.UserResponse `json:"user"`
		Token string              `json:"token"`
	}{
		User: models.UserResponse{
			ID:        user.ID,
			Username:  user.Username,
			Email:     user.Email,
			FirstName: user.FirstName,
			LastName:  user.LastName,
			Credit:    user.Credit,
			CreatedAt: user.CreatedAt,
		},
		Token: token,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}

// Login handles user login
func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var login models.UserLogin
	if err := json.NewDecoder(r.Body).Decode(&login); err != nil {
		sendErrorResponse(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Get user by email
	user, err := db.GetUserByEmail(login.Email)
	if err != nil {
		sendErrorResponse(w, "Invalid credentials", http.StatusUnauthorized)
		return
	}

	// Check password
	if !auth.CheckPassword(login.Password, user.Password) {
		sendErrorResponse(w, "Invalid credentials", http.StatusUnauthorized)
		return
	}

	// Generate JWT token
	token, err := auth.GenerateToken(user)
	if err != nil {
		sendErrorResponse(w, "Error generating token", http.StatusInternalServerError)
		return
	}

	// Return user info and token
	response := struct {
		User  models.UserResponse `json:"user"`
		Token string              `json:"token"`
	}{
		User: models.UserResponse{
			ID:        user.ID,
			Username:  user.Username,
			Email:     user.Email,
			FirstName: user.FirstName,
			LastName:  user.LastName,
			Credit:    user.Credit,
			CreatedAt: user.CreatedAt,
		},
		Token: token,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// GetMe gets the current authenticated user
func (h *AuthHandler) GetMe(w http.ResponseWriter, r *http.Request) {
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

	// Return user info without sensitive data
	response := models.UserResponse{
		ID:        user.ID,
		Username:  user.Username,
		Email:     user.Email,
		FirstName: user.FirstName,
		LastName:  user.LastName,
		Credit:    user.Credit,
		CreatedAt: user.CreatedAt,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// VerifyToken checks if a token is valid and returns user information
func (h *AuthHandler) VerifyToken(w http.ResponseWriter, r *http.Request) {
	// Get user ID from context (this will be set by the auth middleware if token is valid)
	userID, ok := r.Context().Value("user_id").(int64)
	if !ok {
		http.Error(w, "Invalid or expired token", http.StatusUnauthorized)
		return
	}

	// Get additional user info if needed
	user, err := db.GetUserByID(userID)
	if err != nil {
		http.Error(w, "Error retrieving user data", http.StatusInternalServerError)
		return
	}

	// Return user information
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":    "success",
		"message":   "Token is valid",
		"user_id":   userID,
		"username":  user.Username,
		"credit":    user.Credit,
		"is_active": true,
	})
}

// Helper function to send error responses in JSON format
func sendErrorResponse(w http.ResponseWriter, message string, statusCode int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(map[string]string{"message": message})
}

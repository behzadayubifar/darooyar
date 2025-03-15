package handlers

import (
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"unicode"

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
			IsAdmin:   user.IsAdmin,
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
			IsAdmin:   user.IsAdmin,
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
		IsAdmin:   user.IsAdmin,
		CreatedAt: user.CreatedAt,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// UpdateProfile updates the user's profile information
func (h *AuthHandler) UpdateProfile(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut && r.Method != http.MethodPatch {
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
	var profileUpdate models.ProfileUpdate
	if err := json.NewDecoder(r.Body).Decode(&profileUpdate); err != nil {
		log.Printf("Error decoding request body: %v", err)
		sendErrorResponse(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Update user profile
	updatedUser, err := db.UpdateUserProfile(userID, &profileUpdate)
	if err != nil {
		log.Printf("Error updating user profile: %v", err)
		sendErrorResponse(w, "Error updating profile", http.StatusInternalServerError)
		return
	}

	// Return updated user info
	response := models.UserResponse{
		ID:        updatedUser.ID,
		Username:  updatedUser.Username,
		Email:     updatedUser.Email,
		FirstName: updatedUser.FirstName,
		LastName:  updatedUser.LastName,
		Credit:    updatedUser.Credit,
		IsAdmin:   updatedUser.IsAdmin,
		CreatedAt: updatedUser.CreatedAt,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// ChangePassword changes the user's password
func (h *AuthHandler) ChangePassword(w http.ResponseWriter, r *http.Request) {
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
	var passwordChange models.PasswordChange
	if err := json.NewDecoder(r.Body).Decode(&passwordChange); err != nil {
		log.Printf("Error decoding request body: %v", err)
		sendErrorResponse(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate new password
	if err := validatePassword(passwordChange.NewPassword); err != nil {
		log.Printf("Invalid new password: %v", err)
		sendErrorResponse(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Get user to verify current password
	user, err := db.GetUserByID(userID)
	if err != nil {
		log.Printf("Error getting user by ID: %v", err)
		sendErrorResponse(w, "User not found", http.StatusNotFound)
		return
	}

	// Verify current password
	if !auth.CheckPassword(passwordChange.CurrentPassword, user.Password) {
		sendErrorResponse(w, "Current password is incorrect", http.StatusUnauthorized)
		return
	}

	// Hash the new password
	hashedPassword, err := auth.HashPassword(passwordChange.NewPassword)
	if err != nil {
		log.Printf("Error hashing password: %v", err)
		sendErrorResponse(w, "Error processing password", http.StatusInternalServerError)
		return
	}

	// Update password in database
	err = db.UpdateUserPassword(userID, hashedPassword)
	if err != nil {
		log.Printf("Error updating password: %v", err)
		sendErrorResponse(w, "Error updating password", http.StatusInternalServerError)
		return
	}

	// Return success response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"message": "Password updated successfully",
	})
}

// validatePassword checks if a password meets the required criteria
func validatePassword(password string) error {
	if len(password) < 8 {
		return errors.New("Password must be at least 8 characters long")
	}

	hasUpper := false
	hasLower := false
	hasDigit := false

	for _, char := range password {
		if unicode.IsUpper(char) {
			hasUpper = true
		} else if unicode.IsLower(char) {
			hasLower = true
		} else if unicode.IsDigit(char) {
			hasDigit = true
		}
	}

	if !hasUpper {
		return errors.New("Password must contain at least one uppercase letter")
	}
	if !hasLower {
		return errors.New("Password must contain at least one lowercase letter")
	}
	if !hasDigit {
		return errors.New("Password must contain at least one digit")
	}

	return nil
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
		"is_admin":  user.IsAdmin,
		"is_active": true,
	})
}

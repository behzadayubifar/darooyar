package handlers

import (
	"encoding/json"
	"net/http"
)

// sendErrorResponse is a helper function to send error responses
func sendErrorResponse(w http.ResponseWriter, message string, statusCode int) {
	response := map[string]interface{}{
		"status":  "error",
		"message": message,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(response)
}

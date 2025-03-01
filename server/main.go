package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/darooyar/server/handlers"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables from .env file
	if err := godotenv.Load(); err != nil {
		log.Println("Warning: No .env file found, using system environment variables")
	}

	// Create a new ServeMux (router)
	mux := http.NewServeMux()

	// Initialize handlers
	prescriptionHandler := handlers.NewPrescriptionHandler()
	avalAIHandler := handlers.NewAvalAIHandler()

	// Define API routes

	// Health check endpoint
	mux.HandleFunc("GET /api/health", func(w http.ResponseWriter, r *http.Request) {
		response := map[string]interface{}{
			"status":  "success",
			"message": "دارویار API is running",
			"version": "1.0.0",
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(response)
	})

	// Prescription analysis endpoints
	mux.HandleFunc("POST /api/analyze-prescription/text", prescriptionHandler.AnalyzePrescriptionText)
	mux.HandleFunc("POST /api/analyze-prescription/image", prescriptionHandler.AnalyzePrescriptionImage)

	// AI endpoints
	mux.HandleFunc("POST /api/ai/completion", avalAIHandler.GenerateCompletion)
	mux.HandleFunc("POST /api/ai/analyze-prescription", avalAIHandler.AnalyzePrescriptionWithAI)

	// Configure CORS middleware
	handler := corsMiddleware(mux)

	// Set up the server
	server := &http.Server{
		Addr:         ":8080",
		Handler:      handler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start the server
	log.Println("Starting دارویار API server on :8080")
	if err := server.ListenAndServe(); err != nil {
		log.Fatalf("Failed to start server: %v", err)
		os.Exit(1)
	}
}

// corsMiddleware adds CORS headers to all responses
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Set CORS headers
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Origin, Content-Type, Accept, Authorization")
		w.Header().Set("Access-Control-Expose-Headers", "Content-Length")
		w.Header().Set("Access-Control-Allow-Credentials", "true")
		w.Header().Set("Access-Control-Max-Age", "86400") // 24 hours

		// Handle preflight requests
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		// Call the next handler
		next.ServeHTTP(w, r)
	})
}

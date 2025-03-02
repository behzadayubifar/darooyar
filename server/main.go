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
	aiHandler := handlers.NewAIHandler()

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
	mux.HandleFunc("POST /api/ai/completion", aiHandler.GenerateCompletion)
	mux.HandleFunc("POST /api/ai/analyze-prescription", aiHandler.AnalyzePrescriptionWithAI)

	// Configure CORS middleware
	handler := corsMiddleware(mux)

	// Set up the server
	addr := os.Getenv("SERVER_ADDR")
	if addr == "" {
		addr = ":8080" // Default to all interfaces on port 8080
	}

	server := &http.Server{
		Addr:         addr,
		Handler:      handler,
		ReadTimeout:  120 * time.Second,
		WriteTimeout: 120 * time.Second,
		IdleTimeout:  180 * time.Second,
	}

	// Start the server
	log.Printf("Starting دارویار API server on %s", addr)
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

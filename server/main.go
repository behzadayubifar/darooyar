package main

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/darooyar/server/config"
	"github.com/darooyar/server/db"
	"github.com/darooyar/server/db/migrations"
	"github.com/darooyar/server/handlers"
	"github.com/darooyar/server/middleware"
	"github.com/darooyar/server/nats"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables from .env file
	if err := godotenv.Load(); err != nil {
		log.Println("Warning: No .env file found, using system environment variables")
	}

	// Get configuration
	cfg := config.GetConfig()

	// Initialize database
	if err := db.InitDB(cfg); err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}
	defer db.CloseDB()

	// Run database migrations
	if err := migrations.RunMigrations(); err != nil {
		log.Fatalf("Failed to run SQL file database migrations: %v", err)
	}

	// Run SQL migrations
	if err := migrations.RunSQLMigrations(); err != nil {
		log.Fatalf("Failed to run SQL migrations: %v", err)
	}

	// Run in-memory migrations
	if err := migrations.RunInMemoryMigrations(); err != nil {
		log.Fatalf("Failed to run in-memory database migrations: %v", err)
	}

	// Initialize NATS
	if err := nats.InitNATS(); err != nil {
		log.Printf("Warning: Failed to initialize NATS: %v", err)
		log.Println("The server will continue without NATS support. AI requests will be processed synchronously.")
	} else {
		defer nats.CloseNATS()

		// Initialize AI service for NATS
		aiService, err := nats.NewAIService()
		if err != nil {
			log.Printf("Warning: Failed to initialize AI service for NATS: %v", err)
			log.Println("The server will continue without NATS AI service. AI requests will be processed synchronously.")
		} else {
			log.Println("AI service initialized for NATS")
			_ = aiService // Use the service to avoid unused variable warning
		}
	}

	// Create a new ServeMux (router)
	mux := http.NewServeMux()

	// Initialize handlers
	prescriptionHandler := handlers.NewPrescriptionHandler()
	aiHandler := handlers.NewAIHandler()
	authHandler := handlers.NewAuthHandler()
	chatHandler := handlers.NewChatHandler()
	folderHandler := handlers.NewFolderHandler()
	creditHandler := handlers.NewCreditHandler()
	giftHandler := handlers.NewGiftHandler()

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

	// Public endpoints (no auth required)
	mux.HandleFunc("POST /api/auth/register", authHandler.Register)
	mux.HandleFunc("POST /api/auth/login", authHandler.Login)

	// Protected routes (with auth middleware)
	protected := http.NewServeMux()

	// Chat routes
	protected.HandleFunc("POST /api/chats", chatHandler.CreateChat)
	protected.HandleFunc("GET /api/chats", chatHandler.GetUserChats)
	protected.HandleFunc("GET /api/chats/{id}", chatHandler.GetChat)
	protected.HandleFunc("PUT /api/chats/{id}", chatHandler.UpdateChat)
	protected.HandleFunc("DELETE /api/chats/{id}", chatHandler.DeleteChat)
	protected.HandleFunc("GET /api/chats/{id}/messages", chatHandler.GetChatMessages)
	protected.HandleFunc("POST /api/messages", chatHandler.CreateMessage)

	// Additional chat routes with different path patterns for maximum compatibility
	protected.HandleFunc("POST /api/chats/{id}/messages", chatHandler.CreateChatMessage)
	protected.HandleFunc("POST /api/chat/{id}/messages", chatHandler.CreateChatMessage)
	protected.HandleFunc("POST /messages", chatHandler.CreateMessage)
	protected.HandleFunc("POST /chats/{id}/messages", chatHandler.CreateChatMessage)
	protected.HandleFunc("POST /chat/{id}/messages", chatHandler.CreateChatMessage)
	protected.HandleFunc("POST /api/chats/{id}/messages/image", chatHandler.UploadImageMessage)
	protected.HandleFunc("POST /api/chat/{id}/messages/image", chatHandler.UploadImageMessage)
	protected.HandleFunc("POST /chats/{id}/messages/image", chatHandler.UploadImageMessage)
	protected.HandleFunc("POST /chat/{id}/messages/image", chatHandler.UploadImageMessage)

	// Folder routes
	protected.HandleFunc("POST /api/folders", folderHandler.CreateFolder)
	protected.HandleFunc("GET /api/folders", folderHandler.GetUserFolders)
	protected.HandleFunc("GET /api/folders/{id}", folderHandler.GetFolder)
	protected.HandleFunc("PUT /api/folders/{id}", folderHandler.UpdateFolder)
	protected.HandleFunc("DELETE /api/folders/{id}", folderHandler.DeleteFolder)

	// Auth and other routes
	protected.HandleFunc("GET /api/auth/me", authHandler.GetMe)
	protected.HandleFunc("GET /api/auth/verify", authHandler.VerifyToken)
	protected.HandleFunc("PUT /api/auth/profile", authHandler.UpdateProfile)
	protected.HandleFunc("POST /api/auth/change-password", authHandler.ChangePassword)
	protected.HandleFunc("POST /api/analyze-prescription/text", prescriptionHandler.AnalyzePrescriptionText)
	protected.HandleFunc("POST /api/analyze-prescription/image", prescriptionHandler.AnalyzePrescriptionImage)
	protected.HandleFunc("POST /api/ai/completion", aiHandler.GenerateCompletion)
	protected.HandleFunc("POST /api/ai/analyze-prescription", aiHandler.AnalyzePrescriptionWithAI)

	// Credit routes
	protected.HandleFunc("GET /api/credit", creditHandler.GetUserCredit)
	protected.HandleFunc("POST /api/credit/add", creditHandler.AddCredit)
	protected.HandleFunc("POST /api/credit/subtract", creditHandler.SubtractCredit)
	protected.HandleFunc("GET /api/credit/user", creditHandler.GetUserCreditByID)

	// New credit routes for user payments
	protected.HandleFunc("POST /api/user/credit/add", creditHandler.ProcessUserPayment)
	protected.HandleFunc("GET /api/user/transactions", creditHandler.GetUserTransactions)

	// Plan and subscription routes
	protected.HandleFunc("GET /api/plans", handlers.GetAllPlans)
	protected.HandleFunc("GET /api/plans/{id}", handlers.GetPlanByID)
	protected.HandleFunc("POST /api/plans", middleware.RequireAdmin(handlers.CreatePlan)) // Admin only
	protected.HandleFunc("POST /api/subscriptions/purchase", handlers.PurchasePlan)
	protected.HandleFunc("GET /api/subscriptions", handlers.GetUserSubscriptions)
	protected.HandleFunc("GET /api/subscriptions/active", handlers.GetActiveUserSubscriptions)
	protected.HandleFunc("GET /api/subscriptions/current", handlers.GetCurrentUserSubscription)
	protected.HandleFunc("POST /api/subscriptions/use", handlers.UseSubscription)
	protected.HandleFunc("GET /api/transactions", handlers.GetCreditTransactions)

	// Gift routes (admin only)
	protected.HandleFunc("POST /api/gifts/plan", middleware.RequireAdmin(giftHandler.GiftPlanToUser))
	protected.HandleFunc("POST /api/gifts/credit", middleware.RequireAdmin(giftHandler.GiftCreditToUser))
	protected.HandleFunc("GET /api/gifts/user/{id}", middleware.RequireAdmin(giftHandler.GetUserGiftTransactions))
	protected.HandleFunc("GET /api/gifts/admin", middleware.RequireAdmin(giftHandler.GetAdminGiftTransactions))

	// Apply auth middleware to protected routes
	mux.Handle("/api/", middleware.AuthMiddleware(protected))

	// Configure CORS middleware
	handler := corsMiddleware(mux)

	// Apply the auth check middleware to all routes
	handler = middleware.AuthCheckMiddleware(handler)

	// Set up the server
	server := &http.Server{
		Addr:         cfg.ServerAddr,
		Handler:      handler,
		ReadTimeout:  120 * time.Second,
		WriteTimeout: 120 * time.Second,
		IdleTimeout:  180 * time.Second,
	}

	// Start the server
	log.Printf("Starting دارویار API server on %s", cfg.ServerAddr)
	if err := server.ListenAndServe(); err != nil {
		log.Fatalf("Failed to start server: %v", err)
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

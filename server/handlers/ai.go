package handlers

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"

	"github.com/darooyar/server/models"
	"github.com/sashabaranov/go-openai"
)

// AIHandler handles AI-related API endpoints
type AIHandler struct {
	client *openai.Client
}

// NewAIHandler creates a new AI handler
func NewAIHandler() *AIHandler {
	// Get API key from environment variable
	apiKey := os.Getenv("OPENAI_API_KEY")
	if apiKey == "" {
		log.Println("Warning: OPENAI_API_KEY environment variable is not set")
		// In production, you might want to fail fast here
		// For development, we'll continue with a nil client
	}

	// Create OpenAI client
	client := openai.NewClient(apiKey)

	return &AIHandler{
		client: client,
	}
}

// GenerateCompletion handles text completion requests
func (h *AIHandler) GenerateCompletion(w http.ResponseWriter, r *http.Request) {
	// Set content type
	w.Header().Set("Content-Type", "application/json")

	// Check if client is initialized
	if h.client == nil {
		writeErrorResponse(w, "OpenAI client not initialized. API key may be missing.", http.StatusInternalServerError)
		return
	}

	// Parse the request body
	var request models.CompletionRequest
	err := json.NewDecoder(r.Body).Decode(&request)
	if err != nil {
		writeErrorResponse(w, "Invalid request format", http.StatusBadRequest)
		return
	}

	// Validate the request
	if request.Prompt == "" {
		writeErrorResponse(w, "Prompt field is required", http.StatusBadRequest)
		return
	}

	// Log the request (in a real app, you might want to sanitize sensitive data)
	log.Printf("Received completion request: %s", request.Prompt)

	// Call OpenAI API
	resp, err := h.client.CreateChatCompletion(
		context.Background(),
		openai.ChatCompletionRequest{
			Model: openai.GPT3Dot5Turbo,
			Messages: []openai.ChatCompletionMessage{
				{
					Role:    openai.ChatMessageRoleUser,
					Content: request.Prompt,
				},
			},
			MaxTokens: 500,
		},
	)

	if err != nil {
		log.Printf("Error calling OpenAI API: %v", err)
		writeErrorResponse(w, "Error generating completion", http.StatusInternalServerError)
		return
	}

	// Extract the response
	completion := ""
	if len(resp.Choices) > 0 {
		completion = resp.Choices[0].Message.Content
	}

	// Write the response
	response := models.CompletionResponse{
		Status:     "success",
		Completion: completion,
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// AnalyzePrescriptionWithAI handles AI-powered prescription analysis
func (h *AIHandler) AnalyzePrescriptionWithAI(w http.ResponseWriter, r *http.Request) {
	// Set content type
	w.Header().Set("Content-Type", "application/json")

	// Check if client is initialized
	if h.client == nil {
		writeErrorResponse(w, "OpenAI client not initialized. API key may be missing.", http.StatusInternalServerError)
		return
	}

	// Parse the request body
	var request models.TextAnalysisRequest
	err := json.NewDecoder(r.Body).Decode(&request)
	if err != nil {
		writeErrorResponse(w, "Invalid request format", http.StatusBadRequest)
		return
	}

	// Validate the request
	if request.Text == "" {
		writeErrorResponse(w, "Text field is required", http.StatusBadRequest)
		return
	}

	// Log the request
	log.Printf("Received AI prescription analysis request: %s", request.Text)

	// Prepare the prompt for the AI
	prompt := "لطفاً این نسخه پزشکی را تحلیل کنید و داروها، دوزها و توصیه‌های مصرف را استخراج کنید:\n\n" + request.Text

	// Call OpenAI API
	resp, err := h.client.CreateChatCompletion(
		context.Background(),
		openai.ChatCompletionRequest{
			Model: openai.GPT3Dot5Turbo,
			Messages: []openai.ChatCompletionMessage{
				{
					Role:    openai.ChatMessageRoleSystem,
					Content: "شما یک دستیار داروساز هستید که به تحلیل نسخه‌های پزشکی کمک می‌کند. لطفاً داروها، دوزها و توصیه‌های مصرف را به فارسی استخراج کنید.",
				},
				{
					Role:    openai.ChatMessageRoleUser,
					Content: prompt,
				},
			},
			MaxTokens: 1000,
		},
	)

	if err != nil {
		log.Printf("Error calling OpenAI API: %v", err)
		writeErrorResponse(w, "Error analyzing prescription", http.StatusInternalServerError)
		return
	}

	// Extract the response
	analysis := ""
	if len(resp.Choices) > 0 {
		analysis = resp.Choices[0].Message.Content
	}

	// Write the response
	response := models.AnalysisResponse{
		Status:   "success",
		Analysis: analysis,
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

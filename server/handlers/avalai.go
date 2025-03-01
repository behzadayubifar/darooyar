package handlers

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"

	"github.com/darooyar/server/models"
)

// AvalAIHandler handles AI-related API endpoints using Aval AI
type AvalAIHandler struct {
	apiKey  string
	baseURL string
}

// NewAvalAIHandler creates a new Aval AI handler
func NewAvalAIHandler() *AvalAIHandler {
	// Get API key from environment variable
	apiKey := os.Getenv("AVALAI_API_KEY")
	if apiKey == "" {
		log.Println("Warning: AVALAI_API_KEY environment variable is not set")
		// In production, you might want to fail fast here
	}

	// Get base URL from environment variable or use default
	baseURL := os.Getenv("AVALAI_API_BASE_URL")
	if baseURL == "" {
		baseURL = "https://api.avalai.ir/v1"
		log.Println("Using default Aval AI base URL:", baseURL)
	}

	return &AvalAIHandler{
		apiKey:  apiKey,
		baseURL: baseURL,
	}
}

// makeRequest makes a request to the Aval AI API
func (h *AvalAIHandler) makeRequest(ctx context.Context, endpoint string, requestBody interface{}) (*http.Response, error) {
	// Convert request body to JSON
	jsonBody, err := json.Marshal(requestBody)
	if err != nil {
		return nil, fmt.Errorf("error marshaling request: %w", err)
	}

	// Create request
	url := h.baseURL + endpoint
	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewBuffer(jsonBody))
	if err != nil {
		return nil, fmt.Errorf("error creating request: %w", err)
	}

	// Set headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+h.apiKey)

	// Make request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("error making request: %w", err)
	}

	return resp, nil
}

// GenerateCompletion handles text completion requests
func (h *AvalAIHandler) GenerateCompletion(w http.ResponseWriter, r *http.Request) {
	// Set content type
	w.Header().Set("Content-Type", "application/json")

	// Check if API key is initialized
	if h.apiKey == "" {
		writeErrorResponse(w, "Aval AI API key not initialized. API key may be missing.", http.StatusInternalServerError)
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

	// Prepare request for Aval AI API
	avalAIRequest := models.AvalAICompletionRequest{
		Model: "gpt-3.5-turbo", // Default model
		Messages: []models.AvalAIMessage{
			{
				Role:    "user",
				Content: request.Prompt,
			},
		},
		MaxTokens: 500,
	}

	// Make request to Aval AI API
	resp, err := h.makeRequest(r.Context(), "/chat/completions", avalAIRequest)
	if err != nil {
		log.Printf("Error calling Aval AI API: %v", err)
		writeErrorResponse(w, "Error generating completion", http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	// Check response status
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		log.Printf("Aval AI API error (status %d): %s", resp.StatusCode, string(body))
		writeErrorResponse(w, fmt.Sprintf("Aval AI API error (status %d)", resp.StatusCode), http.StatusInternalServerError)
		return
	}

	// Parse response
	var avalAIResponse models.AvalAICompletionResponse
	if err := json.NewDecoder(resp.Body).Decode(&avalAIResponse); err != nil {
		log.Printf("Error parsing Aval AI response: %v", err)
		writeErrorResponse(w, "Error parsing completion response", http.StatusInternalServerError)
		return
	}

	// Extract the response
	completion := ""
	if len(avalAIResponse.Choices) > 0 {
		completion = avalAIResponse.Choices[0].Message.Content
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
func (h *AvalAIHandler) AnalyzePrescriptionWithAI(w http.ResponseWriter, r *http.Request) {
	// Set content type
	w.Header().Set("Content-Type", "application/json")

	// Check if API key is initialized
	if h.apiKey == "" {
		writeErrorResponse(w, "Aval AI API key not initialized. API key may be missing.", http.StatusInternalServerError)
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

	// Prepare request for Aval AI API
	avalAIRequest := models.AvalAICompletionRequest{
		Model: "gpt-3.5-turbo", // Default model
		Messages: []models.AvalAIMessage{
			{
				Role:    "system",
				Content: "شما یک دستیار داروساز هستید که به تحلیل نسخه‌های پزشکی کمک می‌کند. لطفاً داروها، دوزها و توصیه‌های مصرف را به فارسی استخراج کنید.",
			},
			{
				Role:    "user",
				Content: prompt,
			},
		},
		MaxTokens: 1000,
	}

	// Make request to Aval AI API
	resp, err := h.makeRequest(r.Context(), "/chat/completions", avalAIRequest)
	if err != nil {
		log.Printf("Error calling Aval AI API: %v", err)
		writeErrorResponse(w, "Error analyzing prescription", http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	// Check response status
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		log.Printf("Aval AI API error (status %d): %s", resp.StatusCode, string(body))
		writeErrorResponse(w, fmt.Sprintf("Aval AI API error (status %d)", resp.StatusCode), http.StatusInternalServerError)
		return
	}

	// Parse response
	var avalAIResponse models.AvalAICompletionResponse
	if err := json.NewDecoder(resp.Body).Decode(&avalAIResponse); err != nil {
		log.Printf("Error parsing Aval AI response: %v", err)
		writeErrorResponse(w, "Error parsing analysis response", http.StatusInternalServerError)
		return
	}

	// Extract the response
	analysis := ""
	if len(avalAIResponse.Choices) > 0 {
		analysis = avalAIResponse.Choices[0].Message.Content
	}

	// Write the response
	response := models.AnalysisResponse{
		Status:   "success",
		Analysis: analysis,
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

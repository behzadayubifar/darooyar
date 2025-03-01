package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"

	"github.com/darooyar/server/models"
)

// AvalAIHandler handles Aval AI-related API endpoints
type AvalAIHandler struct {
	apiKey     string
	apiBaseURL string
}

// NewAvalAIHandler creates a new Aval AI handler
func NewAvalAIHandler() *AvalAIHandler {
	// Get API key from environment variable
	apiKey := os.Getenv("AVALAI_API_KEY")
	if apiKey == "" {
		log.Println("Warning: AVALAI_API_KEY environment variable is not set")
	}

	// Get API base URL from environment variable or use default
	apiBaseURL := os.Getenv("AVALAI_API_BASE_URL")
	if apiBaseURL == "" {
		apiBaseURL = "https://api.aval.ai" // Default base URL, replace with actual Aval AI API URL
		log.Println("Using default Aval AI API base URL:", apiBaseURL)
	}

	return &AvalAIHandler{
		apiKey:     apiKey,
		apiBaseURL: apiBaseURL,
	}
}

// GenerateCompletion handles text completion requests
func (h *AvalAIHandler) GenerateCompletion(w http.ResponseWriter, r *http.Request) {
	// Set content type
	w.Header().Set("Content-Type", "application/json")

	// Check if API key is set
	if h.apiKey == "" {
		writeErrorResponse(w, "Aval AI API key not set. Please set AVALAI_API_KEY environment variable.", http.StatusInternalServerError)
		return
	}

	// Parse the request body
	var request models.AvalAICompletionRequest
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

	// Prepare the request to Aval AI API
	// Note: Adjust the request structure based on actual Aval AI API requirements
	requestBody, err := json.Marshal(map[string]interface{}{
		"prompt": request.Prompt,
		"model":  "gpt-3.5", // Replace with appropriate Aval AI model name
	})
	if err != nil {
		log.Printf("Error marshaling request: %v", err)
		writeErrorResponse(w, "Error preparing request", http.StatusInternalServerError)
		return
	}

	// Create HTTP request to Aval AI API
	completionURL := fmt.Sprintf("%s/v1/completions", h.apiBaseURL)
	req, err := http.NewRequest("POST", completionURL, bytes.NewBuffer(requestBody))
	if err != nil {
		log.Printf("Error creating request: %v", err)
		writeErrorResponse(w, "Error creating request", http.StatusInternalServerError)
		return
	}

	// Set headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", h.apiKey))

	// Send request to Aval AI API
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Printf("Error calling Aval AI API: %v", err)
		writeErrorResponse(w, "Error generating completion", http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	// Read response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Printf("Error reading response body: %v", err)
		writeErrorResponse(w, "Error reading response", http.StatusInternalServerError)
		return
	}

	// Check response status code
	if resp.StatusCode != http.StatusOK {
		log.Printf("Aval AI API returned non-200 status code: %d, body: %s", resp.StatusCode, string(body))
		writeErrorResponse(w, fmt.Sprintf("Aval AI API error: %s", string(body)), http.StatusInternalServerError)
		return
	}

	// Parse response
	var avalResponse models.AvalAIAPIResponse
	err = json.Unmarshal(body, &avalResponse)
	if err != nil {
		log.Printf("Error parsing response: %v", err)
		writeErrorResponse(w, "Error parsing response", http.StatusInternalServerError)
		return
	}

	// Check if response is successful
	if !avalResponse.Success {
		log.Printf("Aval AI API returned error: %s", avalResponse.Message)
		writeErrorResponse(w, fmt.Sprintf("Aval AI API error: %s", avalResponse.Message), http.StatusInternalServerError)
		return
	}

	// Extract the completion text
	completion := avalResponse.Data.Text

	// Write the response
	response := models.AvalAICompletionResponse{
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

	// Check if API key is set
	if h.apiKey == "" {
		writeErrorResponse(w, "Aval AI API key not set. Please set AVALAI_API_KEY environment variable.", http.StatusInternalServerError)
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
	systemPrompt := "شما یک دستیار داروساز هستید که به تحلیل نسخه‌های پزشکی کمک می‌کند. لطفاً داروها، دوزها و توصیه‌های مصرف را به فارسی استخراج کنید."
	userPrompt := "لطفاً این نسخه پزشکی را تحلیل کنید و داروها، دوزها و توصیه‌های مصرف را استخراج کنید:\n\n" + request.Text

	// Prepare the request to Aval AI API
	// Note: Adjust the request structure based on actual Aval AI API requirements
	requestBody, err := json.Marshal(map[string]interface{}{
		"model": "gpt-3.5", // Replace with appropriate Aval AI model name
		"messages": []map[string]string{
			{
				"role":    "system",
				"content": systemPrompt,
			},
			{
				"role":    "user",
				"content": userPrompt,
			},
		},
	})
	if err != nil {
		log.Printf("Error marshaling request: %v", err)
		writeErrorResponse(w, "Error preparing request", http.StatusInternalServerError)
		return
	}

	// Create HTTP request to Aval AI API
	chatURL := fmt.Sprintf("%s/v1/chat/completions", h.apiBaseURL)
	req, err := http.NewRequest("POST", chatURL, bytes.NewBuffer(requestBody))
	if err != nil {
		log.Printf("Error creating request: %v", err)
		writeErrorResponse(w, "Error creating request", http.StatusInternalServerError)
		return
	}

	// Set headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", h.apiKey))

	// Send request to Aval AI API
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Printf("Error calling Aval AI API: %v", err)
		writeErrorResponse(w, "Error analyzing prescription", http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	// Read response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Printf("Error reading response body: %v", err)
		writeErrorResponse(w, "Error reading response", http.StatusInternalServerError)
		return
	}

	// Check response status code
	if resp.StatusCode != http.StatusOK {
		log.Printf("Aval AI API returned non-200 status code: %d, body: %s", resp.StatusCode, string(body))
		writeErrorResponse(w, fmt.Sprintf("Aval AI API error: %s", string(body)), http.StatusInternalServerError)
		return
	}

	// Parse response
	var avalResponse models.AvalAIAPIResponse
	err = json.Unmarshal(body, &avalResponse)
	if err != nil {
		log.Printf("Error parsing response: %v", err)
		writeErrorResponse(w, "Error parsing response", http.StatusInternalServerError)
		return
	}

	// Check if response is successful
	if !avalResponse.Success {
		log.Printf("Aval AI API returned error: %s", avalResponse.Message)
		writeErrorResponse(w, fmt.Sprintf("Aval AI API error: %s", avalResponse.Message), http.StatusInternalServerError)
		return
	}

	// Extract the analysis text
	analysis := avalResponse.Data.Text

	// Write the response
	response := models.AnalysisResponse{
		Status:   "success",
		Analysis: analysis,
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

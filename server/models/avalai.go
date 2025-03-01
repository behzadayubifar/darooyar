package models

// AvalAI-related models for the Darooyar API
// These models are used for interacting with the Aval AI API

// AvalAICompletionRequest represents a request for Aval AI text completion
type AvalAICompletionRequest struct {
	Prompt string `json:"prompt" binding:"required"`
}

// AvalAICompletionResponse represents the response from the Aval AI API
type AvalAICompletionResponse struct {
	Status     string `json:"status"`
	Completion string `json:"completion"`
}

// AvalAIAPIResponse represents the raw response structure from Aval AI API
// Note: This structure may need to be adjusted based on actual Aval AI API response format
type AvalAIAPIResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message,omitempty"`
	Data    struct {
		Text string `json:"text"`
	} `json:"data,omitempty"`
}

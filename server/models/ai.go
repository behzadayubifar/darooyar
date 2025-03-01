package models

// CompletionRequest represents a request for AI text completion
type CompletionRequest struct {
	Prompt string `json:"prompt" binding:"required"`
}

// CompletionResponse represents the response from the AI text completion
type CompletionResponse struct {
	Status     string `json:"status"`
	Completion string `json:"completion"`
}

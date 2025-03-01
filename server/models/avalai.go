package models

// AvalAI-related models for the Darooyar API
// These models are used for interacting with the Aval AI API

// AvalAIMessage represents a message in a chat conversation
type AvalAIMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

// AvalAICompletionRequest represents a request for chat completion
type AvalAICompletionRequest struct {
	Model     string          `json:"model"`
	Messages  []AvalAIMessage `json:"messages"`
	MaxTokens int             `json:"max_tokens,omitempty"`
}

// AvalAICompletionChoice represents a completion choice returned by the API
type AvalAICompletionChoice struct {
	Message      AvalAIMessage `json:"message"`
	FinishReason string        `json:"finish_reason"`
}

// AvalAICompletionResponse represents the response from the API
type AvalAICompletionResponse struct {
	ID      string                   `json:"id"`
	Object  string                   `json:"object"`
	Created int64                    `json:"created"`
	Choices []AvalAICompletionChoice `json:"choices"`
}

// CompletionRequest represents a request for AI text completion (client-facing)
// This is reused from the original AI models to maintain compatibility
// type CompletionRequest struct {
//     Prompt string `json:"prompt" binding:"required"`
// }

// CompletionResponse represents the response from the AI text completion (client-facing)
// This is reused from the original AI models to maintain compatibility
// type CompletionResponse struct {
//     Status     string `json:"status"`
//     Completion string `json:"completion"`
// }

// TextAnalysisRequest represents a request for text analysis (client-facing)
// This is reused from the original AI models to maintain compatibility
// type TextAnalysisRequest struct {
//     Text string `json:"text" binding:"required"`
// }

// AnalysisResponse represents the response from the text analysis (client-facing)
// This is reused from the original AI models to maintain compatibility
// type AnalysisResponse struct {
//     Status   string `json:"status"`
//     Analysis string `json:"analysis"`
// }

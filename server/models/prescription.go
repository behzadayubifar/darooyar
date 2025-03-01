package models

import "time"

// TextAnalysisRequest represents a request to analyze prescription text
type TextAnalysisRequest struct {
	Text string `json:"text" binding:"required"`
}

// ImageAnalysisRequest represents a request to analyze a prescription image
// This is handled differently in Gin using FormFile, so we don't need a struct for it

// AnalysisResponse represents the response from the prescription analysis
type AnalysisResponse struct {
	Status   string `json:"status"`
	Analysis string `json:"analysis"`
}

// ErrorResponse represents an error response
type ErrorResponse struct {
	Status  string `json:"status"`
	Message string `json:"message"`
}

// Prescription represents a prescription in the database
type Prescription struct {
	ID        string    `json:"id"`
	Title     string    `json:"title"`
	Text      string    `json:"text,omitempty"`
	ImagePath string    `json:"image_path,omitempty"`
	Analysis  string    `json:"analysis"`
	CreatedAt time.Time `json:"created_at"`
}

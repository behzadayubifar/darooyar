package handlers

import (
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"

	"github.com/darooyar/server/models"
	"github.com/google/uuid"
)

// PrescriptionHandler handles prescription-related API endpoints
type PrescriptionHandler struct {
	// In a real implementation, you would have a database connection here
	// For now, we'll just use mock responses
}

// NewPrescriptionHandler creates a new prescription handler
func NewPrescriptionHandler() *PrescriptionHandler {
	return &PrescriptionHandler{}
}

// AnalyzePrescriptionText handles text-based prescription analysis
func (h *PrescriptionHandler) AnalyzePrescriptionText(w http.ResponseWriter, r *http.Request) {
	// Set content type
	w.Header().Set("Content-Type", "application/json")

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

	// Log the request (in a real app, you might want to sanitize sensitive data)
	log.Printf("Received text analysis request: %s", request.Text)

	// For now, return a mock analysis
	// In a real implementation, you would call an AI service or your own analysis logic
	analysis := h.analyzeText(request.Text)

	// Write the response
	response := models.AnalysisResponse{
		Status:   "success",
		Analysis: analysis,
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// AnalyzePrescriptionImage handles image-based prescription analysis
func (h *PrescriptionHandler) AnalyzePrescriptionImage(w http.ResponseWriter, r *http.Request) {
	// Set content type
	w.Header().Set("Content-Type", "application/json")

	// Parse the multipart form
	err := r.ParseMultipartForm(10 << 20) // 10 MB max
	if err != nil {
		writeErrorResponse(w, "Failed to parse form", http.StatusBadRequest)
		return
	}

	// Get the image file from the request
	file, header, err := r.FormFile("image")
	if err != nil {
		writeErrorResponse(w, "No image file provided", http.StatusBadRequest)
		return
	}
	defer file.Close()

	// Log the request
	log.Printf("Received image analysis request: %s", header.Filename)

	// In a real implementation, you would:
	// 1. Save the file to disk
	// 2. Process the image to extract text
	// 3. Analyze the extracted text

	// Generate a unique filename
	filename := uuid.New().String() + filepath.Ext(header.Filename)

	// For demonstration purposes, we'll save the file to a temporary directory
	// In a real implementation, you would save it to a proper storage location
	tempDir := os.TempDir()
	filePath := filepath.Join(tempDir, filename)

	// Create a new file
	dst, err := os.Create(filePath)
	if err != nil {
		writeErrorResponse(w, "Failed to save image", http.StatusInternalServerError)
		return
	}
	defer dst.Close()

	// Copy the uploaded file to the destination file
	_, err = io.Copy(dst, file)
	if err != nil {
		writeErrorResponse(w, "Failed to save image", http.StatusInternalServerError)
		return
	}

	// For now, return a mock analysis
	analysis := h.analyzeImage(filePath)

	// Write the response
	response := models.AnalysisResponse{
		Status:   "success",
		Analysis: analysis,
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// Helper function to write error responses
func writeErrorResponse(w http.ResponseWriter, message string, statusCode int) {
	response := models.ErrorResponse{
		Status:  "error",
		Message: message,
	}
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(response)
}

// analyzeText provides a mock analysis of prescription text
func (h *PrescriptionHandler) analyzeText(text string) string {
	// In a real implementation, this would call an AI service or your own analysis logic
	return "\u062A\u062D\u0644\u06CC\u0644 \u0645\u062A\u0646 \u0646\u0633\u062E\u0647: \u0627\u06CC\u0646 \u0646\u0633\u062E\u0647 \u0634\u0627\u0645\u0644 \u062F\u0627\u0631\u0648\u0647\u0627\u06CC " +
		"\u0622\u0645\u0648\u06A9\u0633\u06CC\u0633\u06CC\u0644\u06CC\u0646 (500 \u0645\u06CC\u0644\u06CC\u06AF\u0631\u0645\u060C 3 \u0628\u0627\u0631 \u062F\u0631 \u0631\u0648\u0632)\u060C " +
		"\u0627\u0633\u062A\u0627\u0645\u06CC\u0646\u0648\u0641\u0646 (500 \u0645\u06CC\u0644\u06CC\u06AF\u0631\u0645\u060C \u0647\u0631 6 \u0633\u0627\u0639\u062A \u062F\u0631 \u0635\u0648\u0631\u062A \u062F\u0631\u062F) " +
		"\u0645\u06CC\u0628\u0627\u0634\u062F. \u062A\u0648\u0635\u06CC\u0647 \u0645\u06CC\u0634\u0648\u062F \u062F\u0627\u0631\u0648 \u0631\u0627 \u0628\u0627 \u063A\u0630\u0627 \u0645\u0635\u0631\u0641 \u06A9\u0646\u06CC\u062F \u0648 \u062F\u0648\u0631\u0647 \u062F\u0631\u0645\u0627\u0646 \u0631\u0627 \u06A9\u0627\u0645\u0644 \u06A9\u0646\u06CC\u062F."
}

// analyzeImage provides a mock analysis of a prescription image
func (h *PrescriptionHandler) analyzeImage(imagePath string) string {
	// In a real implementation, this would process the image and extract text
	return "\u062A\u062D\u0644\u06CC\u0644 \u062A\u0635\u0648\u06CC\u0631 \u0646\u0633\u062E\u0647: \u0627\u06CC\u0646 \u0646\u0633\u062E\u0647 \u0634\u0627\u0645\u0644 \u062F\u0627\u0631\u0648\u0647\u0627\u06CC \u0622\u0646\u062A\u06CC\u0628\u06CC\u0648\u062A\u06CC\u06A9 \u0648 \u0645\u0633\u06A9\u0646 \u0627\u0633\u062A. " +
		"\u062A\u0648\u0635\u06CC\u0647 \u0645\u06CC\u0634\u0648\u062F \u062F\u0627\u0631\u0648 \u0631\u0627 \u0637\u0628\u0642 \u062F\u0633\u062A\u0648\u0631 \u067E\u0632\u0634\u06A9 \u0645\u0635\u0631\u0641 \u06A9\u0646\u06CC\u062F. " +
		"\u062F\u0627\u0631\u0648\u0647\u0627\u06CC \u062A\u062C\u0648\u06CC\u0632 \u0634\u062F\u0647: \u0622\u0632\u06CC\u062A\u0631\u0648\u0645\u0627\u06CC\u0633\u06CC\u0646 (250 \u0645\u06CC\u0644\u06CC\u06AF\u0631\u0645\u060C \u0631\u0648\u0632\u06CC \u06CC\u06A9 \u0639\u062F\u062F)\u060C " +
		"\u0627\u06CC\u0628\u0648\u067E\u0631\u0648\u0641\u0646 (400 \u0645\u06CC\u0644\u06CC\u06AF\u0631\u0645\u060C \u0647\u0631 8 \u0633\u0627\u0639\u062A \u062F\u0631 \u0635\u0648\u0631\u062A \u062F\u0631\u062F)."
}

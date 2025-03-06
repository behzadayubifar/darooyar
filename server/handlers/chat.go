package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/darooyar/server/db"
	"github.com/darooyar/server/models"
	"github.com/darooyar/server/storage"
	"github.com/google/uuid"
)

type ChatHandler struct{}

func NewChatHandler() *ChatHandler {
	return &ChatHandler{}
}

// CreateChat creates a new chat
func (h *ChatHandler) CreateChat(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from context
	userID, ok := r.Context().Value("user_id").(int64)
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	var chatCreate models.ChatCreate
	if err := json.NewDecoder(r.Body).Decode(&chatCreate); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	chat, err := db.CreateChat(&chatCreate, userID)
	if err != nil {
		http.Error(w, "Error creating chat", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(chat)
}

// GetChat retrieves a chat by ID with its messages
func (h *ChatHandler) GetChat(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from context
	userID, ok := r.Context().Value("user_id").(int64)
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Get chat ID from URL
	var chatID int64
	var err error

	// Try to get chat ID from path parameter first
	chatIDStr := r.PathValue("id")
	if chatIDStr != "" {
		chatID, err = strconv.ParseInt(chatIDStr, 10, 64)
		if err != nil {
			http.Error(w, "Invalid chat ID in path", http.StatusBadRequest)
			return
		}
	} else {
		// Fall back to query parameter
		chatID, err = strconv.ParseInt(r.URL.Query().Get("id"), 10, 64)
		if err != nil {
			http.Error(w, "Invalid chat ID in query", http.StatusBadRequest)
			return
		}
	}

	chat, err := db.GetChat(chatID, userID)
	if err != nil {
		http.Error(w, "Chat not found or unauthorized", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(chat)
}

// GetUserChats retrieves all chats for the current user
func (h *ChatHandler) GetUserChats(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from context
	userID, ok := r.Context().Value("user_id").(int64)
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	chats, err := db.GetUserChats(userID)
	if err != nil {
		// Return an empty array instead of an error
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode([]struct{}{})
		return
	}

	// If chats is nil, return an empty array
	if chats == nil {
		chats = []models.Chat{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(chats)
}

// Helper function to detect prescription messages
func isPrescriptionMessage(content string) bool {
	// Common patterns for prescriptions in Persian and English
	prescriptionMarkers := []string{
		"نسخه:",
		"نسخه :",
		"نسخه ",
		"prescription:",
		"prescription ",
		"rx:",
		"rx ",
		"دارو:",
		"دارو ",
		"داروی ",
		"قرص ",
		"کپسول ",
		"شربت ",
		"آمپول ",
	}

	lowerContent := strings.ToLower(content)

	for _, marker := range prescriptionMarkers {
		if strings.Contains(lowerContent, strings.ToLower(marker)) {
			return true
		}
	}

	return false
}

// CreateMessage creates a new message in a chat
func (h *ChatHandler) CreateMessage(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from context
	userID, ok := r.Context().Value("user_id").(int64)
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	var msgCreate models.MessageCreate
	if err := json.NewDecoder(r.Body).Decode(&msgCreate); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Verify chat ownership
	_, err := db.GetChat(msgCreate.ChatID, userID)
	if err != nil {
		http.Error(w, "Chat not found or unauthorized", http.StatusNotFound)
		return
	}

	msg, err := db.CreateMessage(&msgCreate)
	if err != nil {
		http.Error(w, "Error creating message", http.StatusInternalServerError)
		return
	}

	// Return the created message
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(msg)

	// Check if this is a prescription message that needs AI analysis
	if msgCreate.Role == "user" && isPrescriptionMessage(msgCreate.Content) {
		log.Printf("Detected prescription message: %s", msgCreate.Content)
		// Process asynchronously to avoid blocking the response
		go h.generateAIResponse(msgCreate.ChatID, msgCreate.Content, userID)
	}
}

// DeleteChat deletes a chat by ID
func (h *ChatHandler) DeleteChat(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from context
	userID, ok := r.Context().Value("user_id").(int64)
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Get chat ID from URL
	chatIDStr := r.PathValue("id")
	chatID, err := strconv.ParseInt(chatIDStr, 10, 64)
	if err != nil {
		http.Error(w, "Invalid chat ID", http.StatusBadRequest)
		return
	}

	// Verify chat ownership before deletion
	_, err = db.GetChat(chatID, userID)
	if err != nil {
		http.Error(w, "Chat not found or unauthorized", http.StatusNotFound)
		return
	}

	// Delete the chat
	err = db.DeleteChat(chatID)
	if err != nil {
		http.Error(w, "Error deleting chat", http.StatusInternalServerError)
		return
	}

	// Return success response
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"status":  "success",
		"message": "Chat deleted successfully",
	})
}

// GetChatMessages retrieves all messages for a specific chat
func (h *ChatHandler) GetChatMessages(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from context
	userID, ok := r.Context().Value("user_id").(int64)
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Get chat ID from URL
	chatIDStr := r.PathValue("id")
	chatID, err := strconv.ParseInt(chatIDStr, 10, 64)
	if err != nil {
		http.Error(w, "Invalid chat ID", http.StatusBadRequest)
		return
	}

	// Verify chat ownership
	_, err = db.GetChat(chatID, userID)
	if err != nil {
		http.Error(w, "Chat not found or unauthorized", http.StatusNotFound)
		return
	}

	// Get messages for the chat
	messages, err := db.GetChatMessages(chatID)
	if err != nil {
		http.Error(w, "Error retrieving messages", http.StatusInternalServerError)
		return
	}

	// If messages is nil, return an empty array
	if messages == nil {
		messages = []models.Message{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(messages)
}

// UpdateChat updates a chat by ID
func (h *ChatHandler) UpdateChat(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut && r.Method != http.MethodPatch {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from context
	userID, ok := r.Context().Value("user_id").(int64)
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Get chat ID from URL
	chatIDStr := r.PathValue("id")
	chatID, err := strconv.ParseInt(chatIDStr, 10, 64)
	if err != nil {
		http.Error(w, "Invalid chat ID", http.StatusBadRequest)
		return
	}

	// Verify chat ownership before update
	_, err = db.GetChat(chatID, userID)
	if err != nil {
		http.Error(w, "Chat not found or unauthorized", http.StatusNotFound)
		return
	}

	var chatUpdate models.ChatUpdate
	if err := json.NewDecoder(r.Body).Decode(&chatUpdate); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Update the chat
	updatedChat, err := db.UpdateChat(chatID, userID, &chatUpdate)
	if err != nil {
		http.Error(w, "Error updating chat", http.StatusInternalServerError)
		return
	}

	// Return updated chat
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(updatedChat)
}

// CreateChatMessage creates a message for a specific chat (path parameter version)
func (h *ChatHandler) CreateChatMessage(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from context
	userID, ok := r.Context().Value("user_id").(int64)
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Get chat ID from URL
	chatIDStr := r.PathValue("id")
	chatID, err := strconv.ParseInt(chatIDStr, 10, 64)
	if err != nil {
		http.Error(w, "Invalid chat ID", http.StatusBadRequest)
		return
	}

	// Parse request body
	var requestBody struct {
		Content     string `json:"content"`
		Role        string `json:"role"`
		ContentType string `json:"content_type,omitempty"`
	}

	if err := json.NewDecoder(r.Body).Decode(&requestBody); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Create message struct
	msgCreate := models.MessageCreate{
		ChatID:  chatID,
		Role:    requestBody.Role,
		Content: requestBody.Content,
	}

	// Verify chat ownership
	_, err = db.GetChat(chatID, userID)
	if err != nil {
		http.Error(w, "Chat not found or unauthorized", http.StatusNotFound)
		return
	}

	// Create the message
	msg, err := db.CreateMessage(&msgCreate)
	if err != nil {
		http.Error(w, "Error creating message", http.StatusInternalServerError)
		return
	}

	// Return the created message
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(msg)

	// Check if this is a prescription message that needs AI analysis
	if requestBody.Role == "user" && isPrescriptionMessage(requestBody.Content) {
		log.Printf("Detected prescription message: %s", requestBody.Content)
		// Process asynchronously to avoid blocking the response
		go h.generateAIResponse(chatID, requestBody.Content, userID)
	}
}

// Helper method to generate AI responses for prescription messages
func (h *ChatHandler) generateAIResponse(chatID int64, content string, userID int64) {
	// Create a direct HTTP request to the AI analysis endpoint
	aiURL := "https://api.avalai.ir/v1/completions"

	// Prepare the AI prompt
	promptText := fmt.Sprintf(`\u0645\u0646 \u0645\u0633\u0626\u0648\u0644 \u0641\u0646\u06CC \u06CC\u06A9 \u062F\u0627\u0631\u0648\u062E\u0627\u0646\u0647 \u0634\u0647\u0631\u06CC \u0647\u0633\u062A\u0645

\u062E\u0648\u0628 \u0641\u06A9\u0631 \u06A9\u0646 \u0648 \u062A\u0645\u0627\u0645 \u062C\u0648\u0627\u0646\u0628 \u0631\u0648 \u0628\u0631\u0631\u0633\u06CC \u06A9\u0646 \u0648 \u0628\u0627 \u0627\u0633\u062A\u062F\u0644\u0627\u0644 \u062C\u0648\u0627\u0628 \u0628\u062F\u0647

\u0648 \u0628\u0647 \u0627\u06CC\u0646 \u0634\u06A9\u0644 \u0628\u0647 \u0645\u0646 \u062F\u0631 \u0645\u0648\u0631\u062F \u0627\u06CC\u0646 \u0646\u0633\u062E\u0647 \u062C\u0648\u0627\u0628 \u0628\u062F\u0647:

\u0628\u0631\u0631\u0633\u06CC \u0646\u0633\u062E\u0647: %s

\u0628\u0627 \u0633\u0644\u0627\u0645 \u0647\u0645\u06A9\u0627\u0631 \u06AF\u0631\u0627\u0645\u06CC\u060C

\u0628\u0627 \u0628\u0631\u0631\u0633\u06CC \u062F\u0627\u0631\u0648\u0647\u0627\u06CC \u0645\u0648\u062C\u0648\u062F \u062F\u0631 \u0646\u0633\u062E\u0647\u060C \u0627\u0637\u0644\u0627\u0639\u0627\u062A \u0632\u06CC\u0631 \u0631\u0627 \u062E\u062F\u0645\u062A \u0634\u0645\u0627 \u0627\u0631\u0627\u0626\u0647 \u0645\u06CC\u062D\u0647\u0645:

\u0644\u06CC\u0633\u062A \u062F\u0627\u0631\u0648\u0647\u0627\u06CC \u0646\u0633\u062E\u0647:
[\u0627\u06CC\u0646\u062C\u0627 \u0644\u06CC\u0633\u062A \u062F\u0627\u0631\u0648\u0647\u0627 \u0631\u0627 \u0628\u0627 \u062A\u0648\u0636\u06CC\u062D \u0645\u062E\u062A\u0635\u0631 \u0647\u0631 \u062F\u0627\u0631\u0648 \u0628\u0646\u0648\u06CC\u0633]

\u06F1. \u062A\u0634\u062E\u06CC\u0635 \u0627\u062D\u062A\u0645\u0627\u0644\u06CC \u0639\u0627\u0631\u0636\u0647 \u06CC\u0627 \u0628\u06CC\u0645\u0627\u0631\u06CC:
[\u062A\u0648\u0636\u06CC\u062D \u0628\u062F\u0647]

\u06F2. \u062A\u062D\u0627\u062E\u0644\u0627\u062A \u0645\u0647\u0645 \u062F\u0627\u0631\u0648\u0647\u0627 \u06A9\u0647 \u0628\u0627\u06CC\u062F \u0628\u0647 \u0628\u06CC\u0645\u0627\u0631 \u06AF\u0648\u0634\u0632\u062F \u0634\u0648\u062F:
[\u062A\u0648\u0636\u06CC\u062D \u0628\u062F\u0647]

\u06F3. \u0639\u0648\u0627\u0631\u0636 \u0645\u0647\u0645 \u0648 \u0634\u0627\u06CC\u0639\u06CC \u06A9\u0647 \u062D\u062A\u0645\u0627 \u0628\u0627\u06CC\u062F \u0628\u06CC\u0645\u0627\u0631 \u062F\u0631 \u0645\u0648\u0631\u062F \u0627\u06CC\u0646 \u062F\u0627\u0631\u0648\u0647\u0627 \u06CC\u0627\u062D\u0634 \u0628\u0627\u0634\u062F:
[\u062A\u0648\u0636\u06CC\u062D \u0628\u062F\u0647]

\u06F4. \u0627\u06AF\u0631 \u062F\u0627\u0631\u0648\u06CC\u06CC \u0631\u0627 \u0628\u0627\u06CC\u062F \u062F\u0631 \u0632\u0645\u0627\u0646 \u062E\u0627\u0635\u06CC \u0627\u0632 \u0631\u0648\u0632 \u0645\u0635\u0631\u0641 \u06A9\u0631\u062F:
[\u062A\u0648\u0636\u06CC\u062D \u0628\u062F\u0647]

\u06F5. \u0627\u06AF\u0631 \u062F\u0627\u0631\u0648\u06CC\u06CC \u0631\u0648 \u0628\u0627\u06CC\u062F \u0628\u0627 \u0641\u0627\u0635\u0644\u0647 \u0627\u0632 \u063A\u0630\u0627 \u06CC\u0627 \u0628\u0627 \u063A\u0630\u0627 \u0645\u0635\u0631\u0641 \u06A9\u0631\u062F:
[\u062A\u0648\u0636\u06CC\u062D \u0628\u062F\u0647]

\u06F6. \u062A\u0639\u062F\u0627\u062F \u0645\u0635\u0631\u0641 \u0631\u0648\u0632\u0627\u0646\u0647 \u0647\u0631 \u062F\u0627\u0631\u0648:
[\u062A\u0648\u0636\u06CC\u062D \u0628\u062F\u0647]

\u06F7. \u0627\u06AF\u0631 \u0628\u0631\u0627\u06CC \u0639\u0627\u0631\u0636\u0647\u200C\u0627\u06CC \u06A9\u0647 \u062F\u0627\u0631\u0648\u0647\u0627 \u0645\u06CC\u062F\u0647\u0646\u062F \u0646\u06CC\u0627\u0632 \u0628\u0647 \u0645\u062F\u06CC\u0631\u06CC\u062A \u062E\u0627\u0635\u06CC \u0648\u062C\u0648\u062F \u062F\u0627\u0631\u062F \u06A9\u0647 \u0628\u0627\u06CC\u062F \u0627\u0637\u0644\u0627\u0639 \u0628\u062F\u0645 \u0628\u06AF\u0648:
[\u062A\u0648\u0636\u06CC\u062D \u0628\u062F\u0647]`, content)

	// Define request payload - using the correct format with a "prompt" field
	requestData := map[string]interface{}{
		"model":       "gemini-2.0-flash-thinking-exp-01-21",
		"prompt":      promptText,
		"max_tokens":  1500,
		"temperature": 0.7,
	}

	// Convert request to JSON
	requestBody, err := json.Marshal(requestData)
	if err != nil {
		log.Printf("Error marshaling AI request: %v", err)
		return
	}

	// API key should be set in environment
	apiKey := os.Getenv("OPENAI_API_KEY")
	if apiKey == "" {
		log.Printf("No API key found for AI service")
		return
	}

	// Create an HTTP client with timeout
	client := &http.Client{
		Timeout: 45 * time.Second, // Increase timeout for large responses
	}

	// Try multiple endpoints in case the primary one fails
	endpoints := []string{
		aiURL,
		"https://api.avalai.ir/v1/chat/completions", // Alternative endpoint
		"https://api.avalai.ir/chat/completions",
		"https://api.openai.com/v1/completions",
	}

	var analysisContent string
	var responseReceived bool

	for _, endpoint := range endpoints {
		// Create the HTTP request
		req, err := http.NewRequest("POST", endpoint, bytes.NewBuffer(requestBody))
		if err != nil {
			log.Printf("Error creating AI request to %s: %v", endpoint, err)
			continue
		}

		// Set headers
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+apiKey)

		// Log the request for debugging
		log.Printf("Trying AI endpoint: %s", endpoint)

		// Send the request
		resp, err := client.Do(req)
		if err != nil {
			log.Printf("Error calling AI service %s: %v", endpoint, err)
			continue
		}

		// Check response status
		if resp.StatusCode != http.StatusOK {
			bodyBytes, _ := io.ReadAll(resp.Body)
			log.Printf("AI service %s returned status %d: %s",
				endpoint, resp.StatusCode, string(bodyBytes))
			resp.Body.Close()
			continue
		}

		// Try to parse the response based on endpoint type
		if strings.Contains(endpoint, "chat") {
			// Parse chat completion format
			var chatResponse struct {
				Choices []struct {
					Message struct {
						Content string `json:"content"`
					} `json:"message"`
				} `json:"choices"`
			}

			if err := json.NewDecoder(resp.Body).Decode(&chatResponse); err != nil {
				log.Printf("Error decoding chat response from %s: %v", endpoint, err)
				resp.Body.Close()
				continue
			}

			if len(chatResponse.Choices) > 0 {
				analysisContent = chatResponse.Choices[0].Message.Content
				responseReceived = true
				resp.Body.Close()
				break
			}
		} else {
			// Parse standard completion format
			var completionResponse struct {
				Choices []struct {
					Text string `json:"text"`
				} `json:"choices"`
			}

			if err := json.NewDecoder(resp.Body).Decode(&completionResponse); err != nil {
				log.Printf("Error decoding completion response from %s: %v", endpoint, err)
				resp.Body.Close()
				continue
			}

			if len(completionResponse.Choices) > 0 {
				analysisContent = completionResponse.Choices[0].Text
				responseReceived = true
				resp.Body.Close()
				break
			}
		}

		resp.Body.Close()
	}

	// If all endpoints failed or returned empty results, use a default message
	if !responseReceived || analysisContent == "" {
		log.Printf("All AI service endpoints failed to provide analysis")
		analysisContent = "عذر می‌خواهم، در تحلیل این نسخه خطایی رخ داد. لطفا دوباره تلاش کنید."
	}

	// Log a sample of the analysis to check if it's being truncated
	if len(analysisContent) > 100 {
		log.Printf("Analysis received (sample): %s...", analysisContent[:100])
		log.Printf("Analysis length: %d characters", len(analysisContent))
	} else {
		log.Printf("Analysis received: %s", analysisContent)
	}

	// Create a new message with the AI analysis
	aiMsg := models.MessageCreate{
		ChatID:  chatID,
		Role:    "assistant",
		Content: analysisContent,
	}

	// Save the AI message to the database
	aiMessage, err := db.CreateMessage(&aiMsg)
	if err != nil {
		log.Printf("Error creating AI response message: %v", err)
		return
	}

	log.Printf("Successfully added AI response to chat %d with message ID: %d", chatID, aiMessage.ID)
}

// UploadImageMessage handles image uploads for chat messages
func (h *ChatHandler) UploadImageMessage(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from context
	userID, ok := r.Context().Value("user_id").(int64)
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Get chat ID from URL
	chatIDStr := r.PathValue("id")
	chatID, err := strconv.ParseInt(chatIDStr, 10, 64)
	if err != nil {
		http.Error(w, "Invalid chat ID", http.StatusBadRequest)
		return
	}

	// Verify chat ownership
	_, err = db.GetChat(chatID, userID)
	if err != nil {
		http.Error(w, "Chat not found or unauthorized", http.StatusNotFound)
		return
	}

	// Parse multipart form
	err = r.ParseMultipartForm(10 << 20) // 10 MB max
	if err != nil {
		http.Error(w, "Failed to parse form", http.StatusBadRequest)
		return
	}

	// Get the image file from the request
	file, header, err := r.FormFile("image")
	if err != nil {
		http.Error(w, "No image file provided", http.StatusBadRequest)
		return
	}
	defer file.Close()

	// Get the role from the form (default to "user" if not provided)
	role := r.FormValue("role")
	if role == "" {
		role = "user"
	}

	// Initialize S3 client
	s3Client, err := storage.NewS3Client()
	if err != nil {
		log.Printf("Error initializing S3 client: %v", err)
		// Fallback to local storage if S3 client initialization fails
		h.handleLocalImageUpload(w, r, chatID, userID, file, header, role)
		return
	}

	// Determine content type
	contentType := header.Header.Get("Content-Type")
	if contentType == "" {
		contentType = "image/jpeg" // Default content type
	}

	// Upload the image to S3
	imageURL, err := s3Client.UploadFile(file, header.Filename, contentType)
	if err != nil {
		log.Printf("Error uploading image to S3: %v", err)
		// Fallback to local storage if S3 upload fails
		h.handleLocalImageUpload(w, r, chatID, userID, file, header, role)
		return
	}

	// Create a message with the image URL
	msgCreate := models.MessageCreate{
		ChatID:      chatID,
		Role:        role,
		Content:     imageURL,
		ContentType: "image",
	}

	// Save the message to the database
	msg, err := db.CreateMessage(&msgCreate)
	if err != nil {
		http.Error(w, "Error creating message", http.StatusInternalServerError)
		return
	}

	// Return the created message
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(msg)
}

// handleLocalImageUpload is a fallback method for handling image uploads locally
func (h *ChatHandler) handleLocalImageUpload(w http.ResponseWriter, r *http.Request, chatID int64, userID int64, file multipart.File, header *multipart.FileHeader, role string) {
	// Generate a unique filename
	filename := uuid.New().String() + filepath.Ext(header.Filename)

	// Create uploads directory if it doesn't exist
	uploadsDir := "uploads"
	if _, err := os.Stat(uploadsDir); os.IsNotExist(err) {
		os.Mkdir(uploadsDir, 0755)
	}

	// Create the file path
	filePath := filepath.Join(uploadsDir, filename)

	// Create a new file
	dst, err := os.Create(filePath)
	if err != nil {
		http.Error(w, "Failed to save image", http.StatusInternalServerError)
		return
	}
	defer dst.Close()

	// Reset the file reader to the beginning
	file.Seek(0, io.SeekStart)

	// Copy the uploaded file to the destination file
	_, err = io.Copy(dst, file)
	if err != nil {
		http.Error(w, "Failed to save image", http.StatusInternalServerError)
		return
	}

	// Create a message with the local file path
	// In a production environment, you would use a proper URL
	serverURL := os.Getenv("SERVER_URL")
	if serverURL == "" {
		serverURL = "http://localhost:8080"
	}
	imageURL := fmt.Sprintf("%s/%s/%s", serverURL, uploadsDir, filename)

	// Create a message with the image URL
	msgCreate := models.MessageCreate{
		ChatID:      chatID,
		Role:        role,
		Content:     imageURL,
		ContentType: "image",
	}

	// Save the message to the database
	msg, err := db.CreateMessage(&msgCreate)
	if err != nil {
		http.Error(w, "Error creating message", http.StatusInternalServerError)
		return
	}

	// Return the created message
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(msg)
}

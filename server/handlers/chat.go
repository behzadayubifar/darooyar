package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/darooyar/server/db"
	"github.com/darooyar/server/models"
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
	promptText := fmt.Sprintf(`من مسئول فنی یک داروخانه شهری هستم

خوب فکر کن و تمام جوانب رو بررسی کن و با استدلال جواب بده

و به این شکل به من در مورد این نسخه جواب بده:

بررسی نسخه: %s

با سلام همکار گرامی،

با بررسی داروهای موجود در نسخه، اطلاعات زیر را خدمت شما ارائه می‌دهم:

لیست داروهای نسخه:
[اینجا لیست داروها را با توضیح مختصر هر دارو بنویس]

۱. تشخیص احتمالی عارضه یا بیماری:
[توضیح بده]

۲. تداخلات مهم داروها که باید به بیمار گوشزد شود:
[توضیح بده]

۳. عوارض مهم و شایعی که حتما باید بیمار در مورد این داروها یادش باشد:
[توضیح بده]

۴. اگر دارویی را باید در زمان خاصی از روز مصرف کرد:
[توضیح بده]

۵. اگر دارویی رو باید با فاصله از غذا یا با غذا مصرف کرد:
[توضیح بده]

۶. تعداد مصرف روزانه هر دارو:
[توضیح بده]

۷. اگر برای عارضه‌ای که داروها میدهند نیاز به مدیریت خاصی وجود دارد که باید اطلاع بدم بگو:
[توضیح بده]`, content)

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

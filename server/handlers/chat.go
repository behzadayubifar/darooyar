package handlers

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"mime/multipart"
	"net"
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
	"github.com/sashabaranov/go-openai"
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

	// Get the server base URL for local images
	serverBaseURL := os.Getenv("SERVER_BASE_URL")
	if serverBaseURL == "" {
		serverBaseURL = "http://localhost:8080"
	}

	// Initialize S3 client
	s3Client, err := storage.NewS3Client()
	if err != nil {
		log.Printf("Error initializing S3 client: %v", err)
		// Continue without regenerating URLs for S3 objects, but still process local images
	}

	// Process each message to update URLs
	for i, msg := range messages {
		// Only process image messages with metadata
		if msg.ContentType == "image" && msg.Metadata != nil {
			// Check if it's a local image
			isLocal, _ := msg.Metadata["isLocal"].(bool)
			if isLocal {
				// For local images, ensure they have the full server URL
				if !strings.HasPrefix(msg.Content, "http") {
					messages[i].Content = serverBaseURL + msg.Content
					log.Printf("Updated local image URL: %s", messages[i].Content)
				}
			} else if s3Client != nil {
				// For S3 images, generate a fresh pre-signed URL
				objectKey, ok := msg.Metadata["objectKey"].(string)
				if ok && objectKey != "" {
					// Generate a fresh pre-signed URL valid for 24 hours
					presignedURL, urlErr := s3Client.GetTemporaryURL(objectKey, 24*time.Hour)
					if urlErr == nil {
						// Update the content with the fresh URL
						messages[i].Content = presignedURL
						log.Printf("Regenerated pre-signed URL for image: %s", presignedURL)
					} else {
						log.Printf("Error generating pre-signed URL: %v", urlErr)
					}
				}
			}
		}
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

به این نسخه تصویری نگاه کن و به من کمک کن. تصویر نسخه در این آدرس قابل مشاهده است: %s

با سلام همکار گرامی،

با بررسی داروهای موجود در نسخه، اطلاعات زیر را خدمت شما ارائه می‌دهم:

<داروها>
لیست کامل داروها را بنویس و برای هر دارو یک توضیح کامل بنویس که شامل دسته دارویی، مکانیسم اثر و کاربرد اصلی آن باشد. حتما همه داروهای موجود در نسخه را بررسی کن و هیچ دارویی را از قلم نینداز.
</داروها>

<تشخیص>
با توجه به ترکیب داروها، تشخیص احتمالی را با جزئیات کامل توضیح بده و دلیل استفاده از هر دارو را در درمان این عارضه شرح بده.
</تشخیص>

<تداخلات>
تمام تداخلات بین داروهای نسخه را با جزئیات بررسی کن. برای هر تداخل، شدت آن، مکانیسم تداخل و راهکارهای مدیریت آن را توضیح بده. اگر تداخل مهمی وجود ندارد، به صراحت ذکر کن.
</تداخلات>

<عوارض>
عوارض شایع و مهم هر دارو را به تفکیک بنویس و توضیح بده که بیمار چگونه باید این عوارض را مدیریت کند. عوارض خطرناک که نیاز به مراجعه فوری به پزشک دارند را مشخص کن.
</عوارض>

<زمان_مصرف>
برای هر دارو، بهترین زمان مصرف را با دلیل آن توضیح بده. مثلا صبح، شب، قبل از خواب، یا در زمان‌های خاص دیگر.
</زمان_مصرف>

<مصرف_با_غذا>
برای هر دارو مشخص کن که آیا باید با غذا، با معده خالی، یا با فاصله از غذا مصرف شود و دلیل این توصیه را توضیح بده.
</مصرف_با_غذا>

<دوز_مصرف>
دوز و تعداد دفعات مصرف هر دارو را به صورت دقیق بنویس و در صورت نیاز، توضیح بده که چرا این دوز توصیه شده است.
</دوز_مصرف>

<مدیریت_عارضه>
توصیه‌های تکمیلی برای مدیریت بیماری یا عارضه را بنویس، مانند رژیم غذایی خاص، فعالیت‌های فیزیکی توصیه شده یا منع شده، و سایر نکات مهم برای بهبود اثربخشی درمان.
</مدیریت_عارضه>`, content)

	// Define request payload - using the correct format with a "prompt" field
	requestData := map[string]interface{}{
		"model":       "gemini-2.0-flash-thinking-exp-01-21", // Use the most advanced model for image understanding
		"prompt":      promptText,
		"max_tokens":  8000,
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

	// Log the full response for debugging
	log.Printf("Full AI response content (length: %d):", len(analysisContent))

	// Check if the content might be truncated
	if len(analysisContent) > 10 {
		lastRune := []rune(analysisContent)[len([]rune(analysisContent))-1]
		if lastRune != '.' && lastRune != '?' && lastRune != '!' &&
			lastRune != '،' && lastRune != '\n' && lastRune != ':' {
			log.Printf("WARNING: Image analysis content may be truncated, doesn't end with sentence terminator")
			log.Printf("Last 50 characters: %s", analysisContent[len(analysisContent)-min(50, len(analysisContent)):])
		}
	}

	// Log sample of content
	if len(analysisContent) > 200 {
		log.Printf("First 100 chars: %s", analysisContent[:100])
		log.Printf("Last 100 chars: %s", analysisContent[len(analysisContent)-100:])
	} else {
		log.Printf("%s", analysisContent)
	}

	// Create a new message with the AI analysis
	aiMsg := models.MessageCreate{
		ChatID:      chatID,
		Role:        "assistant",
		Content:     analysisContent,
		ContentType: "text",
		Metadata:    map[string]interface{}{"length": len(analysisContent)},
	}

	// Save the AI message to the database
	aiMessage, err := db.CreateMessage(&aiMsg)
	if err != nil {
		log.Printf("Error creating AI response message for image: %v", err)
		return
	}

	// Verify the saved content length matches the original
	if len(aiMessage.Content) != len(analysisContent) {
		log.Printf("WARNING: Content length mismatch! Original: %d, Saved: %d",
			len(analysisContent), len(aiMessage.Content))

		// Log more details about the truncation, if it occurred
		if len(aiMessage.Content) < len(analysisContent) {
			truncatedAt := len(aiMessage.Content)
			log.Printf("Content was truncated at position %d", truncatedAt)
			log.Printf("Content before truncation point: %s", analysisContent[max(0, truncatedAt-30):truncatedAt])
			log.Printf("Content after truncation point that was lost: %s", analysisContent[truncatedAt:min(len(analysisContent), truncatedAt+30)])
		}
	} else {
		log.Printf("Content length verified: original and saved lengths match (%d characters)", len(analysisContent))
	}

	log.Printf("Successfully added AI response for image to chat %d with message ID: %d", chatID, aiMessage.ID)
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

	// Get the object key from the URL
	// Full URL format: https://storage.c2.liara.space/darooyar/uploads/image.jpg
	// We need to extract the path after the bucket name
	urlParts := strings.Split(imageURL, "/")
	objectKey := strings.Join(urlParts[4:], "/") // Extract the path after the bucket name

	// Generate a pre-signed URL that will work with private bucket
	// Set expiration time to 24 hours
	presignedURL, err := s3Client.GetTemporaryURL(objectKey, 24*time.Hour)
	if err != nil {
		log.Printf("Error generating pre-signed URL: %v", err)
		http.Error(w, "Error generating pre-signed URL", http.StatusInternalServerError)
		return
	}

	log.Printf("Generated pre-signed URL for image: %s", presignedURL)

	// Store the object key in the database for future reference
	// This way we can generate new pre-signed URLs when needed
	msgCreate := models.MessageCreate{
		ChatID:      chatID,
		Role:        role,
		Content:     presignedURL,
		ContentType: "image",
		// Store the object key as metadata so we can regenerate pre-signed URLs later
		Metadata: map[string]interface{}{"objectKey": objectKey},
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

	// Process image with AI for prescription analysis
	log.Printf("Processing prescription image for chat ID: %d, image URL: %s", chatID, presignedURL)
	// Run image analysis in a goroutine to avoid blocking
	go func() {
		// Add a delay to ensure the frontend can fetch the new message first
		time.Sleep(1 * time.Second)

		// Process the image
		if err := h.generateImageAIResponse(chatID, presignedURL, userID); err != nil {
			log.Printf("Error generating AI response for image: %v", err)

			// Create an error message to inform the user
			errorMsg := models.MessageCreate{
				ChatID:      chatID,
				Role:        "assistant",
				Content:     "عذر می‌خواهم، در تحلیل این نسخه تصویری خطایی رخ داد. لطفا دوباره تلاش کنید یا نسخه را به صورت متنی وارد کنید.",
				ContentType: "text",
			}

			// Save the error message to the database
			_, err := db.CreateMessage(&errorMsg)
			if err != nil {
				log.Printf("Error creating error message: %v", err)
			}
		}
	}()
}

// Helper method to generate AI responses for prescription images
func (h *ChatHandler) generateImageAIResponse(chatID int64, imageURL string, userID int64) error {
	log.Printf("Starting AI analysis for image at URL: %s", imageURL)

	// Get API key from environment variable
	apiKey := os.Getenv("OPENAI_API_KEY")
	if apiKey == "" {
		log.Printf("No API key found for AI service")
		return fmt.Errorf("no API key found")
	}

	// Try different approaches for image analysis in order of preference
	var analysisContent string
	var err error

	// First try with openai client and multimodal approach
	log.Println("Attempting to analyze image with Gemini multimodal approach")
	analysisContent, err = h.tryMultimodalImageAnalysis(apiKey, imageURL)

	// If that fails, fall back to text prompt approach
	if err != nil || analysisContent == "" {
		log.Printf("Multimodal approach failed: %v. Trying with text prompt approach", err)
		analysisContent, err = h.tryTextPromptImageAnalysis(apiKey, imageURL)

		// If that also fails, try direct HTTP approach as final fallback
		if err != nil || analysisContent == "" {
			log.Printf("Text prompt approach failed: %v. Trying direct HTTP approach", err)
			analysisContent, err = h.tryDirectHTTPForImageAnalysis(apiKey, imageURL)

			// If all approaches fail, provide a fallback error message
			if err != nil || analysisContent == "" {
				log.Printf("All image analysis approaches failed: %v", err)
				analysisContent = "عذر می‌خواهم، در تحلیل این نسخه تصویری خطایی رخ داد. لطفا دوباره تلاش کنید یا نسخه را به صورت متنی وارد کنید."
			}
		}
	}

	// Log the full response for debugging
	log.Printf("Full AI response content (length: %d):", len(analysisContent))

	// Check if the content might be truncated
	if len(analysisContent) > 10 {
		lastRune := []rune(analysisContent)[len([]rune(analysisContent))-1]
		if lastRune != '.' && lastRune != '?' && lastRune != '!' &&
			lastRune != '،' && lastRune != '\n' && lastRune != ':' {
			log.Printf("WARNING: Image analysis content may be truncated, doesn't end with sentence terminator")
			log.Printf("Last 50 characters: %s", analysisContent[len(analysisContent)-min(50, len(analysisContent)):])
		}
	}

	// Log sample of content
	if len(analysisContent) > 200 {
		log.Printf("First 100 chars: %s", analysisContent[:100])
		log.Printf("Last 100 chars: %s", analysisContent[len(analysisContent)-100:])
	} else {
		log.Printf("%s", analysisContent)
	}

	// Create a new message with the AI analysis
	aiMsg := models.MessageCreate{
		ChatID:      chatID,
		Role:        "assistant",
		Content:     analysisContent,
		ContentType: "text",
		Metadata:    map[string]interface{}{"length": len(analysisContent)},
	}

	// Save the AI message to the database
	aiMessage, err := db.CreateMessage(&aiMsg)
	if err != nil {
		log.Printf("Error creating AI response message for image: %v", err)
		return err
	}

	// Verify the saved content length matches the original
	if len(aiMessage.Content) != len(analysisContent) {
		log.Printf("WARNING: Content length mismatch! Original: %d, Saved: %d",
			len(analysisContent), len(aiMessage.Content))

		// Log more details about the truncation, if it occurred
		if len(aiMessage.Content) < len(analysisContent) {
			truncatedAt := len(aiMessage.Content)
			log.Printf("Content was truncated at position %d", truncatedAt)
			log.Printf("Content before truncation point: %s", analysisContent[max(0, truncatedAt-30):truncatedAt])
			log.Printf("Content after truncation point that was lost: %s", analysisContent[truncatedAt:min(len(analysisContent), truncatedAt+30)])
		}
	} else {
		log.Printf("Content length verified: original and saved lengths match (%d characters)", len(analysisContent))
	}

	log.Printf("Successfully added AI response for image to chat %d with message ID: %d", chatID, aiMessage.ID)
	return nil
}

// tryMultimodalImageAnalysis attempts to analyze the image using multimodal API
func (h *ChatHandler) tryMultimodalImageAnalysis(apiKey string, imageURL string) (string, error) {
	// Create OpenAI client with custom base URL
	config := openai.DefaultConfig(apiKey)
	config.BaseURL = "https://api.avalai.ir/v1"

	// Configure HTTP client with longer timeouts for image processing
	transport := &http.Transport{
		TLSHandshakeTimeout: 20 * time.Second,
		DisableKeepAlives:   false,
		MaxIdleConns:        10,
		MaxIdleConnsPerHost: 5,
		IdleConnTimeout:     90 * time.Second,
		DialContext: (&net.Dialer{
			Timeout:   30 * time.Second,
			KeepAlive: 30 * time.Second,
		}).DialContext,
	}

	httpClient := &http.Client{
		Timeout:   60 * time.Second,
		Transport: transport,
	}
	config.HTTPClient = httpClient

	client := openai.NewClientWithConfig(config)
	log.Println("OpenAI client initialized for multimodal image analysis")

	// Create a context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
	defer cancel()

	// First, download the image from the pre-signed URL
	log.Printf("Downloading image from URL: %s", imageURL)

	// Create HTTP request to download the image
	req, err := http.NewRequestWithContext(ctx, "GET", imageURL, nil)
	if err != nil {
		log.Printf("Error creating download request: %v", err)
		return "", err
	}

	// Send request to download the image
	downloadResp, err := httpClient.Do(req)
	if err != nil {
		log.Printf("Error downloading image: %v", err)
		return "", err
	}
	defer downloadResp.Body.Close()

	if downloadResp.StatusCode != http.StatusOK {
		log.Printf("Failed to download image, status code: %d", downloadResp.StatusCode)
		return "", fmt.Errorf("failed to download image: status code %d", downloadResp.StatusCode)
	}

	// Read the image data
	imageData, err := io.ReadAll(downloadResp.Body)
	if err != nil {
		log.Printf("Error reading image data: %v", err)
		return "", err
	}

	log.Printf("Successfully downloaded image, size: %d bytes", len(imageData))

	// Encode the image to base64
	base64Image := base64.StdEncoding.EncodeToString(imageData)

	// Create the image data URL with proper MIME type
	mimeType := downloadResp.Header.Get("Content-Type")
	if mimeType == "" || mimeType == "application/octet-stream" {
		// Detect MIME type from file content based on image header bytes
		mimeType = detectImageMimeType(imageData)
	}
	dataURI := fmt.Sprintf("data:%s;base64,%s", mimeType, base64Image)

	log.Printf("Converted image to base64 data URI with MIME type: %s", mimeType)

	// This is specifically for Gemini models which support multimodal in this format
	aiResp, err := client.CreateChatCompletion(
		ctx,
		openai.ChatCompletionRequest{
			Model: "gemini-2.0-flash-thinking-exp-01-21",
			Messages: []openai.ChatCompletionMessage{
				{
					Role: openai.ChatMessageRoleSystem,
					Content: "من مسئول فنی یک داروخانه شهری هستم. لطفا تصویر نسخه ارسالی را تحلیل کن و به صورت ساختار یافته پاسخ بده. پاسخ باید شامل این بخش‌ها باشد:\n\n" +
						"<داروها>\nلیست کامل داروها را بنویس و برای هر دارو یک توضیح کامل بنویس که شامل دسته دارویی، مکانیسم اثر و کاربرد اصلی آن باشد. حتما همه داروهای موجود در نسخه را بررسی کن و هیچ دارویی را از قلم نینداز.\n</داروها>\n\n" +
						"<تشخیص>\nبا توجه به ترکیب داروها، تشخیص احتمالی را با جزئیات کامل توضیح بده و دلیل استفاده از هر دارو را در درمان این عارضه شرح بده.\n</تشخیص>\n\n" +
						"<تداخلات>\nتمام تداخلات بین داروهای نسخه را با جزئیات بررسی کن. برای هر تداخل، شدت آن، مکانیسم تداخل و راهکارهای مدیریت آن را توضیح بده. اگر تداخل مهمی وجود ندارد، به صراحت ذکر کن.\n</تداخلات>\n\n" +
						"<عوارض>\nعوارض شایع و مهم هر دارو را به تفکیک بنویس و توضیح بده که بیمار چگونه باید این عوارض را مدیریت کند. عوارض خطرناک که نیاز به مراجعه فوری به پزشک دارند را مشخص کن.\n</عوارض>\n\n" +
						"<زمان_مصرف>\nبرای هر دارو، بهترین زمان مصرف را با دلیل آن توضیح بده. مثلا صبح، شب، قبل از خواب، یا در زمان‌های خاص دیگر.\n</زمان_مصرف>\n\n" +
						"<مصرف_با_غذا>\nبرای هر دارو مشخص کن که آیا باید با غذا، با معده خالی، یا با فاصله از غذا مصرف شود و دلیل این توصیه را توضیح بده.\n</مصرف_با_غذا>\n\n" +
						"<دوز_مصرف>\nدوز و تعداد دفعات مصرف هر دارو را به صورت دقیق بنویس و در صورت نیاز، توضیح بده که چرا این دوز توصیه شده است.\n</دوز_مصرف>\n\n" +
						"<مدیریت_عارضه>\nتوصیه‌های تکمیلی برای مدیریت بیماری یا عارضه را بنویس، مانند رژیم غذایی خاص، فعالیت‌های فیزیکی توصیه شده یا منع شده، و سایر نکات مهم برای بهبود اثربخشی درمان.\n</مدیریت_عارضه>",
				},
				{
					Role: openai.ChatMessageRoleUser,
					MultiContent: []openai.ChatMessagePart{
						{
							Type: openai.ChatMessagePartTypeText,
							Text: "لطفا این نسخه تصویری را تحلیل کنید:",
						},
						{
							Type: openai.ChatMessagePartTypeImageURL,
							ImageURL: &openai.ChatMessageImageURL{
								URL: dataURI,
							},
						},
					},
				},
			},
			MaxTokens:   8000,
			Temperature: 0.7,
		},
	)

	// Handle any errors
	if err != nil {
		log.Printf("Error calling AI service with multimodal approach: %v", err)

		// Check for timeout
		if ctx.Err() == context.DeadlineExceeded {
			return "", fmt.Errorf("API request timed out")
		}
		return "", fmt.Errorf("failed to get AI analysis: %v", err)
	}

	// Extract the response content
	if len(aiResp.Choices) > 0 {
		analysisContent := aiResp.Choices[0].Message.Content
		log.Printf("Multimodal image analysis received (sample): %s...", analysisContent[:min(100, len(analysisContent))])
		log.Printf("Multimodal image analysis length: %d characters", len(analysisContent))
		return analysisContent, nil
	}

	log.Printf("Multimodal approach returned empty response")
	return "", fmt.Errorf("empty response from multimodal analysis")
}

// Helper function to get the minimum of two integers
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// handleLocalImageUpload is a fallback method to save images locally if S3 upload fails
func (h *ChatHandler) handleLocalImageUpload(w http.ResponseWriter, r *http.Request, chatID int64, userID int64, file multipart.File, header *multipart.FileHeader, role string) {
	// Create uploads directory if it doesn't exist
	uploadsDir := "./uploads"
	if _, err := os.Stat(uploadsDir); os.IsNotExist(err) {
		os.MkdirAll(uploadsDir, 0755)
	}

	// Generate a unique filename
	fileExt := filepath.Ext(header.Filename)
	newFilename := fmt.Sprintf("%s%s", uuid.New().String(), fileExt)
	filePath := filepath.Join(uploadsDir, newFilename)

	// Create new file
	dst, err := os.Create(filePath)
	if err != nil {
		log.Printf("Error creating local file: %v", err)
		http.Error(w, "Error saving image", http.StatusInternalServerError)
		return
	}
	defer dst.Close()

	// Reset file pointer to beginning
	file.Seek(0, 0)

	// Copy uploaded file data to new file
	_, err = io.Copy(dst, file)
	if err != nil {
		log.Printf("Error copying file data: %v", err)
		http.Error(w, "Error saving image", http.StatusInternalServerError)
		return
	}

	// Generate relative URL path for the saved image
	imageURL := fmt.Sprintf("/uploads/%s", newFilename)

	// Store the local file path as the object key for consistency with S3 implementation
	objectKey := fmt.Sprintf("local/%s", newFilename)

	// Create a message with the image URL
	msgCreate := models.MessageCreate{
		ChatID:      chatID,
		Role:        role,
		Content:     imageURL, // Local URL - the frontend will need to handle this differently
		ContentType: "image",
		Metadata: map[string]interface{}{
			"objectKey": objectKey,
			"isLocal":   true,
		},
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

	// Process image with AI in a goroutine
	go func() {
		time.Sleep(1 * time.Second)

		// Use the absolute URL for AI processing
		serverBaseURL := os.Getenv("SERVER_BASE_URL")
		if serverBaseURL == "" {
			serverBaseURL = "http://localhost:8080"
		}
		absoluteImageURL := fmt.Sprintf("%s%s", serverBaseURL, imageURL)

		if err := h.generateImageAIResponse(chatID, absoluteImageURL, userID); err != nil {
			log.Printf("Error generating AI response for local image: %v", err)

			// Create an error message if AI processing fails
			errorMsg := models.MessageCreate{
				ChatID:      chatID,
				Role:        "assistant",
				Content:     "عذر می‌خواهم، در تحلیل این نسخه تصویری خطایی رخ داد. لطفا دوباره تلاش کنید یا نسخه را به صورت متنی وارد کنید.",
				ContentType: "text",
			}

			// Save the error message
			_, err := db.CreateMessage(&errorMsg)
			if err != nil {
				log.Printf("Error creating error message: %v", err)
			}
		}
	}()
}

// tryTextPromptImageAnalysis attempts to analyze the image using a text prompt with the URL
func (h *ChatHandler) tryTextPromptImageAnalysis(apiKey string, imageURL string) (string, error) {
	// Create OpenAI client with custom base URL
	config := openai.DefaultConfig(apiKey)
	config.BaseURL = "https://api.avalai.ir/v1"

	// Configure HTTP client with longer timeouts for image processing
	transport := &http.Transport{
		TLSHandshakeTimeout: 20 * time.Second,
		DisableKeepAlives:   false,
		MaxIdleConns:        10,
		MaxIdleConnsPerHost: 5,
		IdleConnTimeout:     90 * time.Second,
		DialContext: (&net.Dialer{
			Timeout:   30 * time.Second,
			KeepAlive: 30 * time.Second,
		}).DialContext,
	}

	httpClient := &http.Client{
		Timeout:   60 * time.Second,
		Transport: transport,
	}
	config.HTTPClient = httpClient

	client := openai.NewClientWithConfig(config)
	log.Println("OpenAI client initialized for text prompt image analysis")

	// Create a context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
	defer cancel()

	// Create a text prompt that includes the image URL
	promptText := fmt.Sprintf(`من مسئول فنی یک داروخانه شهری هستم

خوب فکر کن و تمام جوانب رو بررسی کن و با استدلال جواب بده

به این نسخه تصویری نگاه کن و به من کمک کن. تصویر نسخه در این آدرس قابل مشاهده است: %s

با سلام همکار گرامی،

با بررسی داروهای موجود در نسخه، اطلاعات زیر را خدمت شما ارائه می‌دهم:

<داروها>
لیست کامل داروها را بنویس و برای هر دارو یک توضیح کامل بنویس که شامل دسته دارویی، مکانیسم اثر و کاربرد اصلی آن باشد. حتما همه داروهای موجود در نسخه را بررسی کن و هیچ دارویی را از قلم نینداز.
</داروها>

<تشخیص>
با توجه به ترکیب داروها، تشخیص احتمالی را با جزئیات کامل توضیح بده و دلیل استفاده از هر دارو را در درمان این عارضه شرح بده.
</تشخیص>

<تداخلات>
تمام تداخلات بین داروهای نسخه را با جزئیات بررسی کن. برای هر تداخل، شدت آن، مکانیسم تداخل و راهکارهای مدیریت آن را توضیح بده. اگر تداخل مهمی وجود ندارد، به صراحت ذکر کن.
</تداخلات>

<عوارض>
عوارض شایع و مهم هر دارو را به تفکیک بنویس و توضیح بده که بیمار چگونه باید این عوارض را مدیریت کند. عوارض خطرناک که نیاز به مراجعه فوری به پزشک دارند را مشخص کن.
</عوارض>

<زمان_مصرف>
برای هر دارو، بهترین زمان مصرف را با دلیل آن توضیح بده. مثلا صبح، شب، قبل از خواب، یا در زمان‌های خاص دیگر.
</زمان_مصرف>

<مصرف_با_غذا>
برای هر دارو مشخص کن که آیا باید با غذا، با معده خالی، یا با فاصله از غذا مصرف شود و دلیل این توصیه را توضیح بده.
</مصرف_با_غذا>

<دوز_مصرف>
دوز و تعداد دفعات مصرف هر دارو را به صورت دقیق بنویس و در صورت نیاز، توضیح بده که چرا این دوز توصیه شده است.
</دوز_مصرف>

<مدیریت_عارضه>
توصیه‌های تکمیلی برای مدیریت بیماری یا عارضه را بنویس، مانند رژیم غذایی خاص، فعالیت‌های فیزیکی توصیه شده یا منع شده، و سایر نکات مهم برای بهبود اثربخشی درمان.
</مدیریت_عارضه>`, imageURL)

	// Use the ChatCompletion API with just the text prompt
	resp, err := client.CreateChatCompletion(
		ctx,
		openai.ChatCompletionRequest{
			Model: "gemini-2.0-flash-thinking-exp-01-21",
			Messages: []openai.ChatCompletionMessage{
				{
					Role:    openai.ChatMessageRoleUser,
					Content: promptText,
				},
			},
			MaxTokens:   8000,
			Temperature: 0.7,
		},
	)

	// Handle any errors
	if err != nil {
		log.Printf("Error calling AI service with text prompt approach: %v", err)
		return "", err
	}

	// Extract the response content
	if len(resp.Choices) > 0 {
		analysisContent := resp.Choices[0].Message.Content
		log.Printf("Text prompt image analysis received (sample): %s...", analysisContent[:min(100, len(analysisContent))])
		log.Printf("Text prompt image analysis length: %d characters", len(analysisContent))
		return analysisContent, nil
	}

	log.Printf("Text prompt approach returned empty response")
	return "", fmt.Errorf("empty response from text prompt analysis")
}

// tryDirectHTTPForImageAnalysis attempts to analyze the image using direct HTTP requests
func (h *ChatHandler) tryDirectHTTPForImageAnalysis(apiKey string, imageURL string) (string, error) {
	// Define the AI service URL
	aiURL := "https://api.avalai.ir/v1/chat/completions"

	// Create an HTTP client with appropriate timeout
	client := &http.Client{
		Timeout: 60 * time.Second,
		Transport: &http.Transport{
			TLSHandshakeTimeout: 20 * time.Second,
			DisableKeepAlives:   false,
			MaxIdleConns:        10,
			MaxIdleConnsPerHost: 5,
			IdleConnTimeout:     90 * time.Second,
			DialContext: (&net.Dialer{
				Timeout:   30 * time.Second,
				KeepAlive: 30 * time.Second,
			}).DialContext,
		},
	}

	// First, download the image from the pre-signed URL
	log.Printf("Downloading image from URL for direct HTTP approach: %s", imageURL)

	// Create HTTP request to download the image
	downloadReq, err := http.NewRequest("GET", imageURL, nil)
	if err != nil {
		log.Printf("Error creating download request: %v", err)
		return "", err
	}

	// Send request to download the image
	downloadResp, err := client.Do(downloadReq)
	if err != nil {
		log.Printf("Error downloading image: %v", err)
		return "", err
	}
	defer downloadResp.Body.Close()

	if downloadResp.StatusCode != http.StatusOK {
		log.Printf("Failed to download image, status code: %d", downloadResp.StatusCode)
		return "", fmt.Errorf("failed to download image: status code %d", downloadResp.StatusCode)
	}

	// Read the image data
	imageData, err := io.ReadAll(downloadResp.Body)
	if err != nil {
		log.Printf("Error reading image data: %v", err)
		return "", err
	}

	log.Printf("Successfully downloaded image for direct HTTP approach, size: %d bytes", len(imageData))

	// Encode the image to base64
	base64Image := base64.StdEncoding.EncodeToString(imageData)

	// Create the image data URL with proper MIME type
	mimeType := downloadResp.Header.Get("Content-Type")
	if mimeType == "" || mimeType == "application/octet-stream" {
		// Detect MIME type from file content based on image header bytes
		mimeType = detectImageMimeType(imageData)
	}
	dataURI := fmt.Sprintf("data:%s;base64,%s", mimeType, base64Image)

	log.Printf("Converted image to base64 data URI with MIME type: %s", mimeType)

	// Create a text prompt that includes the image URL
	requestData := map[string]interface{}{
		"model": "gemini-2.0-flash-thinking-exp-01-21",
		"messages": []map[string]interface{}{
			{
				"role": "system",
				"content": "من مسئول فنی یک داروخانه شهری هستم. لطفا تصویر نسخه ارسالی را تحلیل کن و به صورت ساختار یافته پاسخ بده. پاسخ باید شامل این بخش‌ها باشد:\n\n" +
					"<داروها>\nلیست کامل داروها را بنویس و برای هر دارو یک توضیح کامل بنویس که شامل دسته دارویی، مکانیسم اثر و کاربرد اصلی آن باشد. حتما همه داروهای موجود در نسخه را بررسی کن و هیچ دارویی را از قلم نینداز.\n</داروها>\n\n" +
					"<تشخیص>\nبا توجه به ترکیب داروها، تشخیص احتمالی را با جزئیات کامل توضیح بده و دلیل استفاده از هر دارو را در درمان این عارضه شرح بده.\n</تشخیص>\n\n" +
					"<تداخلات>\nتمام تداخلات بین داروهای نسخه را با جزئیات بررسی کن. برای هر تداخل، شدت آن، مکانیسم تداخل و راهکارهای مدیریت آن را توضیح بده. اگر تداخل مهمی وجود ندارد، به صراحت ذکر کن.\n</تداخلات>\n\n" +
					"<عوارض>\nعوارض شایع و مهم هر دارو را به تفکیک بنویس و توضیح بده که بیمار چگونه باید این عوارض را مدیریت کند. عوارض خطرناک که نیاز به مراجعه فوری به پزشک دارند را مشخص کن.\n</عوارض>\n\n" +
					"<زمان_مصرف>\nبرای هر دارو، بهترین زمان مصرف را با دلیل آن توضیح بده. مثلا صبح، شب، قبل از خواب، یا در زمان‌های خاص دیگر.\n</زمان_مصرف>\n\n" +
					"<مصرف_با_غذا>\nبرای هر دارو مشخص کن که آیا باید با غذا، با معده خالی، یا با فاصله از غذا مصرف شود و دلیل این توصیه را توضیح بده.\n</مصرف_با_غذا>\n\n" +
					"<دوز_مصرف>\nدوز و تعداد دفعات مصرف هر دارو را به صورت دقیق بنویس و در صورت نیاز، توضیح بده که چرا این دوز توصیه شده است.\n</دوز_مصرف>\n\n" +
					"<مدیریت_عارضه>\nتوصیه‌های تکمیلی برای مدیریت بیماری یا عارضه را بنویس، مانند رژیم غذایی خاص، فعالیت‌های فیزیکی توصیه شده یا منع شده، و سایر نکات مهم برای بهبود اثربخشی درمان.\n</مدیریت_عارضه>",
			},
			{
				"role": "user",
				"content": []map[string]interface{}{
					{
						"type": "text",
						"text": "لطفا این نسخه تصویری را تحلیل کنید:",
					},
					{
						"type": "image_url",
						"image_url": map[string]string{
							"url": dataURI,
						},
					},
				},
			},
		},
		"max_tokens":  8000,
		"temperature": 0.7,
	}

	// Convert request to JSON
	requestBody, err := json.Marshal(requestData)
	if err != nil {
		log.Printf("Error marshaling AI request: %v", err)
		return "", err
	}

	// Create the HTTP request
	req, err := http.NewRequest("POST", aiURL, bytes.NewBuffer(requestBody))
	if err != nil {
		log.Printf("Error creating AI request: %v", err)
		return "", err
	}

	// Set headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+apiKey)

	// Log the request for debugging
	log.Printf("Sending direct HTTP request to %s for image analysis", aiURL)

	// Send the request
	resp, err := client.Do(req)
	if err != nil {
		log.Printf("Error calling AI service: %v", err)
		return "", err
	}
	defer resp.Body.Close()

	// Check response status
	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		log.Printf("AI service returned status %d: %s", resp.StatusCode, string(bodyBytes))
		return "", fmt.Errorf("AI service returned status %d", resp.StatusCode)
	}

	// Parse chat completion format
	var chatResponse struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&chatResponse); err != nil {
		log.Printf("Error decoding chat response: %v", err)
		return "", err
	}

	if len(chatResponse.Choices) > 0 {
		analysisContent := chatResponse.Choices[0].Message.Content
		// Log a sample of the analysis
		log.Printf("Direct HTTP image analysis received (sample): %s...", analysisContent[:min(100, len(analysisContent))])
		log.Printf("Direct HTTP image analysis length: %d characters", len(analysisContent))
		return analysisContent, nil
	}

	return "", fmt.Errorf("empty response from direct HTTP approach")
}

// detectImageMimeType attempts to determine the MIME type of an image based on its header bytes
func detectImageMimeType(data []byte) string {
	// Check for common image formats based on file signatures (magic numbers)
	if len(data) > 2 {
		// JPEG: Starts with FF D8 FF
		if data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF {
			return "image/jpeg"
		}

		// PNG: Starts with 89 50 4E 47 0D 0A 1A 0A
		if len(data) > 8 && data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47 &&
			data[4] == 0x0D && data[5] == 0x0A && data[6] == 0x1A && data[7] == 0x0A {
			return "image/png"
		}

		// GIF: Starts with GIF87a or GIF89a
		if len(data) > 6 && data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x38 &&
			(data[4] == 0x37 || data[4] == 0x39) && data[5] == 0x61 {
			return "image/gif"
		}

		// WebP: Starts with RIFF????WEBP
		if len(data) > 12 && data[0] == 0x52 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x46 &&
			data[8] == 0x57 && data[9] == 0x45 && data[10] == 0x42 && data[11] == 0x50 {
			return "image/webp"
		}

		// BMP: Starts with BM
		if len(data) > 2 && data[0] == 0x42 && data[1] == 0x4D {
			return "image/bmp"
		}
	}

	// If we can't determine the type, default to JPEG (most common for prescriptions)
	log.Println("Could not determine image MIME type from content, defaulting to image/jpeg")
	return "image/jpeg"
}

// max returns the larger of x or y.
func max(x, y int) int {
	if x > y {
		return x
	}
	return y
}

package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

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
	chatID, err := strconv.ParseInt(r.URL.Query().Get("id"), 10, 64)
	if err != nil {
		http.Error(w, "Invalid chat ID", http.StatusBadRequest)
		return
	}

	chat, err := db.GetChat(chatID, userID)
	if err != nil {
		http.Error(w, "Error retrieving chat", http.StatusInternalServerError)
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

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(msg)
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

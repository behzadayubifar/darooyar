package models

import (
	"time"
)

type Chat struct {
	ID        int64     `json:"id"`
	UserID    int64     `json:"user_id"`
	Title     string    `json:"title"`
	FolderID  *int64    `json:"folder_id,omitempty"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type Message struct {
	ID          int64                  `json:"id"`
	ChatID      int64                  `json:"chat_id"`
	Role        string                 `json:"role"` // "user" or "assistant"
	Content     string                 `json:"content"`
	ContentType string                 `json:"content_type,omitempty"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
	CreatedAt   time.Time              `json:"created_at"`
}

type ChatCreate struct {
	Title    string `json:"title"`
	FolderID *int64 `json:"folder_id,omitempty"`
}

type MessageCreate struct {
	ChatID      int64                  `json:"chat_id"`
	Role        string                 `json:"role"`
	Content     string                 `json:"content"`
	ContentType string                 `json:"content_type,omitempty"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
}

type ChatResponse struct {
	ID        int64     `json:"id"`
	UserID    int64     `json:"user_id"`
	Title     string    `json:"title"`
	FolderID  *int64    `json:"folder_id,omitempty"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	Messages  []Message `json:"messages,omitempty"`
}

// ChatUpdate represents the fields that can be updated for a chat
type ChatUpdate struct {
	Title    string `json:"title,omitempty"`
	FolderID *int64 `json:"folder_id,omitempty"`
}

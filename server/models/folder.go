package models

import (
	"time"
)

// Folder represents a folder that contains chats
type Folder struct {
	ID        int64     `json:"id"`
	Name      string    `json:"name"`
	Color     string    `json:"color,omitempty"`
	UserID    int64     `json:"user_id"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	Chats     []Chat    `json:"chats,omitempty"`
	ChatCount int       `json:"chat_count,omitempty"`
}

// FolderCreate represents the data needed to create a new folder
type FolderCreate struct {
	Name  string `json:"name"`
	Color string `json:"color,omitempty"`
}

// FolderUpdate represents the data that can be updated for a folder
type FolderUpdate struct {
	Name  string `json:"name"`
	Color string `json:"color,omitempty"`
}

// FolderResponse represents the response data for a folder
type FolderResponse struct {
	ID        int64     `json:"id"`
	Name      string    `json:"name"`
	Color     string    `json:"color,omitempty"`
	UserID    int64     `json:"user_id"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	ChatCount int       `json:"chat_count"`
	Chats     []Chat    `json:"chats,omitempty"`
}

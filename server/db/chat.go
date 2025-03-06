package db

import (
	"database/sql"
	"errors"
	"time"

	"github.com/darooyar/server/models"
)

// CreateChat creates a new chat in the database
func CreateChat(chat *models.ChatCreate, userID int64) (*models.Chat, error) {
	query := `
		INSERT INTO chats (user_id, title, folder_id, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, user_id, title, folder_id, created_at, updated_at`

	now := time.Now()
	var newChat models.Chat
	var folderID sql.NullInt64
	if chat.FolderID != nil {
		folderID.Int64 = *chat.FolderID
		folderID.Valid = true
	}

	err := DB.QueryRow(
		query,
		userID,
		chat.Title,
		folderID,
		now,
		now,
	).Scan(
		&newChat.ID,
		&newChat.UserID,
		&newChat.Title,
		&folderID,
		&newChat.CreatedAt,
		&newChat.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	if folderID.Valid {
		fid := folderID.Int64
		newChat.FolderID = &fid
	}

	return &newChat, nil
}

// GetChat retrieves a chat by ID with its messages
func GetChat(chatID int64, userID int64) (*models.ChatResponse, error) {
	// First get the chat
	chatQuery := `
		SELECT id, user_id, title, folder_id, created_at, updated_at
		FROM chats
		WHERE id = $1 AND user_id = $2`

	var chat models.ChatResponse
	var folderID sql.NullInt64
	err := DB.QueryRow(chatQuery, chatID, userID).Scan(
		&chat.ID,
		&chat.UserID,
		&chat.Title,
		&folderID,
		&chat.CreatedAt,
		&chat.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, errors.New("chat not found")
	}
	if err != nil {
		return nil, err
	}

	if folderID.Valid {
		fid := folderID.Int64
		chat.FolderID = &fid
	}

	// Then get all messages for this chat
	messagesQuery := `
		SELECT id, chat_id, role, content, content_type, created_at
		FROM messages
		WHERE chat_id = $1
		ORDER BY created_at ASC`

	rows, err := DB.Query(messagesQuery, chatID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var msg models.Message
		var contentType sql.NullString // In case NULL values exist in old records
		err := rows.Scan(
			&msg.ID,
			&msg.ChatID,
			&msg.Role,
			&msg.Content,
			&contentType,
			&msg.CreatedAt,
		)
		if err != nil {
			return nil, err
		}

		if contentType.Valid {
			msg.ContentType = contentType.String
		} else {
			msg.ContentType = "text" // Default for old records
		}

		chat.Messages = append(chat.Messages, msg)
	}

	return &chat, nil
}

// GetUserChats retrieves all chats for a user
func GetUserChats(userID int64) ([]models.Chat, error) {
	query := `
		SELECT id, user_id, title, folder_id, created_at, updated_at
		FROM chats
		WHERE user_id = $1
		ORDER BY updated_at DESC`

	rows, err := DB.Query(query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var chats []models.Chat
	for rows.Next() {
		var chat models.Chat
		var folderID sql.NullInt64
		err := rows.Scan(
			&chat.ID,
			&chat.UserID,
			&chat.Title,
			&folderID,
			&chat.CreatedAt,
			&chat.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}

		if folderID.Valid {
			fid := folderID.Int64
			chat.FolderID = &fid
		}

		chats = append(chats, chat)
	}

	return chats, nil
}

// CreateMessage creates a new message in the database
func CreateMessage(msg *models.MessageCreate) (*models.Message, error) {
	query := `
		INSERT INTO messages (chat_id, role, content, content_type, created_at)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, chat_id, role, content, content_type, created_at`

	contentType := msg.ContentType
	if contentType == "" {
		contentType = "text" // Default to text if not specified
	}

	now := time.Now()
	var newMsg models.Message
	err := DB.QueryRow(
		query,
		msg.ChatID,
		msg.Role,
		msg.Content,
		contentType,
		now,
	).Scan(
		&newMsg.ID,
		&newMsg.ChatID,
		&newMsg.Role,
		&newMsg.Content,
		&newMsg.ContentType,
		&newMsg.CreatedAt,
	)

	if err != nil {
		return nil, err
	}

	// Update the chat's updated_at timestamp
	_, err = DB.Exec(`
		UPDATE chats
		SET updated_at = $1
		WHERE id = $2`,
		now, msg.ChatID)
	if err != nil {
		return nil, err
	}

	return &newMsg, nil
}

// DeleteChat deletes a chat and all its messages from the database
func DeleteChat(chatID int64) error {
	// Start a transaction to ensure both operations succeed or fail together
	tx, err := DB.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// First delete all messages associated with the chat
	_, err = tx.Exec(`DELETE FROM messages WHERE chat_id = $1`, chatID)
	if err != nil {
		return err
	}

	// Then delete the chat itself
	result, err := tx.Exec(`DELETE FROM chats WHERE id = $1`, chatID)
	if err != nil {
		return err
	}

	// Check if any row was affected
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if rowsAffected == 0 {
		return errors.New("chat not found")
	}

	// Commit the transaction
	return tx.Commit()
}

// GetChatMessages retrieves all messages for a specific chat
func GetChatMessages(chatID int64) ([]models.Message, error) {
	query := `
		SELECT id, chat_id, role, content, content_type, created_at
		FROM messages
		WHERE chat_id = $1
		ORDER BY created_at ASC`

	rows, err := DB.Query(query, chatID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var messages []models.Message
	for rows.Next() {
		var msg models.Message
		var contentType sql.NullString // In case NULL values exist in old records
		err := rows.Scan(
			&msg.ID,
			&msg.ChatID,
			&msg.Role,
			&msg.Content,
			&contentType,
			&msg.CreatedAt,
		)
		if err != nil {
			return nil, err
		}

		if contentType.Valid {
			msg.ContentType = contentType.String
		} else {
			msg.ContentType = "text" // Default for old records
		}

		messages = append(messages, msg)
	}

	return messages, nil
}

// UpdateChat updates a chat in the database
func UpdateChat(chatID int64, userID int64, update *models.ChatUpdate) (*models.Chat, error) {
	// First check if the chat exists and belongs to the user
	checkQuery := `
		SELECT id FROM chats
		WHERE id = $1 AND user_id = $2`
	var id int64
	err := DB.QueryRow(checkQuery, chatID, userID).Scan(&id)
	if err == sql.ErrNoRows {
		return nil, errors.New("chat not found or unauthorized")
	}
	if err != nil {
		return nil, err
	}

	// Update the chat
	updateQuery := `
		UPDATE chats
		SET title = COALESCE($1, title),
		    folder_id = $2,
		    updated_at = $3
		WHERE id = $4
		RETURNING id, user_id, title, folder_id, created_at, updated_at`

	now := time.Now()
	var chat models.Chat
	var folderID sql.NullInt64
	if update.FolderID != nil {
		folderID.Int64 = *update.FolderID
		folderID.Valid = true
	}

	err = DB.QueryRow(
		updateQuery,
		update.Title,
		folderID,
		now,
		chatID,
	).Scan(
		&chat.ID,
		&chat.UserID,
		&chat.Title,
		&folderID,
		&chat.CreatedAt,
		&chat.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	if folderID.Valid {
		fid := folderID.Int64
		chat.FolderID = &fid
	}

	return &chat, nil
}

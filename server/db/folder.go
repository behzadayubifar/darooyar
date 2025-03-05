package db

import (
	"database/sql"
	"errors"
	"time"

	"github.com/darooyar/server/models"
)

// CreateFolder creates a new folder in the database
func CreateFolder(folder *models.FolderCreate, userID int64) (*models.Folder, error) {
	query := `
		INSERT INTO folders (user_id, name, color, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, user_id, name, color, created_at, updated_at`

	now := time.Now()
	var newFolder models.Folder
	err := DB.QueryRow(
		query,
		userID,
		folder.Name,
		folder.Color,
		now,
		now,
	).Scan(
		&newFolder.ID,
		&newFolder.UserID,
		&newFolder.Name,
		&newFolder.Color,
		&newFolder.CreatedAt,
		&newFolder.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	return &newFolder, nil
}

// GetFolder retrieves a folder by ID with its chats
func GetFolder(folderID int64, userID int64) (*models.FolderResponse, error) {
	// First get the folder
	folderQuery := `
		SELECT id, user_id, name, color, created_at, updated_at
		FROM folders
		WHERE id = $1 AND user_id = $2`

	var folder models.FolderResponse
	err := DB.QueryRow(folderQuery, folderID, userID).Scan(
		&folder.ID,
		&folder.UserID,
		&folder.Name,
		&folder.Color,
		&folder.CreatedAt,
		&folder.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, errors.New("folder not found")
	}
	if err != nil {
		return nil, err
	}

	// Then get all chats for this folder
	chatsQuery := `
		SELECT id, user_id, title, folder_id, created_at, updated_at
		FROM chats
		WHERE folder_id = $1
		ORDER BY updated_at DESC`

	rows, err := DB.Query(chatsQuery, folderID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	folder.Chats = []models.Chat{}

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

		folder.Chats = append(folder.Chats, chat)
	}

	// Get chat count
	countQuery := `
		SELECT COUNT(*) FROM chats WHERE folder_id = $1`
	err = DB.QueryRow(countQuery, folderID).Scan(&folder.ChatCount)
	if err != nil {
		return nil, err
	}

	return &folder, nil
}

// GetUserFolders retrieves all folders for a user
func GetUserFolders(userID int64) ([]models.Folder, error) {
	query := `
		SELECT f.id, f.user_id, f.name, f.color, f.created_at, f.updated_at, 
		       COUNT(c.id) as chat_count
		FROM folders f
		LEFT JOIN chats c ON f.id = c.folder_id
		WHERE f.user_id = $1
		GROUP BY f.id
		ORDER BY f.name ASC`

	rows, err := DB.Query(query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var folders []models.Folder
	for rows.Next() {
		var folder models.Folder
		err := rows.Scan(
			&folder.ID,
			&folder.UserID,
			&folder.Name,
			&folder.Color,
			&folder.CreatedAt,
			&folder.UpdatedAt,
			&folder.ChatCount,
		)
		if err != nil {
			return nil, err
		}
		folders = append(folders, folder)
	}

	return folders, nil
}

// UpdateFolder updates a folder in the database
func UpdateFolder(folderID int64, userID int64, update *models.FolderUpdate) (*models.Folder, error) {
	// First check if the folder exists and belongs to the user
	checkQuery := `
		SELECT id FROM folders
		WHERE id = $1 AND user_id = $2`
	var id int64
	err := DB.QueryRow(checkQuery, folderID, userID).Scan(&id)
	if err == sql.ErrNoRows {
		return nil, errors.New("folder not found or unauthorized")
	}
	if err != nil {
		return nil, err
	}

	// Update the folder
	updateQuery := `
		UPDATE folders
		SET name = COALESCE($1, name),
		    color = COALESCE($2, color),
		    updated_at = $3
		WHERE id = $4
		RETURNING id, user_id, name, color, created_at, updated_at`

	now := time.Now()
	var folder models.Folder
	err = DB.QueryRow(
		updateQuery,
		update.Name,
		update.Color,
		now,
		folderID,
	).Scan(
		&folder.ID,
		&folder.UserID,
		&folder.Name,
		&folder.Color,
		&folder.CreatedAt,
		&folder.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	return &folder, nil
}

// DeleteFolder deletes a folder from the database
func DeleteFolder(folderID int64, userID int64) error {
	// First check if the folder exists and belongs to the user
	checkQuery := `
		SELECT id FROM folders
		WHERE id = $1 AND user_id = $2`
	var id int64
	err := DB.QueryRow(checkQuery, folderID, userID).Scan(&id)
	if err == sql.ErrNoRows {
		return errors.New("folder not found or unauthorized")
	}
	if err != nil {
		return err
	}

	// Start a transaction
	tx, err := DB.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// Update chats to remove folder_id
	_, err = tx.Exec(`
		UPDATE chats
		SET folder_id = NULL
		WHERE folder_id = $1`,
		folderID)
	if err != nil {
		return err
	}

	// Delete the folder
	_, err = tx.Exec(`
		DELETE FROM folders
		WHERE id = $1`,
		folderID)
	if err != nil {
		return err
	}

	// Commit the transaction
	return tx.Commit()
}

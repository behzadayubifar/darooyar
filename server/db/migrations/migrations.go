package migrations

import (
	"log"

	"github.com/darooyar/server/db"
)

// RunInMemoryMigrations runs all in-memory database migrations
func RunInMemoryMigrations() error {
	log.Println("Running in-memory database migrations...")

	// Create users table
	if err := createUsersTable(); err != nil {
		return err
	}

	// Create folders table
	if err := createFoldersTable(); err != nil {
		return err
	}

	// Create chats table
	if err := createChatsTable(); err != nil {
		return err
	}

	// Create messages table
	if err := createMessagesTable(); err != nil {
		return err
	}

	// Add content_type column to messages table if it doesn't exist
	if err := addContentTypeToMessages(); err != nil {
		return err
	}

	// Add credit field to users table if it doesn't exist
	if err := addCreditToUsers(); err != nil {
		return err
	}

	// Add is_admin field to users and create gift_transactions table
	if err := addGiftTransactions(); err != nil {
		return err
	}

	log.Println("In-memory database migrations completed successfully")
	return nil
}

// createUsersTable creates the users table if it doesn't exist
func createUsersTable() error {
	log.Println("Creating users table if it doesn't exist...")
	_, err := db.DB.Exec(`
		CREATE TABLE IF NOT EXISTS users (
			id BIGSERIAL PRIMARY KEY,
			username VARCHAR(50) NOT NULL UNIQUE,
			email VARCHAR(255) NOT NULL UNIQUE,
			password VARCHAR(255) NOT NULL,
			first_name VARCHAR(50) NOT NULL,
			last_name VARCHAR(50) NOT NULL,
			created_at TIMESTAMP WITH TIME ZONE NOT NULL,
			updated_at TIMESTAMP WITH TIME ZONE NOT NULL
		);
		CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
	`)
	return err
}

// createFoldersTable creates the folders table if it doesn't exist
func createFoldersTable() error {
	log.Println("Creating folders table if it doesn't exist...")
	_, err := db.DB.Exec(`
		CREATE TABLE IF NOT EXISTS folders (
			id BIGSERIAL PRIMARY KEY,
			user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
			name VARCHAR(255) NOT NULL,
			color VARCHAR(20),
			created_at TIMESTAMP WITH TIME ZONE NOT NULL,
			updated_at TIMESTAMP WITH TIME ZONE NOT NULL
		);
		CREATE INDEX IF NOT EXISTS idx_folders_user_id ON folders(user_id);
	`)
	return err
}

// createChatsTable creates the chats table if it doesn't exist
func createChatsTable() error {
	log.Println("Creating chats table if it doesn't exist...")
	_, err := db.DB.Exec(`
		CREATE TABLE IF NOT EXISTS chats (
			id BIGSERIAL PRIMARY KEY,
			user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
			title VARCHAR(255) NOT NULL,
			folder_id BIGINT NULL REFERENCES folders(id) ON DELETE SET NULL,
			created_at TIMESTAMP WITH TIME ZONE NOT NULL,
			updated_at TIMESTAMP WITH TIME ZONE NOT NULL
		);
		CREATE INDEX IF NOT EXISTS idx_chats_user_id ON chats(user_id);
		CREATE INDEX IF NOT EXISTS idx_chats_folder_id ON chats(folder_id);
	`)
	return err
}

// createMessagesTable creates the messages table if it doesn't exist
func createMessagesTable() error {
	log.Println("Creating messages table if it doesn't exist...")
	_, err := db.DB.Exec(`
		CREATE TABLE IF NOT EXISTS messages (
			id BIGSERIAL PRIMARY KEY,
			chat_id BIGINT NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
			role VARCHAR(20) NOT NULL,
			content TEXT NOT NULL,
			created_at TIMESTAMP WITH TIME ZONE NOT NULL
		);
		CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages(chat_id);
		CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);
	`)
	return err
}

// addContentTypeToMessages adds the content_type column to the messages table if it doesn't exist
func addContentTypeToMessages() error {
	// Check if the content_type column already exists
	var exists bool
	err := db.DB.QueryRow(`
		SELECT EXISTS (
			SELECT 1 
			FROM information_schema.columns 
			WHERE table_name = 'messages' AND column_name = 'content_type'
		)
	`).Scan(&exists)

	if err != nil {
		return err
	}

	// If the column doesn't exist, add it
	if !exists {
		log.Println("Adding content_type column to messages table...")
		_, err := db.DB.Exec(`
			ALTER TABLE messages 
			ADD COLUMN content_type VARCHAR(50) DEFAULT 'text'
		`)
		if err != nil {
			return err
		}
		log.Println("Added content_type column to messages table")
	} else {
		log.Println("content_type column already exists in messages table")
	}

	return nil
}

// addCreditToUsers adds the credit column to the users table if it doesn't exist
func addCreditToUsers() error {
	// Check if the credit column already exists
	var exists bool
	err := db.DB.QueryRow(`
		SELECT EXISTS (
			SELECT 1 
			FROM information_schema.columns 
			WHERE table_name = 'users' AND column_name = 'credit'
		)
	`).Scan(&exists)

	if err != nil {
		return err
	}

	// If the column doesn't exist, add it
	if !exists {
		log.Println("Adding credit column to users table...")
		_, err := db.DB.Exec(`
			ALTER TABLE users 
			ADD COLUMN credit DECIMAL(10, 2) NOT NULL DEFAULT 0.00;
			CREATE INDEX IF NOT EXISTS idx_users_credit ON users(credit);
		`)
		if err != nil {
			return err
		}
		log.Println("Added credit column to users table")
	} else {
		log.Println("credit column already exists in users table")
	}

	return nil
}

// addGiftTransactions adds the is_admin field to users and creates the gift_transactions table
func addGiftTransactions() error {
	log.Println("Adding is_admin field to users and creating gift_transactions table if they don't exist...")

	// Add is_admin field to users
	_, err := db.DB.Exec(`
		ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;
	`)
	if err != nil {
		return err
	}

	// Create gift_transactions table
	_, err = db.DB.Exec(`
		CREATE TABLE IF NOT EXISTS gift_transactions (
			id SERIAL PRIMARY KEY,
			admin_id BIGINT NOT NULL REFERENCES users(id),
			user_id BIGINT NOT NULL REFERENCES users(id),
			gift_type VARCHAR(50) NOT NULL,
			plan_id BIGINT REFERENCES plans(id),
			credit_amount DECIMAL(10, 2),
			message TEXT,
			created_at TIMESTAMP NOT NULL DEFAULT NOW()
		);
		CREATE INDEX IF NOT EXISTS idx_gift_transactions_user_id ON gift_transactions(user_id);
		CREATE INDEX IF NOT EXISTS idx_gift_transactions_admin_id ON gift_transactions(admin_id);
	`)
	return err
}

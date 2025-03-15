package db

import (
	"database/sql"
	"log"
	"time"

	"github.com/darooyar/server/models"
)

// CreateTransaction creates a new transaction record in the database
func CreateTransaction(tx models.Transaction) (int64, error) {
	query := `
		INSERT INTO transactions (
			user_id, amount, payment_method, reference_id, status, created_at, metadata
		) VALUES (?, ?, ?, ?, ?, ?, ?)
	`

	stmt, err := DB.Prepare(query)
	if err != nil {
		log.Printf("Error preparing transaction insert statement: %v", err)
		return 0, err
	}
	defer stmt.Close()

	result, err := stmt.Exec(
		tx.UserID,
		tx.Amount,
		tx.PaymentMethod,
		tx.ReferenceID,
		tx.Status,
		tx.CreatedAt,
		tx.Metadata,
	)
	if err != nil {
		log.Printf("Error executing transaction insert: %v", err)
		return 0, err
	}

	id, err := result.LastInsertId()
	if err != nil {
		log.Printf("Error getting last insert ID: %v", err)
		return 0, err
	}

	return id, nil
}

// GetTransactionByReferenceID retrieves a transaction by its reference ID
func GetTransactionByReferenceID(referenceID string) (models.Transaction, error) {
	query := `
		SELECT id, user_id, amount, payment_method, reference_id, status, created_at, metadata
		FROM transactions
		WHERE reference_id = ?
	`

	var tx models.Transaction
	var createdAtStr string

	err := DB.QueryRow(query, referenceID).Scan(
		&tx.ID,
		&tx.UserID,
		&tx.Amount,
		&tx.PaymentMethod,
		&tx.ReferenceID,
		&tx.Status,
		&createdAtStr,
		&tx.Metadata,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return models.Transaction{}, err
		}
		log.Printf("Error querying transaction by reference ID: %v", err)
		return models.Transaction{}, err
	}

	// Parse created_at string to time.Time
	tx.CreatedAt, err = time.Parse("2006-01-02 15:04:05", createdAtStr)
	if err != nil {
		log.Printf("Error parsing created_at time: %v", err)
		// Use current time as fallback
		tx.CreatedAt = time.Now()
	}

	return tx, nil
}

// UpdateTransactionStatus updates the status of a transaction
func UpdateTransactionStatus(txID int64, status string) error {
	query := `
		UPDATE transactions
		SET status = ?
		WHERE id = ?
	`

	stmt, err := DB.Prepare(query)
	if err != nil {
		log.Printf("Error preparing transaction update statement: %v", err)
		return err
	}
	defer stmt.Close()

	_, err = stmt.Exec(status, txID)
	if err != nil {
		log.Printf("Error executing transaction update: %v", err)
		return err
	}

	return nil
}

// GetUserTransactions retrieves a list of transactions for a user with pagination
func GetUserTransactions(userID int64, limit, offset int) ([]models.Transaction, error) {
	query := `
		SELECT id, user_id, amount, payment_method, reference_id, status, created_at, metadata
		FROM transactions
		WHERE user_id = ?
		ORDER BY created_at DESC
		LIMIT ? OFFSET ?
	`

	rows, err := DB.Query(query, userID, limit, offset)
	if err != nil {
		log.Printf("Error querying user transactions: %v", err)
		return nil, err
	}
	defer rows.Close()

	var transactions []models.Transaction

	for rows.Next() {
		var tx models.Transaction
		var createdAtStr string

		err := rows.Scan(
			&tx.ID,
			&tx.UserID,
			&tx.Amount,
			&tx.PaymentMethod,
			&tx.ReferenceID,
			&tx.Status,
			&createdAtStr,
			&tx.Metadata,
		)

		if err != nil {
			log.Printf("Error scanning transaction row: %v", err)
			continue
		}

		// Parse created_at string to time.Time
		tx.CreatedAt, err = time.Parse("2006-01-02 15:04:05", createdAtStr)
		if err != nil {
			log.Printf("Error parsing created_at time: %v", err)
			// Use current time as fallback
			tx.CreatedAt = time.Now()
		}

		transactions = append(transactions, tx)
	}

	if err = rows.Err(); err != nil {
		log.Printf("Error iterating transaction rows: %v", err)
		return nil, err
	}

	return transactions, nil
}

// GetTransactionByID retrieves a transaction by its ID
func GetTransactionByID(txID int64) (models.Transaction, error) {
	query := `
		SELECT id, user_id, amount, payment_method, reference_id, status, created_at, metadata
		FROM transactions
		WHERE id = ?
	`

	var tx models.Transaction
	var createdAtStr string

	err := DB.QueryRow(query, txID).Scan(
		&tx.ID,
		&tx.UserID,
		&tx.Amount,
		&tx.PaymentMethod,
		&tx.ReferenceID,
		&tx.Status,
		&createdAtStr,
		&tx.Metadata,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return models.Transaction{}, err
		}
		log.Printf("Error querying transaction by ID: %v", err)
		return models.Transaction{}, err
	}

	// Parse created_at string to time.Time
	tx.CreatedAt, err = time.Parse("2006-01-02 15:04:05", createdAtStr)
	if err != nil {
		log.Printf("Error parsing created_at time: %v", err)
		// Use current time as fallback
		tx.CreatedAt = time.Now()
	}

	return tx, nil
}

package db

import (
	"database/sql"
	"errors"
	"time"

	"github.com/darooyar/server/models"
)

// CreateUser creates a new user in the database
func CreateUser(user *models.UserCreate) (*models.User, error) {
	query := `
		INSERT INTO users (username, email, password, first_name, last_name, credit, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id, username, email, first_name, last_name, credit, created_at, updated_at`

	now := time.Now()
	var newUser models.User
	err := DB.QueryRow(
		query,
		user.Username,
		user.Email,
		user.Password, // Note: Password should be hashed before being passed here
		user.FirstName,
		user.LastName,
		0.0, // Default credit value for new users
		now,
		now,
	).Scan(
		&newUser.ID,
		&newUser.Username,
		&newUser.Email,
		&newUser.FirstName,
		&newUser.LastName,
		&newUser.Credit,
		&newUser.CreatedAt,
		&newUser.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	return &newUser, nil
}

// GetUserByEmail retrieves a user by email
func GetUserByEmail(email string) (*models.User, error) {
	query := `
		SELECT id, username, email, password, first_name, last_name, credit, created_at, updated_at
		FROM users
		WHERE email = $1`

	var user models.User
	err := DB.QueryRow(query, email).Scan(
		&user.ID,
		&user.Username,
		&user.Email,
		&user.Password,
		&user.FirstName,
		&user.LastName,
		&user.Credit,
		&user.CreatedAt,
		&user.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, errors.New("user not found")
	}
	if err != nil {
		return nil, err
	}

	return &user, nil
}

// GetUserByID retrieves a user by ID
func GetUserByID(id int64) (*models.User, error) {
	query := `
		SELECT id, username, email, first_name, last_name, credit, created_at, updated_at
		FROM users
		WHERE id = $1`

	var user models.User
	err := DB.QueryRow(query, id).Scan(
		&user.ID,
		&user.Username,
		&user.Email,
		&user.FirstName,
		&user.LastName,
		&user.Credit,
		&user.CreatedAt,
		&user.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, errors.New("user not found")
	}
	if err != nil {
		return nil, err
	}

	return &user, nil
}

// UpdateUserCredit updates a user's credit balance
func UpdateUserCredit(userID int64, newCredit float64) error {
	query := `
		UPDATE users
		SET credit = $1, updated_at = $2
		WHERE id = $3`

	_, err := DB.Exec(query, newCredit, time.Now(), userID)
	return err
}

// AddUserCredit adds to a user's credit balance
func AddUserCredit(userID int64, amount float64) error {
	if amount <= 0 {
		return errors.New("amount must be positive")
	}

	query := `
		UPDATE users
		SET credit = credit + $1, updated_at = $2
		WHERE id = $3`

	_, err := DB.Exec(query, amount, time.Now(), userID)
	return err
}

// SubtractUserCredit subtracts from a user's credit balance
func SubtractUserCredit(userID int64, amount float64) error {
	if amount <= 0 {
		return errors.New("amount must be positive")
	}

	// First check if the user has enough credit
	var currentCredit float64
	err := DB.QueryRow("SELECT credit FROM users WHERE id = $1", userID).Scan(&currentCredit)
	if err != nil {
		return err
	}

	if currentCredit < amount {
		return errors.New("insufficient credit")
	}

	query := `
		UPDATE users
		SET credit = credit - $1, updated_at = $2
		WHERE id = $3`

	_, err = DB.Exec(query, amount, time.Now(), userID)
	return err
}

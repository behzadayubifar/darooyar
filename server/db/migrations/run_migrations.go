package migrations

import (
	"log"
	"os"
	"path/filepath"

	"github.com/darooyar/server/db"
)

// RunSQLMigrations runs all SQL migrations in the migrations directory
func RunSQLMigrations() error {
	log.Println("Running SQL migrations...")

	// Create migration_logs table if it doesn't exist
	_, err := db.DB.Exec(`
		CREATE TABLE IF NOT EXISTS migration_logs (
			migration_name VARCHAR(255) PRIMARY KEY,
			description TEXT,
			executed_at TIMESTAMP NOT NULL DEFAULT NOW()
		)
	`)
	if err != nil {
		return err
	}

	// Get all migration files
	migrationFiles := []string{
		"001_initial_schema.sql",
		"002_chat_folders.sql",
		"003_add_user_credit.sql",
		"004_add_plan_tables.sql",
		"005_add_gift_transactions.sql",
		"006_add_initial_plans.sql",
		"007_fix_plan_duration.sql",
	}

	// Run each migration if it hasn't been run already
	for _, file := range migrationFiles {
		// Check if migration has already been run
		var exists bool
		err := db.DB.QueryRow(`
			SELECT EXISTS (
				SELECT 1 FROM migration_logs WHERE migration_name = $1
			)
		`, file).Scan(&exists)

		if err != nil {
			return err
		}

		if exists {
			log.Printf("Migration %s has already been run, skipping", file)
			continue
		}

		// Read migration file
		migrationPath := filepath.Join("db", "migrations", file)
		migrationSQL, err := os.ReadFile(migrationPath)
		if err != nil {
			return err
		}

		// Run migration
		log.Printf("Running migration %s", file)
		_, err = db.DB.Exec(string(migrationSQL))
		if err != nil {
			return err
		}

		// Log migration
		_, err = db.DB.Exec(`
			INSERT INTO migration_logs (migration_name, description, executed_at)
			VALUES ($1, $2, NOW())
		`, file, "Migration from file "+file)
		if err != nil {
			return err
		}

		log.Printf("Migration %s completed successfully", file)
	}

	log.Println("All SQL migrations completed successfully")
	return nil
}

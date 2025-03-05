package migrations

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/darooyar/server/db"
)

// RunMigrations executes all SQL migration files in order
func RunMigrations() error {
	// Get the directory where migration files are stored
	migrationDir, err := getMigrationsDir()
	if err != nil {
		return fmt.Errorf("error getting migrations directory: %v", err)
	}

	// Read all SQL files in the migrations directory
	files, err := os.ReadDir(migrationDir)
	if err != nil {
		return fmt.Errorf("error reading migrations directory: %v", err)
	}

	// Filter and sort SQL files
	var sqlFiles []string
	for _, file := range files {
		if strings.HasSuffix(file.Name(), ".sql") {
			sqlFiles = append(sqlFiles, file.Name())
		}
	}
	sort.Strings(sqlFiles)

	// Execute each migration file
	for _, file := range sqlFiles {
		log.Printf("Running migration: %s", file)

		// Read the SQL file
		content, err := os.ReadFile(filepath.Join(migrationDir, file))
		if err != nil {
			return fmt.Errorf("error reading migration file %s: %v", file, err)
		}

		// Execute the SQL
		_, err = db.DB.Exec(string(content))
		if err != nil {
			return fmt.Errorf("error executing migration %s: %v", file, err)
		}

		log.Printf("Successfully executed migration: %s", file)
	}

	return nil
}

// getMigrationsDir returns the absolute path to the migrations directory
func getMigrationsDir() (string, error) {
	// Try relative path from binary location
	exePath, err := os.Executable()
	if err != nil {
		return "", fmt.Errorf("error getting executable path: %v", err)
	}

	exeDir := filepath.Dir(exePath)

	// Define possible paths where migration files might be located
	possiblePaths := []string{
		filepath.Join(exeDir, "db", "migrations"),
		filepath.Join(exeDir, "server", "db", "migrations"),
		filepath.Join(exeDir, "..", "db", "migrations"),
		filepath.Join(exeDir, "..", "server", "db", "migrations"),
	}

	// Also check current directory and server/db/migrations from current directory
	cwd, err := os.Getwd()
	if err == nil {
		possiblePaths = append(possiblePaths, filepath.Join(cwd, "db", "migrations"))
		possiblePaths = append(possiblePaths, filepath.Join(cwd, "server", "db", "migrations"))
	}

	// Try each path
	for _, path := range possiblePaths {
		if _, err := os.Stat(path); err == nil {
			return path, nil
		}
	}

	return "", fmt.Errorf("migrations directory not found in any of the expected locations")
}

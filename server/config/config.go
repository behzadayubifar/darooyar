package config

import (
	"os"
	"sync"
)

type Config struct {
	ServerAddr   string
	DBHost       string
	DBPort       string
	DBUser       string
	DBPassword   string
	DBName       string
	JWTSecret    string
	OpenAIAPIKey string
}

var (
	config *Config
	once   sync.Once
)

func GetConfig() *Config {
	once.Do(func() {
		config = &Config{
			ServerAddr:   getEnvOrDefault("SERVER_ADDR", ":8080"),
			DBHost:       getEnvOrDefault("DB_HOST", "localhost"),
			DBPort:       getEnvOrDefault("DB_PORT", "5432"),
			DBUser:       getEnvOrDefault("DB_USER", "postgres"),
			DBPassword:   getEnvOrDefault("DB_PASSWORD", ""),
			DBName:       getEnvOrDefault("DB_NAME", "darooyar"),
			JWTSecret:    getEnvOrDefault("JWT_SECRET", ""),
			OpenAIAPIKey: getEnvOrDefault("OPENAI_API_KEY", ""),
		}
	})
	return config
}

func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

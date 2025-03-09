package middleware

import (
	"net/http"
	"strings"

	"github.com/darooyar/server/auth"
)

// List of paths that don't require authentication
var publicPaths = []string{
	"/api/health",
	"/api/auth/register",
	"/api/auth/login",
}

// IsPublicPath checks if a path is in the list of public paths
func IsPublicPath(path string) bool {
	for _, publicPath := range publicPaths {
		if strings.HasPrefix(path, publicPath) {
			return true
		}
	}
	return false
}

// AuthCheckMiddleware is a middleware that checks if a user is authenticated
// for all endpoints except those in the publicPaths list
func AuthCheckMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Skip authentication for public paths
		if IsPublicPath(r.URL.Path) {
			next.ServeHTTP(w, r)
			return
		}

		// Skip OPTIONS requests (for CORS preflight)
		if r.Method == http.MethodOptions {
			next.ServeHTTP(w, r)
			return
		}

		// Get the Authorization header
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			http.Error(w, "Authorization header required", http.StatusUnauthorized)
			return
		}

		// Check if the header starts with "Bearer "
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			http.Error(w, "Invalid authorization header format", http.StatusUnauthorized)
			return
		}

		// Validate the token
		_, err := auth.ValidateToken(parts[1])
		if err != nil {
			http.Error(w, "Invalid token", http.StatusUnauthorized)
			return
		}

		// Continue with the request
		next.ServeHTTP(w, r)
	})
}

# Authentication Middleware

This directory contains middleware for handling authentication in the دارویار API.

## Overview

The authentication system consists of several components:

1. **AuthMiddleware**: Applied to protected routes in the main router. It checks for a valid JWT token in the Authorization header and adds the user ID to the request context.

2. **RequireAuth**: A middleware that can be applied to individual handlers to ensure a user is authenticated. It's useful for routes that need authentication but aren't part of the main protected routes.

3. **AuthCheckMiddleware**: A global middleware that checks if a user is authenticated for all endpoints except those in the public paths list. This provides an additional layer of security.

4. **GetUserFromToken**: A utility function that extracts user information from the token if present. It returns the user ID, email, and a boolean indicating if the user is authenticated.

## Public Paths

The following paths are considered public and don't require authentication:

- `/api/health`: Health check endpoint
- `/api/auth/register`: User registration
- `/api/auth/login`: User login

All other paths require a valid JWT token in the Authorization header.

## Usage

### Protecting Routes

Routes can be protected in two ways:

1. By adding them to the protected router in main.go:

```go
protected := http.NewServeMux()
protected.HandleFunc("GET /api/resource", resourceHandler)
mux.Handle("/api/", middleware.AuthMiddleware(protected))
```

2. By applying the RequireAuth middleware to individual handlers:

```go
mux.HandleFunc("POST /api/resource", middleware.RequireAuth(resourceHandler))
```

### Accessing User Information

In protected handlers, you can access the user ID and email from the request context:

```go
func MyHandler(w http.ResponseWriter, r *http.Request) {
    userID := r.Context().Value("user_id").(int64)
    email := r.Context().Value("email").(string)

    // Use userID and email
}
```

### Checking Authentication Without Blocking

If you need to check if a user is authenticated without blocking the request, you can use the GetUserFromToken function:

```go
func MyHandler(w http.ResponseWriter, r *http.Request) {
    userID, email, isAuthenticated := middleware.GetUserFromToken(r)

    if isAuthenticated {
        // User is authenticated
    } else {
        // User is not authenticated
    }
}
```

## Security Considerations

- All tokens are validated using the JWT_SECRET environment variable
- Tokens expire after 24 hours
- All protected endpoints require a valid token
- The AuthCheckMiddleware provides an additional layer of security by checking all requests

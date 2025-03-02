package handlers

import (
	"bytes"
	"context"
	"encoding/json"
	"log"
	"net"
	"net/http"
	"os"
	"time"

	"github.com/darooyar/server/models"
	"github.com/sashabaranov/go-openai"
)

// AIHandler handles AI-related API endpoints
type AIHandler struct {
	client *openai.Client
}

// NewAIHandler creates a new AI handler
func NewAIHandler() *AIHandler {
	// Get API key from environment variable
	apiKey := os.Getenv("OPENAI_API_KEY")
	var client *openai.Client

	if apiKey == "" {
		log.Println("Warning: OPENAI_API_KEY environment variable is not set")
		// In production, you might want to fail fast here
		// For development, we'll continue with a nil client
		client = nil
	} else {
		// Create OpenAI client with custom base URL
		config := openai.DefaultConfig(apiKey)
		config.BaseURL = "https://api.avalai.ir/v1"

		// Configure HTTP client with longer timeouts and TLS settings
		transport := &http.Transport{
			TLSHandshakeTimeout: 20 * time.Second,
			DisableKeepAlives:   false,
			MaxIdleConns:        10,
			MaxIdleConnsPerHost: 5,
			IdleConnTimeout:     90 * time.Second,
			DialContext: (&net.Dialer{
				Timeout:   30 * time.Second,
				KeepAlive: 30 * time.Second,
			}).DialContext,
		}

		httpClient := &http.Client{
			Timeout:   60 * time.Second,
			Transport: transport,
		}
		config.HTTPClient = httpClient

		client = openai.NewClientWithConfig(config)
		log.Println("OpenAI client initialized with custom base URL and TLS settings")
	}

	return &AIHandler{
		client: client,
	}
}

// GenerateCompletion handles text completion requests
func (h *AIHandler) GenerateCompletion(w http.ResponseWriter, r *http.Request) {
	// Add recovery mechanism to prevent server crashes
	defer func() {
		if r := recover(); r != nil {
			log.Printf("Recovered from panic in GenerateCompletion: %v", r)
			writeErrorResponse(w, "Internal server error", http.StatusInternalServerError)
		}
	}()

	// Set content type
	w.Header().Set("Content-Type", "application/json")

	// Parse the request body
	var request models.CompletionRequest
	err := json.NewDecoder(r.Body).Decode(&request)
	if err != nil {
		writeErrorResponse(w, "Invalid request format", http.StatusBadRequest)
		return
	}

	// Validate the request
	if request.Prompt == "" {
		writeErrorResponse(w, "Prompt field is required", http.StatusBadRequest)
		return
	}

	// Log the request (in a real app, you might want to sanitize sensitive data)
	log.Printf("Received completion request: %s", request.Prompt)

	// Check if client is initialized
	if h.client == nil {
		log.Println("OpenAI client not initialized. Please set OPENAI_API_KEY environment variable.")
		writeErrorResponse(w, "OpenAI API key not configured", http.StatusInternalServerError)
		return
	}

	// Call OpenAI API
	// Create a context with a timeout
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	resp, err := h.client.CreateChatCompletion(
		ctx,
		openai.ChatCompletionRequest{
			Model: "gemini-2.0-flash-thinking-exp-01-21",
			Messages: []openai.ChatCompletionMessage{
				{
					Role:    openai.ChatMessageRoleUser,
					Content: request.Prompt,
				},
			},
			MaxTokens: 500,
		},
	)

	if err != nil {
		log.Printf("Error calling OpenAI API: %v", err)

		// Check if it's a context deadline exceeded error
		if ctx.Err() == context.DeadlineExceeded {
			writeErrorResponse(w, "API request timed out. Please try again later.", http.StatusGatewayTimeout)
			return
		}

		writeErrorResponse(w, "Error generating completion", http.StatusInternalServerError)
		return
	}

	// Extract the response
	completion := ""
	if len(resp.Choices) > 0 {
		completion = resp.Choices[0].Message.Content
	}

	// Write the response
	response := models.CompletionResponse{
		Status:     "success",
		Completion: completion,
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// AnalyzePrescriptionWithAI handles AI-powered prescription analysis
func (h *AIHandler) AnalyzePrescriptionWithAI(w http.ResponseWriter, r *http.Request) {
	// Add recovery mechanism to prevent server crashes
	defer func() {
		if r := recover(); r != nil {
			log.Printf("Recovered from panic in AnalyzePrescriptionWithAI: %v", r)
			writeErrorResponse(w, "Internal server error", http.StatusInternalServerError)
		}
	}()

	// Variables for fallback mechanism
	var fallbackCtx context.Context
	var fallbackCancel context.CancelFunc

	// Set content type
	w.Header().Set("Content-Type", "application/json")

	log.Println("Received request to /api/ai/analyze-prescription")

	// Parse the request body
	var request models.TextAnalysisRequest
	err := json.NewDecoder(r.Body).Decode(&request)
	if err != nil {
		log.Printf("Error decoding request body: %v", err)
		writeErrorResponse(w, "Invalid request format", http.StatusBadRequest)
		return
	}

	// Validate the request
	if request.Text == "" {
		log.Println("Text field is empty")
		writeErrorResponse(w, "Text field is required", http.StatusBadRequest)
		return
	}

	// Log the request
	log.Printf("Received AI prescription analysis request: %s", request.Text)

	// Check if client is initialized
	if h.client == nil {
		log.Println("OpenAI client not initialized. Please set OPENAI_API_KEY environment variable.")
		writeErrorResponse(w, "OpenAI API key not configured", http.StatusInternalServerError)
		return
	}

	log.Println("OpenAI client is initialized. Calling OpenAI API.")
	log.Println("Using custom base URL: https://api.avalai.ir/v1")

	// Prepare the prompt for the AI
	prompt := ":\n\n" + request.Text

	// Call OpenAI API
	log.Println("Sending request to OpenAI API...")

	// Create a context with a longer timeout (45 seconds)
	ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
	defer cancel()

	// Try with a standard model that's more likely to be supported by the API
	resp, err := h.client.CreateChatCompletion(
		ctx,
		openai.ChatCompletionRequest{
			Model: "gemini-2.0-flash-thinking-exp-01-21",
			Messages: []openai.ChatCompletionMessage{
				{
					Role:    openai.ChatMessageRoleSystem,
					Content: "من مسئول فنی یک داروخانه شهری هستم\n\nخوب فکر کن و تمام جوانب رو بررسی کن و با استدلال جواب بده\n\nو به این شکل به من در مورد این نسخه جواب بده:\n\nبا سلام همکار گرامی،\n\nبا بررسی داروهای موجود در نسخه، اطلاعات زیر را خدمت شما ارائه می\u200cدهم:\n\nلیست داروهای نسخه:\n[اینجا لیست داروها را با توضیح مختصر هر دارو بنویس]\n\n۱. تشخیص احتمالی عارضه یا بیماری:\n[توضیح بده]\n\n۲. تداخلات مهم داروها که باید به بیمار گوشزد شود:\n[توضیح بده]\n\n۳. عوارض مهم و شایعی که حتما باید بیمار در مورد این داروها یادش باشد:\n[توضیح بده]\n\n۴. اگر دارویی را باید در زمان خاصی از روز مصرف کرد:\n[توضیح بده]\n\n۵. اگر دارویی رو باید با فاصله از غذا یا با غذا مصرف کرد:\n[توضیح بده]\n\n۶. تعداد مصرف روزانه هر دارو:\n[توضیح بده]\n\n۷. اگر برای عارضه\u200cای که داروها میدهند نیاز به مدیریت خاصی وجود دارد که باید اطلاع بدم بگو:\n[توضیح بده]",
				},
				{
					Role:    openai.ChatMessageRoleUser,
					Content: prompt,
				},
			},
			// Reduced max tokens to avoid timeouts
			MaxTokens: 1500,
		},
	)

	// If there's an error, try with a different model as fallback
	if err != nil {
		log.Printf("Error calling OpenAI API with gemini-2.0-flash-thinking-exp-01-21: %v", err)
		log.Println("Trying fallback with same model but different parameters...")

		// Create a new context for the fallback request
		fallbackCtx, fallbackCancel = context.WithTimeout(context.Background(), 30*time.Second)
		defer fallbackCancel()

		resp, err = h.client.CreateChatCompletion(
			fallbackCtx,
			openai.ChatCompletionRequest{
				Model: "gemini-2.0-flash-thinking-exp-01-21", // Use the same model for fallback
				Messages: []openai.ChatCompletionMessage{
					{
						Role:    openai.ChatMessageRoleSystem,
						Content: "من مسئول فنی یک داروخانه شهری هستم\n\nخوب فکر کن و تمام جوانب رو بررسی کن و با استدلال جواب بده\n\nو به این شکل به من در مورد این نسخه جواب بده:\n\nبا سلام همکار گرامی،\n\nبا بررسی داروهای موجود در نسخه، اطلاعات زیر را خدمت شما ارائه می\u200cدهم:\n\nلیست داروهای نسخه:\n[اینجا لیست داروها را با توضیح مختصر هر دارو بنویس]\n\n۱. تشخیص احتمالی عارضه یا بیماری:\n[توضیح بده]\n\n۲. تداخلات مهم داروها که باید به بیمار گوشزد شود:\n[توضیح بده]\n\n۳. عوارض مهم و شایعی که حتما باید بیمار در مورد این داروها یادش باشد:\n[توضیح بده]\n\n۴. اگر دارویی را باید در زمان خاصی از روز مصرف کرد:\n[توضیح بده]\n\n۵. اگر دارویی رو باید با فاصله از غذا یا با غذا مصرف کرد:\n[توضیح بده]\n\n۶. تعداد مصرف روزانه هر دارو:\n[توضیح بده]\n\n۷. اگر برای عارضه\u200cای که داروها میدهند نیاز به مدیریت خاصی وجود دارد که باید اطلاع بدم بگو:\n[توضیح بده]",
					},
					{
						Role:    openai.ChatMessageRoleUser,
						Content: prompt,
					},
				},
				MaxTokens: 1000, // Even fewer tokens for the fallback
			},
		)

		// If both API calls fail, try a direct HTTP request as a last resort
		if err != nil {
			log.Printf("Error calling OpenAI API with fallback model: %v", err)
			log.Println("Trying direct HTTP request as last resort...")

			// Create a custom HTTP client with appropriate timeouts
			directClient := &http.Client{
				Timeout: 20 * time.Second,
				Transport: &http.Transport{
					TLSHandshakeTimeout: 10 * time.Second,
				},
			}

			// Prepare the request payload
			requestBody := map[string]interface{}{
				"model": "gemini-2.0-flash-thinking-exp-01-21",
				"messages": []map[string]string{
					{
						"role":    "system",
						"content": "من مسئول فنی یک داروخانه شهری هستم\n\nخوب فکر کن و تمام جوانب رو بررسی کن و با استدلال جواب بده\n\nو به این شکل به من در مورد این نسخه جواب بده:\n\nبا سلام همکار گرامی،\n\nبا بررسی داروهای موجود در نسخه، اطلاعات زیر را خدمت شما ارائه می\u200cدهم:\n\nلیست داروهای نسخه:\n[اینجا لیست داروها را با توضیح مختصر هر دارو بنویس]\n\n۱. تشخیص احتمالی عارضه یا بیماری:\n[توضیح بده]\n\n۲. تداخلات مهم داروها که باید به بیمار گوشزد شود:\n[توضیح بده]\n\n۳. عوارض مهم و شایعی که حتما باید بیمار در مورد این داروها یادش باشد:\n[توضیح بده]\n\n۴. اگر دارویی را باید در زمان خاصی از روز مصرف کرد:\n[توضیح بده]\n\n۵. اگر دارویی رو باید با فاصله از غذا یا با غذا مصرف کرد:\n[توضیح بده]\n\n۶. تعداد مصرف روزانه هر دارو:\n[توضیح بده]\n\n۷. اگر برای عارضه\u200cای که داروها میدهند نیاز به مدیریت خاصی وجود دارد که باید اطلاع بدم بگو:\n[توضیح بده]",
					},
					{
						"role":    "user",
						"content": prompt,
					},
				},
				"max_tokens": 800,
			}

			requestBodyBytes, _ := json.Marshal(requestBody)

			// Create a new request
			req, reqErr := http.NewRequest("POST", "https://api.avalai.ir/v1/chat/completions", bytes.NewBuffer(requestBodyBytes))
			if reqErr != nil {
				log.Printf("Error creating direct HTTP request: %v", reqErr)
			} else {
				// Set headers
				req.Header.Set("Content-Type", "application/json")
				req.Header.Set("Authorization", "Bearer "+os.Getenv("OPENAI_API_KEY"))

				// Make the request
				directResp, directErr := directClient.Do(req)
				if directErr != nil {
					log.Printf("Error making direct HTTP request: %v", directErr)
				} else {
					defer directResp.Body.Close()

					// Parse the response
					var directResult map[string]interface{}
					if jsonErr := json.NewDecoder(directResp.Body).Decode(&directResult); jsonErr != nil {
						log.Printf("Error parsing direct HTTP response: %v", jsonErr)
					} else {
						// Extract the content from the response
						if choices, ok := directResult["choices"].([]interface{}); ok && len(choices) > 0 {
							if choice, ok := choices[0].(map[string]interface{}); ok {
								if message, ok := choice["message"].(map[string]interface{}); ok {
									if content, ok := message["content"].(string); ok {
										// Create a mock response
										resp = openai.ChatCompletionResponse{
											Choices: []openai.ChatCompletionChoice{
												{
													Message: openai.ChatCompletionMessage{
														Content: content,
													},
												},
											},
										}
										err = nil // Clear the error since we got a response
										log.Println("Successfully got response from direct HTTP request")
									}
								}
							}
						}
					}
				}
			}
		}
	}

	if err != nil {
		log.Printf("Error calling OpenAI API: %v", err)

		// Check if it's a context deadline exceeded error
		if ctx.Err() == context.DeadlineExceeded || (fallbackCtx != nil && fallbackCtx.Err() == context.DeadlineExceeded) {
			writeErrorResponse(w, "API request timed out. Please try again later.", http.StatusGatewayTimeout)
			return
		}

		writeErrorResponse(w, "Error analyzing prescription", http.StatusInternalServerError)
		return
	}

	log.Println("Received response from OpenAI API")

	// Extract the response
	analysis := ""
	if len(resp.Choices) > 0 {
		analysis = resp.Choices[0].Message.Content
	}

	// Write the response
	response := models.AnalysisResponse{
		Status:   "success",
		Analysis: analysis,
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
	log.Println("Response sent to client")
}

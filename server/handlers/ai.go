package handlers

import (
	"context"
	"encoding/json"
	"log"
	"net"
	"net/http"
	"os"
	"time"

	"github.com/darooyar/server/models"
	"github.com/darooyar/server/nats"
	natspkg "github.com/nats-io/nats.go"
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

	// Check if NATS is available
	if nats.NatsConn == nil || !nats.NatsConn.IsConnected() {
		log.Println("NATS not available, falling back to direct API call")
		h.handleCompletionDirect(w, request)
		return
	}

	// Use NATS for asynchronous processing
	h.handleCompletionWithNATS(w, request)
}

// handleCompletionWithNATS processes the completion request using NATS
func (h *AIHandler) handleCompletionWithNATS(w http.ResponseWriter, request models.CompletionRequest) {
	// Convert request to JSON
	requestData, err := json.Marshal(request)
	if err != nil {
		log.Printf("Error marshaling request: %v", err)
		writeErrorResponse(w, "Error processing request", http.StatusInternalServerError)
		return
	}

	// Create a unique inbox subject for the response
	inbox := nats.NatsConn.NewInbox()

	// Subscribe to the inbox for the response
	sub, err := nats.NatsConn.SubscribeSync(inbox)
	if err != nil {
		log.Printf("Error subscribing to inbox: %v", err)
		writeErrorResponse(w, "Error processing request", http.StatusInternalServerError)
		return
	}
	defer sub.Unsubscribe()

	// Publish the request to the AI completion subject with reply
	if err := nats.NatsConn.PublishRequest(nats.SubjectAICompletion, inbox, requestData); err != nil {
		log.Printf("Error publishing request: %v", err)
		writeErrorResponse(w, "Error processing request", http.StatusInternalServerError)
		return
	}

	// Wait for the response with a timeout
	msg, err := sub.NextMsg(30 * time.Second)
	if err != nil {
		if err == natspkg.ErrTimeout {
			log.Println("Timeout waiting for AI completion response")
			writeErrorResponse(w, "Request timed out. Please try again later.", http.StatusGatewayTimeout)
		} else {
			log.Printf("Error receiving response: %v", err)
			writeErrorResponse(w, "Error processing request", http.StatusInternalServerError)
		}
		return
	}

	// Parse the response
	var response models.CompletionResponse
	if err := json.Unmarshal(msg.Data, &response); err != nil {
		log.Printf("Error unmarshaling response: %v", err)
		writeErrorResponse(w, "Error processing response", http.StatusInternalServerError)
		return
	}

	// Write the response
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// handleCompletionDirect processes the completion request directly (fallback)
func (h *AIHandler) handleCompletionDirect(w http.ResponseWriter, request models.CompletionRequest) {
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
			MaxTokens: 2000,
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

	// Check if NATS is available
	if nats.NatsConn == nil || !nats.NatsConn.IsConnected() {
		log.Println("NATS not available, falling back to direct API call")
		h.handlePrescriptionAnalysisDirect(w, request)
		return
	}

	// Use NATS for asynchronous processing
	h.handlePrescriptionAnalysisWithNATS(w, request)
}

// handlePrescriptionAnalysisWithNATS processes the prescription analysis request using NATS
func (h *AIHandler) handlePrescriptionAnalysisWithNATS(w http.ResponseWriter, request models.TextAnalysisRequest) {
	// Convert request to JSON
	requestData, err := json.Marshal(request)
	if err != nil {
		log.Printf("Error marshaling request: %v", err)
		writeErrorResponse(w, "Error processing request", http.StatusInternalServerError)
		return
	}

	// Create a unique inbox subject for the response
	inbox := nats.NatsConn.NewInbox()

	// Subscribe to the inbox for the response
	sub, err := nats.NatsConn.SubscribeSync(inbox)
	if err != nil {
		log.Printf("Error subscribing to inbox: %v", err)
		writeErrorResponse(w, "Error processing request", http.StatusInternalServerError)
		return
	}
	defer sub.Unsubscribe()

	// Publish the request to the AI prescription subject with reply
	if err := nats.NatsConn.PublishRequest(nats.SubjectAIPrescription, inbox, requestData); err != nil {
		log.Printf("Error publishing request: %v", err)
		writeErrorResponse(w, "Error processing request", http.StatusInternalServerError)
		return
	}

	// Wait for the response with a timeout
	msg, err := sub.NextMsg(45 * time.Second)
	if err != nil {
		if err == natspkg.ErrTimeout {
			log.Println("Timeout waiting for AI prescription analysis response")
			writeErrorResponse(w, "Request timed out. Please try again later.", http.StatusGatewayTimeout)
		} else {
			log.Printf("Error receiving response: %v", err)
			writeErrorResponse(w, "Error processing request", http.StatusInternalServerError)
		}
		return
	}

	// Parse the response
	var response models.AnalysisResponse
	if err := json.Unmarshal(msg.Data, &response); err != nil {
		log.Printf("Error unmarshaling response: %v", err)
		writeErrorResponse(w, "Error processing response", http.StatusInternalServerError)
		return
	}

	// Write the response
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// handlePrescriptionAnalysisDirect processes the prescription analysis request directly (fallback)
func (h *AIHandler) handlePrescriptionAnalysisDirect(w http.ResponseWriter, request models.TextAnalysisRequest) {
	// Check if client is initialized
	if h.client == nil {
		log.Println("OpenAI client not initialized. Please set OPENAI_API_KEY environment variable.")
		writeErrorResponse(w, "OpenAI API key not configured", http.StatusInternalServerError)
		return
	}

	log.Println("OpenAI client is initialized. Calling OpenAI API.")
	log.Println("Using custom base URL: https://api.avalai.ir/v1")

	// Prepare the prompt for the AI
	prompt := "من مسئول فنی یک داروخانه شهری هستم\n\nخوب فکر کن و تمام جوانب رو بررسی کن و با استدلال جواب بده\n\nو به این شکل به من در مورد این نسخه جواب بده:\n\nبا سلام همکار گرامی،\n\nبا بررسی داروهای موجود در نسخه، اطلاعات زیر را خدمت شما ارائه می\u200cدهم:\n\n<داروها>\nلیست کامل داروها را بنویس و برای هر دارو یک توضیح کامل بنویس که شامل دسته دارویی، مکانیسم اثر و کاربرد اصلی آن باشد. حتما همه داروهای موجود در نسخه را بررسی کن و هیچ دارویی را از قلم نینداز.\n</داروها>\n\n<تشخیص>\nبا توجه به ترکیب داروها، تشخیص احتمالی را با جزئیات کامل توضیح بده و دلیل استفاده از هر دارو را در درمان این عارضه شرح بده.\n</تشخیص>\n\n<تداخلات>\nتمام تداخلات بین داروهای نسخه را با جزئیات بررسی کن. برای هر تداخل، شدت آن، مکانیسم تداخل و راهکارهای مدیریت آن را توضیح بده. اگر تداخل مهمی وجود ندارد، به صراحت ذکر کن.\n</تداخلات>\n\n<عوارض>\nعوارض شایع و مهم هر دارو را به تفکیک بنویس و توضیح بده که بیمار چگونه باید این عوارض را مدیریت کند. عوارض خطرناک که نیاز به مراجعه فوری به پزشک دارند را مشخص کن.\n</عوارض>\n\n<زمان_مصرف>\nبرای هر دارو، بهترین زمان مصرف را با دلیل آن توضیح بده. مثلا صبح، شب، قبل از خواب، یا در زمان‌های خاص دیگر.\n</زمان_مصرف>\n\n<مصرف_با_غذا>\nبرای هر دارو مشخص کن که آیا باید با غذا، با معده خالی، یا با فاصله از غذا مصرف شود و دلیل این توصیه را توضیح بده.\n</مصرف_با_غذا>\n\n<دوز_مصرف>\nدوز و تعداد دفعات مصرف هر دارو را به صورت دقیق بنویس و در صورت نیاز، توضیح بده که چرا این دوز توصیه شده است.\n</دوز_مصرف>\n\n<مدیریت_عارضه>\nتوصیه‌های تکمیلی برای مدیریت بیماری یا عارضه را بنویس، مانند رژیم غذایی خاص، فعالیت‌های فیزیکی توصیه شده یا منع شده، و سایر نکات مهم برای بهبود اثربخشی درمان.\n</مدیریت_عارضه>"

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
					Content: prompt,
				},
				{
					Role:    openai.ChatMessageRoleUser,
					Content: request.Text,
				},
			},
			// Reduced max tokens to avoid timeouts
			MaxTokens: 2000,
		},
	)

	// Handle errors
	if err != nil {
		log.Printf("Error calling OpenAI API: %v", err)

		// Check if it's a context deadline exceeded error
		if ctx.Err() == context.DeadlineExceeded {
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

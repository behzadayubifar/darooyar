package nats

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/darooyar/server/models"
	"github.com/nats-io/nats.go"
	"github.com/sashabaranov/go-openai"
)

const (
	// AI related subjects
	SubjectAICompletion           = "ai.completion"
	SubjectAICompletionResponse   = "ai.completion.response"
	SubjectAIPrescription         = "ai.prescription"
	SubjectAIPrescriptionResponse = "ai.prescription.response"
)

// AIService handles AI-related operations through NATS
type AIService struct {
	client *openai.Client
}

// NewAIService creates a new AI service
func NewAIService() (*AIService, error) {
	// Get API key from environment variable
	apiKey := os.Getenv("OPENAI_API_KEY")
	var client *openai.Client

	if apiKey == "" {
		log.Println("Warning: OPENAI_API_KEY environment variable is not set")
		client = nil
	} else {
		// Create OpenAI client with custom base URL
		config := openai.DefaultConfig(apiKey)
		config.BaseURL = "https://api.avalai.ir/v1"

		// Configure HTTP client with longer timeouts and TLS settings
		httpClient := &http.Client{
			Timeout: 60 * time.Second,
		}
		config.HTTPClient = httpClient

		client = openai.NewClientWithConfig(config)
		log.Println("OpenAI client initialized with custom base URL")
	}

	service := &AIService{
		client: client,
	}

	// Subscribe to AI completion requests
	if err := service.subscribeToCompletionRequests(); err != nil {
		return nil, err
	}

	// Subscribe to AI prescription analysis requests
	if err := service.subscribeToPrescriptionRequests(); err != nil {
		return nil, err
	}

	return service, nil
}

// subscribeToCompletionRequests subscribes to AI completion requests
func (s *AIService) subscribeToCompletionRequests() error {
	_, err := NatsConn.Subscribe(SubjectAICompletion, func(msg *nats.Msg) {
		log.Printf("Received AI completion request: %s", string(msg.Data))

		// Parse the request
		var request models.CompletionRequest
		if err := json.Unmarshal(msg.Data, &request); err != nil {
			log.Printf("Error parsing AI completion request: %v", err)
			return
		}

		// Process the request asynchronously
		go func() {
			// Create a context with a timeout
			ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
			defer cancel()

			// Check if client is initialized
			if s.client == nil {
				log.Println("OpenAI client not initialized. Please set OPENAI_API_KEY environment variable.")
				return
			}

			// Call OpenAI API
			resp, err := s.client.CreateChatCompletion(
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

			// Prepare response
			response := models.CompletionResponse{
				Status: "success",
			}

			// Handle errors
			if err != nil {
				log.Printf("Error calling OpenAI API: %v", err)
				response.Status = "error"
				response.Completion = "Error generating completion. Please try again later."
			} else if len(resp.Choices) > 0 {
				response.Completion = resp.Choices[0].Message.Content
			}

			// Send response back
			responseData, err := json.Marshal(response)
			if err != nil {
				log.Printf("Error marshaling AI completion response: %v", err)
				return
			}

			// Publish response to the response subject with the reply subject
			if msg.Reply != "" {
				if err := NatsConn.Publish(msg.Reply, responseData); err != nil {
					log.Printf("Error publishing AI completion response: %v", err)
				}
			} else {
				// If no reply subject, publish to the general response subject
				if err := NatsConn.Publish(SubjectAICompletionResponse, responseData); err != nil {
					log.Printf("Error publishing AI completion response: %v", err)
				}
			}
		}()
	})

	if err != nil {
		return err
	}

	log.Printf("Subscribed to %s", SubjectAICompletion)
	return nil
}

// subscribeToPrescriptionRequests subscribes to AI prescription analysis requests
func (s *AIService) subscribeToPrescriptionRequests() error {
	_, err := NatsConn.Subscribe(SubjectAIPrescription, func(msg *nats.Msg) {
		log.Printf("Received AI prescription analysis request: %s", string(msg.Data))

		// Parse the request
		var request models.TextAnalysisRequest
		if err := json.Unmarshal(msg.Data, &request); err != nil {
			log.Printf("Error parsing AI prescription analysis request: %v", err)
			return
		}

		// Process the request asynchronously
		go func() {
			// Create a context with a timeout
			ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
			defer cancel()

			// Check if client is initialized
			if s.client == nil {
				log.Println("OpenAI client not initialized. Please set OPENAI_API_KEY environment variable.")
				return
			}

			// Prepare the prompt for the AI
			prompt := "من مسئول فنی یک داروخانه شهری هستم\n\nخوب فکر کن و تمام جوانب رو بررسی کن و با استدلال جواب بده\n\nو به این شکل به من در مورد این نسخه جواب بده:\n\nبا سلام همکار گرامی،\n\nبا بررسی داروهای موجود در نسخه، اطلاعات زیر را خدمت شما ارائه می\u200cدهم:\n\n<داروها>\nلیست کامل داروها را بنویس و برای هر دارو یک توضیح کامل بنویس که شامل دسته دارویی، مکانیسم اثر و کاربرد اصلی آن باشد. حتما همه داروهای موجود در نسخه را بررسی کن و هیچ دارویی را از قلم نینداز.\n</داروها>\n\n<تشخیص>\nبا توجه به ترکیب داروها، تشخیص احتمالی را با جزئیات کامل توضیح بده و دلیل استفاده از هر دارو را در درمان این عارضه شرح بده.\n</تشخیص>\n\n<تداخلات>\nتمام تداخلات بین داروهای نسخه را با جزئیات بررسی کن. برای هر تداخل، شدت آن، مکانیسم تداخل و راهکارهای مدیریت آن را توضیح بده. اگر تداخل مهمی وجود ندارد، به صراحت ذکر کن.\n</تداخلات>\n\n<عوارض>\nعوارض شایع و مهم هر دارو را به تفکیک بنویس و توضیح بده که بیمار چگونه باید این عوارض را مدیریت کند. عوارض خطرناک که نیاز به مراجعه فوری به پزشک دارند را مشخص کن.\n</عوارض>\n\n<زمان_مصرف>\nبرای هر دارو، بهترین زمان مصرف را با دلیل آن توضیح بده. مثلا صبح، شب، قبل از خواب، یا در زمان‌های خاص دیگر.\n</زمان_مصرف>\n\n<مصرف_با_غذا>\nبرای هر دارو مشخص کن که آیا باید با غذا، با معده خالی، یا با فاصله از غذا مصرف شود و دلیل این توصیه را توضیح بده.\n</مصرف_با_غذا>\n\n<دوز_مصرف>\nدوز و تعداد دفعات مصرف هر دارو را به صورت دقیق بنویس و در صورت نیاز، توضیح بده که چرا این دوز توصیه شده است.\n</دوز_مصرف>\n\n<مدیریت_عارضه>\nتوصیه‌های تکمیلی برای مدیریت بیماری یا عارضه را بنویس، مانند رژیم غذایی خاص، فعالیت‌های فیزیکی توصیه شده یا منع شده، و سایر نکات مهم برای بهبود اثربخشی درمان.\n</مدیریت_عارضه>"

			// Call OpenAI API
			resp, err := s.client.CreateChatCompletion(
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
					MaxTokens: 2000,
				},
			)

			// Prepare response
			response := models.AnalysisResponse{
				Status: "success",
			}

			// Handle errors
			if err != nil {
				log.Printf("Error calling OpenAI API: %v", err)
				response.Status = "error"
				response.Analysis = "Error analyzing prescription. Please try again later."
			} else if len(resp.Choices) > 0 {
				response.Analysis = resp.Choices[0].Message.Content
			}

			// Send response back
			responseData, err := json.Marshal(response)
			if err != nil {
				log.Printf("Error marshaling AI prescription analysis response: %v", err)
				return
			}

			// Publish response to the response subject with the reply subject
			if msg.Reply != "" {
				if err := NatsConn.Publish(msg.Reply, responseData); err != nil {
					log.Printf("Error publishing AI prescription analysis response: %v", err)
				}
			} else {
				// If no reply subject, publish to the general response subject
				if err := NatsConn.Publish(SubjectAIPrescriptionResponse, responseData); err != nil {
					log.Printf("Error publishing AI prescription analysis response: %v", err)
				}
			}
		}()
	})

	if err != nil {
		return err
	}

	log.Printf("Subscribed to %s", SubjectAIPrescription)
	return nil
}

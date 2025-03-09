package storage

import (
	"context"
	"fmt"
	"io"
	"log"
	"path/filepath"
	"strings"
	"time"

	"bytes"

	"github.com/aws/aws-sdk-go-v2/aws"
	awsconfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
	"github.com/darooyar/server/config"
)

// S3Client represents a client for interacting with S3-compatible storage
type S3Client struct {
	client     *s3.Client
	bucketName string
	endpoint   string
}

// NewS3Client creates a new S3 client using environment variables
func NewS3Client() (*S3Client, error) {
	// Get configuration
	cfg := config.GetConfig()

	// Validate required environment variables
	if cfg.LiaraAccessKey == "" || cfg.LiaraSecretKey == "" || cfg.LiaraEndpoint == "" || cfg.LiaraBucketName == "" {
		return nil, fmt.Errorf("missing required environment variables for S3 storage")
	}

	// Create AWS config
	awsCfg, err := awsconfig.LoadDefaultConfig(context.TODO(), awsconfig.WithRegion("us-west-2"))
	if err != nil {
		return nil, fmt.Errorf("failed to load AWS config: %w", err)
	}

	// Set custom credentials and endpoint
	awsCfg.Credentials = aws.CredentialsProviderFunc(func(ctx context.Context) (aws.Credentials, error) {
		return aws.Credentials{
			AccessKeyID:     cfg.LiaraAccessKey,
			SecretAccessKey: cfg.LiaraSecretKey,
		}, nil
	})
	awsCfg.BaseEndpoint = aws.String(cfg.LiaraEndpoint)

	// Create S3 client
	client := s3.NewFromConfig(awsCfg)

	return &S3Client{
		client:     client,
		bucketName: cfg.LiaraBucketName,
		endpoint:   cfg.LiaraEndpoint,
	}, nil
}

// UploadFile uploads a file to S3 storage and returns the public URL
func (s *S3Client) UploadFile(fileContent io.Reader, fileName string, contentType string) (string, error) {
	// Read the file content
	fileBytes, err := io.ReadAll(fileContent)
	if err != nil {
		return "", fmt.Errorf("failed to read file content: %w", err)
	}

	// Validate and correct content type for images
	if contentType == "" || contentType == "application/octet-stream" {
		// For image files, try to detect proper MIME type
		fileExt := strings.ToLower(filepath.Ext(fileName))
		if fileExt == ".jpg" || fileExt == ".jpeg" || fileExt == ".png" || fileExt == ".gif" || fileExt == ".webp" || fileExt == ".bmp" {
			// Try to detect from content
			detectedType := detectMimeType(fileBytes)
			if detectedType != "" {
				contentType = detectedType
				log.Printf("Detected image MIME type: %s for file %s", contentType, fileName)
			} else {
				// Fallback to extension-based detection
				switch fileExt {
				case ".jpg", ".jpeg":
					contentType = "image/jpeg"
				case ".png":
					contentType = "image/png"
				case ".gif":
					contentType = "image/gif"
				case ".webp":
					contentType = "image/webp"
				case ".bmp":
					contentType = "image/bmp"
				default:
					contentType = "image/jpeg" // Default to JPEG for unknown image types
				}
				log.Printf("Set MIME type to %s based on extension for file %s", contentType, fileName)
			}
		}
	}

	// Generate a unique key for the file
	fileExt := filepath.Ext(fileName)
	timestamp := time.Now().Unix()
	destinationKey := fmt.Sprintf("prescriptions/%d%s", timestamp, fileExt)

	// Upload the file to S3
	_, err = s.client.PutObject(context.TODO(), &s3.PutObjectInput{
		Bucket:      aws.String(s.bucketName),
		Key:         aws.String(destinationKey),
		Body:        bytes.NewReader(fileBytes),
		ContentType: aws.String(contentType),
		ACL:         types.ObjectCannedACLPublicRead, // Make file publicly accessible
	})
	if err != nil {
		return "", fmt.Errorf("failed to upload file to S3: %w", err)
	}

	// Generate the public URL
	publicURL := fmt.Sprintf("%s/%s/%s", s.endpoint, s.bucketName, destinationKey)
	log.Printf("File uploaded successfully to %s with content type: %s", publicURL, contentType)

	return publicURL, nil
}

// detectMimeType detects MIME type from file content
func detectMimeType(data []byte) string {
	// Check for common image formats based on file signatures (magic numbers)
	if len(data) > 2 {
		// JPEG: Starts with FF D8 FF
		if data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF {
			return "image/jpeg"
		}

		// PNG: Starts with 89 50 4E 47 0D 0A 1A 0A
		if len(data) > 8 && data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47 &&
			data[4] == 0x0D && data[5] == 0x0A && data[6] == 0x1A && data[7] == 0x0A {
			return "image/png"
		}

		// GIF: Starts with GIF87a or GIF89a
		if len(data) > 6 && data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x38 &&
			(data[4] == 0x37 || data[4] == 0x39) && data[5] == 0x61 {
			return "image/gif"
		}

		// WebP: Starts with RIFF????WEBP
		if len(data) > 12 && data[0] == 0x52 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x46 &&
			data[8] == 0x57 && data[9] == 0x45 && data[10] == 0x42 && data[11] == 0x50 {
			return "image/webp"
		}

		// BMP: Starts with BM
		if len(data) > 2 && data[0] == 0x42 && data[1] == 0x4D {
			return "image/bmp"
		}
	}

	return ""
}

// GetTemporaryURL generates a temporary signed URL for the given object
func (s *S3Client) GetTemporaryURL(objectKey string, expiration time.Duration) (string, error) {
	// Create a presigner client
	presignClient := s3.NewPresignClient(s.client)

	// Generate a pre-signed URL
	presignedReq, err := presignClient.PresignGetObject(context.TODO(), &s3.GetObjectInput{
		Bucket: aws.String(s.bucketName),
		Key:    aws.String(objectKey),
	}, s3.WithPresignExpires(expiration))
	if err != nil {
		return "", fmt.Errorf("failed to generate pre-signed URL: %w", err)
	}

	return presignedReq.URL, nil
}

// DeleteFile deletes a file from S3 storage
func (s *S3Client) DeleteFile(objectKey string) error {
	_, err := s.client.DeleteObject(context.TODO(), &s3.DeleteObjectInput{
		Bucket: aws.String(s.bucketName),
		Key:    aws.String(objectKey),
	})
	if err != nil {
		return fmt.Errorf("failed to delete file from S3: %w", err)
	}

	log.Printf("File deleted successfully: %s", objectKey)
	return nil
}

# Darooyar Server Makefile

# Variables
BINARY_NAME=darooyar-server
GO=go

# Detect OS
ifeq ($(OS),Windows_NT)
    BINARY_EXT=.exe
    RM_CMD=del /Q
    # For Windows, we need to clean up both with and without extension
    CLEAN_TARGETS=$(BINARY_NAME)$(BINARY_EXT) $(BINARY_NAME)
else
    BINARY_EXT=
    RM_CMD=rm -f
    CLEAN_TARGETS=$(BINARY_NAME)
endif

# Default target - changed to start
.PHONY: all
all: start

# Build the server
.PHONY: build
build:
	@echo Building Darooyar server...
	$(GO) build -o $(BINARY_NAME)$(BINARY_EXT) .

# Run the server
.PHONY: run
run: build
	@echo Starting Darooyar server...
ifeq ($(OS),Windows_NT)
	cmd /c start $(BINARY_NAME)$(BINARY_EXT)
else
	./$(BINARY_NAME)$(BINARY_EXT)
endif

# Clean build artifacts
.PHONY: clean
clean:
	@echo Cleaning up...
ifeq ($(OS),Windows_NT)
	@if exist $(BINARY_NAME)$(BINARY_EXT) $(RM_CMD) $(BINARY_NAME)$(BINARY_EXT)
	@if exist $(BINARY_NAME) $(RM_CMD) $(BINARY_NAME)
	@if exist server.exe $(RM_CMD) server.exe
else
	$(RM_CMD) $(CLEAN_TARGETS)
endif
	@echo Cleanup complete

# Build and run in one command
.PHONY: start
start: build run

# Help command
.PHONY: help
help:
	@echo Darooyar Server Makefile
	@echo 
	@echo Usage:
	@echo   make build    - Build the server
	@echo   make run      - Run the server (builds first)
	@echo   make start    - Build and run the server
	@echo   make clean    - Remove build artifacts
	@echo   make help     - Show this help message 
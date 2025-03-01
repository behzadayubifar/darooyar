# Root Makefile for Darooyar project
# This Makefile manages both server and Flutter components

# Default target - build and run server
.PHONY: all
all: start

# Server targets
.PHONY: server-all server-build server-run server-clean server-start server-help
server-all:
	$(MAKE) -C server all

server-build:
	$(MAKE) -C server build

server-run:
	$(MAKE) -C server run

server-clean:
	$(MAKE) -C server clean

server-start:
	$(MAKE) -C server start

server-help:
	$(MAKE) -C server help

# Flutter targets
.PHONY: flutter-build flutter-run flutter-clean flutter-test flutter-install
flutter-build:
	@echo Building Flutter app...
	@cd flutter && flutter build apk

flutter-run:
	@echo Running Flutter app...
	@cd flutter && flutter run

flutter-clean:
	@echo Cleaning Flutter app...
	@cd flutter && flutter clean

flutter-test:
	@echo Testing Flutter app...
	@cd flutter && flutter test

flutter-install:
	@echo Installing Flutter dependencies...
	@cd flutter && flutter pub get

# Full project commands
.PHONY: build-all run-all clean-all
build-all: server-build flutter-build
	@echo All components built successfully

run-all: server-start flutter-run
	@echo All components running

clean-all: server-clean flutter-clean
	@echo All components cleaned

# Convenience aliases for server (so you can just type 'make build', etc.)
.PHONY: build run clean start help
build: server-build
run: server-run
clean: server-clean
start: server-start
help:
	@echo 
	@echo Darooyar Project Makefile
	@echo 
	@echo Server Commands:
	@echo   make              - Build and run the server (same as 'make start')
	@echo   make build        - Build the server
	@echo   make run          - Run the server (builds first)
	@echo   make start        - Build and run the server
	@echo   make clean        - Remove build artifacts
	@echo 
	@echo Flutter Commands:
	@echo   make flutter-build    - Build the Flutter app
	@echo   make flutter-run      - Run the Flutter app
	@echo   make flutter-clean    - Clean Flutter build artifacts
	@echo   make flutter-test     - Run Flutter tests
	@echo   make flutter-install  - Install Flutter dependencies
	@echo 
	@echo Combined Commands:
	@echo   make build-all        - Build both server and Flutter app
	@echo   make run-all          - Run both server and Flutter app
	@echo   make clean-all        - Clean both server and Flutter app
	@echo 
	@echo   make help             - Show this help message
	@echo 
	@echo Server-specific commands:
	@echo   make server-build, server-run, etc. 
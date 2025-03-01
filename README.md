# دارویار (Darooyar)

دارویار (Darooyar) is a prescription analysis application that helps users understand their medical prescriptions.

## Project Structure

The project consists of two main components:

1. **Flutter App**: A cross-platform mobile application built with Flutter
2. **Go Server**: A backend API server built with Go

## Getting Started

### Prerequisites

- Flutter SDK
- Go 1.16 or higher
- Git
- Aval AI API Key (for AI-powered features)

### Installation

1. Clone the repository:

   ```
   git clone https://github.com/behzadayubifar/darooyar.git
   cd darooyar
   ```

2. Set up the server:

   ```
   cd server
   go mod download
   ```

   Create a `.env` file in the server directory with your Aval AI API key:

   ```
   AVALAI_API_KEY=your_avalai_api_key_here
   AVALAI_API_BASE_URL=https://api.aval.ai
   ```

3. Set up the Flutter app:

   ```
   cd ../app
   flutter pub get
   ```

4. Run the server:

   ```
   cd ../server
   go run main.go
   ```

5. Run the Flutter app:

   ```
   cd ../app
   flutter run
   ```

## Features

- Prescription text analysis
- Prescription image analysis
- AI-powered prescription interpretation using Aval AI
- User-friendly mobile interface

## Development

See the README files in the `server` and `app` directories for more detailed information about each component.

## License

This project is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License - see the [LICENSE](LICENSE) file for details.

This means you are free to:

- Share — copy and redistribute the material in any medium or format
- Adapt — remix, transform, and build upon the material

Under the following terms:

- Attribution — You must give appropriate credit, provide a link to the license, and indicate if changes were made.
- NonCommercial — You may not use the material for commercial purposes.

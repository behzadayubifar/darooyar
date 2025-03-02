# PowerShell script to run the server with the WiFi IP address
Write-Host "Starting server on WiFi IP address..." -ForegroundColor Green

# Kill any existing server processes on port 8080
$existingProcess = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess
if ($null -ne $existingProcess) {
    Write-Host "Killing process using port 8080 (PID: $existingProcess)..." -ForegroundColor Red
    Stop-Process -Id $existingProcess -Force -ErrorAction SilentlyContinue
    # Give it a moment to release the port
    Start-Sleep -Seconds 1
}

# Set environment variable for the server to use
$env:SERVER_ADDR = "0.0.0.0:8080"

# Run the server with the environment variable
Write-Host "Running server on $env:SERVER_ADDR..." -ForegroundColor Green
go run main.go 
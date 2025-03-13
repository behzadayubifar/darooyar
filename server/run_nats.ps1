# PowerShell script to run NATS Server for development

# Check if Docker is installed
$dockerCheck = docker --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker is not installed or not in PATH. Please install Docker first." -ForegroundColor Red
    exit 1
}

# Check if NATS container is already running
$natsRunning = docker ps --filter "name=nats-server" --format "{{.Names}}"
if ($natsRunning -eq "nats-server") {
    Write-Host "NATS Server is already running." -ForegroundColor Green
    exit 0
}

# Check if NATS container exists but is stopped
$natsExists = docker ps -a --filter "name=nats-server" --format "{{.Names}}"
if ($natsExists -eq "nats-server") {
    Write-Host "Starting existing NATS Server container..." -ForegroundColor Yellow
    docker start nats-server
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to start NATS Server container." -ForegroundColor Red
        exit 1
    }
    Write-Host "NATS Server is now running." -ForegroundColor Green
    exit 0
}

# Run new NATS container
Write-Host "Creating and starting new NATS Server container..." -ForegroundColor Yellow
docker run -d --name nats-server -p 4222:4222 -p 8222:8222 -p 6222:6222 nats
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create and start NATS Server container." -ForegroundColor Red
    exit 1
}

Write-Host "NATS Server is now running." -ForegroundColor Green
Write-Host "NATS Server is accessible at: nats://localhost:4222" -ForegroundColor Cyan
Write-Host "NATS Monitoring is accessible at: http://localhost:8222" -ForegroundColor Cyan 
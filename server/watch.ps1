$lastChange = Get-Date
$serverProcess = $null


function Restart-Server {
    Write-Host "Starting server..." -ForegroundColor Green
    
    # Kill any existing server processes
    if ($null -ne $serverProcess) {
        Write-Host "Stopping make process..." -ForegroundColor Yellow
        Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
    }
    
    # Find and kill any existing Go server processes that might be using port 8080
    Write-Host "Checking for existing server processes on port 8080..." -ForegroundColor Yellow
    $existingProcess = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess
    if ($null -ne $existingProcess) {
        Write-Host "Killing process using port 8080 (PID: $existingProcess)..." -ForegroundColor Red
        Stop-Process -Id $existingProcess -Force -ErrorAction SilentlyContinue
        # Give it a moment to release the port
        Start-Sleep -Seconds 1
    }
    
    # Use make instead of direct go commands
    Write-Host "Building with make..." -ForegroundColor Blue
    make build
    
    Write-Host "Running with make..." -ForegroundColor Green
    $script:serverProcess = Start-Process -FilePath "make" -ArgumentList "run" -PassThru -NoNewWindow
    Write-Host "Server started with PID: $($serverProcess.Id)" -ForegroundColor Green
}

Restart-Server

while ($true) {
    $changes = Get-ChildItem -Path . -Recurse -Include "*.go" | Where-Object { $_.LastWriteTime -gt $lastChange }
    
    if ($changes.Count -gt 0) {
        Write-Host "Changes detected in:" -ForegroundColor Cyan
        foreach ($change in $changes) {
            Write-Host "  $($change.FullName)" -ForegroundColor Cyan
        }
        
        $lastChange = Get-Date
        
        Write-Host "Rebuilding and restarting server..." -ForegroundColor Yellow
        Restart-Server
    }
    
    Start-Sleep -Seconds 2
} 
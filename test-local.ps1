# Local Docker Test Script

param(
    [string]$ImageName = "coe-dynamic-hosting",
    [string]$ImageTag = "latest",
    [int]$Port = 5000
)

$ErrorActionPreference = "Stop"

Write-Host "Building and testing Docker image locally..." -ForegroundColor Green

# Build Docker image
Write-Host "Building Docker image..." -ForegroundColor Yellow
docker build -t "${ImageName}:${ImageTag}" .

# Stop any existing container
Write-Host "Stopping any existing containers..." -ForegroundColor Yellow
docker stop $ImageName 2>$null || $true
docker rm $ImageName 2>$null || $true

# Run container
Write-Host "Starting container on port $Port..." -ForegroundColor Yellow
docker run -d --name $ImageName -p "${Port}:5000" "${ImageName}:${ImageTag}"

# Wait a moment for container to start
Start-Sleep -Seconds 5

# Check if container is running
$containerStatus = docker ps --filter "name=$ImageName" --format "table {{.Status}}"
if ($containerStatus -match "Up") {
    Write-Host "Container started successfully!" -ForegroundColor Green
    Write-Host "Application should be available at: http://localhost:$Port" -ForegroundColor Green
    
    # Test endpoint
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$Port" -TimeoutSec 10
        Write-Host "HTTP Status: $($response.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "Warning: Could not reach application endpoint. Container may still be starting." -ForegroundColor Yellow
    }
    
    Write-Host "`nTo view logs: docker logs $ImageName" -ForegroundColor Cyan
    Write-Host "To stop container: docker stop $ImageName" -ForegroundColor Cyan
} else {
    Write-Host "Container failed to start!" -ForegroundColor Red
    Write-Host "Container logs:" -ForegroundColor Red
    docker logs $ImageName
}

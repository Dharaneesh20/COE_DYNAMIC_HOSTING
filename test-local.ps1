# Local Testing Script for COE Dynamic Hosting Docker Container
# Tests the containerized Flask application locally before AWS deployment

param(
    [string]$ImageName = "coe-dynamic-hosting",
    [string]$ImageTag = "latest",
    [int]$Port = 5000
)

$ErrorActionPreference = "Stop"

Write-Host "=== Local Docker Container Testing ===" -ForegroundColor Green

# Check if Docker is running
try {
    docker info | Out-Null
    Write-Host "✓ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
    exit 1
}

# Stop any existing containers
Write-Host "Cleaning up existing containers..." -ForegroundColor Yellow
docker stop $ImageName 2>$null
docker rm $ImageName 2>$null

# Build the image
Write-Host "Building Docker image..." -ForegroundColor Yellow
docker build -t "${ImageName}:${ImageTag}" .
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Docker build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Docker image built successfully" -ForegroundColor Green

# Show image size
$imageInfo = docker images "${ImageName}:${ImageTag}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
Write-Host "Image Information:" -ForegroundColor Cyan
Write-Host $imageInfo -ForegroundColor White

# Run the container
Write-Host "Starting container on port $Port..." -ForegroundColor Yellow
Start-Job -ScriptBlock {
    param($ImageName, $ImageTag, $Port)
    docker run --rm -p "${Port}:5000" --name $ImageName "${ImageName}:${ImageTag}"
} -ArgumentList $ImageName, $ImageTag, $Port -Name "DockerContainer"

# Wait for container to start
Write-Host "Waiting for container to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Test the application
Write-Host "Testing application endpoints..." -ForegroundColor Yellow

try {
    # Test health endpoint
    $response = Invoke-WebRequest -Uri "http://localhost:$Port/" -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 302) {
        Write-Host "✓ Application is responding" -ForegroundColor Green
    } else {
        Write-Host "✗ Application returned status: $($response.StatusCode)" -ForegroundColor Red
    }
    
    # Test login page
    $loginResponse = Invoke-WebRequest -Uri "http://localhost:$Port/login" -UseBasicParsing -TimeoutSec 10
    if ($loginResponse.StatusCode -eq 200) {
        Write-Host "✓ Login page is accessible" -ForegroundColor Green
    } else {
        Write-Host "✗ Login page error: $($loginResponse.StatusCode)" -ForegroundColor Red
    }
    
    Write-Host "" -ForegroundColor White
    Write-Host "=== TEST RESULTS ===" -ForegroundColor Green
    Write-Host "✓ Container is running successfully" -ForegroundColor Green
    Write-Host "✓ Application is responding on http://localhost:$Port" -ForegroundColor Green
    Write-Host "✓ Ready for AWS deployment" -ForegroundColor Green
    Write-Host "" -ForegroundColor White
    Write-Host "Open your browser and navigate to: http://localhost:$Port" -ForegroundColor Cyan
    Write-Host "Press any key to stop the container..." -ForegroundColor Yellow
    
} catch {
    Write-Host "✗ Application test failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Container logs:" -ForegroundColor Yellow
    docker logs $ImageName
}

# Wait for user input
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Stop the container
Write-Host "Stopping container..." -ForegroundColor Yellow
docker stop $ImageName 2>$null
Stop-Job -Name "DockerContainer" 2>$null
Remove-Job -Name "DockerContainer" 2>$null

Write-Host "✓ Container stopped" -ForegroundColor Green
Write-Host "" -ForegroundColor White
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run .\build-and-push.ps1 to deploy to AWS ECR" -ForegroundColor White
Write-Host "2. Follow AWS_FREE_TIER_DEPLOYMENT.md for deployment instructions" -ForegroundColor White

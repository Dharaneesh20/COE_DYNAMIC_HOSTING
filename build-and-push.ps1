# AWS ECR Build and Push Script for COE Dynamic Hosting (PowerShell)
# Optimized for AWS Free Tier

param(
    [string]$AwsAccountId = "YOUR_AWS_ACCOUNT_ID",
    [string]$AwsRegion = "us-east-1",
    [string]$EcrRepository = "coe-dynamic-hosting",
    [string]$ImageTag = "latest"
)

$ErrorActionPreference = "Stop"

Write-Host "=== AWS Free Tier Docker Deployment Script ===" -ForegroundColor Green
Write-Host "Building and pushing Flask app optimized for AWS Free Tier" -ForegroundColor Green

# Check if AWS CLI is installed
try {
    aws --version | Out-Null
    Write-Host "✓ AWS CLI found" -ForegroundColor Green
} catch {
    Write-Host "✗ AWS CLI is not installed. Please install it first." -ForegroundColor Red
    Write-Host "Download from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

# Check if Docker is running
try {
    docker info | Out-Null
    Write-Host "✓ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker is not running. Please start Docker first." -ForegroundColor Red
    exit 1
}

# Verify AWS credentials
Write-Host "Verifying AWS credentials..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity | ConvertFrom-Json
    Write-Host "✓ AWS credentials verified for user: $($identity.Arn)" -ForegroundColor Green
    
    # Auto-detect account ID if not provided
    if ($AwsAccountId -eq "YOUR_AWS_ACCOUNT_ID") {
        $AwsAccountId = $identity.Account
        Write-Host "✓ Auto-detected AWS Account ID: $AwsAccountId" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ AWS credentials not configured. Please run 'aws configure'" -ForegroundColor Red
    exit 1
}

# Build the Docker image with optimizations
Write-Host "Building Docker image optimized for AWS Free Tier..." -ForegroundColor Yellow
docker build -t $EcrRepository`:$ImageTag .
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Docker build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Docker image built successfully" -ForegroundColor Green

# Show image size (important for free tier)
$imageSize = docker images $EcrRepository`:$ImageTag --format "table {{.Size}}" | Select-Object -Skip 1
Write-Host "✓ Image size: $imageSize" -ForegroundColor Cyan

# Login to ECR
Write-Host "Logging in to Amazon ECR..." -ForegroundColor Yellow
$loginToken = aws ecr get-login-password --region $AwsRegion
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to get ECR login token" -ForegroundColor Red
    exit 1
}

$loginToken | docker login --username AWS --password-stdin "$AwsAccountId.dkr.ecr.$AwsRegion.amazonaws.com"
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ ECR login failed" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Successfully logged in to ECR" -ForegroundColor Green

# Create ECR repository if it doesn't exist
Write-Host "Checking if ECR repository exists..." -ForegroundColor Yellow
try {
    aws ecr describe-repositories --repository-names $EcrRepository --region $AwsRegion | Out-Null
    Write-Host "✓ ECR repository exists" -ForegroundColor Green
} catch {
    Write-Host "Creating ECR repository..." -ForegroundColor Yellow
    aws ecr create-repository --repository-name $EcrRepository --region $AwsRegion --image-scanning-configuration scanOnPush=true
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ ECR repository created successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to create ECR repository" -ForegroundColor Red
        exit 1
    }
}

# Tag image for ECR
Write-Host "Tagging image for ECR..." -ForegroundColor Yellow
$EcrUri = "$AwsAccountId.dkr.ecr.$AwsRegion.amazonaws.com/${EcrRepository}:${ImageTag}"
docker tag "${EcrRepository}:${ImageTag}" $EcrUri
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Docker tag failed" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Image tagged successfully" -ForegroundColor Green

# Push image to ECR
Write-Host "Pushing image to ECR..." -ForegroundColor Yellow
docker push $EcrUri
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Docker push failed" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Image pushed successfully" -ForegroundColor Green

Write-Host "" -ForegroundColor White
Write-Host "=== DEPLOYMENT SUCCESSFUL ===" -ForegroundColor Green
Write-Host "Image URI: $EcrUri" -ForegroundColor Cyan
Write-Host "Image size: $imageSize" -ForegroundColor Cyan
Write-Host "" -ForegroundColor White
Write-Host "Next steps for AWS Free Tier deployment:" -ForegroundColor Yellow
Write-Host "1. Update your ECS task definition or Kubernetes deployment with this image URI" -ForegroundColor White
Write-Host "2. For AWS ECS: Use t3.micro instances (free tier eligible)" -ForegroundColor White
Write-Host "3. For AWS EKS: Use t3.small nodes (within free tier limits)" -ForegroundColor White
Write-Host "4. Set CPU/Memory limits: 0.25 vCPU, 512MB RAM" -ForegroundColor White


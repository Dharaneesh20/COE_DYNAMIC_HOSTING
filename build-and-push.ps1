# AWS ECR Build and Push Script for COE Dynamic Hosting (PowerShell)

param(
    [string]$AwsAccountId = "YOUR_AWS_ACCOUNT_ID",
    [string]$AwsRegion = "us-east-1",
    [string]$EcrRepository = "coe-dynamic-hosting",
    [string]$ImageTag = "latest"
)

$ErrorActionPreference = "Stop"

Write-Host "Starting build and push process..." -ForegroundColor Green

# Check if AWS CLI is installed
try {
    aws --version | Out-Null
} catch {
    Write-Host "AWS CLI is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

# Check if Docker is running
try {
    docker info | Out-Null
} catch {
    Write-Host "Docker is not running. Please start Docker first." -ForegroundColor Red
    exit 1
}

# Verify AWS credentials
Write-Host "Verifying AWS credentials..." -ForegroundColor Yellow
try {
    aws sts get-caller-identity | Out-Null
} catch {
    Write-Host "AWS credentials not configured. Please run 'aws configure'" -ForegroundColor Red
    exit 1
}

# Login to ECR
Write-Host "Logging in to Amazon ECR..." -ForegroundColor Yellow
$loginToken = aws ecr get-login-password --region $AwsRegion
$loginToken | docker login --username AWS --password-stdin "$AwsAccountId.dkr.ecr.$AwsRegion.amazonaws.com"

# Create ECR repository if it doesn't exist
Write-Host "Checking if ECR repository exists..." -ForegroundColor Yellow
try {
    aws ecr describe-repositories --repository-names $EcrRepository --region $AwsRegion | Out-Null
} catch {
    Write-Host "Creating ECR repository..." -ForegroundColor Yellow
    aws ecr create-repository --repository-name $EcrRepository --region $AwsRegion
}

# Build Docker image
Write-Host "Building Docker image..." -ForegroundColor Yellow
docker build -t "${EcrRepository}:${ImageTag}" .

# Tag image for ECR
$EcrUri = "$AwsAccountId.dkr.ecr.$AwsRegion.amazonaws.com/${EcrRepository}:${ImageTag}"
docker tag "${EcrRepository}:${ImageTag}" $EcrUri

# Push image to ECR
Write-Host "Pushing image to ECR..." -ForegroundColor Yellow
docker push $EcrUri

Write-Host "Build and push completed successfully!" -ForegroundColor Green
Write-Host "Image URI: $EcrUri" -ForegroundColor Green
Write-Host "Update your Kubernetes deployment.yaml with this image URI" -ForegroundColor Yellow

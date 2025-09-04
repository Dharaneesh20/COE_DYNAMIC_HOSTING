# Kubernetes Deployment Script for AWS EKS (PowerShell)

param(
    [string]$ClusterName = "coe-hosting-cluster",
    [string]$AwsRegion = "us-east-1",
    [string]$Namespace = "default"
)

$ErrorActionPreference = "Stop"

Write-Host "Starting Kubernetes deployment..." -ForegroundColor Green

# Check if kubectl is installed
try {
    kubectl version --client | Out-Null
} catch {
    Write-Host "kubectl is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

# Check if AWS CLI is installed
try {
    aws --version | Out-Null
} catch {
    Write-Host "AWS CLI is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

# Update kubeconfig for EKS cluster
Write-Host "Updating kubeconfig for EKS cluster..." -ForegroundColor Yellow
aws eks update-kubeconfig --region $AwsRegion --name $ClusterName

# Verify cluster connection
Write-Host "Verifying cluster connection..." -ForegroundColor Yellow
kubectl cluster-info

# Apply Kubernetes manifests
Write-Host "Applying Kubernetes manifests..." -ForegroundColor Yellow

# Apply in order
kubectl apply -f kubernetes/secrets.yaml
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/pvc.yaml
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml

# Wait for deployment to be ready
Write-Host "Waiting for deployment to be ready..." -ForegroundColor Yellow
kubectl rollout status deployment/coe-dynamic-hosting --timeout=300s

# Get service information
Write-Host "Deployment completed successfully!" -ForegroundColor Green
Write-Host "Getting service information..." -ForegroundColor Yellow
kubectl get services coe-dynamic-hosting-service

# Get pod status
Write-Host "Pod status:" -ForegroundColor Yellow
kubectl get pods -l app=coe-dynamic-hosting

Write-Host "Application deployed successfully!" -ForegroundColor Green
Write-Host "Note: It may take a few minutes for the LoadBalancer to be ready." -ForegroundColor Yellow


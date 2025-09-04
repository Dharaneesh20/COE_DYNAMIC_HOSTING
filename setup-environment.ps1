# Environment Setup Script for COE Dynamic Hosting

param(
    [string]$AwsAccountId,
    [string]$AwsRegion = "us-east-1",
    [string]$ClusterName = "coe-hosting-cluster"
)

$ErrorActionPreference = "Stop"

Write-Host "COE Dynamic Hosting - Environment Setup" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

# Validate parameters
if (-not $AwsAccountId) {
    Write-Host "Please provide your AWS Account ID:" -ForegroundColor Yellow
    $AwsAccountId = Read-Host
}

Write-Host "`nSetting up environment with:" -ForegroundColor Cyan
Write-Host "AWS Account ID: $AwsAccountId" -ForegroundColor White
Write-Host "AWS Region: $AwsRegion" -ForegroundColor White
Write-Host "Cluster Name: $ClusterName" -ForegroundColor White

# Update build script
Write-Host "`nUpdating build-and-push.ps1..." -ForegroundColor Yellow
$buildScript = Get-Content "build-and-push.ps1" -Raw
$buildScript = $buildScript -replace 'AWS_ACCOUNT_ID="YOUR_AWS_ACCOUNT_ID"', "AWS_ACCOUNT_ID=`"$AwsAccountId`""
$buildScript = $buildScript -replace 'AWS_REGION="us-east-1"', "AWS_REGION=`"$AwsRegion`""
$buildScript | Set-Content "build-and-push.ps1"

# Update deployment script
Write-Host "Updating deploy-k8s.ps1..." -ForegroundColor Yellow
$deployScript = Get-Content "deploy-k8s.ps1" -Raw
$deployScript = $deployScript -replace 'ClusterName = "coe-hosting-cluster"', "ClusterName = `"$ClusterName`""
$deployScript = $deployScript -replace 'AwsRegion = "us-east-1"', "AwsRegion = `"$AwsRegion`""
$deployScript | Set-Content "deploy-k8s.ps1"

# Generate secret key
Write-Host "Generating secure secret key..." -ForegroundColor Yellow
$secretKey = [System.Web.Security.Membership]::GeneratePassword(32, 0)
$secretKeyBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($secretKey))

# Update secrets.yaml
Write-Host "Updating kubernetes/secrets.yaml..." -ForegroundColor Yellow
$secretsContent = @"
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  # Auto-generated secure secret key
  secret-key: $secretKeyBase64
"@
$secretsContent | Set-Content "kubernetes/secrets.yaml"

# Update deployment.yaml with correct image
Write-Host "Updating kubernetes/deployment.yaml..." -ForegroundColor Yellow
$deploymentContent = Get-Content "kubernetes/deployment.yaml" -Raw
$deploymentContent = $deploymentContent -replace 'your-account-id.dkr.ecr.region.amazonaws.com', "$AwsAccountId.dkr.ecr.$AwsRegion.amazonaws.com"
$deploymentContent | Set-Content "kubernetes/deployment.yaml"

Write-Host "`nEnvironment setup completed successfully!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Ensure AWS CLI is configured: aws configure" -ForegroundColor White
Write-Host "2. Create EKS cluster: eksctl create cluster --name $ClusterName --region $AwsRegion ..." -ForegroundColor White
Write-Host "3. Build and push image: .\build-and-push.ps1" -ForegroundColor White
Write-Host "4. Deploy to Kubernetes: .\deploy-k8s.ps1" -ForegroundColor White
Write-Host "`nFor detailed instructions, see AWS_EKS_DEPLOYMENT_GUIDE.md" -ForegroundColor Yellow

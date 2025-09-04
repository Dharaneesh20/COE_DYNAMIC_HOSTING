#!/bin/bash

# AWS ECR Build and Push Script for COE Dynamic Hosting

set -e

# Configuration - Update these values
AWS_ACCOUNT_ID="YOUR_AWS_ACCOUNT_ID"
AWS_REGION="us-east-1"
ECR_REPOSITORY="coe-dynamic-hosting"
IMAGE_TAG="latest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting build and push process...${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Verify AWS credentials
echo -e "${YELLOW}Verifying AWS credentials...${NC}"
aws sts get-caller-identity > /dev/null || {
    echo -e "${RED}AWS credentials not configured. Please run 'aws configure'${NC}"
    exit 1
}

# Login to ECR
echo -e "${YELLOW}Logging in to Amazon ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Create ECR repository if it doesn't exist
echo -e "${YELLOW}Checking if ECR repository exists...${NC}"
aws ecr describe-repositories --repository-names $ECR_REPOSITORY --region $AWS_REGION &> /dev/null || {
    echo -e "${YELLOW}Creating ECR repository...${NC}"
    aws ecr create-repository --repository-name $ECR_REPOSITORY --region $AWS_REGION
}

# Build Docker image
echo -e "${YELLOW}Building Docker image...${NC}"
docker build -t $ECR_REPOSITORY:$IMAGE_TAG .

# Tag image for ECR
ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG"
docker tag $ECR_REPOSITORY:$IMAGE_TAG $ECR_URI

# Push image to ECR
echo -e "${YELLOW}Pushing image to ECR...${NC}"
docker push $ECR_URI

echo -e "${GREEN}Build and push completed successfully!${NC}"
echo -e "${GREEN}Image URI: $ECR_URI${NC}"
echo -e "${YELLOW}Update your Kubernetes deployment.yaml with this image URI${NC}"

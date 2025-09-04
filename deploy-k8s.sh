#!/bin/bash

# Kubernetes Deployment Script for AWS EKS

set -e

# Configuration
CLUSTER_NAME="coe-hosting-cluster"
AWS_REGION="us-east-1"
NAMESPACE="default"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Kubernetes deployment...${NC}"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Update kubeconfig for EKS cluster
echo -e "${YELLOW}Updating kubeconfig for EKS cluster...${NC}"
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

# Verify cluster connection
echo -e "${YELLOW}Verifying cluster connection...${NC}"
kubectl cluster-info

# Apply Kubernetes manifests
echo -e "${YELLOW}Applying Kubernetes manifests...${NC}"

# Apply in order
kubectl apply -f kubernetes/secrets.yaml
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/pvc.yaml
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml

# Wait for deployment to be ready
echo -e "${YELLOW}Waiting for deployment to be ready...${NC}"
kubectl rollout status deployment/coe-dynamic-hosting --timeout=300s

# Get service information
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${YELLOW}Getting service information...${NC}"
kubectl get services coe-dynamic-hosting-service

# Get pod status
echo -e "${YELLOW}Pod status:${NC}"
kubectl get pods -l app=coe-dynamic-hosting

echo -e "${GREEN}Application deployed successfully!${NC}"
echo -e "${YELLOW}Note: It may take a few minutes for the LoadBalancer to be ready.${NC}"

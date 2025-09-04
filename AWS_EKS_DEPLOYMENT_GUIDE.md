# AWS EKS Deployment Guide for COE Dynamic Hosting

This guide provides step-by-step instructions to deploy your Python Flask application to AWS using Docker and Kubernetes (EKS).

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
3. **Docker** installed and running
4. **kubectl** installed
5. **eksctl** installed (for EKS cluster creation)

## Step-by-Step Deployment Process

### Step 1: Install Required Tools

#### Install AWS CLI
```bash
# Windows (using PowerShell)
msiexec /i https://awscli.amazonaws.com/AWSCLIV2.msi

# Or using Chocolatey
choco install awscli
```

#### Install kubectl
```bash
# Windows (using PowerShell)
curl -LO https://dl.k8s.io/release/v1.28.0/bin/windows/amd64/kubectl.exe
# Move kubectl.exe to a directory in your PATH
```

#### Install eksctl
```bash
# Windows (using PowerShell)
choco install eksctl
```

#### Install Docker Desktop
Download and install from: https://www.docker.com/products/docker-desktop

### Step 2: Configure AWS Credentials

```bash
aws configure
```
Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., us-east-1)
- Default output format (json)

### Step 3: Create EKS Cluster

```bash
# Create EKS cluster (this takes 10-15 minutes)
eksctl create cluster \
  --name coe-hosting-cluster \
  --region us-east-1 \
  --nodegroup-name workers \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 4 \
  --managed
```

### Step 4: Build and Push Docker Image

#### Update Configuration
1. Edit `build-and-push.ps1` and replace:
   - `YOUR_AWS_ACCOUNT_ID` with your actual AWS account ID
   - Update region if different from `us-east-1`

#### Run Build Script
```powershell
# PowerShell
.\build-and-push.ps1
```

#### Update Kubernetes Deployment
1. Copy the Image URI from the build script output
2. Edit `kubernetes/deployment.yaml`
3. Replace `your-account-id.dkr.ecr.region.amazonaws.com/coe-dynamic-hosting:latest` with your actual Image URI

### Step 5: Generate Secret Key

```powershell
# Generate a secure secret key
$secretKey = [System.Web.Security.Membership]::GeneratePassword(32, 0)
$secretKeyBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($secretKey))
Write-Host "Secret Key (Base64): $secretKeyBase64"
```

Update `kubernetes/secrets.yaml` with the generated base64 secret key.

### Step 6: Deploy to Kubernetes

```powershell
# PowerShell
.\deploy-k8s.ps1
```

### Step 7: Access Your Application

1. **Get Load Balancer URL:**
```bash
kubectl get services coe-dynamic-hosting-service
```

2. **Wait for External IP:** It may take 5-10 minutes for AWS to provision the load balancer.

3. **Access Application:** Once you have the external IP/hostname, access your application at:
   ```
   http://<EXTERNAL-IP>
   ```

## Monitoring and Management

### Check Pod Status
```bash
kubectl get pods -l app=coe-dynamic-hosting
```

### View Pod Logs
```bash
kubectl logs -l app=coe-dynamic-hosting
```

### Scale Application
```bash
kubectl scale deployment coe-dynamic-hosting --replicas=5
```

### Update Application
1. Build and push new image with different tag
2. Update deployment.yaml with new image
3. Apply changes:
```bash
kubectl apply -f kubernetes/deployment.yaml
```

## Storage Considerations

- **Database:** Currently using SQLite with persistent volume
- **File Uploads:** Stored in persistent volume
- **For Production:** Consider migrating to:
  - Amazon RDS for database
  - Amazon S3 for file storage

## Security Best Practices

1. **Use IAM roles** instead of access keys where possible
2. **Enable network policies** for pod-to-pod communication
3. **Use secrets** for sensitive configuration
4. **Regular security updates** for base images
5. **Monitor with CloudWatch** and AWS CloudTrail

## Cost Optimization

1. **Use spot instances** for worker nodes
2. **Set up cluster autoscaling**
3. **Monitor resource usage** and adjust requests/limits
4. **Clean up unused resources**

## Cleanup

To avoid ongoing charges, delete resources when not needed:

```bash
# Delete Kubernetes resources
kubectl delete -f kubernetes/

# Delete EKS cluster
eksctl delete cluster --name coe-hosting-cluster --region us-east-1

# Delete ECR repository
aws ecr delete-repository --repository-name coe-dynamic-hosting --force
```

## Troubleshooting

### Common Issues

1. **Image Pull Errors:** Verify ECR permissions and image URI
2. **Pod Stuck in Pending:** Check resource requests and node capacity
3. **Service Not Accessible:** Verify security groups and load balancer settings
4. **Database Issues:** Check persistent volume mounting and permissions

### Useful Commands

```bash
# Describe pod for detailed information
kubectl describe pod <pod-name>

# Execute command in pod
kubectl exec -it <pod-name> -- /bin/bash

# View cluster events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## Next Steps

1. **Set up CI/CD pipeline** using GitHub Actions or AWS CodePipeline
2. **Implement monitoring** with Prometheus and Grafana
3. **Add SSL/TLS** using AWS Certificate Manager and Application Load Balancer
4. **Configure custom domain** using Route 53
5. **Implement backup strategy** for persistent data

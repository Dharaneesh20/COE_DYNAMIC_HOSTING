# AWS Free Tier Deployment Guide for COE Dynamic Hosting

This guide helps you deploy the Flask application to AWS using free tier eligible services.

## Prerequisites

1. **AWS Account** with free tier access
2. **AWS CLI** installed and configured
3. **Docker Desktop** installed and running
4. **PowerShell** (Windows) or **Bash** (Linux/Mac)

## Docker Container Overview

The application has been containerized with the following optimizations:

- **Base Image**: Python 3.11-slim (minimal size)
- **Production Server**: Gunicorn with 2 workers
- **Resource Limits**: 0.25 vCPU, 512MB RAM (free tier friendly)
- **Security**: Non-root user, minimal attack surface
- **Health Checks**: Built-in application health monitoring

## Deployment Options

### Option 1: AWS ECS Fargate (Recommended for Free Tier)

**Benefits**: 
- No server management
- Pay only for running time
- Free tier includes 20GB-hours per month

**Steps**:

1. **Build and Push to ECR**:
   ```powershell
   # Update account ID in the script
   .\build-and-push.ps1 -AwsAccountId YOUR_ACCOUNT_ID
   ```

2. **Create ECS Cluster**:
   ```bash
   aws ecs create-cluster --cluster-name coe-hosting-cluster
   ```

3. **Create Task Definition**:
   ```bash
   # Update account ID in aws-ecs-task-definition.json
   aws ecs register-task-definition --cli-input-json file://aws-ecs-task-definition.json
   ```

4. **Create ECS Service**:
   ```bash
   aws ecs create-service \
     --cluster coe-hosting-cluster \
     --service-name coe-hosting-service \
     --task-definition coe-dynamic-hosting \
     --desired-count 1 \
     --launch-type FARGATE \
     --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}"
   ```

### Option 2: AWS EC2 (t3.micro - Free Tier)

**Benefits**: 
- Full control over the environment
- 750 hours per month free
- Persistent storage

**Steps**:

1. **Launch EC2 Instance**:
   - Instance Type: t3.micro
   - AMI: Amazon Linux 2
   - Security Group: Allow HTTP (80), HTTPS (443), SSH (22)

2. **Install Docker**:
   ```bash
   sudo yum update -y
   sudo yum install -y docker
   sudo service docker start
   sudo usermod -a -G docker ec2-user
   ```

3. **Pull and Run Container**:
   ```bash
   # Pull from ECR (after building with build-and-push.ps1)
   docker pull YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/coe-dynamic-hosting:latest
   
   # Run with docker-compose
   docker-compose up -d
   ```

### Option 3: AWS Lightsail

**Benefits**: 
- Simple setup
- Predictable pricing
- Free tier: 3 months of $3.50/month plan

**Steps**:

1. **Create Lightsail Instance**:
   - Choose container service
   - Upload docker-compose.yml
   - Set environment variables

2. **Configure Domain**:
   - Use Lightsail DNS management
   - Set up SSL certificate

## Cost Optimization for Free Tier

### Resource Limits
```yaml
# In docker-compose.yml
deploy:
  resources:
    limits:
      cpus: '0.25'        # 25% of 1 vCPU
      memory: 512M        # 512MB RAM
    reservations:
      cpus: '0.125'       # 12.5% guaranteed
      memory: 256M        # 256MB guaranteed
```

### Auto-scaling Configuration
```bash
# ECS Auto Scaling (keep within free tier)
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/coe-hosting-cluster/coe-hosting-service \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 1 \
  --max-capacity 2
```

## Environment Variables

Required environment variables for production:

```bash
FLASK_ENV=production
SECRET_KEY=your-secret-key-here
DATABASE_PATH=/app/data/cloud_storage.db
UPLOAD_FOLDER=/app/uploads
```

## Security Considerations

1. **Secrets Management**: Use AWS Secrets Manager
2. **Network Security**: Configure VPC and Security Groups
3. **SSL/TLS**: Use AWS Application Load Balancer with ACM
4. **IAM Roles**: Least privilege principle

## Monitoring and Logging

### CloudWatch Integration
```bash
# Create log group
aws logs create-log-group --log-group-name /ecs/coe-dynamic-hosting

# Set retention policy (to manage costs)
aws logs put-retention-policy \
  --log-group-name /ecs/coe-dynamic-hosting \
  --retention-in-days 7
```

### Health Check Endpoint
The application includes a health check that:
- Verifies database connectivity
- Checks application responsiveness
- Returns HTTP 200 on success

## Backup Strategy

### Database Backup
```bash
# Create backup script for SQLite database
#!/bin/bash
BACKUP_DIR="/app/backups"
DATE=$(date +%Y%m%d_%H%M%S)
sqlite3 /app/data/cloud_storage.db ".backup $BACKUP_DIR/backup_$DATE.db"

# Upload to S3 (free tier: 5GB storage)
aws s3 cp "$BACKUP_DIR/backup_$DATE.db" s3://your-backup-bucket/
```

## Troubleshooting

### Common Issues

1. **Container Won't Start**:
   ```bash
   # Check logs
   docker logs container_name
   
   # Check disk space
   df -h
   ```

2. **Database Connection Issues**:
   ```bash
   # Verify volume mounts
   docker inspect container_name
   
   # Check permissions
   ls -la /app/data/
   ```

3. **Memory Issues**:
   ```bash
   # Monitor resource usage
   docker stats
   
   # Adjust limits in docker-compose.yml
   ```

## Cost Monitoring

Set up billing alerts:
```bash
aws budgets create-budget \
  --account-id YOUR_ACCOUNT_ID \
  --budget '{
    "BudgetName": "coe-hosting-budget",
    "BudgetLimit": {"Amount": "5", "Unit": "USD"},
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }'
```

## Next Steps

1. **Domain Setup**: Configure Route 53 or use a custom domain
2. **CDN**: Set up CloudFront for static assets
3. **Database**: Consider migrating to RDS PostgreSQL (free tier available)
4. **Scaling**: Implement horizontal pod autoscaling based on usage

## Support

For issues with this deployment:
1. Check the application logs
2. Verify AWS service limits
3. Monitor CloudWatch metrics
4. Review the troubleshooting section above

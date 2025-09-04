# COE Dynamic Hosting - Cloud Storage Application

A Flask-based cloud storage application with user authentication, file upload/download capabilities, and comprehensive deployment support for AWS EKS (Elastic Kubernetes Service).

## Features

- **User Authentication**: Secure registration and login system
- **File Management**: Upload, download, and manage files
- **Storage Limits**: Configurable storage quotas per user
- **Dashboard**: User-friendly interface for file management
- **Responsive Design**: Works on desktop and mobile devices
- **Production Ready**: Configured for containerized deployment

## Project Structure

```
COE_DYNAMIC_HOSTING/
├── app.py                     # Main Flask application
├── config.py                  # Configuration settings
├── requirements.txt           # Python dependencies
├── Dockerfile                 # Docker container configuration
├── .dockerignore             # Docker build exclusions
├── templates/                # HTML templates
│   ├── base.html
│   ├── dashboard.html
│   ├── login.html
│   ├── pricing.html
│   └── register.html
├── kubernetes/               # Kubernetes manifests
│   ├── deployment.yaml       # Application deployment
│   ├── service.yaml          # Load balancer service
│   ├── pvc.yaml              # Persistent volume claims
│   ├── secrets.yaml          # Application secrets
│   └── configmap.yaml        # Configuration map
├── build-and-push.ps1        # Docker build and ECR push script
├── deploy-k8s.ps1            # Kubernetes deployment script
├── test-local.ps1            # Local testing script
└── AWS_EKS_DEPLOYMENT_GUIDE.md # Deployment guide
```

## Quick Start

### Local Development

1. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

2. **Run Application**
   ```bash
   python app.py
   ```

3. **Access Application**
   - Open http://localhost:5000
   - Register a new account or login

### Docker Testing

1. **Test Locally with Docker**
   ```powershell
   .\test-local.ps1
   ```

2. **Access Application**
   - Open http://localhost:5000

## Production Deployment on AWS

### Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- Docker Desktop installed
- kubectl installed
- eksctl installed

### Quick Deployment

1. **Create EKS Cluster**
   ```bash
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

2. **Build and Push to ECR**
   ```powershell
   # Update AWS_ACCOUNT_ID in build-and-push.ps1
   .\build-and-push.ps1
   ```

3. **Deploy to Kubernetes**
   ```powershell
   # Update image URI in kubernetes/deployment.yaml
   .\deploy-k8s.ps1
   ```

For detailed instructions, see [AWS_EKS_DEPLOYMENT_GUIDE.md](AWS_EKS_DEPLOYMENT_GUIDE.md)

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `FLASK_ENV` | Environment (development/production) | development |
| `SECRET_KEY` | Flask secret key | Auto-generated |
| `DATABASE_PATH` | SQLite database path | cloud_storage.db |
| `UPLOAD_FOLDER` | File upload directory | uploads |
| `MAX_CONTENT_LENGTH` | Maximum file size | 16MB |

### Production Configuration

The application automatically uses production settings when `FLASK_ENV=production`:

- Debug mode disabled
- Secure session cookies
- HTTP-only cookies
- SameSite cookie protection

## Security Features

- Password hashing using Werkzeug
- Session-based authentication
- Secure file handling
- SQL injection protection
- XSS protection via template escaping
- CSRF protection ready

## Architecture

### Application Layer
- **Flask Web Framework**: Lightweight and flexible
- **SQLite Database**: Simple, serverless database
- **File Storage**: Local filesystem with persistent volumes

### Infrastructure Layer
- **Docker**: Containerized application
- **Kubernetes**: Container orchestration
- **AWS EKS**: Managed Kubernetes service
- **AWS ECR**: Container registry
- **AWS EBS**: Persistent storage

## Monitoring and Management

### Health Checks
- Kubernetes liveness and readiness probes
- Custom health check endpoint
- Container health monitoring

### Scaling
```bash
# Scale application pods
kubectl scale deployment coe-dynamic-hosting --replicas=5

# Auto-scaling (optional)
kubectl autoscale deployment coe-dynamic-hosting --cpu-percent=70 --min=2 --max=10
```

### Logging
```bash
# View application logs
kubectl logs -l app=coe-dynamic-hosting

# Follow logs
kubectl logs -f deployment/coe-dynamic-hosting
```

## Development

### Local Setup

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd COE_DYNAMIC_HOSTING
   ```

2. **Virtual Environment**
   ```bash
   python -m venv venv
   venv\Scripts\activate  # Windows
   pip install -r requirements.txt
   ```

3. **Database Initialization**
   ```bash
   python -c "from app import init_db; init_db()"
   ```

### Testing

```bash
# Run tests
python test_app.py

# Test Docker build
.\test-local.ps1
```

## Production Considerations

### Database Migration
For production, consider migrating from SQLite to:
- **Amazon RDS** (PostgreSQL/MySQL)
- **Amazon Aurora Serverless**

### File Storage Migration
Consider migrating from local storage to:
- **Amazon S3** for file storage
- **Amazon EFS** for shared filesystem

### Security Enhancements
- **SSL/TLS** with AWS Certificate Manager
- **WAF** (Web Application Firewall)
- **VPC** network isolation
- **IAM roles** instead of access keys

### Monitoring
- **CloudWatch** for application metrics
- **CloudTrail** for audit logging
- **X-Ray** for distributed tracing

## Cost Optimization

- Use **spot instances** for worker nodes
- Implement **cluster autoscaling**
- Set appropriate **resource requests/limits**
- Monitor usage with **AWS Cost Explorer**

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
1. Check the troubleshooting section in the deployment guide
2. Review Kubernetes events: `kubectl get events`
3. Check application logs: `kubectl logs -l app=coe-dynamic-hosting`
4. Open an issue in the repository

## Changelog

### v1.0.0
- Initial release
- Flask application with user authentication
- File upload/download functionality
- Docker containerization
- Kubernetes deployment manifests
- AWS EKS deployment guide

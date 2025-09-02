# AWS EC2 Cloud Storage Platform

A lightweight Flask-based cloud storage platform designed for AWS EC2 free tier deployment.

## Features

- **User Authentication**: Secure login and registration system
- **File Management**: Upload, download, and delete files
- **Storage Tracking**: Monitor storage usage with visual indicators
- **Responsive Design**: Mobile-friendly interface using Bootstrap
- **SQLite Database**: Lightweight database for user and file management
- **Security**: Password hashing and secure file handling

## Pages

1. **Login Page**: User authentication
2. **Register Page**: New user registration with free tier benefits
3. **Dashboard Page**: File management and account overview
4. **Pricing Page**: Plans and FAQ section

## Technical Specifications

- **Framework**: Flask (Python)
- **Database**: SQLite
- **Frontend**: Bootstrap 5 + Bootstrap Icons
- **File Storage**: Local filesystem
- **Authentication**: Werkzeug password hashing
- **File Size Limit**: 16MB per file
- **Storage Limit**: 100MB per user (free tier)

## AWS EC2 Free Tier Deployment

### Prerequisites

1. AWS Account with EC2 free tier access
2. EC2 instance (t2.micro recommended)
3. Security group allowing HTTP (port 80) and SSH (port 22)

### Deployment Steps

#### Step 1: Launch EC2 Instance

1. Go to AWS Console → EC2
2. Click "Launch Instance"
3. Choose Ubuntu Server 22.04 LTS (Free tier eligible)
4. Select t2.micro instance type
5. Create or select a key pair for SSH access
6. Configure security group:
   - SSH (22) from your IP
   - HTTP (80) from anywhere (0.0.0.0/0)
7. Launch instance

#### Step 2: Connect to Instance

```bash
# Replace with your key file and instance IP
ssh -i your-key.pem ubuntu@your-ec2-public-ip
```

#### Step 3: Upload Application Files

Option A - Using SCP:
```bash
# From your local machine
scp -i your-key.pem -r . ubuntu@your-ec2-public-ip:~/aws-cloud-storage/
```

Option B - Using Git:
```bash
# On EC2 instance
git clone your-repository-url
cd your-repository-name
```

#### Step 4: Run Deployment Script

```bash
# Make script executable
chmod +x deploy.sh

# Run deployment script
sudo ./deploy.sh
```

#### Step 5: Install Application

```bash
# Copy files to web directory
sudo cp -r * /var/www/aws-cloud-storage/
sudo chown -R awsapp:awsapp /var/www/aws-cloud-storage/

# Install Python dependencies
sudo -u awsapp /var/www/aws-cloud-storage/venv/bin/pip install -r /var/www/aws-cloud-storage/requirements.txt

# Create uploads directory
sudo -u awsapp mkdir -p /var/www/aws-cloud-storage/uploads

# Initialize database
sudo -u awsapp /var/www/aws-cloud-storage/venv/bin/python -c "
import sys
sys.path.append('/var/www/aws-cloud-storage')
from app import init_db
init_db()
print('Database initialized successfully!')
"
```

#### Step 6: Start Services

```bash
# Start the application
sudo systemctl start aws-cloud-storage
sudo systemctl start nginx

# Check status
sudo systemctl status aws-cloud-storage
sudo systemctl status nginx

# View logs if needed
sudo journalctl -u aws-cloud-storage -f
```

#### Step 7: Configure Firewall (if needed)

```bash
# Allow HTTP and SSH
sudo ufw allow 22
sudo ufw allow 80
sudo ufw enable
```

### Accessing Your Application

Your cloud storage platform will be available at:
`http://your-ec2-public-ip`

### Cost Optimization for Free Tier

1. **Instance Type**: Use t2.micro (free tier eligible)
2. **Storage**: Use only the free 30GB EBS storage
3. **Data Transfer**: Stay within 15GB/month limit
4. **Monitoring**: Use basic CloudWatch monitoring (free)

### Troubleshooting

#### Check Application Status
```bash
sudo systemctl status aws-cloud-storage
sudo journalctl -u aws-cloud-storage -n 20
```

#### Check Nginx Status
```bash
sudo systemctl status nginx
sudo nginx -t
```

#### Check Application Logs
```bash
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

#### Restart Services
```bash
sudo systemctl restart aws-cloud-storage
sudo systemctl restart nginx
```

## Security Considerations

1. **SSL/TLS**: Consider adding Let's Encrypt for HTTPS
2. **Firewall**: Configure UFW or AWS Security Groups properly
3. **Updates**: Regularly update system packages
4. **Backups**: Backup your database and uploaded files
5. **Monitoring**: Set up basic monitoring and alerts

## File Structure

```
aws-cloud-storage/
├── app.py              # Main Flask application
├── requirements.txt    # Python dependencies
├── deploy.sh          # Deployment script
├── README.md          # This file
└── templates/         # HTML templates
    ├── base.html      # Base template
    ├── login.html     # Login page
    ├── register.html  # Registration page
    ├── dashboard.html # Dashboard page
    └── pricing.html   # Pricing page
```

## Default Credentials

After deployment, you can create an account through the registration page. No default credentials are provided for security reasons.

## Scaling Considerations

For production use beyond free tier:
- Use RDS for database instead of SQLite
- Implement S3 for file storage
- Add Redis for session management
- Use Application Load Balancer
- Implement CloudFront for CDN

## Support

This application is designed for educational and testing purposes on AWS EC2 free tier. For production use, additional security and scalability measures should be implemented.

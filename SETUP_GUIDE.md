# AWS Cloud Storage - Quick Setup Guide

## Local Development Setup (Windows)

### Prerequisites
- Python 3.8 or higher
- Git (optional)

### Step 1: Setup Local Environment

```powershell
# Navigate to project directory
cd "c:\Users\Dharaneesh\Desktop\Dynamic Cloud Dev"

# Create virtual environment
python -m venv venv

# Activate virtual environment
.\venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### Step 2: Run the Application

```powershell
# Start the Flask application
python app.py
```

The application will be available at: http://localhost:5000

### Step 3: Test the Application

```powershell
# In another terminal, run the test script
python test_app.py
```

## AWS EC2 Deployment (Free Tier)

### Step 1: AWS Account Setup
1. Create AWS account (if not already have one)
2. Verify email and complete account setup
3. No credit card billing with free tier limits

### Step 2: Launch EC2 Instance
1. Go to AWS Console → EC2
2. Click "Launch Instance"
3. **Name**: aws-cloud-storage
4. **AMI**: Ubuntu Server 22.04 LTS (Free tier eligible)
5. **Instance Type**: t2.micro (Free tier eligible)
6. **Key Pair**: Create new or use existing
7. **Security Group**: 
   - SSH (22) from My IP
   - HTTP (80) from Anywhere
8. **Storage**: 8GB gp3 (Free tier: up to 30GB)
9. Click "Launch Instance"

### Step 3: Connect to EC2 Instance

#### Option A: EC2 Instance Connect (Browser-based)
1. Select your instance
2. Click "Connect"
3. Choose "EC2 Instance Connect"
4. Click "Connect"

#### Option B: SSH Client
```bash
# Download your key pair file (.pem)
# Change permissions (Linux/Mac)
chmod 400 your-key.pem

# Connect via SSH
ssh -i your-key.pem ubuntu@your-public-ip
```

### Step 4: Upload Application Files

#### Option A: Using Git (Recommended)
```bash
# On EC2 instance
sudo apt update
sudo apt install git -y
git clone https://github.com/your-username/aws-cloud-storage.git
cd aws-cloud-storage
```

#### Option B: Using SCP (from local machine)
```bash
# Upload files to EC2
scp -i your-key.pem -r . ubuntu@your-public-ip:~/aws-cloud-storage/
```

### Step 5: Deploy Application

```bash
# On EC2 instance, run the deployment script
chmod +x deploy.sh
sudo ./deploy.sh

# Copy application files
sudo cp -r * /var/www/aws-cloud-storage/
sudo chown -R awsapp:awsapp /var/www/aws-cloud-storage/

# Install dependencies
sudo -u awsapp /var/www/aws-cloud-storage/venv/bin/pip install -r /var/www/aws-cloud-storage/requirements.txt

# Create uploads directory
sudo -u awsapp mkdir -p /var/www/aws-cloud-storage/uploads

# Initialize database
cd /var/www/aws-cloud-storage
sudo -u awsapp /var/www/aws-cloud-storage/venv/bin/python -c "from app import init_db; init_db()"

# Start services
sudo systemctl start aws-cloud-storage
sudo systemctl start nginx

# Enable auto-start on reboot
sudo systemctl enable aws-cloud-storage
sudo systemctl enable nginx
```

### Step 6: Access Your Application

Your cloud storage platform will be available at:
`http://your-ec2-public-ip`

## Free Tier Limits to Watch

### EC2 Free Tier (12 months)
- **Compute**: 750 hours/month of t2.micro instances
- **Storage**: 30GB EBS General Purpose SSD
- **Data Transfer**: 15GB/month out to internet

### Staying Within Free Tier
1. **Use only t2.micro instances**
2. **Stop instances when not needed** (you're not charged for stopped instances)
3. **Monitor usage** via AWS Billing Dashboard
4. **Set up billing alerts** for $1 to get warnings

### Cost Optimization Tips
1. **Stop instance at night** if not needed 24/7
2. **Use AWS Free Tier Usage page** to monitor limits
3. **Delete unused resources** (snapshots, unused volumes)
4. **Use CloudWatch free tier** for basic monitoring

## Troubleshooting

### Application Not Starting
```bash
# Check application status
sudo systemctl status aws-cloud-storage

# View logs
sudo journalctl -u aws-cloud-storage -f

# Restart application
sudo systemctl restart aws-cloud-storage
```

### Nginx Issues
```bash
# Check nginx status
sudo systemctl status nginx

# Test nginx configuration
sudo nginx -t

# View nginx logs
sudo tail -f /var/log/nginx/error.log
```

### Database Issues
```bash
# Check if database file exists
ls -la /var/www/aws-cloud-storage/cloud_storage.db

# Recreate database
cd /var/www/aws-cloud-storage
sudo -u awsapp /var/www/aws-cloud-storage/venv/bin/python -c "from app import init_db; init_db()"
```

## Security Notes

1. **Change default Flask secret key** in production
2. **Use HTTPS** for production (Let's Encrypt is free)
3. **Keep system updated**: `sudo apt update && sudo apt upgrade`
4. **Monitor access logs** regularly
5. **Use strong passwords** for user accounts

## Next Steps

1. **Custom Domain**: Point your domain to EC2 public IP
2. **SSL Certificate**: Use Let's Encrypt for HTTPS
3. **Monitoring**: Set up CloudWatch alarms
4. **Backups**: Backup database and user files
5. **Scaling**: Upgrade to paid tier when needed

## Support

For issues or questions:
1. Check AWS documentation
2. Use AWS Support (free tier includes basic support)
3. Monitor AWS Free Tier usage regularly

Remember: The goal is to learn and experiment without incurring charges!

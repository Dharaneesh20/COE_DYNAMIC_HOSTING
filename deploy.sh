#!/bin/bash

# AWS EC2 Setup Script for Flask Cloud Storage App
# Run this script on your EC2 instance after connecting via SSH

echo "=== AWS Cloud Storage Deployment Script ==="
echo "Setting up Flask application on EC2..."

# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Python3 and pip
sudo apt install python3 python3-pip python3-venv nginx supervisor -y

# Create application directory
sudo mkdir -p /var/www/aws-cloud-storage
cd /var/www/aws-cloud-storage

# Create application user
sudo useradd -r -s /bin/false awsapp || true
sudo chown -R awsapp:awsapp /var/www/aws-cloud-storage

# Create Python virtual environment
sudo -u awsapp python3 -m venv venv
sudo -u awsapp /var/www/aws-cloud-storage/venv/bin/pip install --upgrade pip

# Note: You'll need to upload your application files here
echo "Upload your Flask application files to /var/www/aws-cloud-storage/"
echo "Then run: sudo -u awsapp /var/www/aws-cloud-storage/venv/bin/pip install -r requirements.txt"

# Create systemd service file
sudo tee /etc/systemd/system/aws-cloud-storage.service > /dev/null <<EOF
[Unit]
Description=AWS Cloud Storage Flask App
After=network.target

[Service]
User=awsapp
Group=awsapp
WorkingDirectory=/var/www/aws-cloud-storage
Environment="PATH=/var/www/aws-cloud-storage/venv/bin"
ExecStart=/var/www/aws-cloud-storage/venv/bin/python app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Configure Nginx
sudo tee /etc/nginx/sites-available/aws-cloud-storage > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        client_max_body_size 20M;
    }

    location /static {
        alias /var/www/aws-cloud-storage/static;
    }
}
EOF

# Enable Nginx site
sudo ln -sf /etc/nginx/sites-available/aws-cloud-storage /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Enable and start services
sudo systemctl daemon-reload
sudo systemctl enable aws-cloud-storage
sudo systemctl enable nginx

echo "Setup complete! Next steps:"
echo "1. Upload your Flask app files to /var/www/aws-cloud-storage/"
echo "2. Install Python dependencies: sudo -u awsapp /var/www/aws-cloud-storage/venv/bin/pip install -r requirements.txt"
echo "3. Start services: sudo systemctl start aws-cloud-storage nginx"
echo "4. Check status: sudo systemctl status aws-cloud-storage"

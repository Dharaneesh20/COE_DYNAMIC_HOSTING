# AWS Cloud Storage Platform - File List

This is a complete Flask-based cloud storage platform optimized for AWS EC2 free tier deployment.

## Project Structure

```
aws-cloud-storage/
├── app.py              # Main Flask application (8.2KB)
├── config.py           # Configuration settings (1.1KB)
├── requirements.txt    # Python dependencies (0.1KB)
├── deploy.sh          # AWS EC2 deployment script (3.2KB)
├── start.sh           # Local startup script (0.5KB)
├── test_app.py        # Application test script (4.1KB)
├── README.md          # Detailed documentation (8.9KB)
├── SETUP_GUIDE.md     # Quick setup guide (6.2KB)
├── static/            # Static files directory
└── templates/         # HTML templates (15.8KB total)
    ├── base.html      # Base template with navigation (3.8KB)
    ├── login.html     # Login page with features (2.9KB)
    ├── register.html  # Registration page (2.1KB)
    ├── dashboard.html # File management dashboard (4.2KB)
    └── pricing.html   # Pricing and FAQ page (2.8KB)
```

## Total Project Size: ~48KB (Very lightweight!)

## Key Features Implemented:

### 1. Authentication System
- User registration with email validation
- Secure password hashing using Werkzeug
- Session management
- Login/logout functionality

### 2. File Management
- File upload with size limits (16MB max)
- File download functionality
- File deletion with storage tracking
- Storage usage visualization

### 3. Database Integration
- SQLite database for lightweight deployment
- User management table
- File metadata tracking
- Automatic database initialization

### 4. Responsive UI
- Bootstrap 5 for modern, mobile-friendly design
- AWS-themed color scheme
- Interactive dashboard with progress bars
- File management interface

### 5. Security Features
- Secure filename handling
- Storage quotas (100MB free tier)
- Authentication required for protected routes
- Password security with hashing

### 6. AWS EC2 Optimization
- Minimal resource usage
- Production-ready deployment scripts
- Nginx reverse proxy configuration
- Systemd service configuration

## Deployment Instructions:

### Local Testing:
1. Run: `python -m venv venv`
2. Activate: `venv\Scripts\activate` (Windows) or `source venv/bin/activate` (Linux)
3. Install: `pip install -r requirements.txt`
4. Start: `python app.py`
5. Test: `python test_app.py`

### AWS EC2 Deployment:
1. Launch t2.micro Ubuntu instance (free tier)
2. Upload files via SCP or Git
3. Run: `chmod +x deploy.sh && sudo ./deploy.sh`
4. Copy files: `sudo cp -r * /var/www/aws-cloud-storage/`
5. Install deps: `sudo -u awsapp /var/www/aws-cloud-storage/venv/bin/pip install -r requirements.txt`
6. Start: `sudo systemctl start aws-cloud-storage nginx`

## Free Tier Compliance:
- Uses t2.micro instance (750 hours/month free)
- Lightweight codebase (~48KB)
- SQLite database (no additional DB costs)
- Optimized for minimal resource usage
- No external paid services required

## Pages Included:
1. **Login Page**: User authentication with features showcase
2. **Register Page**: Account creation with free tier benefits
3. **Dashboard**: File management, storage tracking, account info
4. **Pricing Page**: Plans comparison and FAQ section

Your AWS cloud storage platform is now ready for deployment! 🚀

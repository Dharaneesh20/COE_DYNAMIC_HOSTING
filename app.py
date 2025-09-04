from flask import Flask, render_template, request, redirect, url_for, session, flash, send_file
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
import sqlite3
import os
from datetime import datetime
import secrets
from config import ProductionConfig, DevelopmentConfig

app = Flask(__name__)

# Configure app based on environment
env = os.environ.get('FLASK_ENV', 'development')
if env == 'production':
    app.config.from_object(ProductionConfig)
else:
    app.config.from_object(DevelopmentConfig)

# Ensure upload directory exists
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

def init_db():
    """Initialize the database"""
    db_path = app.config['DATABASE_PATH']
    # Ensure database directory exists
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Users table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            storage_used INTEGER DEFAULT 0,
            storage_limit INTEGER DEFAULT 104857600
        )
    ''')
    
    # Files table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS files (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            filename TEXT NOT NULL,
            original_filename TEXT NOT NULL,
            file_size INTEGER NOT NULL,
            upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users (id)
        )
    ''')
    
    conn.commit()
    conn.close()

def get_db_connection():
    """Get database connection"""
    conn = sqlite3.connect(app.config['DATABASE_PATH'])
    conn.row_factory = sqlite3.Row
    return conn

@app.route('/')
def index():
    """Home page - redirect to login if not authenticated"""
    if 'user_id' in session:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    """Login page"""
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        conn = get_db_connection()
        user = conn.execute('SELECT * FROM users WHERE username = ?', (username,)).fetchone()
        conn.close()
        
        if user and check_password_hash(user['password_hash'], password):
            session['user_id'] = user['id']
            session['username'] = user['username']
            flash('Login successful!', 'success')
            return redirect(url_for('dashboard'))
        else:
            flash('Invalid username or password!', 'error')
    
    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    """Registration page"""
    if request.method == 'POST':
        username = request.form['username']
        email = request.form['email']
        password = request.form['password']
        confirm_password = request.form['confirm_password']
        
        if password != confirm_password:
            flash('Passwords do not match!', 'error')
            return render_template('register.html')
        
        conn = get_db_connection()
        
        # Check if user already exists
        existing_user = conn.execute(
            'SELECT id FROM users WHERE username = ? OR email = ?', 
            (username, email)
        ).fetchone()
        
        if existing_user:
            flash('Username or email already exists!', 'error')
            conn.close()
            return render_template('register.html')
        
        # Create new user
        password_hash = generate_password_hash(password)
        conn.execute(
            'INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)',
            (username, email, password_hash)
        )
        conn.commit()
        conn.close()
        
        flash('Registration successful! Please login.', 'success')
        return redirect(url_for('login'))
    
    return render_template('register.html')

@app.route('/dashboard')
def dashboard():
    """Dashboard page - requires authentication"""
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    conn = get_db_connection()
    
    # Get user info
    user = conn.execute('SELECT * FROM users WHERE id = ?', (session['user_id'],)).fetchone()
    
    # Get user files
    files = conn.execute(
        'SELECT * FROM files WHERE user_id = ? ORDER BY upload_date DESC',
        (session['user_id'],)
    ).fetchall()
    
    conn.close()
    
    # Calculate storage usage percentage
    storage_percentage = (user['storage_used'] / user['storage_limit']) * 100
    
    return render_template('dashboard.html', 
                         user=user, 
                         files=files, 
                         storage_percentage=storage_percentage)

@app.route('/upload', methods=['POST'])
def upload_file():
    """Handle file upload"""
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    if 'file' not in request.files:
        flash('No file selected!', 'error')
        return redirect(url_for('dashboard'))
    
    file = request.files['file']
    if file.filename == '':
        flash('No file selected!', 'error')
        return redirect(url_for('dashboard'))
    
    if file:
        conn = get_db_connection()
        user = conn.execute('SELECT * FROM users WHERE id = ?', (session['user_id'],)).fetchone()
        
        # Check storage limit
        file_size = len(file.read())
        file.seek(0)  # Reset file pointer
        
        if user['storage_used'] + file_size > user['storage_limit']:
            flash('Storage limit exceeded!', 'error')
            conn.close()
            return redirect(url_for('dashboard'))
        
        # Save file
        filename = secure_filename(file.filename)
        unique_filename = f"{session['user_id']}_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{filename}"
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], unique_filename)
        file.save(file_path)
        
        # Update database
        conn.execute(
            'INSERT INTO files (user_id, filename, original_filename, file_size) VALUES (?, ?, ?, ?)',
            (session['user_id'], unique_filename, filename, file_size)
        )
        
        conn.execute(
            'UPDATE users SET storage_used = storage_used + ? WHERE id = ?',
            (file_size, session['user_id'])
        )
        
        conn.commit()
        conn.close()
        
        flash('File uploaded successfully!', 'success')
    
    return redirect(url_for('dashboard'))

@app.route('/download/<int:file_id>')
def download_file(file_id):
    """Download a file"""
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    conn = get_db_connection()
    file_record = conn.execute(
        'SELECT * FROM files WHERE id = ? AND user_id = ?',
        (file_id, session['user_id'])
    ).fetchone()
    conn.close()
    
    if not file_record:
        flash('File not found!', 'error')
        return redirect(url_for('dashboard'))
    
    file_path = os.path.join(app.config['UPLOAD_FOLDER'], file_record['filename'])
    if os.path.exists(file_path):
        return send_file(file_path, as_attachment=True, download_name=file_record['original_filename'])
    else:
        flash('File not found on server!', 'error')
        return redirect(url_for('dashboard'))

@app.route('/delete/<int:file_id>')
def delete_file(file_id):
    """Delete a file"""
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    conn = get_db_connection()
    file_record = conn.execute(
        'SELECT * FROM files WHERE id = ? AND user_id = ?',
        (file_id, session['user_id'])
    ).fetchone()
    
    if file_record:
        # Delete from filesystem
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], file_record['filename'])
        if os.path.exists(file_path):
            os.remove(file_path)
        
        # Update database
        conn.execute('DELETE FROM files WHERE id = ?', (file_id,))
        conn.execute(
            'UPDATE users SET storage_used = storage_used - ? WHERE id = ?',
            (file_record['file_size'], session['user_id'])
        )
        conn.commit()
        flash('File deleted successfully!', 'success')
    else:
        flash('File not found!', 'error')
    
    conn.close()
    return redirect(url_for('dashboard'))

@app.route('/pricing')
def pricing():
    """Pricing page"""
    return render_template('pricing.html')

@app.route('/logout')
def logout():
    """Logout"""
    session.clear()
    flash('You have been logged out.', 'info')
    return redirect(url_for('login'))

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=False)

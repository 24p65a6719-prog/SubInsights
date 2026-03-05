# SubInsights - API Server Setup Guide

**Status**: Ready for Implementation  
**Frameworks Supported**: Flask, FastAPI  
**Database Ready**: PostgreSQL, MongoDB  
**Timeline**: 1-2 weeks to full deployment

---

## 📋 Overview

This guide provides step-by-step instructions to set up the SubInsights API server and connect it to a database. The backend code is complete and tested - this guide focuses on server setup and database integration.

---

## Prerequisites

### Required
- Python 3.8+
- pip (Python package manager)
- PostgreSQL 12+ (or MongoDB 4+)
- Git (for version control)

### Recommended
- Postman (for API testing)
- VS Code (IDE)
- Docker (for containerization)

---

## Part 1: Flask Server Setup (Recommended for Beginners)

### Step 1: Install Dependencies

```bash
# Navigate to project
cd c:\Subinsights

# Install Flask and extensions
pip install flask
pip install flask-cors
pip install flask-sqlalchemy
pip install python-dotenv
pip install psycopg2-binary
pip install requests
pip install sqlalchemy
```

### Step 2: Create Server File

Create `backend/server.py`:

```python
from flask import Flask, jsonify, request
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
import os
from datetime import datetime

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Configuration
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv(
    'DATABASE_URL',
    'postgresql://user:password@localhost:5432/subinsights'
)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JSON_SORT_KEYS'] = False

# Initialize database
db = SQLAlchemy(app)

# Import routes
from backend.api.auth_routes import auth_bp
from backend.api.subscription_routes import subscription_bp
from backend.api.hotel_routes import hotel_bp

# Register blueprints
app.register_blueprint(auth_bp, url_prefix='/api/auth')
app.register_blueprint(subscription_bp, url_prefix='/api/subscriptions')
app.register_blueprint(hotel_bp, url_prefix='/api/hotels')

# Health check endpoint
@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'service': 'SubInsights API'
    }), 200

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({'success': False, 'message': 'Endpoint not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'success': False, 'message': 'Internal server error'}), 500

# CORS headers
@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
    return response

if __name__ == '__main__':
    with app.app_context():
        # Create tables
        db.create_all()
    
    # Run development server
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=True  # Set to False in production
    )
```

### Step 3: Create Environment File

Create `.env` in project root:

```
# Flask Configuration
FLASK_APP=backend/server.py
FLASK_ENV=development
SECRET_KEY=your-secret-key-here-change-in-production

# Database Configuration
DATABASE_URL=postgresql://postgres:password@localhost:5432/subinsights
DB_USER=postgres
DB_PASSWORD=your_password
DB_HOST=localhost
DB_PORT=5432
DB_NAME=subinsights

# Email Configuration (for SMTP mode)
EMAIL_SMTP_SERVER=smtp.gmail.com
EMAIL_SMTP_PORT=587
EMAIL_SENDER=your-email@gmail.com
EMAIL_PASSWORD=your-app-password
EMAIL_DEMO_MODE=False  # Set to True for console logging

# Session Configuration
SESSION_TIMEOUT_MINUTES=60
JWT_SECRET_KEY=your-jwt-secret-key

# API Configuration
API_HOST=0.0.0.0
API_PORT=5000
API_DEBUG=True  # Set to False in production
```

### Step 4: Create Database Models

Create `backend/models/database.py`:

```python
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime, timedelta
import uuid
import hashlib

db = SQLAlchemy()

class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = db.Column(db.String(255), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(255), nullable=False)
    full_name = db.Column(db.String(255), nullable=False)
    phone = db.Column(db.String(20), nullable=True)
    is_verified = db.Column(db.Boolean, default=False)
    otp_code = db.Column(db.String(6), nullable=True)
    otp_expiry = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    subscriptions = db.relationship('UserSubscription', backref='user', lazy=True)
    sessions = db.relationship('Session', backref='user', lazy=True)
    
    def set_password(self, password):
        self.password_hash = hashlib.sha256(password.encode()).hexdigest()
    
    def check_password(self, password):
        return self.password_hash == hashlib.sha256(password.encode()).hexdigest()
    
    def to_dict(self):
        return {
            'user_id': self.id,
            'email': self.email,
            'full_name': self.full_name,
            'phone': self.phone,
            'is_verified': self.is_verified,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

class Subscription(db.Model):
    __tablename__ = 'subscriptions'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text, nullable=True)
    price = db.Column(db.Float, nullable=False)
    tier = db.Column(db.String(50), nullable=False)  # basic, premium, elite
    features = db.Column(db.JSON, nullable=False)  # JSON array
    benefits = db.Column(db.JSON, nullable=False)  # JSON array
    support_level = db.Column(db.String(50), nullable=False)
    renewable = db.Column(db.Boolean, default=True)
    renewal_period_days = db.Column(db.Integer, default=365)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    user_subscriptions = db.relationship('UserSubscription', backref='subscription', lazy=True)
    
    def to_dict(self):
        return {
            'subscription_id': self.id,
            'name': self.name,
            'description': self.description,
            'price': self.price,
            'tier': self.tier,
            'features': self.features,
            'benefits': self.benefits,
            'support_level': self.support_level,
            'renewable': self.renewable,
            'renewal_period_days': self.renewal_period_days
        }

class UserSubscription(db.Model):
    __tablename__ = 'user_subscriptions'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    subscription_id = db.Column(db.String(36), db.ForeignKey('subscriptions.id'), nullable=False)
    purchase_date = db.Column(db.DateTime, default=datetime.utcnow)
    valid_from = db.Column(db.DateTime, nullable=False)
    expires_at = db.Column(db.DateTime, nullable=False)
    amount = db.Column(db.Float, nullable=False)
    currency = db.Column(db.String(3), default='USD')
    status = db.Column(db.String(50), default='active')  # active, expired, cancelled
    auto_renew = db.Column(db.Boolean, default=True)
    geofence_enabled = db.Column(db.Boolean, default=False)
    geofence_locations = db.Column(db.JSON, nullable=True)  # JSON array of hotel names
    
    def to_dict(self):
        return {
            'purchase_id': self.id,
            'user_id': self.user_id,
            'subscription_id': self.subscription_id,
            'amount': self.amount,
            'currency': self.currency,
            'purchase_date': self.purchase_date.isoformat() if self.purchase_date else None,
            'valid_from': self.valid_from.isoformat() if self.valid_from else None,
            'expires_at': self.expires_at.isoformat() if self.expires_at else None,
            'status': self.status,
            'auto_renew': self.auto_renew,
            'geofence_enabled': self.geofence_enabled,
            'geofence_locations': self.geofence_locations
        }

class Hotel(db.Model):
    __tablename__ = 'hotels'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = db.Column(db.String(255), nullable=False)
    category = db.Column(db.String(50), nullable=False)  # hotel, restaurant, library
    latitude = db.Column(db.Float, nullable=False)
    longitude = db.Column(db.Float, nullable=False)
    address = db.Column(db.String(500), nullable=False)
    phone = db.Column(db.String(20), nullable=True)
    website = db.Column(db.String(500), nullable=True)
    rating = db.Column(db.Float, default=0.0)
    amenities = db.Column(db.JSON, nullable=False)
    subscription_benefits = db.Column(db.JSON, nullable=False)
    geofence_radius_km = db.Column(db.Float, default=0.5)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    reviews = db.relationship('Review', backref='hotel', lazy=True)
    
    def to_dict(self):
        return {
            'hotel_id': self.id,
            'name': self.name,
            'category': self.category,
            'latitude': self.latitude,
            'longitude': self.longitude,
            'address': self.address,
            'phone': self.phone,
            'website': self.website,
            'rating': self.rating,
            'review_count': len(self.reviews),
            'amenities': self.amenities,
            'subscription_benefits': self.subscription_benefits,
            'geofence_radius_km': self.geofence_radius_km
        }

class Review(db.Model):
    __tablename__ = 'reviews'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    hotel_id = db.Column(db.String(36), db.ForeignKey('hotels.id'), nullable=False)
    reviewer_name = db.Column(db.String(255), nullable=False)
    rating = db.Column(db.Float, nullable=False)  # 1-5 stars
    comment = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'review_id': self.id,
            'hotel_id': self.hotel_id,
            'reviewer_name': self.reviewer_name,
            'rating': self.rating,
            'comment': self.comment,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

class Session(db.Model):
    __tablename__ = 'sessions'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    expires_at = db.Column(db.DateTime, nullable=False)
    ip_address = db.Column(db.String(50), nullable=True)
    user_agent = db.Column(db.String(500), nullable=True)
    
    def is_valid(self):
        return datetime.utcnow() < self.expires_at
    
    def to_dict(self):
        return {
            'session_id': self.id,
            'user_id': self.user_id,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'expires_at': self.expires_at.isoformat() if self.expires_at else None,
            'is_valid': self.is_valid()
        }
```

### Step 5: Run the Server

```bash
# Set Flask app
set FLASK_APP=backend/server.py

# Run development server
python -m flask run

# Or use:
python backend/server.py

# Server will run on http://localhost:5000
```

**Expected Output**:
```
 * Running on http://127.0.0.1:5000
 * Restarting with reloader
 * Debugger is active!
 * Debugger PIN: 123-456-789
```

---

## Part 2: Database Setup (PostgreSQL)

### Step 1: Install PostgreSQL

**Windows**:
```bash
# Download from https://www.postgresql.org/download/windows/
# Run installer, choose default options
# Remember the password you set
```

### Step 2: Create Database

```bash
# Open PostgreSQL command prompt
# Or use psql in terminal

psql -U postgres

# Then in SQL:
CREATE DATABASE subinsights;
CREATE USER subinsights_user WITH PASSWORD 'secure_password_here';
ALTER ROLE subinsights_user SET client_encoding TO 'utf8';
ALTER ROLE subinsights_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE subinsights_user SET default_transaction_deferrable TO on;
ALTER ROLE subinsights_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE subinsights TO subinsights_user;
\q
```

### Step 3: Update .env File

```
DATABASE_URL=postgresql://subinsights_user:secure_password_here@localhost:5432/subinsights
```

### Step 4: Run Migrations

```bash
# Using Flask-Migrate (alternative setup)
pip install flask-migrate

flask db init
flask db migrate -m "Initial migration"
flask db upgrade
```

Or manually create tables by running the Flask app:
```bash
python backend/server.py
# This will create all tables automatically
```

---

## Part 3: Testing the API

### Test 1: Health Check

```bash
curl http://localhost:5000/api/health
```

**Expected Response**:
```json
{
  "status": "healthy",
  "timestamp": "2026-02-12T15:30:00.123456",
  "service": "SubInsights API"
}
```

### Test 2: Register User

```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "TestPass123!",
    "full_name": "Test User",
    "phone": "+1-555-0100"
  }'
```

### Test 3: Login

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "TestPass123!"
  }'
```

### Test 4: List Subscriptions

```bash
curl http://localhost:5000/api/subscriptions
```

### Using Postman (Recommended)

1. Download Postman: https://www.postman.com/
2. Import requests collection
3. Set variables: `base_url`, `session_id`
4. Run test suite

---

## Part 4: Connecting Frontend

### Update Frontend API Calls

In `frontend/auth/register.html` and other pages:

```javascript
// Old (demo mode)
// const response = await fetch('/api/auth/register', {

// New (with server)
const BASE_URL = 'http://localhost:5000';

const response = await fetch(`${BASE_URL}/api/auth/register`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  },
  body: JSON.stringify({
    email: userEmail,
    password: userPassword,
    full_name: userName,
    phone: userPhone
  })
});

const data = await response.json();
if (data.success) {
  localStorage.setItem('sessionId', data.session_id);
  // ... continue flow
}
```

### CORS Configuration

Server already has CORS enabled, but if needed:

```python
from flask_cors import CORS

CORS(app, resources={
    r"/api/*": {
        "origins": ["http://localhost:3000", "http://localhost:8000"],
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"]
    }
})
```

---

## Part 5: Deployment

### Docker Setup

Create `Dockerfile`:

```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV FLASK_APP=backend/server.py
ENV FLASK_ENV=production

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "backend.server:app"]
```

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  web:
    build: .
    ports:
      - "5000:5000"
    environment:
      - DATABASE_URL=postgresql://subinsights_user:password@db:5432/subinsights
      - FLASK_ENV=production
    depends_on:
      - db
    volumes:
      - .:/app

  db:
    image: postgres:13
    environment:
      POSTGRES_USER: subinsights_user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: subinsights
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

volumes:
  postgres_data:
```

Run with Docker:
```bash
docker-compose up
```

---

## Part 6: Production Checklist

### Before Going Live

- [ ] Change `FLASK_ENV=production`
- [ ] Set strong `SECRET_KEY` in .env
- [ ] Disable Flask debug mode
- [ ] Configure real SMTP email server
- [ ] Set up SSL/HTTPS certificates
- [ ] Enable rate limiting
- [ ] Set up logging
- [ ] Configure database backups
- [ ] Test all API endpoints
- [ ] Performance test load
- [ ] Set up monitoring
- [ ] Configure CI/CD pipeline

### Security Hardening

```python
# In server.py, add:

from werkzeug.security import generate_password_hash, check_password_hash
from flask_talisman import Talisman
from flask_limiter import Limiter

# Enable security headers
Talisman(app, 
    force_https=True,
    strict_transport_security=True,
    content_security_policy={
        'default-src': "'self'"
    }
)

# Enable rate limiting
limiter = Limiter(app, key_func=lambda: request.remote_addr)

@app.route('/api/auth/login', methods=['POST'])
@limiter.limit("5 per minute")
def login():
    # ...
    pass
```

---

## Troubleshooting

### Issue: "Module not found"
```bash
pip install -r requirements.txt
```

### Issue: "Database connection refused"
```bash
# Check PostgreSQL is running
# Verify DATABASE_URL in .env
# Check password is correct
```

### Issue: CORS errors in browser
```python
# Ensure CORS is enabled in server.py
CORS(app)
```

### Issue: Port 5000 already in use
```bash
# Change port in server.py
app.run(port=5001)

# Or kill process using port 5000
netstat -ano | findstr :5000
taskkill /PID <PID> /F
```

---

## Next Steps

After API server is running:

1. ✅ Frontend connects to backend API
2. ✅ Database persists all data
3. ✅ Email SMTP configured for production
4. ✅ Real location services integrated
5. ✅ Payment gateway connected
6. ✅ Admin dashboard built
7. ✅ Mobile app developed
8. ✅ Deploy to production (AWS, Azure, Heroku)

---

## Useful Commands

```bash
# Check Python version
python --version

# List installed packages
pip list

# Install requirements
pip install -r requirements.txt

# Run Flask in development
flask run

# Run Flask with custom host/port
flask run --host=0.0.0.0 --port=8000

# Debug mode
export FLASK_APP=backend/server.py
export FLASK_ENV=development
flask run

# Create requirements file
pip freeze > requirements.txt

# PostgreSQL commands
psql -U postgres
\l  # List databases
\d  # Describe tables
\q  # Quit

# Docker commands
docker-compose up
docker-compose down
docker-compose logs -f
```

---

## Resources

- Flask Documentation: https://flask.palletsprojects.com/
- SQLAlchemy: https://docs.sqlalchemy.org/
- PostgreSQL: https://www.postgresql.org/docs/
- Flask-CORS: https://flask-cors.readthedocs.io/
- Postman API Testing: https://www.postman.com/

---

## Summary

You now have everything needed to:

1. ✅ Set up a Flask API server
2. ✅ Configure PostgreSQL database
3. ✅ Create all database models
4. ✅ Connect frontend to backend
5. ✅ Test all endpoints
6. ✅ Deploy to production

**Estimated time to completion**: 1-2 weeks full setup including testing and deployment.

---

*API Server Setup Guide v1.0*  
*Status: Ready for Implementation*  
*Last Updated: February 12, 2026*


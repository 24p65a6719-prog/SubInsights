from flask import Flask, jsonify, request, send_from_directory, render_template_string
from flask_cors import CORS
import os
import sys
from datetime import datetime, timedelta
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Get the base directory
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRONTEND_DIR = os.path.join(BASE_DIR, 'frontend')

# Initialize Flask app with static folder configuration
app = Flask(__name__, static_folder=FRONTEND_DIR, static_url_path='')
CORS(app)

# Import backend modules - create fresh instances using loaded .env credentials
try:
    from backend.auth.email_service import EmailService
    from backend.auth.user_manager import UserManager
    from backend.subscriptions.subscription_manager import subscription_manager
    from backend.hotels.hotel_manager import hotel_manager

    # Build a fresh EmailService using credentials loaded from .env
    _sender_email = os.environ.get('SENDER_EMAIL')
    _sender_password = os.environ.get('SENDER_PASSWORD')
    _smtp_server = os.environ.get('SMTP_SERVER', 'smtp.gmail.com')
    _smtp_port = int(os.environ.get('SMTP_PORT', 587))
    _demo_mode = os.environ.get('DEMO_MODE', 'true').lower() == 'true'

    if _sender_email and _sender_password and not _demo_mode:
        email_service = EmailService(
            smtp_server=_smtp_server,
            smtp_port=_smtp_port,
            sender_email=_sender_email,
            sender_password=_sender_password,
            demo_mode=False
        )
        print(f"[Server] Email service initialized: REAL MODE ({_sender_email})")
    else:
        email_service = EmailService(demo_mode=True)
        print("[Server] Email service initialized: DEMO MODE")

    user_manager = UserManager(email_service=email_service, demo_mode=False)

except ImportError as e:
    print(f"Warning: {e}")

# Configure app
app.config['JSON_SORT_KEYS'] = False

# ==================== AUTHENTICATION ROUTES ====================

@app.route('/api/auth/register', methods=['POST'])
def register():
    """Register new user"""
    try:
        data = request.get_json()
        
        if not data or not all(k in data for k in ('email', 'password', 'full_name')):
            return jsonify({'success': False, 'message': 'Missing required fields'}), 400
        
        success, msg, user = user_manager.register_user(
            email=data['email'],
            password=data['password'],
            full_name=data['full_name'],
            phone=data.get('phone', '')
        )
        
        if success:
            response = {
                'success': True,
                'message': msg,
                'user_id': user.id,
                'email': user.email,
                'otp_valid_until': (datetime.utcnow() + timedelta(minutes=15)).isoformat()
            }
            
            # In demo mode, return OTP code for testing purposes
            if email_service.demo_mode:
                response['demo_otp'] = user.otp_code
                response['message'] = f"Registration successful! OTP: {user.otp_code} (Demo Mode - Check this OTP or server logs)"
            
            return jsonify(response), 201
        else:
            return jsonify({'success': False, 'message': msg}), 400
    except Exception as e:
        print(f"Error in register: {str(e)}")
        return jsonify({'success': False, 'message': f'Server error: {str(e)}'}), 500

@app.route('/api/auth/verify-otp', methods=['POST'])
def verify_otp():
    """Verify OTP code"""
    try:
        data = request.get_json()
        
        if not data or 'email' not in data or 'otp_code' not in data:
            return jsonify({'success': False, 'message': 'Missing email or OTP code'}), 400
        
        success, msg = user_manager.verify_otp(data['email'], data['otp_code'])
        
        if success:
            return jsonify({
                'success': True,
                'message': msg,
                'status': 'verified'
            }), 200
        else:
            return jsonify({'success': False, 'message': msg}), 400
    except Exception as e:
        print(f"Error in verify_otp: {str(e)}")
        return jsonify({'success': False, 'message': f'Server error: {str(e)}'}), 500

@app.route('/api/auth/resend-otp', methods=['POST'])
def resend_otp():
    """Resend OTP code"""
    try:
        data = request.get_json()
        
        if not data or 'email' not in data:
            return jsonify({'success': False, 'message': 'Missing email'}), 400
        
        user = user_manager.get_user_by_email(data['email'])
        if not user:
            return jsonify({'success': False, 'message': 'User not found'}), 404
        
        otp = user.generate_otp()
        email_service.send_otp_email(user.email, otp, user.full_name)
        
        response = {
            'success': True,
            'message': 'OTP sent to your email. Check your inbox.',
            'email': user.email,
            'otp_valid_until': (datetime.utcnow() + timedelta(minutes=15)).isoformat()
        }
        
        # In demo mode, return OTP code for testing purposes
        if email_service.demo_mode:
            response['demo_otp'] = otp
            response['message'] = f"New OTP: {otp} (Demo Mode - Check this OTP or server logs)"
        
        return jsonify(response), 200
    except Exception as e:
        print(f"Error in resend_otp: {str(e)}")
        return jsonify({'success': False, 'message': f'Server error: {str(e)}'}), 500

@app.route('/api/debug/email-logs', methods=['GET'])
def get_email_logs():
    """Get email logs (demo mode only) - for debugging"""
    if not email_service.demo_mode:
        return jsonify({'success': False, 'message': 'Not available in production mode'}), 403
    
    logs = email_service.get_email_log()
    stats = email_service.get_email_stats()
    
    return jsonify({
        'success': True,
        'demo_mode': True,
        'email_logs': logs,
        'email_stats': stats
    }), 200

@app.route('/api/auth/login', methods=['POST'])
def login():
    """User login - verifies password then sends OTP"""
    data = request.get_json()
    
    if not data or 'email' not in data or 'password' not in data:
        return jsonify({'success': False, 'message': 'Missing email or password'}), 400
    
    email = data['email'].strip().lower()
    password = data['password']

    user = user_manager.get_user_by_email(email)

    if not user:
        return jsonify({'success': False, 'message': 'User not found. Please register first.'}), 404

    if not user.is_verified:
        return jsonify({'success': False, 'message': 'Please verify your email first before logging in.'}), 403

    if not user.verify_password(password):
        return jsonify({'success': False, 'message': 'Invalid password. Please try again.'}), 401

    # Password is correct — generate and send login OTP
    otp_code = user.generate_otp()
    success_email, email_msg = email_service.send_otp_email(email, otp_code, user.full_name)
    print(f"[Login OTP] Sent to {email}: {email_msg}")

    response = {
        'success': True,
        'message': f'Password verified! A login OTP has been sent to {email}. Please check your inbox.',
        'email': email,
        'otp_valid_until': (datetime.utcnow() + timedelta(minutes=15)).isoformat()
    }
    if email_service.demo_mode:
        response['demo_otp'] = otp_code

    return jsonify(response), 200


@app.route('/api/auth/verify-login-otp', methods=['POST'])
def verify_login_otp():
    """Verify the login OTP and create session"""
    data = request.get_json()

    if not data or 'email' not in data or 'otp_code' not in data:
        return jsonify({'success': False, 'message': 'Missing email or OTP code'}), 400

    email = data['email'].strip().lower()
    otp_code = data['otp_code'].strip()

    user = user_manager.get_user_by_email(email)
    if not user:
        return jsonify({'success': False, 'message': 'User not found.'}), 404

    is_valid, msg = user.verify_otp(otp_code)
    if is_valid:
        session_id = user_manager._create_session(user.id)
        return jsonify({
            'success': True,
            'message': 'Login successful! Welcome back.',
            'session_id': session_id,
            'user_id': user.id,
            'email': user.email,
            'full_name': user.full_name
        }), 200
    else:
        return jsonify({'success': False, 'message': msg}), 400


@app.route('/api/auth/logout', methods=['POST'])
def logout():
    """User logout"""
    data = request.get_json()
    session_id = data.get('session_id') if data else None
    
    if session_id and session_id in user_manager.sessions:
        del user_manager.sessions[session_id]
    
    return jsonify({
        'success': True,
        'message': 'Logged out successfully'
    }), 200

@app.route('/api/auth/change-password', methods=['POST'])
def change_password():
    """Change user password"""
    data = request.get_json()
    session_id = request.headers.get('Authorization', '').replace('Bearer ', '')
    
    if not session_id or session_id not in user_manager.sessions:
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    user_id = user_manager.sessions[session_id]['user_id']
    user = user_manager.get_user_by_id(user_id)
    
    if not user:
        return jsonify({'success': False, 'message': 'User not found'}), 404
    
    if not user.check_password(data.get('old_password', '')):
        return jsonify({'success': False, 'message': 'Old password is incorrect'}), 400
    
    user.set_password(data.get('new_password', ''))
    return jsonify({
        'success': True,
        'message': 'Password changed successfully'
    }), 200

@app.route('/api/auth/profile', methods=['GET'])
def get_profile():
    """Get user profile"""
    session_id = request.headers.get('Authorization', '').replace('Bearer ', '')
    
    if not session_id or session_id not in user_manager.sessions:
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    user_id = user_manager.sessions[session_id]['user_id']
    user = user_manager.get_user_by_id(user_id)
    
    if not user:
        return jsonify({'success': False, 'message': 'User not found'}), 404
    
    return jsonify({
        'success': True,
        'user': {
            'user_id': user.id,
            'email': user.email,
            'full_name': user.full_name,
            'phone': user.phone,
            'is_verified': user.is_verified,
            'created_at': user.created_at.isoformat() if hasattr(user, 'created_at') else None
        }
    }), 200

@app.route('/api/auth/profile', methods=['PUT'])
def update_profile():
    """Update user profile"""
    data = request.get_json()
    session_id = request.headers.get('Authorization', '').replace('Bearer ', '')
    
    if not session_id or session_id not in user_manager.sessions:
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    user_id = user_manager.sessions[session_id]['user_id']
    user = user_manager.get_user_by_id(user_id)
    
    if not user:
        return jsonify({'success': False, 'message': 'User not found'}), 404
    
    if 'full_name' in data:
        user.full_name = data['full_name']
    if 'phone' in data:
        user.phone = data['phone']
    
    return jsonify({
        'success': True,
        'message': 'Profile updated successfully',
        'user': {
            'full_name': user.full_name,
            'phone': user.phone
        }
    }), 200

@app.route('/api/auth/validate-session', methods=['POST'])
def validate_session():
    """Validate session"""
    data = request.get_json()
    session_id = data.get('session_id') if data else None
    
    if session_id and session_id in user_manager.sessions:
        user_id = user_manager.sessions[session_id]['user_id']
        return jsonify({
            'success': True,
            'is_valid': True,
            'user_id': user_id,
            'expires_at': (datetime.utcnow()).isoformat()
        }), 200
    else:
        return jsonify({
            'success': False,
            'is_valid': False,
            'message': 'Session expired or invalid'
        }), 401

# ==================== SUBSCRIPTION ROUTES ====================

@app.route('/api/subscriptions', methods=['GET'])
def get_subscriptions():
    """Get all subscriptions"""
    tier = request.args.get('tier')
    
    subs = list(subscription_manager.subscriptions.values())
    
    if tier:
        subs = [s for s in subs if s.tier == tier]
    
    return jsonify({
        'success': True,
        'subscriptions': [
            {
                'subscription_id': s.id,
                'name': s.name,
                'price': s.price,
                'tier': s.tier.value if hasattr(s.tier, 'value') else str(s.tier),
                'description': getattr(s, 'description', ''),
                'icon': getattr(s, 'icon', '🎯'),
                'color': getattr(s, 'color', '#667eea'),
                'logo': getattr(s, 'logo', ''),
                'features': s.features,
                'benefits': [
                    {
                        'name': b.name,
                        'discount_percentage': getattr(b, 'discount_percentage', 0),
                        'description': getattr(b, 'description', '')
                    } for b in s.benefits
                ]
            } for s in subs
        ],
        'total': len(subs)
    }), 200

@app.route('/api/subscriptions/<subscription_id>', methods=['GET'])
def get_subscription(subscription_id):
    """Get subscription details"""
    sub = subscription_manager.subscriptions.get(subscription_id)
    
    if not sub:
        return jsonify({'success': False, 'message': 'Subscription not found'}), 404
    
    return jsonify({
        'success': True,
        'subscription': {
            'subscription_id': sub.subscription_id,
            'name': sub.name,
            'description': sub.description,
            'price': sub.price,
            'tier': sub.tier,
            'features': sub.features,
            'benefits': [
                {
                    'name': b.name,
                    'discount_percentage': b.discount_percentage,
                    'description': b.description
                } for b in sub.benefits
            ]
        }
    }), 200

@app.route('/api/subscriptions/purchase', methods=['POST'])
def purchase_subscription():
    """Purchase subscription"""
    data = request.get_json()
    session_id = request.headers.get('Authorization', '').replace('Bearer ', '')
    
    if not session_id or session_id not in user_manager.sessions:
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    user_id = user_manager.sessions[session_id]['user_id']
    sub_id = data.get('subscription_id') if data else None
    
    success, msg, purchase = subscription_manager.purchase_subscription(user_id, sub_id)
    
    if success:
        return jsonify({
            'success': True,
            'message': msg,
            'purchase': {
                'purchase_id': purchase.purchase_id,
                'subscription_name': purchase.subscription_id,
                'amount': purchase.amount,
                'purchase_date': purchase.purchase_date.isoformat() if hasattr(purchase, 'purchase_date') else None
            }
        }), 201
    else:
        return jsonify({'success': False, 'message': msg}), 400

# ==================== HOTEL ROUTES ====================

@app.route('/api/hotels', methods=['GET'])
def get_hotels():
    """Get all hotels"""
    hotels = list(hotel_manager.hotels.values())
    
    return jsonify({
        'success': True,
        'hotels': [
            {
                'hotel_id': h.hotel_id,
                'name': h.name,
                'category': h.category,
                'latitude': h.latitude,
                'longitude': h.longitude,
                'address': h.address,
                'rating': h.rating,
                'review_count': len(h.reviews) if hasattr(h, 'reviews') else 0
            } for h in hotels
        ],
        'total': len(hotels)
    }), 200

@app.route('/api/hotels/<hotel_id>', methods=['GET'])
def get_hotel(hotel_id):
    """Get hotel details"""
    hotel = hotel_manager.hotels.get(hotel_id)
    
    if not hotel:
        return jsonify({'success': False, 'message': 'Hotel not found'}), 404
    
    return jsonify({
        'success': True,
        'hotel': {
            'hotel_id': hotel.hotel_id,
            'name': hotel.name,
            'category': hotel.category,
            'latitude': hotel.latitude,
            'longitude': hotel.longitude,
            'address': hotel.address,
            'phone': hotel.phone,
            'website': hotel.website,
            'rating': hotel.rating,
            'amenities': hotel.amenities if hasattr(hotel, 'amenities') else []
        }
    }), 200

@app.route('/api/hotels/nearby', methods=['GET'])
def get_nearby_hotels():
    """Get nearby hotels"""
    lat = request.args.get('latitude', type=float)
    lng = request.args.get('longitude', type=float)
    radius = request.args.get('radius_km', 10, type=float)
    
    if lat is None or lng is None:
        return jsonify({'success': False, 'message': 'Missing latitude or longitude'}), 400
    
    nearby = hotel_manager.get_nearby_hotels(lat, lng, radius)
    
    return jsonify({
        'success': True,
        'user_location': {'latitude': lat, 'longitude': lng},
        'nearby_hotels': [
            {
                'hotel_id': h.hotel_id,
                'name': h.name,
                'distance_km': hotel_manager.calculate_distance(lat, lng, h.latitude, h.longitude),
                'rating': h.rating,
                'address': h.address
            } for h in nearby
        ],
        'total_found': len(nearby)
    }), 200

# ==================== HEALTH CHECK ====================

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'service': 'SubInsights API',
        'version': '2.0'
    }), 200

# ==================== ERROR HANDLERS ====================

@app.errorhandler(404)
def not_found(error):
    return jsonify({'success': False, 'message': 'Endpoint not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'success': False, 'message': 'Internal server error'}), 500

# ==================== CORS ====================

@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
    return response

# ==================== STATIC FILE SERVING ====================

@app.route('/')
def serve_index():
    """Serve login-register.html as default entry point"""
    return send_from_directory(FRONTEND_DIR, 'login-register.html')

@app.route('/<path:filename>')
def serve_static(filename):
    """Serve static files"""
    # Don't serve API routes as static files
    if filename.startswith('api/'):
        return jsonify({'error': 'API endpoint not found'}), 404
    
    # Try to find the file
    filepath = os.path.join(FRONTEND_DIR, filename)
    
    # If it's a directory, try to serve index.html from that directory
    if os.path.isdir(filepath):
        index_path = os.path.join(filepath, 'index.html')
        if os.path.exists(index_path):
            return send_from_directory(FRONTEND_DIR, filename + '/index.html')
    
    # Otherwise serve the file if it exists
    if os.path.exists(filepath):
        return send_from_directory(FRONTEND_DIR, filename)
    
    # If not found, return 404
    return jsonify({'error': 'File not found'}), 404

if __name__ == '__main__':
    print("""
    ================================================================================
                        SubInsights API Server v2.0
    ================================================================================
    
    Starting server...
    """)

    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('FLASK_ENV', 'production') == 'development'

    app.run(
        host='0.0.0.0',
        port=port,
        debug=debug,
        use_reloader=False
    )

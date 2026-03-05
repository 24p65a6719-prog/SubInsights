"""
Authentication API Routes
Handles user registration, verification, and login endpoints
"""
from typing import Dict, Tuple
from datetime import datetime
import json


class AuthAPIRouter:
    """
    Authentication API routes
    
    Endpoints:
    - POST /api/auth/register - Register new user
    - POST /api/auth/verify-otp - Verify OTP
    - POST /api/auth/resend-otp - Resend OTP
    - POST /api/auth/login - Login user
    - POST /api/auth/logout - Logout user
    - POST /api/auth/change-password - Change password
    - GET /api/auth/profile - Get user profile
    - PUT /api/auth/profile - Update profile
    """
    
    def __init__(self, user_manager, email_service):
        """
        Initialize auth router
        
        Args:
            user_manager: UserManager instance
            email_service: EmailService instance
        """
        self.user_manager = user_manager
        self.email_service = email_service
        self.routes = {}
        self._register_routes()
    
    def _register_routes(self):
        """Register all authentication endpoints"""
        self.routes["POST /api/auth/register"] = self.register
        self.routes["POST /api/auth/verify-otp"] = self.verify_otp
        self.routes["POST /api/auth/resend-otp"] = self.resend_otp
        self.routes["POST /api/auth/login"] = self.login
        self.routes["POST /api/auth/logout"] = self.logout
        self.routes["POST /api/auth/change-password"] = self.change_password
        self.routes["GET /api/auth/profile"] = self.get_profile
        self.routes["PUT /api/auth/profile"] = self.update_profile
        self.routes["POST /api/auth/validate-session"] = self.validate_session
    
    def register(self, request_data: Dict) -> Tuple[Dict, int]:
        """
        Register new user
        
        Request body:
        {
            "email": "user@example.com",
            "password": "password123",
            "full_name": "John Doe",
            "phone": "+1234567890" (optional)
        }
        
        Returns:
            (response, status_code)
        """
        try:
            email = request_data.get('email', '').strip()
            password = request_data.get('password', '').strip()
            full_name = request_data.get('full_name', '').strip()
            phone = request_data.get('phone', '').strip()
            
            # Validate required fields
            if not email or not password or not full_name:
                return {
                    "success": False,
                    "message": "Email, password, and full name are required"
                }, 400
            
            # Register user
            success, message, user = self.user_manager.register_user(
                email=email,
                password=password,
                full_name=full_name,
                phone=phone if phone else None
            )
            
            if success:
                return {
                    "success": True,
                    "message": message,
                    "user_id": user.id,
                    "email": user.email
                }, 201
            else:
                return {
                    "success": False,
                    "message": message
                }, 409
        
        except Exception as e:
            return {
                "success": False,
                "message": f"Registration error: {str(e)}"
            }, 500
    
    def verify_otp(self, request_data: Dict) -> Tuple[Dict, int]:
        """
        Verify OTP and complete email verification
        
        Request body:
        {
            "email": "user@example.com",
            "otp_code": "123456"
        }
        
        Returns:
            (response, status_code)
        """
        try:
            email = request_data.get('email', '').strip()
            otp_code = request_data.get('otp_code', '').strip()
            
            if not email or not otp_code:
                return {
                    "success": False,
                    "message": "Email and OTP code are required"
                }, 400
            
            success, message = self.user_manager.verify_otp(email, otp_code)
            
            if success:
                # Get session token created by verify_otp
                user = self.user_manager.get_user_by_email(email)
                # Create a new session for the verified user
                session_id = self.user_manager._create_session(user.id)
                
                return {
                    "success": True,
                    "message": message,
                    "session_id": session_id,
                    "user_id": user.id
                }, 200
            else:
                return {
                    "success": False,
                    "message": message
                }, 400
        
        except Exception as e:
            return {
                "success": False,
                "message": f"Verification error: {str(e)}"
            }, 500
    
    def resend_otp(self, request_data: Dict) -> Tuple[Dict, int]:
        """
        Resend OTP to email
        
        Request body:
        {
            "email": "user@example.com"
        }
        
        Returns:
            (response, status_code)
        """
        try:
            email = request_data.get('email', '').strip()
            
            if not email:
                return {
                    "success": False,
                    "message": "Email is required"
                }, 400
            
            success, message = self.user_manager.resend_otp(email)
            
            return {
                "success": success,
                "message": message
            }, 200 if success else 400
        
        except Exception as e:
            return {
                "success": False,
                "message": f"Resend error: {str(e)}"
            }, 500
    
    def login(self, request_data: Dict) -> Tuple[Dict, int]:
        """
        Login user with email and password
        
        Request body:
        {
            "email": "user@example.com",
            "password": "password123"
        }
        
        Returns:
            (response, status_code)
        """
        try:
            email = request_data.get('email', '').strip()
            password = request_data.get('password', '').strip()
            
            if not email or not password:
                return {
                    "success": False,
                    "message": "Email and password are required"
                }, 400
            
            success, message, session_id = self.user_manager.login(email, password)
            
            if success:
                user = self.user_manager.get_user_by_email(email)
                return {
                    "success": True,
                    "message": message,
                    "session_id": session_id,
                    "user_id": user.id,
                    "email": user.email,
                    "full_name": user.full_name
                }, 200
            else:
                return {
                    "success": False,
                    "message": message
                }, 401
        
        except Exception as e:
            return {
                "success": False,
                "message": f"Login error: {str(e)}"
            }, 500
    
    def logout(self, request_data: Dict, session_id: str = None) -> Tuple[Dict, int]:
        """
        Logout user
        
        Request header:
        X-Session-ID: <session_id>
        
        Returns:
            (response, status_code)
        """
        try:
            if not session_id:
                return {
                    "success": False,
                    "message": "Session ID required"
                }, 400
            
            success, message = self.user_manager.logout(session_id)
            
            return {
                "success": success,
                "message": message
            }, 200 if success else 400
        
        except Exception as e:
            return {
                "success": False,
                "message": f"Logout error: {str(e)}"
            }, 500
    
    def change_password(self, request_data: Dict, session_id: str = None) -> Tuple[Dict, int]:
        """
        Change user password
        
        Request header:
        X-Session-ID: <session_id>
        
        Request body:
        {
            "old_password": "currentpass123",
            "new_password": "newpass456"
        }
        
        Returns:
            (response, status_code)
        """
        try:
            if not session_id:
                return {
                    "success": False,
                    "message": "Session ID required"
                }, 401
            
            # Validate session
            is_valid, user_id = self.user_manager.validate_session(session_id)
            if not is_valid:
                return {
                    "success": False,
                    "message": "Invalid or expired session"
                }, 401
            
            old_password = request_data.get('old_password', '').strip()
            new_password = request_data.get('new_password', '').strip()
            
            if not old_password or not new_password:
                return {
                    "success": False,
                    "message": "Old and new passwords required"
                }, 400
            
            success, message = self.user_manager.change_password(
                user_id, old_password, new_password
            )
            
            return {
                "success": success,
                "message": message
            }, 200 if success else 400
        
        except Exception as e:
            return {
                "success": False,
                "message": f"Password change error: {str(e)}"
            }, 500
    
    def get_profile(self, session_id: str = None) -> Tuple[Dict, int]:
        """
        Get user profile
        
        Request header:
        X-Session-ID: <session_id>
        
        Returns:
            (response, status_code)
        """
        try:
            if not session_id:
                return {
                    "success": False,
                    "message": "Session ID required"
                }, 401
            
            # Validate session
            user = self.user_manager.get_user_by_session(session_id)
            if not user:
                return {
                    "success": False,
                    "message": "Invalid or expired session"
                }, 401
            
            return {
                "success": True,
                "user": user.get_profile()
            }, 200
        
        except Exception as e:
            return {
                "success": False,
                "message": f"Profile retrieval error: {str(e)}"
            }, 500
    
    def update_profile(self, request_data: Dict, session_id: str = None) -> Tuple[Dict, int]:
        """
        Update user profile
        
        Request header:
        X-Session-ID: <session_id>
        
        Request body:
        {
            "full_name": "Jane Doe" (optional),
            "phone": "+1234567890" (optional)
        }
        
        Returns:
            (response, status_code)
        """
        try:
            if not session_id:
                return {
                    "success": False,
                    "message": "Session ID required"
                }, 401
            
            # Validate session
            is_valid, user_id = self.user_manager.validate_session(session_id)
            if not is_valid:
                return {
                    "success": False,
                    "message": "Invalid or expired session"
                }, 401
            
            full_name = request_data.get('full_name', '').strip()
            phone = request_data.get('phone', '').strip()
            
            success, message = self.user_manager.update_user_profile(
                user_id,
                full_name=full_name if full_name else None,
                phone=phone if phone else None
            )
            
            if success:
                user = self.user_manager.get_user(user_id)
                return {
                    "success": True,
                    "message": message,
                    "user": user.get_profile()
                }, 200
            else:
                return {
                    "success": False,
                    "message": message
                }, 400
        
        except Exception as e:
            return {
                "success": False,
                "message": f"Profile update error: {str(e)}"
            }, 500
    
    def validate_session(self, request_data: Dict = None, session_id: str = None) -> Tuple[Dict, int]:
        """
        Validate session (for frontend use)
        
        Request header:
        X-Session-ID: <session_id>
        
        Returns:
            (response, status_code)
        """
        try:
            if not session_id:
                return {
                    "success": False,
                    "is_valid": False,
                    "message": "Session ID required"
                }, 401
            
            is_valid, user_id = self.user_manager.validate_session(session_id)
            
            if is_valid:
                user = self.user_manager.get_user(user_id)
                return {
                    "success": True,
                    "is_valid": True,
                    "user_id": user_id,
                    "email": user.email,
                    "full_name": user.full_name
                }, 200
            else:
                return {
                    "success": False,
                    "is_valid": False,
                    "message": "Invalid or expired session"
                }, 401
        
        except Exception as e:
            return {
                "success": False,
                "is_valid": False,
                "message": f"Session validation error: {str(e)}"
            }, 500

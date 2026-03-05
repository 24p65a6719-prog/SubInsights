"""
User Manager Module
Handles user registration, authentication, and session management
"""
from typing import Dict, Optional, Tuple, List
from datetime import datetime, timedelta
import uuid
from backend.auth.user import User
from backend.auth.email_service import EmailService


class UserManager:
    """
    Manages user authentication lifecycle:
    - Registration with email/password
    - OTP generation and verification
    - Login and session management
    - User database operations
    """
    
    def __init__(self, email_service: EmailService = None, demo_mode: bool = True):
        """
        Initialize user manager
        
        Args:
            email_service: EmailService instance for sending OTPs
            demo_mode: If True, use in-memory storage; if False, use database
        """
        self.email_service = email_service or EmailService(demo_mode=demo_mode)
        self.users: Dict[str, User] = {}  # id -> User
        self.users_by_email: Dict[str, User] = {}  # email -> User
        self.sessions: Dict[str, Tuple[str, datetime]] = {}  # session_id -> (user_id, expiry)
        self.demo_mode = demo_mode
    
    def register_user(self, email: str, password: str, full_name: str, phone: str = None) -> Tuple[bool, str, Optional[User]]:
        """
        Register new user
        
        Args:
            email: User's email address
            password: User's password (will be hashed)
            full_name: User's full name
            phone: Optional phone number
        
        Returns:
            (success, message, user) - user is None if failed
        """
        # Check if email already registered
        if email.lower() in self.users_by_email:
            # Allow re-registration for testing purposes by deleting the old user
            old_user = self.users_by_email[email.lower()]
            if old_user.id in self.users:
                del self.users[old_user.id]
            del self.users_by_email[email.lower()]
        
        # Validate email format
        try:
            User.is_valid_email(email)
        except:
            return False, "Invalid email format.", None
        
        # Validate password strength
        if len(password) < 6:
            return False, "Password must be at least 6 characters.", None
        
        # Create new user
        user_id = str(uuid.uuid4())[:8]
        password_hash = User.hash_password(password)
        
        user = User(
            id=user_id,
            email=email.lower(),
            password_hash=password_hash,
            full_name=full_name,
            phone=phone
        )
        
        # Store user
        self.users[user_id] = user
        self.users_by_email[email.lower()] = user
        
        # Generate and send OTP
        otp_code = user.generate_otp()
        success, msg = self.email_service.send_otp_email(email, otp_code, full_name)
        
        return True, f"Registration successful! OTP sent to {email}", user
    
    def verify_otp(self, email: str, otp_code: str) -> Tuple[bool, str]:
        """
        Verify OTP for email verification
        
        Args:
            email: User's email address
            otp_code: OTP code to verify
        
        Returns:
            (success, message)
        """
        user = self.users_by_email.get(email.lower())
        
        if not user:
            return False, "User not found."
        
        is_valid, message = user.verify_otp(otp_code)
        
        if is_valid:
            # Create session for verified user
            session_id = self._create_session(user.id)
            return True, f"Email verified successfully! Session created: {session_id}"
        
        return False, message
    
    def resend_otp(self, email: str) -> Tuple[bool, str]:
        """
        Resend OTP to email
        
        Args:
            email: User's email address
        
        Returns:
            (success, message)
        """
        user = self.users_by_email.get(email.lower())
        
        if not user:
            return False, "User not found."
        
        if user.is_verified:
            return False, "User already verified."
        
        otp_code = user.generate_otp()
        success, msg = self.email_service.send_otp_email(email, otp_code, user.full_name)
        
        return True, f"New OTP sent to {email}"
    
    def login(self, email: str, password: str) -> Tuple[bool, str, Optional[str]]:
        """
        Login user with email and password
        
        Args:
            email: User's email address
            password: User's password
        
        Returns:
            (success, message, session_id) - session_id is None if failed
        """
        user = self.users_by_email.get(email.lower())
        
        if not user:
            return False, "User not found.", None
        
        if not user.is_verified:
            return False, "Email not verified. Please verify your email first.", None
        
        if not user.verify_password(password):
            return False, "Invalid password.", None
        
        # Create session
        session_id = self._create_session(user.id)
        
        return True, "Login successful!", session_id
    
    def logout(self, session_id: str) -> Tuple[bool, str]:
        """
        Logout user by destroying session
        
        Args:
            session_id: Session ID to destroy
        
        Returns:
            (success, message)
        """
        if session_id in self.sessions:
            del self.sessions[session_id]
            return True, "Logged out successfully."
        
        return False, "Invalid session ID."
    
    def validate_session(self, session_id: str) -> Tuple[bool, Optional[str]]:
        """
        Validate session and return user_id if valid
        
        Args:
            session_id: Session ID to validate
        
        Returns:
            (is_valid, user_id) - user_id is None if invalid
        """
        if session_id not in self.sessions:
            return False, None
        
        user_id, expiry = self.sessions[session_id]
        
        # Check if session expired
        if datetime.now() > expiry:
            del self.sessions[session_id]
            return False, None
        
        # Extend session by 1 hour
        self.sessions[session_id] = (user_id, datetime.now() + timedelta(hours=1))
        
        return True, user_id
    
    def get_user(self, user_id: str) -> Optional[User]:
        """Get user by ID"""
        return self.users.get(user_id)
    
    def get_user_by_email(self, email: str) -> Optional[User]:
        """Get user by email"""
        return self.users_by_email.get(email.lower())
    
    def get_user_by_session(self, session_id: str) -> Optional[User]:
        """Get user from valid session"""
        is_valid, user_id = self.validate_session(session_id)
        
        if is_valid and user_id:
            return self.users.get(user_id)
        
        return None
    
    def update_user_profile(self, user_id: str, full_name: str = None, phone: str = None) -> Tuple[bool, str]:
        """
        Update user profile information
        
        Args:
            user_id: User ID to update
            full_name: New full name (optional)
            phone: New phone (optional)
        
        Returns:
            (success, message)
        """
        user = self.users.get(user_id)
        
        if not user:
            return False, "User not found."
        
        if full_name:
            user.full_name = full_name
        
        if phone:
            user.phone = phone
        
        return True, "Profile updated successfully."
    
    def change_password(self, user_id: str, old_password: str, new_password: str) -> Tuple[bool, str]:
        """
        Change user password
        
        Args:
            user_id: User ID
            old_password: Current password
            new_password: New password
        
        Returns:
            (success, message)
        """
        user = self.users.get(user_id)
        
        if not user:
            return False, "User not found."
        
        if not user.verify_password(old_password):
            return False, "Current password is incorrect."
        
        if len(new_password) < 6:
            return False, "New password must be at least 6 characters."
        
        user.password_hash = User.hash_password(new_password)
        return True, "Password changed successfully."
    
    def get_all_users(self) -> List[User]:
        """Get all registered users (for admin/testing)"""
        return list(self.users.values())
    
    def get_statistics(self) -> Dict:
        """Get user management statistics"""
        verified_count = sum(1 for u in self.users.values() if u.is_verified)
        unverified_count = len(self.users) - verified_count
        
        return {
            "total_users": len(self.users),
            "verified_users": verified_count,
            "unverified_users": unverified_count,
            "active_sessions": len(self.sessions),
            "email_stats": self.email_service.get_email_stats()
        }
    
    def _create_session(self, user_id: str) -> str:
        """
        Create new session for user
        
        Args:
            user_id: User ID for session
        
        Returns:
            session_id: New session ID
        """
        session_id = str(uuid.uuid4())
        expiry = datetime.now() + timedelta(hours=1)  # Sessions expire in 1 hour
        self.sessions[session_id] = (user_id, expiry)
        return session_id
    
    def demo_setup(self):
        """
        Setup demo data for testing
        
        Creates a few demo users for testing the authentication flow
        """
        # Demo user 1: Already verified
        demo_user_1 = User(
            id="demo001",
            email="john@example.com",
            password_hash=User.hash_password("password123"),
            full_name="John Doe",
            phone="+1234567890"
        )
        demo_user_1.is_verified = True
        self.users["demo001"] = demo_user_1
        self.users_by_email["john@example.com"] = demo_user_1
        
        # Demo user 2: Needs OTP verification
        demo_user_2 = User(
            id="demo002",
            email="jane@example.com",
            password_hash=User.hash_password("secure456"),
            full_name="Jane Smith",
            phone="+1234567891"
        )
        demo_user_2.generate_otp()  # Generate OTP for testing
        self.users["demo002"] = demo_user_2
        self.users_by_email["jane@example.com"] = demo_user_2
        
        print("[AuthSystem] Demo users loaded:")
        print(f"  - John Doe (john@example.com) - VERIFIED ✓")
        print(f"  - Jane Smith (jane@example.com) - Waiting for OTP verification")

# Create singleton instance
user_manager = UserManager(demo_mode=True)
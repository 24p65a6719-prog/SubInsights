"""
User Authentication Module
Handles user registration, email verification (OTP), and login
"""
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Optional, Dict
import hashlib
import secrets
import re


@dataclass
class User:
    """
    User account model with authentication details
    
    Attributes:
        id: Unique user identifier
        email: User's email address
        password_hash: Hashed password (never store plain text)
        full_name: User's full name
        is_verified: Whether email is verified via OTP
        phone: Optional phone for notifications
        created_at: Account creation timestamp
        otp_code: Current OTP for verification
        otp_expiry: When OTP expires
        otp_attempts: Failed OTP attempts (to prevent brute force)
    """
    id: str
    email: str
    password_hash: str
    full_name: str
    is_verified: bool = False
    phone: Optional[str] = None
    created_at: datetime = field(default_factory=datetime.now)
    otp_code: Optional[str] = None
    otp_expiry: Optional[datetime] = None
    otp_attempts: int = 0
    
    def __post_init__(self):
        """Validate email format"""
        if not self.is_valid_email(self.email):
            raise ValueError(f"Invalid email format: {self.email}")
    
    @staticmethod
    def is_valid_email(email: str) -> bool:
        """Validate email format"""
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return re.match(pattern, email) is not None
    
    @staticmethod
    def hash_password(password: str) -> str:
        """Hash password using SHA-256"""
        return hashlib.sha256(password.encode()).hexdigest()
    
    def verify_password(self, password: str) -> bool:
        """Check if password matches hash"""
        return self.password_hash == self.hash_password(password)
    
    def generate_otp(self) -> str:
        """Generate 6-digit OTP and set expiry (15 minutes)"""
        self.otp_code = ''.join([str(secrets.randbelow(10)) for _ in range(6)])
        self.otp_expiry = datetime.now() + timedelta(minutes=15)
        self.otp_attempts = 0
        return self.otp_code
    
    def verify_otp(self, code: str) -> tuple[bool, str]:
        """
        Verify OTP code
        
        Returns:
            (is_valid, message)
        """
        if not self.otp_code:
            return False, "No OTP generated"
        
        if datetime.now() > self.otp_expiry:
            return False, "OTP expired. Request new OTP."
        
        if self.otp_attempts >= 3:
            return False, "Too many failed attempts. Request new OTP."
        
        if code != self.otp_code:
            self.otp_attempts += 1
            return False, f"Invalid OTP. {3 - self.otp_attempts} attempts remaining."
        
        self.is_verified = True
        return True, "Email verified successfully"
    
    def get_profile(self) -> Dict:
        """Get public user profile (without sensitive data)"""
        return {
            "id": self.id,
            "email": self.email,
            "full_name": self.full_name,
            "is_verified": self.is_verified,
            "phone": self.phone,
            "created_at": self.created_at.isoformat()
        }

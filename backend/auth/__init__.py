"""
Authentication Module
Provides user registration, email verification, and login functionality
"""

from backend.auth.user import User
from backend.auth.email_service import EmailService
from backend.auth.user_manager import UserManager

__all__ = [
    'User',
    'EmailService',
    'UserManager',
]

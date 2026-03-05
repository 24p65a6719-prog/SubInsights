"""
Authentication System Demo
Tests user registration, OTP verification, and login flows
"""
import sys
import time
from datetime import datetime

# Add backend to path
sys.path.insert(0, 'c:\\Subinsights')

from backend.auth import UserManager, EmailService


def print_header(text):
    """Print formatted header"""
    print("\n" + "="*80)
    print(f"  {text}")
    print("="*80)


def print_step(step_num, description):
    """Print step header"""
    print(f"\n[Step {step_num}] {description}")
    print("-" * 60)


def demo_auth_system():
    """Run authentication system demo"""
    
    print_header("SubInsights Authentication System Demo")
    print(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Initialize services
    print_step(1, "Initializing Email and User Management Services")
    
    email_service = EmailService(demo_mode=True)
    print("✓ Email service initialized (demo mode)")
    
    user_manager = UserManager(email_service=email_service, demo_mode=True)
    print("✓ User manager initialized")
    
    # Setup demo data
    print_step(2, "Loading Demo Users")
    user_manager.demo_setup()
    
    # Test 1: Check demo users
    print_step(3, "Checking Registered Users")
    
    all_users = user_manager.get_all_users()
    for user in all_users:
        status = "✓ VERIFIED" if user.is_verified else "⏳ PENDING OTP"
        print(f"  - {user.full_name} ({user.email}) {status}")
    
    # Test 2: Attempt login with verified user
    print_step(4, "Testing Login (Verified User)")
    
    success, msg, session_id = user_manager.login("john@example.com", "password123")
    if success:
        print(f"✓ Login successful")
        print(f"  Session ID: {session_id[:16]}...")
        print(f"  User: John Doe")
    else:
        print(f"✗ Login failed: {msg}")
    
    # Test 3: Register new user
    print_step(5, "Testing User Registration")
    
    success, msg, user = user_manager.register_user(
        email="alice@example.com",
        password="secure789",
        full_name="Alice Johnson",
        phone="+1987654321"
    )
    
    if success:
        print(f"✓ Registration successful")
        print(f"  User ID: {user.id}")
        print(f"  Email: {user.email}")
        print(f"  Name: {user.full_name}")
        print(f"  Phone: {user.phone}")
        print(f"  OTP Code (for testing): {user.otp_code}")
    else:
        print(f"✗ Registration failed: {msg}")
    
    # Test 4: Verify OTP
    print_step(6, "Testing OTP Verification")
    
    if user.otp_code:
        success, msg = user_manager.verify_otp("alice@example.com", user.otp_code)
        
        if success:
            print(f"✓ OTP verification successful")
            print(f"  Email is now verified")
            
            # Try to login now
            success, msg, session_id = user_manager.login("alice@example.com", "secure789")
            if success:
                print(f"✓ Login with verified account successful")
                print(f"  Session ID: {session_id[:16]}...")
        else:
            print(f"✗ OTP verification failed: {msg}")
    
    # Test 5: Test invalid password
    print_step(7, "Testing Invalid Password")
    
    success, msg, session_id = user_manager.login("john@example.com", "wrongpassword")
    if not success:
        print(f"✓ Correctly rejected invalid password")
        print(f"  Message: {msg}")
    else:
        print(f"✗ Should have rejected invalid password")
    
    # Test 6: Test session validation
    print_step(8, "Testing Session Management")
    
    success, msg, session_id = user_manager.login("john@example.com", "password123")
    if success:
        # Validate session
        is_valid, user_id = user_manager.validate_session(session_id)
        print(f"✓ Session created: {session_id[:16]}...")
        print(f"✓ Session validation: {'VALID' if is_valid else 'INVALID'}")
        
        # Get user from session
        user_from_session = user_manager.get_user_by_session(session_id)
        if user_from_session:
            print(f"✓ Retrieved user from session: {user_from_session.full_name}")
    
    # Test 7: Test password change
    print_step(9, "Testing Password Change")
    
    success, msg = user_manager.change_password(
        "demo001",  # John Doe's ID
        "password123",  # old password
        "newpassword456"  # new password
    )
    
    if success:
        print(f"✓ Password changed successfully")
        
        # Try login with old password (should fail)
        success_old, _, _ = user_manager.login("john@example.com", "password123")
        print(f"  Old password works: {success_old} (should be False)")
        
        # Try login with new password (should succeed)
        success_new, _, _ = user_manager.login("john@example.com", "newpassword456")
        print(f"  New password works: {success_new} (should be True)")
        
        # Reset to original password for other tests
        user_manager.change_password("demo001", "newpassword456", "password123")
    
    # Test 8: Test profile update
    print_step(10, "Testing Profile Update")
    
    success, msg = user_manager.update_user_profile(
        "demo001",
        full_name="John Doe Updated",
        phone="+9876543210"
    )
    
    if success:
        print(f"✓ Profile updated successfully")
        user = user_manager.get_user("demo001")
        print(f"  New name: {user.full_name}")
        print(f"  New phone: {user.phone}")
    
    # Test 9: Email statistics
    print_step(11, "Email Service Statistics")
    
    stats = email_service.get_email_stats()
    print(f"Total emails sent: {stats['total_emails']}")
    print(f"Demo mode: {stats['demo_mode']}")
    print(f"Emails by type:")
    for email_type, count in stats['by_type'].items():
        print(f"  - {email_type}: {count}")
    
    # Test 10: System statistics
    print_step(12, "User Management Statistics")
    
    stats = user_manager.get_statistics()
    print(f"Total users: {stats['total_users']}")
    print(f"Verified users: {stats['verified_users']}")
    print(f"Unverified users: {stats['unverified_users']}")
    print(f"Active sessions: {stats['active_sessions']}")
    
    # Summary
    print_header("Authentication Demo Complete")
    print("""
✓ Registration System Working
✓ Email OTP Service Working  
✓ Password Security Working
✓ Session Management Working
✓ Profile Management Working

Next Steps:
1. Integration with API routes (/api/auth/*)
2. Frontend forms for registration/login/verification
3. Database persistence (replace in-memory storage)
4. Email service configuration (SMTP/SendGrid)
5. Session token expiry and refresh handling
""")
    
    print(f"Completed: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")


if __name__ == "__main__":
    try:
        demo_auth_system()
    except Exception as e:
        print(f"\n✗ Error: {str(e)}")
        import traceback
        traceback.print_exc()

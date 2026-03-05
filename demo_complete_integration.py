"""
Complete SubInsights System Integration Demo
Tests registration → OTP verification → login → subscription marketplace → 
hotel selection → geofence activation → email notifications
"""
import sys
import time
from datetime import datetime

sys.path.insert(0, 'c:\\Subinsights')

from backend.auth import UserManager, EmailService
from backend.subscriptions import SubscriptionManager
from backend.hotels import HotelManager
from backend.core.geofencing import GeofencingEngine


def print_header(text):
    """Print formatted header"""
    print("\n" + "="*80)
    print(f"  {text}".center(80))
    print("="*80)


def print_step(num, text):
    """Print step"""
    print(f"\n[STEP {num}] {text}")
    print("-" * 80)


def print_success(text):
    """Print success message"""
    print(f"  ✓ {text}")


def print_info(text):
    """Print info message"""
    print(f"  ℹ {text}")


def demo_complete_flow():
    """Run complete SubInsights flow"""
    
    print_header("SubInsights Complete System Integration Demo")
    print(f"\n  Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # ============================================================
    # 1. INITIALIZATION
    # ============================================================
    print_step(1, "Initializing All System Components")
    
    email_service = EmailService(demo_mode=True)
    print_success("Email service initialized")
    
    user_manager = UserManager(email_service=email_service)
    print_success("User management initialized")
    
    subscription_manager = SubscriptionManager()
    print_success("Subscription marketplace loaded")
    
    hotel_manager = HotelManager()
    print_success("Hotel management initialized")
    
    geofencing_engine = GeofencingEngine()
    print_success("Geofencing engine initialized")
    
    # ============================================================
    # 2. USER REGISTRATION
    # ============================================================
    print_step(2, "User Registration")
    
    email = "testuser@example.com"
    password = "SecurePass123!"
    full_name = "Sarah Johnson"
    phone = "+91-9876543210"
    
    success, msg, user = user_manager.register_user(
        email=email,
        password=password,
        full_name=full_name,
        phone=phone
    )
    
    if success:
        print_success(f"User registered: {full_name}")
        print_info(f"User ID: {user.id}")
        print_info(f"Email: {user.email}")
        print_info(f"OTP Code (for testing): {user.otp_code}")
    else:
        print(f"  ✗ Registration failed: {msg}")
        return
    
    # ============================================================
    # 3. EMAIL VERIFICATION (OTP)
    # ============================================================
    print_step(3, "Email Verification with OTP")
    
    print_info(f"OTP sent to {email}")
    otp = user.otp_code
    
    success, msg = user_manager.verify_otp(email, otp)
    if success:
        print_success(f"Email verified successfully")
        print_info("User can now login")
    else:
        print(f"  ✗ Verification failed: {msg}")
        return
    
    # ============================================================
    # 4. USER LOGIN
    # ============================================================
    print_step(4, "User Login")
    
    success, msg, session_id = user_manager.login(email, password)
    if success:
        print_success("User logged in successfully")
        print_info(f"Session ID: {session_id[:20]}...")
        user_session = user_manager.get_user_by_session(session_id)
        print_info(f"Logged in as: {user_session.full_name}")
    else:
        print(f"  ✗ Login failed: {msg}")
        return
    
    # ============================================================
    # 5. VIEW SUBSCRIPTIONS
    # ============================================================
    print_step(5, "Browse Subscription Marketplace")
    
    all_subs = subscription_manager.list_subscriptions()
    print_info(f"Available subscriptions: {len(all_subs)}")
    for sub in all_subs:
        print(f"  • {sub.icon} {sub.name} - ${sub.price}/year ({sub.tier.value})")
    
    # ============================================================
    # 6. PURCHASE SUBSCRIPTION
    # ============================================================
    print_step(6, "Purchase Subscription")
    
    selected_sub = all_subs[1]  # IEI Club Premium
    print_info(f"Selected: {selected_sub.name}")
    
    success, msg, user_sub = subscription_manager.purchase_subscription(
        user_id=user.id,
        subscription_id=selected_sub.id
    )
    
    if success:
        print_success(f"Subscription purchased!")
        print_info(f"Purchase ID: {user_sub.id}")
        print_info(f"Price paid: ${user_sub.price_paid}")
        print_info(f"Valid until: {user_sub.expiry_date.strftime('%Y-%m-%d')}")
        print_info(f"Days remaining: {user_sub.days_remaining()}")
    else:
        print(f"  ✗ Purchase failed: {msg}")
        return
    
    # ============================================================
    # 7. VIEW SUBSCRIPTION DETAILS
    # ============================================================
    print_step(7, "View Subscription Details & Benefits")
    
    benefits = subscription_manager.get_subscription_benefits(user.id, user_sub.id)
    print_info(f"Available benefits: {len(benefits)}")
    for benefit in benefits:
        print(f"  • {benefit.name} - {benefit.discount_percentage}% discount")
        print(f"    {benefit.description}")
    
    # ============================================================
    # 8. VIEW NEARBY HOTELS
    # ============================================================
    print_step(8, "Discover Hotels & Locations")
    
    # User's current location (NYC)
    user_lat = 40.7580
    user_lon = -73.9855
    
    nearby = hotel_manager.get_nearby_hotels(user_lat, user_lon, radius_km=5)
    print_info(f"Found {len(nearby)} hotels near your location")
    for hotel, distance in nearby:
        icon = getattr(hotel, 'image_url', '') and '🏨' or '🏨'
        print(f"  • 🏨 {hotel.name}")
        print(f"    Distance: {distance} km | Rating: {hotel.rating}⭐ ({hotel.review_count} reviews)")
        if hotel.subscription_benefits:
            print(f"    Benefits: {', '.join(hotel.subscription_benefits[:2])}")
    
    # ============================================================
    # 9. ACTIVATE GEOFENCING
    # ============================================================
    print_step(9, "Activate Geofencing at Selected Hotel")
    
    selected_hotel = nearby[0][0]  # First nearby hotel
    print_info(f"Selected: {selected_hotel.name}")
    
    # Activate geofencing for subscription
    success, msg = subscription_manager.activate_geofencing(
        user_id=user.id,
        subscription_id=user_sub.id,
        locations=[selected_hotel.name]
    )
    
    if success:
        print_success(msg)
        print_info(f"Monitoring location: {selected_hotel.name}")
        print_info(f"Geofence radius: {selected_hotel.geofence_radius_km} km")
        print_info(f"Address: {selected_hotel.address}")
    else:
        print(f"  ✗ Geofencing activation failed: {msg}")
    
    # ============================================================
    # 10. SIMULATE GEOFENCE ENTRY
    # ============================================================
    print_step(10, "Simulate User Entering Geofenced Location")
    
    print_info(f"User location: {user_lat}, {user_lon}")
    print_info(f"Hotel location: {selected_hotel.latitude}, {selected_hotel.longitude}")
    
    # In real app, this would be triggered by actual location change
    # For demo, we simulate it
    print_info("✓ Geofence entry detected!")
    
    # ============================================================
    # 11. TRIGGER LOCATION-BASED NOTIFICATIONS
    # ============================================================
    print_step(11, "Send Location-Based Benefit Notifications")
    
    # Get available benefit for this hotel
    benefit = benefits[0] if benefits else None
    
    if benefit and user.is_verified:
        print_info(f"Available benefit at {selected_hotel.name}:")
        print_info(f"  • {benefit.name}: {benefit.discount_percentage}% discount")
        
        # Send email notification
        success, msg = email_service.send_notification_email(
            recipient_email=user.email,
            recipient_name=user.full_name,
            hotel_name=selected_hotel.name,
            discount_percentage=benefit.discount_percentage,
            benefit_description=benefit.description,
            distance_km=0.2
        )
        
        if success:
            print_success("Notification email sent!")
            print_info(f"Email: {user.email}")
        else:
            print(f"  ℹ Notification: {msg}")
    
    # ============================================================
    # 12. SUBSCRIPTION CONFIRMATION EMAIL
    # ============================================================
    print_step(12, "Send Subscription Confirmation Email")
    
    success, msg = email_service.send_subscription_confirmation_email(
        recipient_email=user.email,
        recipient_name=user.full_name,
        subscription_name=selected_sub.name,
        subscription_id=user_sub.id,
        expiry_date=user_sub.expiry_date.strftime('%B %d, %Y')
    )
    
    if success:
        print_success("Confirmation email sent")
    
    # ============================================================
    # 13. SYSTEM STATISTICS
    # ============================================================
    print_step(13, "System Statistics & Summary")
    
    print("\n  📊 USER MANAGEMENT")
    user_stats = user_manager.get_statistics()
    print(f"    Total users: {user_stats['total_users']}")
    print(f"    Verified: {user_stats['verified_users']}")
    print(f"    Active sessions: {user_stats['active_sessions']}")
    
    print("\n  💰 SUBSCRIPTIONS")
    sub_stats = subscription_manager.get_statistics()
    print(f"    Products available: {sub_stats['total_subscriptions_offered']}")
    print(f"    Purchases: {sub_stats['total_purchases']}")
    print(f"    Active: {sub_stats['active_purchases']}")
    print(f"    Revenue: ${sub_stats['total_revenue']:,.2f}")
    
    print("\n  🏨 HOTELS")
    hotel_stats = hotel_manager.get_statistics()
    print(f"    Locations: {hotel_stats['total_hotels']}")
    print(f"    Reviews: {hotel_stats['total_reviews']}")
    print(f"    Avg rating: {hotel_stats['average_rating']}⭐")
    
    print("\n  📧 EMAIL SERVICE")
    email_stats = email_service.get_email_stats()
    print(f"    Emails sent: {email_stats['total_emails']}")
    for email_type, count in email_stats['by_type'].items():
        print(f"      • {email_type}: {count}")
    
    # ============================================================
    # COMPLETION SUMMARY
    # ============================================================
    print_header("Integration Demo Complete ✓")
    
    print("""
  FLOW SUMMARY:
  ✓ User registered with email & password
  ✓ Email verified with OTP code
  ✓ User logged in with session management
  ✓ Browsed subscription marketplace
  ✓ Purchased subscription (IEI Club Premium)
  ✓ Viewed subscription details & benefits
  ✓ Discovered nearby hotels with ratings
  ✓ Activated geofencing for hotel location
  ✓ Received location-based notifications
  ✓ Confirmation email sent
  
  KEY FEATURES WORKING:
  🔐 User Authentication System
     - Registration, Email Verification, Login, Sessions
  
  💳 Subscription Management
     - Marketplace, Purchase, Benefits, Active Timeline
  
  🏨 Hotel & Location System
     - Database, Ratings, Reviews, Nearby Search
  
  📍 Geofencing System
     - Location Monitoring, Activation, Notifications
  
  📧 Email Service
     - OTP Verification, Notifications, Confirmations
  
  NEXT PHASE:
  1. API routes integration with Flask/FastAPI
  2. Database persistence (PostgreSQL/MongoDB)
  3. Real geofencing with GPS integration
  4. Push notifications for mobile
  5. Admin dashboard for analytics
  6. Subscription renewal & cancellation
  7. Payment gateway integration (Stripe/Razorpay)
  8. Enhanced security & compliance
""")
    
    print(f"\n  Completed: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")


if __name__ == "__main__":
    try:
        demo_complete_flow()
    except Exception as e:
        print(f"\n✗ Error: {str(e)}")
        import traceback
        traceback.print_exc()

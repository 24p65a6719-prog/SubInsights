#!/usr/bin/env python
"""
SubInsights Demo Script
Demonstrates all core systems working together
"""
import sys
import time
from pathlib import Path

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent / "backend"))

from backend.main import SubInsightsBackend
from backend.models.merchant import Location


def print_section(title):
    """Print formatted section header"""
    print("\n" + "=" * 80)
    print(f"  {title}")
    print("=" * 80)

def demonstration():
    """Run full SubInsights demonstration"""
    
    print_section("SubInsights - Location-Aware Benefit Discovery System")
    
    # Initialize backend
    print("\n[Step 1] Initializing Backend Systems...")
    backend = SubInsightsBackend()
    
    # Start monitoring
    print("\n[Step 2] Starting Geofence Monitoring...")
    backend.start()
    
    # Display user memberships
    print("\n[Step 3] Displaying User Memberships...")
    memberships = backend.get_user_memberships("user_1")
    print(f"\nUser has {len(memberships)} active memberships:")
    for m in memberships:
        days_left = m.days_until_expiry()
        print(f"  • {m.name} ({m.category})")
        print(f"    Expires in {days_left} days")
        print(f"    Benefits: {', '.join(m.associated_benefits)}")
    
    # Display verified benefits
    print("\n[Step 4] Checking Verified Benefits...")
    benefits = backend.get_user_benefits("user_1")
    verified = [b for b in benefits if b.is_verified]
    print(f"\nUser has {len(verified)}/{len(benefits)} verified benefits:")
    for b in verified:
        print(f"  ✓ {b.title}")
        print(f"    Discount: {b.discount_percent}% | Score: {b.verification_score:.1%}")
    
    # Get nearby merchants
    print("\n[Step 5] Scanning for Nearby Merchants...")
    nearby_merchants = backend.geofence_engine.get_nearby_merchants(radius_km=10)
    print(f"\nFound {len(nearby_merchants)} merchants within 10km:")
    for m in nearby_merchants:
        print(f"\n  📍 {m.name}")
        print(f"     Address: {m.address}")
        print(f"     Benefits: {len(m.benefits_offered)}")
        print(f"     Rating: {m.average_review_rating} ({m.total_reviews} reviews)")
        
        # Show benefits at this merchant
        for bid in m.benefits_offered:
            b = backend.get_benefit(bid)
            if b:
                verified_str = f"✓ {b.verification_score:.0%}" if b.is_verified else "✗"
                print(f"       • {b.title}: {b.discount_percent}% off [{verified_str}]")
    
    # Simulate location update and geofence entry
    print("\n[Step 6] Simulating Geofence Entry...")
    print("\nScenario: User walks into Marriott Hotel")
    
    # Get Marriott location
    marriott = backend.merchants.get("merch_marriott_001")
    if marriott:
        # Move user to Marriott location
        new_lat = marriott.location.latitude + 0.0001
        new_lon = marriott.location.longitude + 0.0001
        
        print(f"  Moving user to: {new_lat}, {new_lon}")
        backend.geofence_engine.update_user_location(new_lat, new_lon)
        backend.location_service.update_user_location("user_1", new_lat, new_lon)
        
        # Wait for geofence detection
        print("  Waiting for geofence detection (5 seconds)...")
        time.sleep(5)
        
        # Check generated alerts
        pending = backend.alert_system.get_pending_alerts("user_1")
        if pending:
            print(f"\n  ✓ Generated {len(pending)} alerts!")
            for alert in pending:
                print(f"\n    📢 {alert.title}")
                print(f"       {alert.message}")
                print(f"       Priority: {alert.priority}")
        else:
            print("\n  (No alerts generated in demo mode)")
    
    # Show nearby benefits from current location
    print("\n[Step 7] Getting Benefits Nearby Current Location...")
    nearby_benefits = backend.get_nearby_benefits("user_1", radius_km=5)
    if nearby_benefits:
        print(f"\nFound {len(nearby_benefits)} nearby benefits:")
        for item in nearby_benefits[:5]:
            benefit = item["benefit"]
            merchant = item["merchant"]
            distance = item["distance"]
            
            status = "✓ VERIFIED" if benefit.is_verified else "⚠ NOT VERIFIED"
            print(f"\n  {status} {benefit.title}")
            print(f"  📍 {merchant.name} ({distance:.2f} km away)")
            print(f"  💰 {benefit.discount_percent}% off | Confidence: {benefit.verification_score:.0%}")
    else:
        print("\nNo nearby benefits found")
    
    # Demonstrate BERT verification
    print("\n[Step 8] BERT Verification Process...")
    
    # Pick a benefit and verify it
    if benefits:
        test_benefit = benefits[0]
        print(f"\nVerifying: {test_benefit.title}")
        
        # Get merchant
        merchant = None
        for m in backend.merchants.values():
            if test_benefit.id in m.benefits_offered:
                merchant = m
                break
        
        if merchant:
            print(f"  Merchant: {merchant.name}")
            
            # Scrape reviews
            print("  1. Scraping merchant reviews...")
            reviews = backend.web_scraper.scrape_merchant_reviews(merchant.id, merchant.name)
            print(f"     ✓ Retrieved {len(reviews)} reviews")
            
            # BERT analysis
            print("  2. Running BERT sentiment analysis...")
            for review in reviews[:2]:
                print(f"     • \"{review[:60]}...\"")
            
            is_verified, score, reasoning = backend.bert_engine.verify_benefit(
                test_benefit.id, merchant.name, reviews
            )
            
            print(f"  3. Analysis result:")
            print(f"     Status: {'VERIFIED ✓' if is_verified else 'NOT VERIFIED ✗'}")
            print(f"     Confidence: {score:.0%}")
            print(f"     Reason: {reasoning}")
    
    # Show alert statistics
    print("\n[Step 9] System Statistics...")
    stats = backend.alert_system.get_statistics()
    notif_stats = backend.notification_service.get_delivery_stats()
    
    print(f"\n Alert System:")
    print(f"  Total created: {stats['total_created']}")
    print(f"  Pending: {stats['pending']}")
    print(f"  Sent: {stats['sent']}")
    print(f"  Claimed: {stats['claimed']}")
    print(f"  Dismissed: {stats['dismissed']}")
    
    print(f"\n Notification Service:")
    print(f"  Total sent: {notif_stats['total_sent']}")
    print(f"  Succeeded: {notif_stats['succeeded']}")
    print(f"  Failed: {notif_stats['failed']}")
    
    # Show savings estimation
    print("\n[Step 10] Estimated Annual Savings...")
    verified_benefits = [b for b in backend.get_user_benefits("user_1") if b.is_verified]
    total_discount = sum(b.discount_percent for b in verified_benefits)
    
    print(f"\n  Verified benefits: {len(verified_benefits)}")
    print(f"  Combined discount: {total_discount}%")
    
    # Estimate based on average spending categories
    estimated_hotel_spend = 2000  # $2k/year on hotels
    estimated_travel_spend = 3000  # $3k/year on travel
    estimated_dining_spend = 1000  # $1k/year on dining
    
    hotel_benefits = [b for b in verified_benefits if 'hotel' in ' '.join(b.merchant_categories).lower()]
    travel_benefits = [b for b in verified_benefits if any(cat in ['travel', 'airlines'] for cat in b.merchant_categories)]
    dining_benefits = [b for b in verified_benefits if 'dining' in ' '.join(b.merchant_categories).lower() or 'restaurant' in ' '.join(b.merchant_categories).lower()]
    
    hotel_savings = (sum(b.discount_percent for b in hotel_benefits) / 100) * estimated_hotel_spend if hotel_benefits else 0
    travel_savings = (sum(b.discount_percent for b in travel_benefits) / 100) * estimated_travel_spend if travel_benefits else 0
    dining_savings = (sum(b.discount_percent for b in dining_benefits) / 100) * estimated_dining_spend if dining_benefits else 0
    
    total_savings = hotel_savings + travel_savings + dining_savings
    
    print(f"\n  Estimated Annual Savings:")
    if hotel_savings > 0:
        print(f"    Hotels: ${hotel_savings:.2f}")
    if travel_savings > 0:
        print(f"    Travel: ${travel_savings:.2f}")
    if dining_savings > 0:
        print(f"    Dining: ${dining_savings:.2f}")
    print(f"\n    💰 TOTAL: ${total_savings:.2f}/year")
    
    # Wrap up
    print_section("Demo Complete!")
    
    print("\n📚 Key Features Demonstrated:")
    print("  ✓ Geofencing: Real-time location monitoring")
    print("  ✓ BERT Verification: AI-powered benefit validation")
    print("  ✓ Alert System: Context-aware notifications")
    print("  ✓ Web Scraping: Merchant review collection")
    print("  ✓ Location Service: GPS tracking & subscriptions")
    print("  ✓ API Layer: REST endpoints for frontend")
    
    print("\n🚀 Next Steps:")
    print("  1. Open: frontend/index.html in browser")
    print("  2. Update location coordinates")
    print("  3. Click 'Update Location' to trigger geofence checks")
    print("  4. View alerts and benefits in real-time")
    print("  5. Claim benefits with generated codes")
    
    print("\n📖 Learn More:")
    print("  • Architecture: docs/ARCHITECTURE.md")
    print("  • API Docs: backend/api/routes.py")
    print("  • Frontend Code: frontend/app.js")
    
    print("\n" + "=" * 80)
    print("  Thank you for exploring SubInsights!")
    print("=" * 80 + "\n")
    
    # Stop monitoring
    backend.stop()


if __name__ == "__main__":
    try:
        demonstration()
    except KeyboardInterrupt:
        print("\n\n⏹️  Demo interrupted by user")
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()

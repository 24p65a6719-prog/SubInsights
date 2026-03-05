"""
SubInsights Backend Main Entry Point
Initializes and orchestrates all backend systems
"""
from typing import Dict, List, Optional
from datetime import datetime

from backend.core.geofencing import GeofencingEngine
from backend.core.bert_verification import BERTVerificationEngine
from backend.core.alert_system import AlertSystem, push_notification_handler, email_notification_handler
from backend.services.web_scraper import WebScraperService
from backend.services.location_service import LocationService
from backend.services.notification_service import NotificationService, \
    push_notification_handler as notif_push, \
    email_notification_handler as notif_email
from backend.models.membership import Membership
from backend.models.benefit import Benefit
from backend.models.merchant import Merchant, Location
from backend.models.detection import GeofenceEvent
from backend.config import get_config, DEMO_MEMBERSHIPS, DEMO_BENEFITS, DEMO_MERCHANTS


class SubInsightsBackend:
    """
    Main backend system orchestrating all SubInsights components
    
    Coordinates:
    - Geofencing: Location monitoring
    - BERT Verification: Benefit validation
    - Alerts: User notifications
    - Services: Web scraping, location tracking, notifications
    """
    
    def __init__(self):
        """Initialize SubInsights backend"""
        print("=" * 70)
        print("  SubInsights Backend Initialization")
        print("=" * 70)
        
        self.config = get_config()
        
        # Initialize core systems
        self.geofence_engine = GeofencingEngine(
            update_interval=self.config.GEOFENCE_UPDATE_INTERVAL
        )
        self.bert_engine = BERTVerificationEngine()
        self.alert_system = AlertSystem()
        
        # Initialize services
        self.web_scraper = WebScraperService()
        self.location_service = LocationService()
        self.notification_service = NotificationService()
        
        # Data stores (in-memory for demo)
        self.memberships: Dict[str, Membership] = {}
        self.benefits: Dict[str, Benefit] = {}
        self.merchants: Dict[str, Merchant] = {}
        
        # Setup notification channels
        self._setup_notification_channels()
        
        # Load demo data
        self._load_demo_data()
        
        # Setup callbacks
        self._setup_callbacks()
        
        print("\n✓ Backend initialized successfully\n")
        
    def _setup_notification_channels(self) -> None:
        """Configure notification channels"""
        print("\n[Setup] Configuring notification channels...")
        
        self.notification_service.register_channel("push", notif_push)
        self.notification_service.register_channel("email", notif_email)
        
        # Configure user preferences
        self.notification_service.set_channel_preference("user_1", "push", True)
        self.notification_service.set_channel_preference("user_1", "email", True)
        
    def _load_demo_data(self) -> None:
        """Load demo data for testing"""
        print("\n[Setup] Loading demo data...")
        
        # Load merchants first (needed by benefits)
        for m in DEMO_MERCHANTS:
            merchant = Merchant(
                id=m["id"],
                name=m["name"],
                category=m["category"],
                location=Location(m["latitude"], m["longitude"]),
                address=m["address"],
                benefits_offered=m.get("benefits", []),
                average_review_rating=m.get("rating", 4.0),
                is_active=m.get("is_active", True)
            )
            self.merchants[merchant.id] = merchant
            self.geofence_engine.add_merchant(merchant)
            
        print(f"  ✓ Loaded {len(self.merchants)} merchants")
        
        # Load memberships
        for m in DEMO_MEMBERSHIPS:
            from datetime import datetime as dt
            membership = Membership(
                id=m["id"],
                name=m["name"],
                category=m["category"],
                user_id=m["user_id"],
                start_date=dt.strptime(m["start_date"], "%Y-%m-%d"),
                end_date=dt.strptime(m["end_date"], "%Y-%m-%d"),
                associated_benefits=m.get("benefits", [])
            )
            self.memberships[membership.id] = membership
            
        print(f"  ✓ Loaded {len(self.memberships)} memberships")
        
        # Load benefits
        for b in DEMO_BENEFITS:
            benefit = Benefit(
                id=b["id"],
                membership_id=b["membership_id"],
                title=b["title"],
                description=b["description"],
                discount_percent=b["discount_percent"],
                merchant_categories=b["merchant_categories"],
                eligible_merchants=b.get("merchants", []),
                expiry_date=datetime.strptime(b["expiry_date"], "%Y-%m-%d"),
                is_verified=b.get("is_verified", False),
                verification_score=b.get("verification_score", 0.0),
                last_verification=datetime.now() if b.get("is_verified") else None
            )
            self.benefits[benefit.id] = benefit
            
        print(f"  ✓ Loaded {len(self.benefits)} benefits")
        
    def _setup_callbacks(self) -> None:
        """Setup callbacks for geofence events"""
        print("\n[Setup] Configuring event callbacks...")
        
        # When a geofence entry occurs, create alerts
        def on_geofence_event(event_type: str, merchant: Merchant, event: GeofenceEvent, **kwargs):
            if event_type == "entry" and event:
                self._handle_geofence_entry(merchant, event)
                
        self.geofence_engine.add_event_callback(on_geofence_event)
        print("  ✓ Geofence callbacks registered")
        
    def _handle_geofence_entry(self, merchant: Merchant, event: GeofenceEvent) -> None:
        """Handle user entering merchant geofence"""
        print(f"\n[BackendSystem] Processing geofence entry for {merchant.name}...")
        
        # Get benefits at this merchant
        benefit_ids = merchant.benefits_offered
        
        if not benefit_ids:
            print(f"  No benefits available at {merchant.name}")
            return
            
        # For each benefit, verify and create alert
        for benefit_id in benefit_ids:
            benefit = self.benefits.get(benefit_id)
            if not benefit:
                continue
                
            # Skip if already expired
            if benefit.is_expired():
                print(f"  Skipping {benefit.title} (expired)")
                continue
                
            # Check verification status
            if not benefit.is_verified:
                # Trigger BERT verification
                self._verify_benefit_internal(benefit)
                
            # If verified, create alert
            if benefit.is_verified:
                alert = self.alert_system.create_alert(
                    user_id=event.user_id,
                    geofence_event=event,
                    merchant=merchant,
                    benefit=benefit
                )
                
                # Send alert
                self.notification_service.send(alert)
                
    def _verify_benefit_internal(self, benefit: Benefit) -> None:
        """Internally verify a benefit using BERT"""
        merchant = None
        for m in self.merchants.values():
            if benefit.id in m.benefits_offered:
                merchant = m
                break
                
        if not merchant:
            print(f"  No merchant found for benefit {benefit.id}")
            return
            
        # Scrape reviews
        reviews = self.web_scraper.scrape_merchant_reviews(
            merchant.id, merchant.name
        )
        
        # Verify with BERT
        is_verified, score, reasoning = self.bert_engine.verify_benefit(
            benefit.id, merchant.name, reviews
        )
        
        # Update benefit
        benefit.is_verified = is_verified
        benefit.verification_score = score
        benefit.last_verification = datetime.now()
        
        print(f"  {benefit.title}: {'✓ VERIFIED' if is_verified else '✗ NOT VERIFIED'} ({score:.1%})")
        print(f"    Reason: {reasoning}")
        
    def start(self) -> None:
        """Start background monitoring systems"""
        print("\n" + "=" * 70)
        print("  Starting SubInsights Monitoring Systems")
        print("=" * 70)
        
        # Set initial user location (San Francisco)
        initial_lat = 37.7749
        initial_lon = -122.4194
        self.location_service.update_user_location("user_1", initial_lat, initial_lon)
        self.geofence_engine.update_user_location(initial_lat, initial_lon)
        
        # Start geofence monitoring
        self.geofence_engine.start_monitoring()
        
        print("\n✓ All systems online. Ready for geofence detection.\n")
        
    def stop(self) -> None:
        """Stop background monitoring"""
        self.geofence_engine.stop_monitoring()
        
    # ============ Data Access Methods ============
    
    def get_user_memberships(self, user_id: str) -> List[Membership]:
        """Get all memberships for user"""
        return [m for m in self.memberships.values() if m.user_id == user_id]
        
    def get_membership(self, membership_id: str) -> Optional[Membership]:
        """Get specific membership"""
        return self.memberships.get(membership_id)
        
    def get_user_benefits(self, user_id: str) -> List[Benefit]:
        """Get all benefits for user"""
        memberships = self.get_user_memberships(user_id)
        benefit_ids = []
        for m in memberships:
            benefit_ids.extend(m.associated_benefits)
            
        return [self.benefits[bid] for bid in benefit_ids if bid in self.benefits]
        
    def get_benefit(self, benefit_id: str) -> Optional[Benefit]:
        """Get specific benefit"""
        return self.benefits.get(benefit_id)
        
    def verify_benefit(self, benefit_id: str) -> bool:
        """Trigger verification of a benefit"""
        benefit = self.get_benefit(benefit_id)
        if not benefit:
            return False
            
        self._verify_benefit_internal(benefit)
        return benefit.is_verified
        
    def get_nearby_benefits(self, user_id: str, radius_km: float = 5.0) -> List[Dict]:
        """Get benefits available at nearby merchants"""
        user_location = self.location_service.get_user_location(user_id)
        if not user_location:
            return []
            
        nearby = []
        
        for merchant in self.merchants.values():
            distance = merchant.distance_to(user_location)
            if distance <= radius_km:
                for benefit_id in merchant.benefits_offered:
                    benefit = self.benefits.get(benefit_id)
                    if benefit and not benefit.is_expired():
                        nearby.append({
                            "benefit": benefit,
                            "merchant": merchant,
                            "distance": distance
                        })
        
        # Sort by distance
        nearby.sort(key=lambda x: x["distance"])
        return nearby[:10]  # Return top 10

"""
Subscription Module
Handles subscription products, user purchases, and benefit management
"""
from dataclasses import dataclass, field
from typing import List, Dict, Optional
from datetime import datetime, timedelta
from enum import Enum
import uuid


class SubscriptionTier(Enum):
    """Subscription tier levels"""
    BASIC = "basic"
    PREMIUM = "premium"
    ELITE = "elite"


@dataclass
class Benefit:
    """
    Benefit/perk associated with a subscription
    
    Attributes:
        id: Unique benefit identifier
        name: Benefit name
        description: Detailed description
        discount_percentage: Discount percentage (0-100)
        category: Category (hotel, dining, travel, etc.)
        applicable_merchants: List of merchant types/names where benefit applies
        terms: Terms and conditions
        valid_at_locations: Specific locations/hotels where valid
    """
    id: str
    name: str
    description: str
    discount_percentage: int
    category: str
    applicable_merchants: List[str] = field(default_factory=list)
    terms: str = ""
    valid_at_locations: List[str] = field(default_factory=list)
    
    def to_dict(self) -> Dict:
        """Convert to dictionary"""
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "discount_percentage": self.discount_percentage,
            "category": self.category,
            "applicable_merchants": self.applicable_merchants,
            "terms": self.terms,
            "valid_at_locations": self.valid_at_locations
        }


@dataclass
class Subscription:
    """
    Subscription product offered by SubInsights
    
    Attributes:
        id: Unique subscription identifier
        name: Subscription name (e.g., "IEI Club")
        description: Detailed description
        price: Annual price in USD
        tier: Subscription tier (basic, premium, elite)
        features: List of key features
        benefits: List of Benefit objects
        max_users: Maximum users per subscription (0 = unlimited)
        renewal_interval: Days between renewals (365 for annual)
        icon: Emoji or icon representation
        color: Brand color for UI
        logo: Logo image path for UI display
    """
    id: str
    name: str
    description: str
    price: float
    tier: SubscriptionTier
    features: List[str] = field(default_factory=list)
    benefits: List[Benefit] = field(default_factory=list)
    max_users: int = 0  # 0 = unlimited
    renewal_interval: int = 365
    icon: str = "📋"
    color: str = "#667eea"
    logo: str = ""
    created_at: datetime = field(default_factory=datetime.now)
    
    def to_dict(self) -> Dict:
        """Convert to dictionary"""
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "price": self.price,
            "tier": self.tier.value,
            "features": self.features,
            "benefits": [b.to_dict() for b in self.benefits],
            "max_users": self.max_users,
            "renewal_interval": self.renewal_interval,
            "icon": self.icon,
            "color": self.color,
            "logo": self.logo
        }


@dataclass
class UserSubscription:
    """
    User's active subscription purchase
    
    Attributes:
        id: Unique purchase ID
        user_id: User who purchased
        subscription_id: Subscription product ID
        purchase_date: When subscription was purchased
        start_date: When subscription becomes active
        expiry_date: When subscription expires
        renewal_date: Next renewal date
        price_paid: Price paid (may differ from current)
        geofence_active: Whether geofencing is enabled
        geofence_locations: Specific hotel/merchant locations geofence is active for
        status: active, expired, cancelled, suspended
    """
    id: str
    user_id: str
    subscription_id: str
    subscription_name: str
    purchase_date: datetime
    start_date: datetime
    expiry_date: datetime
    renewal_date: datetime
    price_paid: float
    geofence_active: bool = False
    geofence_locations: List[str] = field(default_factory=list)
    status: str = "active"
    
    def is_active(self) -> bool:
        """Check if subscription is currently active"""
        now = datetime.now()
        return self.status == "active" and now >= self.start_date and now < self.expiry_date
    
    def days_remaining(self) -> int:
        """Days until expiration"""
        if not self.is_active():
            return 0
        return (self.expiry_date - datetime.now()).days
    
    def to_dict(self) -> Dict:
        """Convert to dictionary"""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "subscription_id": self.subscription_id,
            "subscription_name": self.subscription_name,
            "purchase_date": self.purchase_date.isoformat(),
            "start_date": self.start_date.isoformat(),
            "expiry_date": self.expiry_date.isoformat(),
            "renewal_date": self.renewal_date.isoformat(),
            "price_paid": self.price_paid,
            "geofence_active": self.geofence_active,
            "geofence_locations": self.geofence_locations,
            "status": self.status,
            "is_active": self.is_active(),
            "days_remaining": self.days_remaining()
        }


class SubscriptionManager:
    """
    Manages subscriptions, purchases, and user subscriptions
    """
    
    def __init__(self):
        """Initialize subscription manager"""
        self.subscriptions: Dict[str, Subscription] = {}  # id -> Subscription
        self.user_subscriptions: Dict[str, List[UserSubscription]] = {}  # user_id -> [subscriptions]
        self.purchase_history: List[UserSubscription] = []
        self._load_default_subscriptions()
    
    def _load_default_subscriptions(self):
        """Load default subscription products"""
        
        # IEI Club Subscription
        iei_benefits = [
            Benefit(
                id="iei_hotel_discount",
                name="Hotel Discount",
                description="30% discount on hotel bookings at partner properties",
                discount_percentage=30,
                category="hotel",
                applicable_merchants=["Marriott", "Hilton", "Radisson"],
                valid_at_locations=["Nationwide"]
            ),
            Benefit(
                id="iei_dining_discount",
                name="Dining Rewards",
                description="20% cashback on dining at premium restaurants",
                discount_percentage=20,
                category="dining",
                applicable_merchants=["Premium Restaurants"],
                valid_at_locations=["Major Cities"]
            ),
            Benefit(
                id="iei_travel_credit",
                name="Annual Travel Credit",
                description="$500 annual travel credit for flights and accommodations",
                discount_percentage=0,
                category="travel",
                applicable_merchants=["Airlines", "Hotels"],
                terms="Redeemable on flights, hotels, and car rentals"
            )
        ]
        
        iei = Subscription(
            id="sub_iei_001",
            name="IEI Club Premium",
            description="Professional networking with exclusive travel and hospitality benefits. Perfect for corporate professionals.",
            price=299.99,
            tier=SubscriptionTier.PREMIUM,
            features=[
                "30% Hotel Discount",
                "20% Dining Rewards",
                "$500 Travel Credit",
                "Priority Customer Support",
                "Geofence Notifications",
                "Mobile App Access"
            ],
            benefits=iei_benefits,
            icon="🏢",
            color="#3498db",
            logo="/images/ndl_logo.png"
        )
        
        # IEEE Membership
        ieee_benefits = [
            Benefit(
                id="ieee_conference_discount",
                name="Conference Discounts",
                description="25% discount on IEEE conference registrations",
                discount_percentage=25,
                category="education",
                applicable_merchants=["IEEE Events"],
            ),
            Benefit(
                id="ieee_journal_access",
                name="Journal Access",
                description="Unlimited access to IEEE publications and research papers",
                discount_percentage=0,
                category="education",
                applicable_merchants=["IEEE Digital Library"],
                terms="Valid for 1 year of membership"
            ),
            Benefit(
                id="ieee_hotel_discount",
                name="Hotel Discounts",
                description="25% discount on hotel stays for conferences and events",
                discount_percentage=25,
                category="hotel",
                applicable_merchants=["Partner Hotels"],
            ),
            Benefit(
                id="ieee_training",
                name="Professional Training",
                description="Access to online courses and certifications",
                discount_percentage=50,
                category="education",
                applicable_merchants=["IEEE Learning"],
                terms="Includes AWS, cloud computing, and AI/ML courses"
            )
        ]
        
        ieee = Subscription(
            id="sub_ieee_001",
            name="IEEE Membership Plus",
            description="Professional technical membership with unlimited access to research, conferences, and career resources.",
            price=199.99,
            tier=SubscriptionTier.BASIC,
            features=[
                "25% Conference Discounts",
                "Unlimited Journal Access",
                "25% Hotel Discounts",
                "50% Training Discounts",
                "Career Development Tools",
                "Member Community Access"
            ],
            benefits=ieee_benefits,
            icon="🔬",
            color="#e74c3c",
            logo="/images/ieee_logo.svg"
        )
        
        # National Library Membership
        library_benefits = [
            Benefit(
                id="library_ebook_access",
                name="eBook Access",
                description="Unlimited access to 2 million ebooks and audiobooks",
                discount_percentage=0,
                category="education",
                applicable_merchants=["National Library"],
                terms="Available 24/7 on all devices"
            ),
            Benefit(
                id="library_cafe_discount",
                name="Cafe Discount",
                description="15% discount at library cafe for members",
                discount_percentage=15,
                category="dining",
                applicable_merchants=["Library Cafes"],
            ),
            Benefit(
                id="library_event_discount",
                name="Event Tickets",
                description="40% discount on literary events and author readings",
                discount_percentage=40,
                category="entertainment",
                applicable_merchants=["Library Events"],
            ),
            Benefit(
                id="library_vip_parking",
                name="VIP Parking",
                description="Free valet parking for premium members",
                discount_percentage=0,
                category="parking",
                applicable_merchants=["All Branches"],
                terms="Valid at all 15 library locations"
            )
        ]
        
        library = Subscription(
            id="sub_library_001",
            name="National Library Elite",
            description="Premium library membership with unlimited digital and physical access, plus exclusive perks.",
            price=149.99,
            tier=SubscriptionTier.ELITE,
            features=[
                "Unlimited eBook Access",
                "15% Cafe Discount",
                "40% Event Discounts",
                "Free VIP Parking",
                "Priority Reservations",
                "Exclusive Member Events",
                "Family Account (4 people)"
            ],
            benefits=library_benefits,
            icon="📚",
            color="#27ae60",
            logo="/images/iei_logo.png"
        )
        
        # Store subscriptions
        self.subscriptions[iei.id] = iei
        self.subscriptions[ieee.id] = ieee
        self.subscriptions[library.id] = library
    
    def get_subscription(self, subscription_id: str) -> Optional[Subscription]:
        """Get subscription by ID"""
        return self.subscriptions.get(subscription_id)
    
    def list_subscriptions(self, tier: SubscriptionTier = None) -> List[Subscription]:
        """
        List all subscriptions, optionally filtered by tier
        
        Args:
            tier: Optional tier to filter by
        
        Returns:
            List of subscriptions
        """
        subs = list(self.subscriptions.values())
        
        if tier:
            subs = [s for s in subs if s.tier == tier]
        
        return sorted(subs, key=lambda s: s.price)
    
    def purchase_subscription(self, user_id: str, subscription_id: str, promo_code: str = None) -> tuple[bool, str, Optional[UserSubscription]]:
        """
        Purchase subscription for user
        
        Args:
            user_id: User purchasing
            subscription_id: Subscription to purchase
            promo_code: Optional promo code for discount
        
        Returns:
            (success, message, user_subscription)
        """
        subscription = self.get_subscription(subscription_id)
        
        if not subscription:
            return False, "Subscription not found", None
        
        # Calculate price (apply promo if needed)
        price = subscription.price
        
        # Create user subscription
        purchase_id = str(uuid.uuid4())[:8]
        now = datetime.now()
        start_date = now
        expiry_date = now + timedelta(days=subscription.renewal_interval)
        renewal_date = expiry_date
        
        user_sub = UserSubscription(
            id=purchase_id,
            user_id=user_id,
            subscription_id=subscription_id,
            subscription_name=subscription.name,
            purchase_date=now,
            start_date=start_date,
            expiry_date=expiry_date,
            renewal_date=renewal_date,
            price_paid=price,
            status="active"
        )
        
        # Store purchase
        if user_id not in self.user_subscriptions:
            self.user_subscriptions[user_id] = []
        
        self.user_subscriptions[user_id].append(user_sub)
        self.purchase_history.append(user_sub)
        
        return True, f"Subscription '{subscription.name}' purchased successfully", user_sub
    
    def get_user_subscriptions(self, user_id: str) -> List[UserSubscription]:
        """Get all subscriptions for a user"""
        return self.user_subscriptions.get(user_id, [])
    
    def get_active_subscriptions(self, user_id: str) -> List[UserSubscription]:
        """Get active subscriptions for a user"""
        subs = self.get_user_subscriptions(user_id)
        return [s for s in subs if s.is_active()]
    
    def get_expired_subscriptions(self, user_id: str) -> List[UserSubscription]:
        """Get expired subscriptions for a user"""
        subs = self.get_user_subscriptions(user_id)
        return [s for s in subs if not s.is_active()]
    
    def activate_geofencing(self, user_id: str, subscription_id: str, locations: List[str] = None) -> tuple[bool, str]:
        """
        Activate geofencing for user subscription
        
        Args:
            user_id: User ID
            subscription_id: UserSubscription ID (purchase ID)
            locations: Specific locations to monitor (optional)
        
        Returns:
            (success, message)
        """
        subs = self.get_user_subscriptions(user_id)
        user_sub = next((s for s in subs if s.id == subscription_id), None)
        
        if not user_sub:
            return False, "Subscription not found"
        
        if not user_sub.is_active():
            return False, "Subscription is not active"
        
        user_sub.geofence_active = True
        user_sub.geofence_locations = locations or []
        
        return True, "Geofencing activated for your subscription"
    
    def get_subscription_benefits(self, user_id: str, subscription_id: str) -> List[Benefit]:
        """
        Get ava ilable benefits for user's subscription
        
        Args:
            user_id: User ID
            subscription_id: UserSubscription ID
        
        Returns:
            List of benefits
        """
        subs = self.get_user_subscriptions(user_id)
        user_sub = next((s for s in subs if s.id == subscription_id), None)
        
        if not user_sub or not user_sub.is_active():
            return []
        
        subscription = self.get_subscription(user_sub.subscription_id)
        return subscription.benefits if subscription else []
    
    def get_statistics(self) -> Dict:
        """Get subscription statistics"""
        total_purchased = len(self.purchase_history)
        active_purchases = sum(1 for s in self.purchase_history if s.is_active())
        total_revenue = sum(s.price_paid for s in self.purchase_history)
        
        purchases_by_subscription = {}
        for sub in self.purchase_history:
            purchases_by_subscription[sub.subscription_name] = \
                purchases_by_subscription.get(sub.subscription_name, 0) + 1
        
        return {
            "total_subscriptions_offered": len(self.subscriptions),
            "total_purchases": total_purchased,
            "active_purchases": active_purchases,
            "total_revenue": total_revenue,
            "avg_purchase_value": total_revenue / total_purchased if total_purchased > 0 else 0,
            "purchases_by_subscription": purchases_by_subscription,
            "geofence_enabled": sum(1 for s in self.purchase_history if s.geofence_active)
        }

# Create singleton instance
subscription_manager = SubscriptionManager()
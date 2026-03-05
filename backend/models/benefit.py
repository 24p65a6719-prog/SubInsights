"""
Benefit model - represents individual perks and discounts
"""
from dataclasses import dataclass, field
from typing import List, Dict
from datetime import datetime


@dataclass
class Benefit:
    """
    Represents a single benefit/perk from a membership
    
    Attributes:
        id: Unique benefit identifier
        membership_id: Associated membership
        title: Benefit name (e.g., "Hotel Discount", "Travel Incentive")
        description: Detailed description of the benefit
        discount_percent: Discount percentage (0-100)
        merchant_categories: Types of merchants offering this benefit
        eligible_merchants: Specific merchant IDs offering this benefit
        expiry_date: When the benefit offer expires
        is_verified: Whether sentiment analysis confirmed it's active
        verification_score: BERT sentiment confidence (0-1)
        last_verification: When was it last verified
        geofencing_radius: Radius in meters for geofencing alerts
    """
    id: str
    membership_id: str
    title: str
    description: str
    discount_percent: float
    merchant_categories: List[str]  # e.g., ["hotel", "restaurant", "travel"]
    eligible_merchants: List[str] = field(default_factory=list)
    expiry_date: datetime = None
    is_verified: bool = False
    verification_score: float = 0.0  # BERT confidence
    last_verification: datetime = None
    geofencing_radius: float = 1000.0  # meters
    
    def is_expired(self) -> bool:
        """Check if benefit offer has expired"""
        if self.expiry_date is None:
            return False
        return datetime.now() > self.expiry_date
    
    def get_verification_status(self) -> str:
        """Get human-readable verification status"""
        if not self.is_verified:
            return "Not Verified"
        elif self.verification_score > 0.8:
            return "Highly Verified"
        elif self.verification_score > 0.6:
            return "Moderately Verified"
        else:
            return "Weakly Verified"

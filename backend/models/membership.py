"""
Membership model - represents user's subscriptions and memberships
"""
from dataclasses import dataclass, field
from typing import List, Dict
from datetime import datetime


@dataclass
class Membership:
    """
    Represents a user's membership or subscription
    
    Attributes:
        id: Unique membership identifier
        name: Name of membership (e.g., "IEEE", "IEI", "American Express Platinum")
        category: Type of membership (professional, credit_card, lifestyle)
        user_id: Associated user
        start_date: When membership started
        end_date: When membership expires
        is_active: Whether membership is currently valid
        associated_benefits: List of benefit IDs linked to this membership
    """
    id: str
    name: str
    category: str  # "professional", "credit_card", "lifestyle"
    user_id: str
    start_date: datetime
    end_date: datetime
    is_active: bool = True
    associated_benefits: List[str] = field(default_factory=list)
    
    def is_expired(self) -> bool:
        """Check if membership has expired"""
        return datetime.now() > self.end_date
    
    def days_until_expiry(self) -> int:
        """Calculate days remaining until expiration"""
        delta = self.end_date - datetime.now()
        return delta.days

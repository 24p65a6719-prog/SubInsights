"""
Merchant model - represents businesses offering benefits
"""
from dataclasses import dataclass, field
from typing import List, Tuple
from datetime import datetime


@dataclass
class Location:
    """GPS coordinates"""
    latitude: float
    longitude: float
    
    def distance_to(self, other: 'Location') -> float:
        """Calculate distance to another location in kilometers (haversine formula)"""
        from math import radians, cos, sin, asin, sqrt
        
        lon1, lat1, lon2, lat2 = map(radians, [
            self.longitude, self.latitude, 
            other.longitude, other.latitude
        ])
        dlon = lon2 - lon1
        dlat = lat2 - lat1
        a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
        c = 2 * asin(sqrt(a))
        km = 6371 * c
        return km


@dataclass
class Merchant:
    """
    Represents a business location offering membership benefits
    
    Attributes:
        id: Unique merchant identifier
        name: Business name
        category: Type of business (hotel, restaurant, retail, etc.)
        location: GPS coordinates
        address: Physical address
        phone: Contact number
        website: Business website
        benefits_offered: List of benefit IDs offered by this merchant
        average_review_rating: Customer rating (0-5)
        total_reviews: Total number of reviews
        is_active: Whether merchant is currently honoring membership benefits
        last_sentiment_check: When reviews were last analyzed by BERT
    """
    id: str
    name: str
    category: str
    location: Location
    address: str
    phone: str = ""
    website: str = ""
    benefits_offered: List[str] = field(default_factory=list)
    average_review_rating: float = 0.0
    total_reviews: int = 0
    is_active: bool = True
    last_sentiment_check: datetime = None
    
    def distance_to(self, user_location: Location) -> float:
        """Calculate distance to user in kilometers"""
        return self.location.distance_to(user_location)

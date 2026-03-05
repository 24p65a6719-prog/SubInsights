"""
Hotel Management Module
Handles hotel data, ratings, reviews, and location information
"""
from dataclasses import dataclass, field
from typing import List, Dict, Optional, Tuple
from datetime import datetime
import uuid


@dataclass
class Review:
    """User review for a hotel/location"""
    id: str
    user_name: str
    rating: float  # 1-5 stars
    comment: str
    date: datetime
    reviewer_verified: bool = True


@dataclass
class Hotel:
    """
    Hotel/Restaurant location for subscription benefits
    
    Attributes:
        id: Unique hotel ID
        name: Hotel name
        description: Brief description
        category: Type (hotel, restaurant, cafe, etc.)
        latitude: GPS latitude
        longitude: GPS longitude
        address: Physical address
        phone: Contact number
        website: Official website
        rating: Average rating (1-5 stars)
        review_count: Number of reviews
        reviews: List of Review objects
        amenities: List of amenities/features
        subscription_benefits: List of applicable subscription benefits
        geofence_radius_km: Geofencing radius in kilometers
        opening_hours: Operating hours
        image_url: Hotel image URL
    """
    id: str
    name: str
    description: str
    category: str
    latitude: float
    longitude: float
    address: str
    phone: str
    website: str
    rating: float = 0.0
    review_count: int = 0
    reviews: List[Review] = field(default_factory=list)
    amenities: List[str] = field(default_factory=list)
    subscription_benefits: List[str] = field(default_factory=list)
    geofence_radius_km: float = 0.5
    opening_hours: str = "24/7"
    image_url: str = ""
    
    def add_review(self, user_name: str, rating: float, comment: str) -> Review:
        """Add a review to the hotel"""
        review_id = str(uuid.uuid4())[:8]
        review = Review(
            id=review_id,
            user_name=user_name,
            rating=rating,
            comment=comment,
            date=datetime.now()
        )
        self.reviews.append(review)
        
        # Update average rating
        self._update_rating()
        return review
    
    def _update_rating(self):
        """Recalculate average rating"""
        if not self.reviews:
            self.rating = 0.0
            self.review_count = 0
        else:
            self.rating = sum(r.rating for r in self.reviews) / len(self.reviews)
            self.review_count = len(self.reviews)
    
    def to_dict(self) -> Dict:
        """Convert to dictionary for API/JSON"""
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "category": self.category,
            "latitude": self.latitude,
            "longitude": self.longitude,
            "address": self.address,
            "phone": self.phone,
            "website": self.website,
            "rating": round(self.rating, 1),
            "review_count": self.review_count,
            "amenities": self.amenities,
            "subscription_benefits": self.subscription_benefits,
            "geofence_radius_km": self.geofence_radius_km,
            "opening_hours": self.opening_hours,
            "image_url": self.image_url
        }


class HotelManager:
    """
    Manages hotels, ratings, reviews, and geolocation data
    """
    
    def __init__(self):
        """Initialize hotel manager"""
        self.hotels: Dict[str, Hotel] = {}  # id -> Hotel
        self.hotels_by_name: Dict[str, Hotel] = {}  # name -> Hotel
        self._load_sample_hotels()
    
    def _load_sample_hotels(self):
        """Load sample hotel data"""
        
        # Marriott Hotels
        marriott = Hotel(
            id="hotel_marriott_001",
            name="Marriott Hotels & Resorts",
            description="Luxury hotel chain with premium amenities and world-class service",
            category="hotel",
            latitude=40.7580,
            longitude=-73.9855,
            address="1535 Broadway, New York, NY 10036",
            phone="+1-800-228-9290",
            website="https://www.marriott.com",
            geofence_radius_km=1.0,
            opening_hours="24/7",
            amenities=[
                "Free WiFi",
                "Fitness Center",
                "Swimming Pool",
                "Room Service",
                "Business Center",
                "Spa & Wellness",
                "Restaurant & Bar",
                "Concierge"
            ],
            subscription_benefits=[
                "30% Hotel Discount (IEI)",
                "25% Hotel Discount (IEEE)"
            ],
            image_url="https://example.com/marriott.jpg"
        )
        
        # Add sample reviews
        marriott.add_review("John D.", 5.0, "Excellent service and pristine rooms. Highly recommended!")
        marriott.add_review("Sarah M.", 4.5, "Great location, comfortable beds, friendly staff")
        marriott.add_review("Mike T.", 4.8, "Best hotel experience ever, will come back")
        marriott.add_review("Emma W.", 5.0, "Outstanding! Everything was perfect")
        
        # Hilton Hotels
        hilton = Hotel(
            id="hotel_hilton_001",
            name="Hilton Hotels & Resorts",
            description="International hotel brand known for comfort and consistency",
            category="hotel",
            latitude=40.7489,
            longitude=-73.9680,
            address="1250 Avenue of the Americas, New York, NY 10020",
            phone="+1-800-445-8667",
            website="https://www.hilton.com",
            geofence_radius_km=0.8,
            opening_hours="24/7",
            amenities=[
                "Free WiFi",
                "Gym",
                "Restaurant",
                "Bar",
                "Meeting Rooms",
                "Laundry Service",
                "24-Hour Reception",
                "Coffee Shop"
            ],
            subscription_benefits=[
                "30% Hotel Discount (IEI)",
                "25% Hotel Discount (IEEE)"
            ],
            image_url="https://example.com/hilton.jpg"
        )
        
        hilton.add_review("Alex K.", 4.2, "Good value for money, convenient location")
        hilton.add_review("Lisa P.", 4.6, "Clean rooms, helpful staff, nice amenities")
        hilton.add_review("Robert H.", 4.3, "Comfortable stay, reasonable prices")
        
        # Premium Restaurant
        restaurant = Hotel(
            id="hotel_restaurant_001",
            name="Le Bernardin Fine Dining",
            description="Award-winning French seafood restaurant with Michelin stars",
            category="restaurant",
            latitude=40.7631,
            longitude=-73.9776,
            address="155 W 51st St, New York, NY 10019",
            phone="+1-212-554-1515",
            website="https://www.le-bernardin.com",
            geofence_radius_km=0.3,
            opening_hours="12:00 PM - 10:30 PM",
            amenities=[
                "Michelin Star",
                "Fine Dining",
                "Wine Selection",
                "Private Dining",
                "Chef's Table",
                "Sommelier Service",
                "Valeted Parking"
            ],
            subscription_benefits=[
                "20% Dining Rewards (IEI)",
                "15% Cafe Discount (Library)"
            ],
            image_url="https://example.com/lebernadin.jpg"
        )
        
        restaurant.add_review("Thomas L.", 5.0, "Incredible food and impeccable service. Worth every penny!")
        restaurant.add_review("Catherine R.", 5.0, "Best dining experience of my life")
        restaurant.add_review("David M.", 4.9, "Exceptional cuisine, unforgettable evening")
        
        # National Library
        library = Hotel(
            id="location_library_001",
            name="National Central Library",
            description="Premier public library with 2+ million books and digital resources",
            category="library",
            latitude=40.7532,
            longitude=-73.9822,
            address="476 5th Ave, New York, NY 10018",
            phone="+1-212-930-0800",
            website="https://www.library.org",
            geofence_radius_km=0.5,
            opening_hours="10:00 AM - 6:00 PM",
            amenities=[
                "Digital Library",
                "Reading Rooms",
                "Research Database",
                "Cafe",
                "Events Hall",
                "Computer Lab",
                "Rare Collections",
                "WiFi"
            ],
            subscription_benefits=[
                "Unlimited eBook Access (National Library)",
                "40% Event Discount (National Library)",
                "15% Cafe Discount (National Library)"
            ],
            image_url="https://example.com/library.jpg"
        )
        
        library.add_review("Patricia S.", 4.8, "Amazing collection, great atmosphere for studying")
        library.add_review("Kevin T.", 4.6, "Excellent resources and helpful librarians")
        library.add_review("Monica J.", 4.7, "Perfect place for research and learning")
        
        # Add hotels to manager
        for hotel in [marriott, hilton, restaurant, library]:
            self.hotels[hotel.id] = hotel
            self.hotels_by_name[hotel.name.lower()] = hotel
    
    def get_hotel(self, hotel_id: str) -> Optional[Hotel]:
        """Get hotel by ID"""
        return self.hotels.get(hotel_id)
    
    def get_hotel_by_name(self, name: str) -> Optional[Hotel]:
        """Get hotel by name"""
        return self.hotels_by_name.get(name.lower())
    
    def search_hotels(self, query: str = "") -> List[Hotel]:
        """Search hotels by name or description"""
        if not query:
            return list(self.hotels.values())
        
        query_lower = query.lower()
        return [
            h for h in self.hotels.values()
            if query_lower in h.name.lower() or query_lower in h.description.lower()
        ]
    
    def get_hotels_by_category(self, category: str) -> List[Hotel]:
        """Get all hotels of a specific category"""
        return [h for h in self.hotels.values() if h.category.lower() == category.lower()]
    
    def get_nearby_hotels(self, latitude: float, longitude: float, radius_km: float = 10) -> List[Tuple[Hotel, float]]:
        """
        Get nearby hotels within radius
        
        Args:
            latitude: User's latitude
            longitude: User's longitude
            radius_km: Search radius in kilometers
        
        Returns:
            List of (hotel, distance_km) tuples sorted by distance
        """
        from math import radians, cos, sin, asin, sqrt
        
        def haversine_distance(lat1, lon1, lat2, lon2):
            """Calculate distance between two coordinates in km"""
            lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
            dlon = lon2 - lon1
            dlat = lat2 - lat1
            a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
            c = 2 * asin(sqrt(a))
            km = 6371 * c
            return km
        
        nearby = []
        for hotel in self.hotels.values():
            distance = haversine_distance(latitude, longitude, hotel.latitude, hotel.longitude)
            if distance <= radius_km:
                nearby.append((hotel, round(distance, 2)))
        
        # Sort by distance
        return sorted(nearby, key=lambda x: x[1])
    
    def add_review(self, hotel_id: str, user_name: str, rating: float, comment: str) -> Tuple[bool, str]:
        """Add a review to a hotel"""
        hotel = self.get_hotel(hotel_id)
        
        if not hotel:
            return False, "Hotel not found"
        
        if rating < 1 or rating > 5:
            return False, "Rating must be between 1 and 5"
        
        if not comment:
            return False, "Comment is required"
        
        hotel.add_review(user_name, rating, comment)
        return True, "Review added successfully"
    
    def get_hotel_reviews(self, hotel_id: str) -> List[Review]:
        """Get all reviews for a hotel"""
        hotel = self.get_hotel(hotel_id)
        return hotel.reviews if hotel else []
    
    def get_hotels_with_benefit(self, benefit_name: str) -> List[Hotel]:
        """Get all hotels that offer a specific benefit"""
        return [
            h for h in self.hotels.values()
            if any(benefit_name.lower() in b.lower() for b in h.subscription_benefits)
        ]
    
    def get_statistics(self) -> Dict:
        """Get hotel statistics"""
        total_hotels = len(self.hotels)
        total_reviews = sum(len(h.reviews) for h in self.hotels.values())
        avg_rating = sum(h.rating for h in self.hotels.values()) / total_hotels if total_hotels > 0 else 0
        
        by_category = {}
        for hotel in self.hotels.values():
            by_category[hotel.category] = by_category.get(hotel.category, 0) + 1
        
        return {
            "total_hotels": total_hotels,
            "total_reviews": total_reviews,
            "average_rating": round(avg_rating, 1),
            "hotels_by_category": by_category
        }

# Create singleton instance
hotel_manager = HotelManager()
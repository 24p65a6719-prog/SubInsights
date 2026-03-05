"""
Location Service
Handles user location tracking and position updates
"""
from typing import Optional, Dict, List
from datetime import datetime
from backend.models.merchant import Location


class LocationService:
    """
    Manages user location data and position history
    
    In production, would integrate with:
    - OS location APIs (iOS/Android)
    - GPS/WiFi/Cell triangulation
    - Privacy-preserving location sharing
    """
    
    def __init__(self):
        """Initialize location service"""
        self.user_current_location: Dict[str, Location] = {}
        self.location_history: Dict[str, List[Dict]] = {}
        self.geofence_subscriptions: Dict[str, List[str]] = {}  # user -> [merchant_ids]
        
    def update_user_location(self, 
                            user_id: str, 
                            latitude: float, 
                            longitude: float) -> Location:
        """
        Update user's current location
        
        Args:
            user_id: User identifier
            latitude: Current latitude
            longitude: Current longitude
            
        Returns:
            Updated Location object
        """
        location = Location(latitude, longitude)
        
        # Store current location
        self.user_current_location[user_id] = location
        
        # Store in history
        if user_id not in self.location_history:
            self.location_history[user_id] = []
            
        self.location_history[user_id].append({
            "timestamp": datetime.now().isoformat(),
            "latitude": latitude,
            "longitude": longitude
        })
        
        return location
        
    def get_user_location(self, user_id: str) -> Optional[Location]:
        """Get user's last known location"""
        return self.user_current_location.get(user_id)
        
    def get_location_history(self, user_id: str, limit: int = 100) -> List[Dict]:
        """Get user's location history"""
        history = self.location_history.get(user_id, [])
        return history[-limit:]
        
    def calculate_distance(self, 
                          user_id: str, 
                          target_location: Location) -> Optional[float]:
        """
        Calculate distance from user to target location
        
        Args:
            user_id: User identifier
            target_location: Target Location object
            
        Returns:
            Distance in kilometers, or None if user location unknown
        """
        user_loc = self.get_user_location(user_id)
        if not user_loc:
            return None
            
        return user_loc.distance_to(target_location)
        
    def subscribe_to_geofence(self, user_id: str, merchant_id: str) -> None:
        """Subscribe user to geofence notifications for a merchant"""
        if user_id not in self.geofence_subscriptions:
            self.geofence_subscriptions[user_id] = []
            
        if merchant_id not in self.geofence_subscriptions[user_id]:
            self.geofence_subscriptions[user_id].append(merchant_id)
            print(f"[Location] Subscribed {user_id} to geofence for merchant {merchant_id}")
            
    def unsubscribe_from_geofence(self, user_id: str, merchant_id: str) -> None:
        """Unsubscribe user from geofence notifications"""
        if user_id in self.geofence_subscriptions:
            try:
                self.geofence_subscriptions[user_id].remove(merchant_id)
                print(f"[Location] Unsubscribed {user_id} from merchant {merchant_id}")
            except ValueError:
                pass
                
    def get_user_subscriptions(self, user_id: str) -> List[str]:
        """Get list of merchants user is subscribed to"""
        return self.geofence_subscriptions.get(user_id, [])
        
    def get_stats(self, user_id: str) -> Dict:
        """Get location tracking statistics"""
        history = self.location_history.get(user_id, [])
        
        return {
            "tracked_since": history[0]["timestamp"] if history else None,
            "total_updates": len(history),
            "subscribed_merchants": len(self.get_user_subscriptions(user_id)),
            "last_update": history[-1]["timestamp"] if history else None
        }

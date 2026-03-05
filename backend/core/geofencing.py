"""
Geofencing Engine - OS-level background location monitoring
Detects when user enters proximity zones of benefit merchants
"""
import threading
import time
from typing import List, Callable, Dict, Optional
from datetime import datetime
import json
from backend.models.merchant import Location, Merchant
from backend.models.detection import GeofenceEvent


class GeofencingEngine:
    """
    Manages real-time geofence monitoring with background thread support
    
    How it works:
    1. User's current location is continuously monitored
    2. When entering merchant geofence radius, triggers callback
    3. Checks which benefits are available at that merchant
    4. Generates geofence events for alert system
    """
    
    def __init__(self, update_interval: float = 5.0):
        """
        Initialize geofencing engine
        
        Args:
            update_interval: How often to check location (seconds)
        """
        self.update_interval = update_interval
        self.is_running = False
        self.current_location: Optional[Location] = None
        self.active_merchants: Dict[str, Merchant] = {}
        self.user_inside_geofence: Dict[str, bool] = {}  # merchant_id -> bool
        self.callbacks: List[Callable] = []  # Callback functions for events
        self.monitor_thread = None
        self.detected_events: List[GeofenceEvent] = []
        
    def add_merchant(self, merchant: Merchant) -> None:
        """Add a merchant to monitor"""
        self.active_merchants[merchant.id] = merchant
        self.user_inside_geofence[merchant.id] = False
        
    def add_event_callback(self, callback: Callable) -> None:
        """Register callback function for geofence events"""
        self.callbacks.append(callback)
        
    def update_user_location(self, latitude: float, longitude: float) -> None:
        """
        Update user's current GPS position
        
        Args:
            latitude: User's latitude
            longitude: User's longitude
        """
        self.current_location = Location(latitude, longitude)
        
    def start_monitoring(self) -> None:
        """Start background geofence monitoring thread"""
        if self.is_running:
            return
            
        self.is_running = True
        self.monitor_thread = threading.Thread(
            target=self._monitor_loop,
            daemon=True,
            name="GeofenceMonitor"
        )
        self.monitor_thread.start()
        print("[Geofence] Background monitoring started")
        
    def stop_monitoring(self) -> None:
        """Stop background monitoring"""
        self.is_running = False
        if self.monitor_thread:
            self.monitor_thread.join(timeout=5)
        print("[Geofence] Background monitoring stopped")
        
    def _monitor_loop(self) -> None:
        """Main monitoring loop running in background thread"""
        while self.is_running:
            if self.current_location:
                self._check_geofences()
            time.sleep(self.update_interval)
            
    def _check_geofences(self) -> None:
        """Check all merchants for geofence entry/exit"""
        for merchant_id, merchant in self.active_merchants.items():
            distance_km = merchant.distance_to(self.current_location)
            distance_m = distance_km * 1000
            
            # Check if user is within geofence
            user_in_range = distance_m <= 1000  # 1km radius
            was_in_range = self.user_inside_geofence.get(merchant_id, False)
            
            # Geofence ENTRY
            if user_in_range and not was_in_range:
                self._handle_geofence_entry(merchant)
                self.user_inside_geofence[merchant_id] = True
                
            # Geofence EXIT
            elif not user_in_range and was_in_range:
                self._handle_geofence_exit(merchant)
                self.user_inside_geofence[merchant_id] = False
                
    def _handle_geofence_entry(self, merchant: Merchant) -> None:
        """Handle user entering merchant geofence"""
        print(f"\n[Geofence] ENTRY DETECTED: {merchant.name}")
        print(f"  - Category: {merchant.category}")
        print(f"  - Available benefits: {len(merchant.benefits_offered)}")
        
        # Create geofence event
        event = GeofenceEvent(
            id=f"evt_{int(time.time())}",
            user_id="current_user",  # Would come from auth
            merchant_id=merchant.id,
            benefits_detected=merchant.benefits_offered,
            entry_time=datetime.now(),
            location_at_entry=self.current_location
        )
        
        self.detected_events.append(event)
        
        # Trigger callbacks
        for callback in self.callbacks:
            try:
                callback(event_type="entry", merchant=merchant, event=event)
            except Exception as e:
                print(f"[Geofence] Callback error: {e}")
                
    def _handle_geofence_exit(self, merchant: Merchant) -> None:
        """Handle user exiting merchant geofence"""
        print(f"\n[Geofence] EXIT DETECTED: {merchant.name}")
        
        # Update last event
        for event in reversed(self.detected_events):
            if event.merchant_id == merchant.id and event.exit_time is None:
                event.exit_time = datetime.now()
                break
                
        # Trigger callbacks
        for callback in self.callbacks:
            try:
                callback(event_type="exit", merchant=merchant, event=None)
            except Exception as e:
                print(f"[Geofence] Callback error: {e}")
                
    def get_nearby_merchants(self, radius_km: float = 5.0) -> List[Merchant]:
        """
        Get merchants within specified radius of current location
        
        Args:
            radius_km: Search radius in kilometers
            
        Returns:
            List of nearby merchants sorted by distance
        """
        if not self.current_location:
            return []
            
        nearby = []
        for merchant in self.active_merchants.values():
            distance = merchant.distance_to(self.current_location)
            if distance <= radius_km:
                nearby.append((merchant, distance))
                
        # Sort by distance
        nearby.sort(key=lambda x: x[1])
        return [m for m, _ in nearby]

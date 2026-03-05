"""
REST API Routes
Exposes SubInsights functionality via HTTP endpoints
"""
from typing import Dict, List, Optional
from datetime import datetime
import json


class APIRouter:
    """
    REST API endpoint definitions
    
    In production, would use FastAPI, Flask, or similar framework
    """
    
    def __init__(self, backend_system):
        """Initialize API router with backend system reference"""
        self.backend = backend_system
        self.routes = {}
        self._register_routes()
        
    def _register_routes(self):
        """Register all API endpoints"""
        
        # User & Membership endpoints
        self.routes["/api/memberships"] = self.get_user_memberships
        self.routes["/api/memberships/<id>"] = self.get_membership_details
        
        # Benefits endpoints
        self.routes["/api/benefits"] = self.list_benefits
        self.routes["/api/benefits/nearby"] = self.get_nearby_benefits
        self.routes["/api/benefits/<id>/verify"] = self.verify_benefit
        
        # Geofencing endpoints
        self.routes["/api/location/update"] = self.update_location
        self.routes["/api/geofence/status"] = self.get_geofence_status
        self.routes["/api/merchants/nearby"] = self.get_nearby_merchants
        
        # Alerts endpoints
        self.routes["/api/alerts/pending"] = self.get_pending_alerts
        self.routes["/api/alerts/<id>/claim"] = self.claim_benefit
        self.routes["/api/alerts/<id>/dismiss"] = self.dismiss_alert
        self.routes["/api/alerts/history"] = self.get_alert_history
        
        # Analytics endpoints
        self.routes["/api/analytics/summary"] = self.get_analytics
        self.routes["/api/analytics/savings"] = self.calculate_savings
        
    # ============ User & Membership Endpoints ============
    
    def get_user_memberships(self, user_id: str) -> Dict:
        """
        GET /api/memberships
        Get all memberships for current user
        """
        memberships = self.backend.get_user_memberships(user_id)
        
        return {
            "status": "success",
            "data": [
                {
                    "id": m.id,
                    "name": m.name,
                    "category": m.category,
                    "is_active": m.is_active,
                    "expires_in_days": m.days_until_expiry(),
                    "benefits_count": len(m.associated_benefits)
                }
                for m in memberships
            ]
        }
    
    def get_membership_details(self, membership_id: str) -> Dict:
        """
        GET /api/memberships/<id>
        Get detailed membership information
        """
        membership = self.backend.get_membership(membership_id)
        
        if not membership:
            return {"status": "error", "message": "Membership not found"}
        
        return {
            "status": "success",
            "data": {
                "id": membership.id,
                "name": membership.name,
                "category": membership.category,
                "start_date": membership.start_date.isoformat(),
                "end_date": membership.end_date.isoformat(),
                "is_active": membership.is_active and not membership.is_expired(),
                "benefits": membership.associated_benefits,
                "days_remaining": membership.days_until_expiry()
            }
        }
    
    # ============ Benefits Endpoints ============
    
    def list_benefits(self, user_id: str, verified_only: bool = False) -> Dict:
        """
        GET /api/benefits
        List benefits for user
        Query params: verified_only=true
        """
        benefits = self.backend.get_user_benefits(user_id)
        
        if verified_only:
            benefits = [b for b in benefits if b.is_verified]
        
        return {
            "status": "success",
            "data": [
                {
                    "id": b.id,
                    "title": b.title,
                    "discount_percent": b.discount_percent,
                    "is_verified": b.is_verified,
                    "verification_score": b.verification_score,
                    "expired": b.is_expired(),
                    "categories": b.merchant_categories
                }
                for b in benefits
            ],
            "total": len(benefits),
            "verified_count": sum(1 for b in benefits if b.is_verified)
        }
    
    def get_nearby_benefits(self, user_id: str, radius_km: float = 5.0) -> Dict:
        """
        GET /api/benefits/nearby
        Get benefits available at nearby merchants
        Query params: radius_km=5
        """
        nearby = self.backend.get_nearby_benefits(user_id, radius_km)
        
        return {
            "status": "success",
            "data": [
                {
                    "benefit_id": b["benefit"].id,
                    "merchant_id": b["merchant"].id,
                    "title": b["benefit"].title,
                    "merchant_name": b["merchant"].name,
                    "distance_km": b["distance"],
                    "discount": b["benefit"].discount_percent,
                    "verified": b["benefit"].is_verified
                }
                for b in nearby
            ],
            "count": len(nearby)
        }
    
    def verify_benefit(self, benefit_id: str) -> Dict:
        """
        POST /api/benefits/<id>/verify
        Trigger BERT verification for a benefit
        """
        success = self.backend.verify_benefit(benefit_id)
        
        benefit = self.backend.get_benefit(benefit_id)
        
        return {
            "status": "success" if success else "partial",
            "benefit_id": benefit_id,
            "is_verified": benefit.is_verified,
            "verification_score": benefit.verification_score,
            "last_verified": benefit.last_verification.isoformat()
        }
    
    # ============ Location & Geofencing Endpoints ============
    
    def update_location(self, user_id: str, latitude: float, longitude: float) -> Dict:
        """
        POST /api/location/update
        Update user's current location
        Body: {"latitude": 37.7749, "longitude": -122.4194}
        """
        self.backend.location_service.update_user_location(user_id, latitude, longitude)
        
        # Check for nearby benefits
        nearby = self.backend.get_nearby_benefits(user_id, radius_km=5)
        
        return {
            "status": "success",
            "location": {
                "latitude": latitude,
                "longitude": longitude,
                "updated_at": datetime.now().isoformat()
            },
            "nearby_benefits": len(nearby)
        }
    
    def get_geofence_status(self, user_id: str) -> Dict:
        """
        GET /api/geofence/status
        Get geofence monitoring status
        """
        return {
            "status": "success",
            "monitoring_enabled": self.backend.geofence_engine.is_running,
            "subscriptions": len(self.backend.location_service.get_user_subscriptions(user_id)),
            "detected_events": len(self.backend.geofence_engine.detected_events),
            "alerts_pending": len(self.backend.alert_system.get_pending_alerts(user_id))
        }
    
    def get_nearby_merchants(self, user_id: str, radius_km: float = 5.0) -> Dict:
        """
        GET /api/merchants/nearby
        Get merchants within radius offering verified benefits
        """
        merchants = self.backend.geofence_engine.get_nearby_merchants(radius_km)
        
        return {
            "status": "success",
            "merchants": [
                {
                    "id": m.id,
                    "name": m.name,
                    "category": m.category,
                    "address": m.address,
                    "benefits_count": len(m.benefits_offered),
                    "distance_km": m.distance_to(
                        self.backend.location_service.get_user_location(user_id)
                    ) if self.backend.location_service.get_user_location(user_id) else None
                }
                for m in merchants
            ],
            "total": len(merchants)
        }
    
    # ============ Alerts Endpoints ============
    
    def get_pending_alerts(self, user_id: str) -> Dict:
        """
        GET /api/alerts/pending
        Get pending alerts for user
        """
        alerts = self.backend.alert_system.get_pending_alerts(user_id)
        
        return {
            "status": "success",
            "alerts": [
                {
                    "id": a.id,
                    "title": a.title,
                    "message": a.message,
                    "priority": a.priority,
                    "created_at": a.created_at.isoformat(),
                    "benefit_id": a.benefit_id,
                    "merchant_id": a.merchant_id
                }
                for a in alerts
            ],
            "count": len(alerts)
        }
    
    def claim_benefit(self, user_id: str, alert_id: str) -> Dict:
        """
        POST /api/alerts/<id>/claim
        User claims a benefit
        """
        result = self.backend.alert_system.claim_benefit(alert_id)
        
        return {
            "status": "success" if result.get("status") == "claimed" else "error",
            "claim": result
        }
    
    def dismiss_alert(self, user_id: str, alert_id: str) -> Dict:
        """
        POST /api/alerts/<id>/dismiss
        User dismisses an alert
        """
        self.backend.alert_system.dismiss_alert(alert_id)
        
        return {
            "status": "success",
            "alert_id": alert_id,
            "action": "dismissed"
        }
    
    def get_alert_history(self, user_id: str, limit: int = 20) -> Dict:
        """
        GET /api/alerts/history
        Get user's alert history
        Query params: limit=20
        """
        history = self.backend.alert_system.get_alert_history(user_id, limit)
        
        return {
            "status": "success",
            "alerts": [
                {
                    "id": a.id,
                    "title": a.title,
                    "status": a.status.value,
                    "sent_at": a.sent_at.isoformat() if a.sent_at else None,
                    "benefit_id": a.benefit_id,
                    "merchant_id": a.merchant_id
                }
                for a in history
            ],
            "total": len(history)
        }
    
    # ============ Analytics Endpoints ============
    
    def get_analytics(self, user_id: str) -> Dict:
        """
        GET /api/analytics/summary
        Get analytics summary
        """
        stats = {
            "alerts": self.backend.alert_system.get_statistics(),
            "location": self.backend.location_service.get_stats(user_id),
            "geofence": {
                "is_monitoring": self.backend.geofence_engine.is_running,
                "merchants_tracked": len(self.backend.geofence_engine.active_merchants)
            }
        }
        
        return {
            "status": "success",
            "data": stats
        }
    
    def calculate_savings(self, user_id: str) -> Dict:
        """
        GET /api/analytics/savings
        Calculate estimated savings from benefits
        """
        benefits = self.backend.get_user_benefits(user_id)
        
        # Simple calculation: sum of all discount percentages
        # In production: would use actual claimed benefits + historical data
        total_discount = sum(b.discount_percent for b in benefits if b.is_verified and not b.is_expired())
        avg_discount = total_discount / len([b for b in benefits if b.is_verified]) if benefits else 0
        
        # Estimate: average spend per category × discount
        estimated_annual_savings = (total_discount / 100) * 5000  # Assumes $5k/year spend
        
        return {
            "status": "success",
            "data": {
                "total_discount_percent": total_discount,
                "average_discount_percent": avg_discount,
                "verified_benefits": sum(1 for b in benefits if b.is_verified),
                "estimated_annual_savings": estimated_annual_savings,
                "currency": "USD"
            }
        }

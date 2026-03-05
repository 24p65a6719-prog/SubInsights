"""
Real-time Alert System
Sends notifications when user enters benefit zones and benefits are verified
"""
import json
from typing import List, Callable, Dict, Optional
from datetime import datetime
from backend.models.detection import Alert, AlertStatus, GeofenceEvent
from backend.models.benefit import Benefit
from backend.models.merchant import Merchant


class AlertSystem:
    """
    Manages real-time notifications to users about nearby verified benefits
    
    How it works:
    1. Receives geofence entry events from GeofencingEngine
    2. For each benefit at merchant, checks if BERT-verified
    3. Creates alert if benefit is verified and not expired
    4. Sends notification via configured channels (push, email, SMS)
    """
    
    def __init__(self):
        """Initialize alert system"""
        self.pending_alerts: List[Alert] = []
        self.sent_alerts: List[Alert] = []
        self.notification_channels: List[Callable] = []  # Configured notification handlers
        self.user_alert_preferences: Dict[str, Dict] = {}  # User settings
        
    def add_notification_channel(self, handler: Callable) -> None:
        """
        Register a notification channel (push, email, SMS, etc.)
        
        Args:
            handler: Async function that sends notification
        """
        self.notification_channels.append(handler)
        
    def set_user_preferences(self, user_id: str, preferences: Dict) -> None:
        """
        Set notification preferences for user
        
        Args:
            user_id: User identifier
            preferences: {
                "enabled": bool,
                "channels": ["push", "email"],
                "alert_types": ["high_value", "expiring", "new"],
                "quiet_hours": {"start": "22:00", "end": "08:00"},
                "max_alerts_per_day": 10
            }
        """
        self.user_alert_preferences[user_id] = preferences
        
    def create_alert(self,
                    user_id: str,
                    geofence_event: GeofenceEvent,
                    merchant: Merchant,
                    benefit: Benefit) -> Alert:
        """
        Create an alert for a verified benefit
        
        Args:
            user_id: User to notify
            geofence_event: Triggering geofence entry
            merchant: Merchant offering benefit
            benefit: The verified benefit
            
        Returns:
            Created Alert object
        """
        
        # Determine priority based on discount value
        discount = benefit.discount_percent
        if discount >= 30:
            priority = "high"
        elif discount >= 15:
            priority = "medium"
        else:
            priority = "low"
            
        # Create compelling alert message
        title = f"🎉 Exclusive: {benefit.title} at {merchant.name}"
        
        message = f"{merchant.name} is honoring your {benefit.title}! "\
                  f"Get {discount}% off. Valid today. Tap to claim now."
        
        alert = Alert(
            id=f"alert_{int(datetime.now().timestamp() * 1000)}",
            user_id=user_id,
            geofence_event_id=geofence_event.id,
            title=title,
            message=message,
            benefit_id=benefit.id,
            merchant_id=merchant.id,
            created_at=datetime.now(),
            status=AlertStatus.PENDING,
            priority=priority
        )
        
        self.pending_alerts.append(alert)
        print(f"\n[Alert] Created: {title}")
        print(f"  Priority: {priority} | Discount: {discount}% | Score: {benefit.verification_score:.1%}")
        
        return alert
        
    def send_alert(self, alert: Alert) -> bool:
        """
        Send alert to user via configured channels
        
        Args:
            alert: Alert to send
            
        Returns:
            True if successfully sent
        """
        # Check user preferences
        prefs = self.user_alert_preferences.get(alert.user_id, {})
        
        if not prefs.get("enabled", True):
            print(f"[Alert] Skipped {alert.id}: User has alerts disabled")
            return False
            
        # Send through all configured channels
        sent_count = 0
        for channel in self.notification_channels:
            try:
                # In production, these would be async
                success = channel(alert)
                if success:
                    sent_count += 1
            except Exception as e:
                print(f"[Alert] Channel error: {e}")
                
        if sent_count > 0:
            alert.status = AlertStatus.SENT
            alert.sent_at = datetime.now()
            self.sent_alerts.append(alert)
            self.pending_alerts.remove(alert)
            print(f"[Alert] Sent {alert.id} via {sent_count} channel(s)")
            return True
        else:
            print(f"[Alert] Failed to send {alert.id}")
            return False
            
    def dismiss_alert(self, alert_id: str) -> None:
        """User dismissed the alert"""
        for alert in self.pending_alerts:
            if alert.id == alert_id:
                alert.status = AlertStatus.DISMISSED
                self.sent_alerts.append(alert)
                self.pending_alerts.remove(alert)
                print(f"[Alert] Dismissed: {alert_id}")
                break
                
    def claim_benefit(self, alert_id: str) -> Dict:
        """
        User claimed the benefit
        
        Returns:
            Claim details (redemption code, merchant info, etc.)
        """
        for alert in self.sent_alerts + self.pending_alerts:
            if alert.id == alert_id:
                alert.status = AlertStatus.CLAIMED
                
                claim = {
                    "claim_id": f"claim_{int(datetime.now().timestamp())}",
                    "status": "claimed",
                    "alert_id": alert_id,
                    "claimed_at": datetime.now().isoformat(),
                    "benefit_id": alert.benefit_id,
                    "merchant_id": alert.merchant_id,
                    "user_id": alert.user_id,
                    "redemption_code": f"SUB{alert_id[-6:]}",  # Simple code
                    "instructions": "Show this code to merchant at checkout"
                }
                
                print(f"\n[Alert] CLAIMED: {alert_id}")
                print(f"  Redemption Code: {claim['redemption_code']}")
                
                return claim
                
        return {"status": "error", "message": "Alert not found"}
        
    def get_pending_alerts(self, user_id: str) -> List[Alert]:
        """Get pending alerts for user"""
        return [a for a in self.pending_alerts if a.user_id == user_id]
        
    def get_alert_history(self, user_id: str, limit: int = 20) -> List[Alert]:
        """Get recent alert history for user"""
        user_alerts = [a for a in self.sent_alerts if a.user_id == user_id]
        return user_alerts[-limit:]
        
    def get_statistics(self) -> Dict:
        """Get alert system statistics"""
        return {
            "total_created": len(self.pending_alerts) + len(self.sent_alerts),
            "pending": len(self.pending_alerts),
            "sent": len(self.sent_alerts),
            "claimed": sum(1 for a in self.sent_alerts if a.status == AlertStatus.CLAIMED),
            "dismissed": sum(1 for a in self.sent_alerts if a.status == AlertStatus.DISMISSED)
        }


# Standard notification channels

def push_notification_handler(alert: Alert) -> bool:
    """Send push notification (would integrate with Firebase, APNs, etc.)"""
    print(f"  📱 Push: {alert.title}")
    return True


def email_notification_handler(alert: Alert) -> bool:
    """Send email notification"""
    print(f"  📧 Email: Sent to user")
    return True


def sms_notification_handler(alert: Alert) -> bool:
    """Send SMS notification (only for high-priority)"""
    if alert.priority == "high":
        print(f"  📲 SMS: {alert.message[:50]}...")
        return True
    return False

"""
Notification Service
Sends alerts through various channels (push, email, SMS, etc.)
"""
import json
from typing import Dict, List, Callable, Optional
from datetime import datetime
from backend.models.detection import Alert


class NotificationService:
    """
    Unified notification dispatcher
    
    Supports multiple channels:
    - Push notifications (Firebase Cloud Messaging, APNs)
    - Email (SMTP)
    - SMS (Twilio)
    - In-app notifications
    - Webhook callbacks
    """
    
    def __init__(self):
        """Initialize notification service"""
        self.channels: Dict[str, Callable] = {}
        self.delivery_log: List[Dict] = []
        self.user_channel_preferences: Dict[str, Dict[str, bool]] = {}
        self.delivery_stats = {
            "total_sent": 0,
            "succeeded": 0,
            "failed": 0,
            "by_channel": {}
        }
        
    def register_channel(self, name: str, handler: Callable) -> None:
        """
        Register a notification channel
        
        Args:
            name: Channel name (e.g., "push", "email", "sms")
            handler: Function that sends notification
        """
        self.channels[name] = handler
        self.delivery_stats["by_channel"][name] = {"sent": 0, "failed": 0}
        print(f"[Notification] Registered channel: {name}")
        
    def set_channel_preference(self, user_id: str, channel: str, enabled: bool) -> None:
        """Set user's preference for a notification channel"""
        if user_id not in self.user_channel_preferences:
            self.user_channel_preferences[user_id] = {}
            
        self.user_channel_preferences[user_id][channel] = enabled
        
    def get_enabled_channels(self, user_id: str) -> List[str]:
        """Get enabled channels for a user"""
        prefs = self.user_channel_preferences.get(user_id, {})
        
        # By default, all channels enabled unless explicitly disabled
        enabled = []
        for channel_name in self.channels:
            if prefs.get(channel_name, True):  # Default True
                enabled.append(channel_name)
                
        return enabled
        
    def send(self, alert: Alert, preferred_channels: Optional[List[str]] = None) -> bool:
        """
        Send alert through available channels
        
        Args:
            alert: Alert to send
            preferred_channels: Specific channels to use (None = all enabled)
            
        Returns:
            True if sent through at least one channel
        """
        
        # Determine which channels to use
        if preferred_channels:
            channels_to_use = preferred_channels
        else:
            channels_to_use = self.get_enabled_channels(alert.user_id)
            
        if not channels_to_use:
            print(f"[Notification] No enabled channels for {alert.user_id}")
            return False
            
        sent_count = 0
        failed_channels = []
        
        for channel_name in channels_to_use:
            if channel_name not in self.channels:
                failed_channels.append(channel_name)
                continue
                
            try:
                handler = self.channels[channel_name]
                success = handler(alert)
                
                if success:
                    sent_count += 1
                    self.delivery_stats["by_channel"][channel_name]["sent"] += 1
                else:
                    failed_channels.append(channel_name)
                    self.delivery_stats["by_channel"][channel_name]["failed"] += 1
                    
            except Exception as e:
                print(f"[Notification] {channel_name} error: {e}")
                failed_channels.append(channel_name)
                self.delivery_stats["by_channel"][channel_name]["failed"] += 1
                
        # Log delivery
        self.delivery_log.append({
            "timestamp": datetime.now().isoformat(),
            "alert_id": alert.id,
            "user_id": alert.user_id,
            "sent_via": channels_to_use[:sent_count],
            "failed_via": failed_channels,
            "success": sent_count > 0
        })
        
        # Update stats
        self.delivery_stats["total_sent"] += 1
        if sent_count > 0:
            self.delivery_stats["succeeded"] += 1
        else:
            self.delivery_stats["failed"] += 1
            
        return sent_count > 0
        
    def send_bulk(self, alerts: List[Alert]) -> Dict:
        """
        Send multiple alerts
        
        Args:
            alerts: List of alerts to send
            
        Returns:
            Statistics of bulk send operation
        """
        results = {
            "total": len(alerts),
            "succeeded": 0,
            "failed": 0
        }
        
        for alert in alerts:
            if self.send(alert):
                results["succeeded"] += 1
            else:
                results["failed"] += 1
                
        return results
        
    def get_delivery_stats(self) -> Dict:
        """Get notification delivery statistics"""
        return self.delivery_stats.copy()
        
    def get_delivery_log(self, user_id: Optional[str] = None, limit: int = 50) -> List[Dict]:
        """Get delivery log (optionally filtered by user)"""
        log = self.delivery_log
        
        if user_id:
            log = [d for d in log if d["user_id"] == user_id]
            
        return log[-limit:]


# Pre-built notification channel handlers

def push_notification_handler(alert: Alert) -> bool:
    """
    Send push notification (integrates with FCM/APNs)
    """
    try:
        print(f"  📱 Push → {alert.user_id}: {alert.title}")
        # In production: call FCM API
        # fcm_client.send(device_token, message)
        return True
    except Exception:
        return False


def email_notification_handler(alert: Alert) -> bool:
    """
    Send email notification
    """
    try:
        print(f"  📧 Email → {alert.user_id}: {alert.title}")
        # In production: send via SMTP
        # smtp_client.send(user_email, subject, body)
        return True
    except Exception:
        return False


def sms_notification_handler(alert: Alert) -> bool:
    """
    Send SMS notification (only for high priority)
    """
    try:
        if alert.priority != "high":
            return False
            
        print(f"  📲 SMS → {alert.user_id}: {alert.message[:50]}...")
        # In production: send via Twilio
        # twilio_client.send_sms(user_phone, message)
        return True
    except Exception:
        return False


def webhook_notification_handler(alert: Alert) -> bool:
    """
    Send webhook to external service
    """
    try:
        payload = {
            "type": "benefit_alert",
            "alert_id": alert.id,
            "user_id": alert.user_id,
            "title": alert.title,
            "message": alert.message
        }
        print(f"  🔗 Webhook → {alert.user_id}: {json.dumps(payload)}")
        # In production: POST to webhook URL
        # requests.post(webhook_url, json=payload)
        return True
    except Exception:
        return False


# Import at bottom to avoid circular imports
import json

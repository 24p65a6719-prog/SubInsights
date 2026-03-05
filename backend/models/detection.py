"""
Detection model - represents geofencing detection events
"""
from dataclasses import dataclass, field
from typing import List
from datetime import datetime
from enum import Enum


class AlertStatus(Enum):
    """Status of an alert"""
    PENDING = "pending"
    SENT = "sent"
    DISMISSED = "dismissed"
    CLAIMED = "claimed"


@dataclass
class GeofenceEvent:
    """
    Represents a geofencing detection event
    
    Attributes:
        id: Unique event ID
        user_id: User who triggered the event
        merchant_id: Merchant that was entered
        benefits_detected: Benefit IDs applicable at this location
        entry_time: When user entered geofence
        exit_time: When user left geofence (None if still inside)
        location_at_entry: User's coordinates at entry
    """
    id: str
    user_id: str
    merchant_id: str
    benefits_detected: List[str] = field(default_factory=list)
    entry_time: datetime = None
    exit_time: datetime = None
    location_at_entry: 'Location' = None


@dataclass
class Alert:
    """
    Represents a notification sent to the user
    
    Attributes:
        id: Unique alert ID
        user_id: User to be notified
        geofence_event_id: Associated detection event
        title: Alert headline
        message: Alert body text
        benefit_id: Associated benefit
        merchant_id: Associated merchant
        created_at: When alert was generated
        sent_at: When alert was delivered
        status: Current status of alert
        priority: "high", "medium", "low"
    """
    id: str
    user_id: str
    geofence_event_id: str
    title: str
    message: str
    benefit_id: str
    merchant_id: str
    created_at: datetime = None
    sent_at: datetime = None
    status: AlertStatus = AlertStatus.PENDING
    priority: str = "medium"  # "high", "medium", "low"

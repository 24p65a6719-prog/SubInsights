"""
SubInsights Backend Configuration
Central configuration for all backend services
"""
import os
from typing import Dict, List


class Config:
    """Base configuration"""
    
    # Environment
    ENV = os.getenv("ENVIRONMENT", "development")
    DEBUG = ENV == "development"
    
    # Location & Geofencing
    GEOFENCE_UPDATE_INTERVAL = 5.0  # seconds
    GEOFENCE_RADIUS_DEFAULT = 1000.0  # meters
    LOCATION_HISTORY_LIMIT = 1000
    
    # BERT Verification
    BERT_VERIFICATION_THRESHOLD = 0.6  # Confidence score required
    BERT_REVERIFICATION_HOURS = 24  # Re-check benefits every 24 hours
    MIN_REVIEWS_FOR_VERIFICATION = 3
    
    # Web Scraping
    SCRAPER_CACHE_HOURS = 24
    SCRAPER_BATCH_SIZE = 10
    SCRAPER_TIMEOUT_SECONDS = 30
    
    # Alerts
    MAX_ALERTS_PER_HOUR = 10
    ALERT_PRIORITY_THRESHOLDS = {
        "high": 30,      # 30% discount = high priority
        "medium": 15,    # 15% = medium
        "low": 5         # 5% = low
    }
    
    # Notification Channels
    ENABLED_NOTIFICATION_CHANNELS = ["push", "email"]
    
    # Database (in production: PostgreSQL, MongoDB, etc.)
    DB_TYPE = "in_memory"  # For demo purposes
    
    # API
    API_VERSION = "v1"
    API_RATE_LIMIT = "100/minute"
    
    # Security
    JWT_SECRET = os.getenv("JWT_SECRET", "demo-secret-key-change-in-production")
    TOKEN_EXPIRY_HOURS = 24
    
    # Logging
    LOG_LEVEL = "INFO" if ENV == "production" else "DEBUG"
    LOG_FORMAT = "[%(asctime)s] %(name)s - %(levelname)s - %(message)s"
    

class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True
    ENV = "development"
    GEOFENCE_UPDATE_INTERVAL = 2.0  # More frequent in dev
    

class ProductionConfig(Config):
    """Production configuration"""
    DEBUG = False
    ENV = "production"
    

class TestingConfig(Config):
    """Testing configuration"""
    ENV = "testing"
    GEOFENCE_UPDATE_INTERVAL = 0.5
    

def get_config() -> Config:
    """Get appropriate configuration based on environment"""
    env = os.getenv("ENVIRONMENT", "development")
    
    configs = {
        "development": DevelopmentConfig,
        "production": ProductionConfig,
        "testing": TestingConfig,
    }
    
    return configs.get(env, DevelopmentConfig)()


# Sample Data for Demo
DEMO_MEMBERSHIPS = [
    {
        "id": "mem_ieee_001",
        "name": "IEEE Professional Membership",
        "category": "professional",
        "user_id": "user_1",
        "start_date": "2023-01-15",
        "end_date": "2025-12-31",
        "benefits": ["hotel_discount", "travel_incentive", "dining_credit"]
    },
    {
        "id": "mem_amex_001",
        "name": "American Express Platinum",
        "category": "credit_card",
        "user_id": "user_1",
        "start_date": "2022-06-01",
        "end_date": "2026-06-01",
        "benefits": ["travel_credit", "hotel_upgrade", "concierge", "dining_credit"]
    },
    {
        "id": "mem_hilton_001",
        "name": "Hilton Honors Platinum",
        "category": "lifestyle",
        "user_id": "user_1",
        "start_date": "2023-03-10",
        "end_date": "2025-03-10",
        "benefits": ["room_upgrade", "breakfast_voucher", "late_checkout"]
    }
]

DEMO_BENEFITS = [
    {
        "id": "ben_hotel_discount",
        "membership_id": "mem_ieee_001",
        "title": "Hotel Discount",
        "description": "Get 15% off hotel stays at participating chains",
        "discount_percent": 15.0,
        "merchant_categories": ["hotel", "travel"],
        "merchants": ["merch_marriott_001", "merch_hilton_001"],
        "expiry_date": "2025-12-31",
        "is_verified": True,
        "verification_score": 0.85
    },
    {
        "id": "ben_travel_incentive",
        "membership_id": "mem_ieee_001",
        "title": "Travel Incentive",
        "description": "Earn 2x points on all travel bookings",
        "discount_percent": 5.0,
        "merchant_categories": ["travel", "airlines"],
        "merchants": ["merch_united_001"],
        "expiry_date": "2025-12-31",
        "is_verified": True,
        "verification_score": 0.72
    },
    {
        "id": "ben_amex_travel_credit",
        "membership_id": "mem_amex_001",
        "title": "$200 Annual Travel Credit",
        "description": "Get $200 credit toward travel purchases",
        "discount_percent": 25.0,
        "merchant_categories": ["travel", "hotels", "airlines"],
        "merchants": ["merch_marriott_001", "merch_united_001"],
        "expiry_date": "2026-06-01",
        "is_verified": True,
        "verification_score": 0.95
    },
    {
        "id": "ben_dining_credit",
        "membership_id": "mem_amex_001",
        "title": "$100 Dining Credit",
        "description": "Credit toward restaurant purchases via Amex Offers",
        "discount_percent": 10.0,
        "merchant_categories": ["restaurant", "dining"],
        "merchants": [],  # Added dynamically for participating restaurants
        "expiry_date": "2026-06-01",
        "is_verified": True,
        "verification_score": 0.88
    }
]

DEMO_MERCHANTS = [
    {
        "id": "merch_marriott_001",
        "name": "Marriott Hotels",
        "category": "hotel",
        "latitude": 37.7749,
        "longitude": -122.4194,
        "address": "San Francisco, CA",
        "benefits": ["ben_hotel_discount", "ben_amex_travel_credit"],
        "rating": 4.5,
        "is_active": True
    },
    {
        "id": "merch_hilton_001",
        "name": "Hilton Hotels",
        "category": "hotel",
        "latitude": 37.7751,
        "longitude": -122.4194,
        "address": "San Francisco, CA",
        "benefits": ["ben_hotel_discount"],
        "rating": 4.3,
        "is_active": True
    },
    {
        "id": "merch_united_001",
        "name": "United Airlines",
        "category": "airline",
        "latitude": 37.6213,
        "longitude": -122.3790,
        "address": "San Francisco Airport, CA",
        "benefits": ["ben_travel_incentive", "ben_amex_travel_credit"],
        "rating": 3.8,
        "is_active": True
    },
    {
        "id": "merch_restaurant_sf",
        "name": "Michelin Restaurant SF",
        "category": "restaurant",
        "latitude": 37.7948,
        "longitude": -122.4010,
        "address": "San Francisco, CA",
        "benefits": ["ben_dining_credit"],
        "rating": 4.7,
        "is_active": True
    }
]

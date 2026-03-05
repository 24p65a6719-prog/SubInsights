# SubInsights API Documentation

**Base URL**: `http://localhost:5000/api`
**Version**: 2.0
**Auth**: Session-based (session ID stored in localStorage)

---

## Table of Contents
1. Authentication Endpoints
2. Subscription Endpoints
3. Hotel Endpoints
4. Error Responses
5. Data Models
6. Example Workflows

---

## 1. Authentication Endpoints

### 1.1 User Registration

**Endpoint**: `POST /api/auth/register`

**Description**: Create a new user account and send OTP verification email.

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "full_name": "John Doe",
  "phone": "+91-9876543210"
}
```

**Response (Success - 201)**:
```json
{
  "success": true,
  "message": "Registration successful! OTP sent to your email.",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "otp_valid_until": "2026-02-12 15:15:30"
}
```

**Response (Error - 400)**:
```json
{
  "success": false,
  "message": "Email already registered",
  "error_code": "DUPLICATE_EMAIL"
}
```

**Validation Rules**:
- Email: Valid email format, unique in system
- Password: Minimum 6 characters
- Full Name: Required, 2-100 characters
- Phone: Optional, valid phone format

**Frontend Integration**:
```javascript
// register.html
const response = await fetch('/api/auth/register', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    email: document.getElementById('email').value,
    password: document.getElementById('password').value,
    full_name: document.getElementById('fullName').value,
    phone: document.getElementById('phone').value
  })
});
const data = await response.json();
if (data.success) {
  localStorage.setItem('pendingEmail', data.email);
  window.location.href = '/frontend/auth/verify.html';
}
```

---

### 1.2 OTP Verification

**Endpoint**: `POST /api/auth/verify-otp`

**Description**: Verify user email using OTP and activate account.

**Request Body**:
```json
{
  "email": "user@example.com",
  "otp_code": "123456"
}
```

**Response (Success - 200)**:
```json
{
  "success": true,
  "message": "Email verified successfully!",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "verified"
}
```

**Response (Error - 400)**:
```json
{
  "success": false,
  "message": "Invalid OTP code",
  "error_code": "INVALID_OTP",
  "attempts_remaining": 2
}
```

**OTP Requirements**:
- 6 digits
- Expires in 15 minutes
- 3 failed attempt limit
- Case-insensitive input

**Frontend Integration**:
```javascript
// verify.html
const otp = Array.from(document.querySelectorAll('.otp-field'))
  .map(field => field.value)
  .join('');

const response = await fetch('/api/auth/verify-otp', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    email: localStorage.getItem('pendingEmail'),
    otp_code: otp
  })
});
```

---

### 1.3 Resend OTP

**Endpoint**: `POST /api/auth/resend-otp`

**Description**: Resend OTP code to user's email.

**Request Body**:
```json
{
  "email": "user@example.com"
}
```

**Response (Success - 200)**:
```json
{
  "success": true,
  "message": "OTP sent to your email",
  "email": "user@example.com",
  "otp_valid_until": "2026-02-12 15:15:30"
}
```

**Response (Error - 429)**:
```json
{
  "success": false,
  "message": "Too many OTP requests. Wait 60 seconds.",
  "error_code": "RATE_LIMIT_EXCEEDED"
}
```

**Rate Limiting**:
- 3 resends per 24 hours per email
- 60 second cooldown between resends

---

### 1.4 Login

**Endpoint**: `POST /api/auth/login`

**Description**: Authenticate user and create session.

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "remember_me": true
}
```

**Response (Success - 200)**:
```json
{
  "success": true,
  "message": "Login successful!",
  "session_id": "5bffae27-c4e7-4068-8d9f-a1b2c3d4e5f6",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "full_name": "John Doe",
  "is_verified": true,
  "session_expiry": "2026-02-12 17:15:30"
}
```

**Response (Error - 401)**:
```json
{
  "success": false,
  "message": "Invalid email or password",
  "error_code": "AUTH_FAILED"
}
```

**Frontend Integration**:
```javascript
// login.html
const response = await fetch('/api/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    email: document.getElementById('email').value,
    password: document.getElementById('password').value,
    remember_me: document.getElementById('rememberMe').checked
  })
});
const data = await response.json();
if (data.success) {
  localStorage.setItem('sessionId', data.session_id);
  localStorage.setItem('userId', data.user_id);
  window.location.href = '/frontend/subscriptions/marketplace.html';
}
```

---

### 1.5 Validate Session

**Endpoint**: `POST /api/auth/validate-session`

**Description**: Check if current session is valid.

**Request Body**:
```json
{
  "session_id": "5bffae27-c4e7-4068-8d9f-a1b2c3d4e5f6"
}
```

**Response (Valid - 200)**:
```json
{
  "success": true,
  "is_valid": true,
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "expires_at": "2026-02-12 17:15:30"
}
```

**Response (Invalid - 401)**:
```json
{
  "success": false,
  "is_valid": false,
  "message": "Session expired"
}
```

---

### 1.6 Logout

**Endpoint**: `POST /api/auth/logout`

**Description**: Terminate user session.

**Request Body**:
```json
{
  "session_id": "5bffae27-c4e7-4068-8d9f-a1b2c3d4e5f6"
}
```

**Response (Success - 200)**:
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

### 1.7 Get User Profile

**Endpoint**: `GET /api/auth/profile`

**Headers**:
```
Authorization: Bearer {session_id}
```

**Response (Success - 200)**:
```json
{
  "success": true,
  "user": {
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "full_name": "John Doe",
    "phone": "+91-9876543210",
    "is_verified": true,
    "created_at": "2026-02-12 14:15:30",
    "profile_picture": null
  }
}
```

---

### 1.8 Update User Profile

**Endpoint**: `PUT /api/auth/profile`

**Headers**:
```
Authorization: Bearer {session_id}
```

**Request Body**:
```json
{
  "full_name": "John Doe Jr",
  "phone": "+91-9876543211",
  "profile_picture_url": "https://example.com/pic.jpg"
}
```

**Response (Success - 200)**:
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "user": {
    "full_name": "John Doe Jr",
    "phone": "+91-9876543211"
  }
}
```

---

### 1.9 Change Password

**Endpoint**: `POST /api/auth/change-password`

**Headers**:
```
Authorization: Bearer {session_id}
```

**Request Body**:
```json
{
  "old_password": "SecurePass123!",
  "new_password": "NewSecurePass456!",
  "new_password_confirm": "NewSecurePass456!"
}
```

**Response (Success - 200)**:
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

**Response (Error - 400)**:
```json
{
  "success": false,
  "message": "Old password is incorrect",
  "error_code": "INVALID_PASSWORD"
}
```

---

## 2. Subscription Endpoints

### 2.1 Get All Subscriptions

**Endpoint**: `GET /api/subscriptions`

**Query Parameters**:
```
?tier=premium        (Filter by tier: basic, premium, elite)
?search=ieee         (Search by name)
```

**Response (Success - 200)**:
```json
{
  "success": true,
  "subscriptions": [
    {
      "subscription_id": "sub_ieee_001",
      "name": "IEEE Membership Plus",
      "price": 199.99,
      "tier": "basic",
      "currency": "USD",
      "features": [
        "Access to IEEE Xplore",
        "Monthly magazine",
        "Networking events"
      ],
      "benefits": [
        {
          "name": "Conference Discount",
          "discount_percentage": 25,
          "category": "conference",
          "description": "25% off IEEE conferences"
        }
      ]
    }
  ],
  "total": 3
}
```

---

### 2.2 Get Subscription Details

**Endpoint**: `GET /api/subscriptions/{subscription_id}`

**Response (Success - 200)**:
```json
{
  "success": true,
  "subscription": {
    "subscription_id": "sub_ieee_001",
    "name": "IEEE Membership Plus",
    "description": "Professional membership for engineers",
    "price": 199.99,
    "tier": "basic",
    "features": [10 items],
    "benefits": [4 items with discounts],
    "cancellation_policy": "30-day money-back guarantee",
    "support_level": "Email support",
    "renewable": true,
    "renewal_period_days": 365
  }
}
```

---

### 2.3 Purchase Subscription

**Endpoint**: `POST /api/subscriptions/purchase`

**Headers**:
```
Authorization: Bearer {session_id}
```

**Request Body**:
```json
{
  "subscription_id": "sub_ieee_001",
  "user_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response (Success - 201)**:
```json
{
  "success": true,
  "message": "Subscription purchased successfully!",
  "purchase": {
    "purchase_id": "purch_12345678",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "subscription_id": "sub_ieee_001",
    "subscription_name": "IEEE Membership Plus",
    "amount": 199.99,
    "currency": "USD",
    "purchase_date": "2026-02-12 15:30:00",
    "valid_from": "2026-02-12 15:30:00",
    "expires_at": "2027-02-12 15:30:00",
    "auto_renew": true,
    "geofence_enabled": false
  }
}
```

---

### 2.4 Get User's Active Subscriptions

**Endpoint**: `GET /api/subscriptions/user/active`

**Headers**:
```
Authorization: Bearer {session_id}
```

**Response (Success - 200)**:
```json
{
  "success": true,
  "subscriptions": [
    {
      "purchase_id": "purch_12345678",
      "subscription_name": "IEEE Membership Plus",
      "price": 199.99,
      "purchase_date": "2026-02-12 15:30:00",
      "expires_at": "2027-02-12 15:30:00",
      "days_remaining": 365,
      "status": "active",
      "auto_renew": true,
      "geofence_enabled": false,
      "geofence_locations": []
    }
  ],
  "total_active": 1
}
```

---

### 2.5 Get Subscription Benefits

**Endpoint**: `GET /api/subscriptions/{subscription_id}/benefits`

**Response (Success - 200)**:
```json
{
  "success": true,
  "subscription": "IEEE Membership Plus",
  "benefits": [
    {
      "benefit_id": "ben_conf_25",
      "name": "Conference Discount",
      "discount_percentage": 25,
      "description": "25% discount on IEEE conference registrations",
      "applicable_merchants": ["IEEE Conferences"],
      "valid_from": "2026-02-12",
      "valid_until": "2027-02-12"
    },
    {
      "benefit_id": "ben_journal_inf",
      "name": "Journal Access",
      "discount_percentage": null,
      "description": "Unlimited access to IEEE Xplore journals",
      "applicable_merchants": ["IEEE Xplore", "Digital Library"],
      "valid_from": "2026-02-12",
      "valid_until": "2027-02-12"
    }
  ]
}
```

---

### 2.6 Activate Geofencing for Subscription

**Endpoint**: `POST /api/subscriptions/{purchase_id}/activate-geofencing`

**Headers**:
```
Authorization: Bearer {session_id}
```

**Request Body**:
```json
{
  "locations": [
    "Marriott Hotels & Resorts",
    "Hilton Hotels & Resorts"
  ]
}
```

**Response (Success - 200)**:
```json
{
  "success": true,
  "message": "Geofencing activated successfully!",
  "purchase_id": "purch_12345678",
  "geofence_enabled": true,
  "geofence_locations": [
    "Marriott Hotels & Resorts",
    "Hilton Hotels & Resorts"
  ],
  "status": "Geofencing activated ✓"
}
```

---

## 3. Hotel Endpoints

### 3.1 Get All Hotels

**Endpoint**: `GET /api/hotels`

**Query Parameters**:
```
?category=hotel       (Filter: hotel, restaurant, library)
?sort=rating         (Sort: rating, name, distance)
?limit=10            (Default: 50)
```

**Response (Success - 200)**:
```json
{
  "success": true,
  "hotels": [
    {
      "hotel_id": "hotel_001",
      "name": "Marriott Hotels & Resorts",
      "category": "hotel",
      "latitude": 40.7580,
      "longitude": -73.9855,
      "address": "1535 Broadway, New York, NY 10036",
      "phone": "+1-800-627-7468",
      "website": "https://www.marriott.com",
      "rating": 4.8,
      "review_count": 4,
      "amenities": ["WiFi", "Fitness Center", "Restaurant", "Spa"],
      "subscription_benefits": ["Hotel Discount 30%"],
      "geofence_radius_km": 0.5
    }
  ],
  "total": 4
}
```

---

### 3.2 Get Hotel Details

**Endpoint**: `GET /api/hotels/{hotel_id}`

**Response (Success - 200)**:
```json
{
  "success": true,
  "hotel": {
    "hotel_id": "hotel_001",
    "name": "Marriott Hotels & Resorts",
    "full_description": "Luxury hotel chain with 1000+ locations worldwide",
    "category": "hotel",
    "coordinates": {
      "latitude": 40.7580,
      "longitude": -73.9855
    },
    "address": "1535 Broadway, New York, NY 10036",
    "phone": "+1-800-627-7468",
    "website": "https://www.marriott.com",
    "rating": 4.8,
    "reviews": [
      {
        "reviewer_name": "Sarah R",
        "rating": 5.0,
        "comment": "Excellent service and clean rooms!",
        "date": "2026-02-10"
      }
    ],
    "amenities": ["WiFi", "Fitness Center", "Restaurant", "Spa", "Room Service"],
    "check_in_time": "15:00",
    "check_out_time": "11:00",
    "subscription_benefits": [
      {
        "benefit_name": "Hotel Discount",
        "discount_percentage": 30,
        "subscription": "IEI Club Premium"
      }
    ],
    "geofence_radius_km": 0.5
  }
}
```

---

### 3.3 Find Nearby Hotels

**Endpoint**: `GET /api/hotels/nearby`

**Query Parameters**:
```
?latitude=40.7580
?longitude=-73.9855
?radius_km=5        (Default: 10 km)
?category=hotel     (Optional filter)
```

**Response (Success - 200)**:
```json
{
  "success": true,
  "user_location": {
    "latitude": 40.7580,
    "longitude": -73.9855
  },
  "nearby_hotels": [
    {
      "hotel_id": "hotel_001",
      "name": "Marriott Hotels & Resorts",
      "distance_km": 0.0,
      "rating": 4.8,
      "address": "1535 Broadway, New York, NY 10036"
    },
    {
      "hotel_id": "hotel_002",
      "name": "Hilton Hotels & Resorts",
      "distance_km": 0.5,
      "rating": 4.4,
      "address": "1200 Avenue of Americas, New York, NY 10036"
    }
  ],
  "total_found": 2
}
```

---

### 3.4 Get Hotel Reviews

**Endpoint**: `GET /api/hotels/{hotel_id}/reviews`

**Response (Success - 200)**:
```json
{
  "success": true,
  "hotel_id": "hotel_001",
  "hotel_name": "Marriott Hotels & Resorts",
  "average_rating": 4.8,
  "review_count": 4,
  "reviews": [
    {
      "review_id": "rev_001",
      "reviewer_name": "Sarah R",
      "rating": 5.0,
      "comment": "Excellent service and clean rooms!",
      "date": "2026-02-10"
    },
    {
      "review_id": "rev_002",
      "reviewer_name": "John D",
      "rating": 4.5,
      "comment": "Great location, a bit noisy at night",
      "date": "2026-02-08"
    }
  ]
}
```

---

### 3.5 Add Review to Hotel

**Endpoint**: `POST /api/hotels/{hotel_id}/reviews`

**Headers**:
```
Authorization: Bearer {session_id}
```

**Request Body**:
```json
{
  "rating": 4.5,
  "comment": "Great stay! Highly recommended.",
  "reviewer_name": "John D"
}
```

**Response (Success - 201)**:
```json
{
  "success": true,
  "message": "Review added successfully!",
  "review": {
    "review_id": "rev_new_001",
    "hotel_id": "hotel_001",
    "reviewer_name": "John D",
    "rating": 4.5,
    "comment": "Great stay! Highly recommended.",
    "date": "2026-02-12"
  },
  "updated_hotel_rating": 4.8
}
```

---

## 4. Error Responses

### Standard Error Format

```json
{
  "success": false,
  "message": "Human-readable error message",
  "error_code": "ERROR_CODE",
  "details": "Optional detailed information",
  "request_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Common Error Codes

| Status | Code | Message |
|--------|------|---------|
| 400 | INVALID_REQUEST | Invalid request parameters |
| 400 | VALIDATION_ERROR | Input validation failed |
| 401 | UNAUTHORIZED | Authentication required |
| 401 | AUTH_FAILED | Invalid credentials |
| 403 | FORBIDDEN | Not authorized to access resource |
| 404 | NOT_FOUND | Resource not found |
| 409 | CONFLICT | Resource already exists |
| 429 | RATE_LIMITED | Too many requests |
| 500 | INTERNAL_ERROR | Server error |

### 400 - Invalid Request
```json
{
  "success": false,
  "message": "Invalid request parameters",
  "error_code": "INVALID_REQUEST",
  "details": "Missing required field: email"
}
```

### 401 - Unauthorized
```json
{
  "success": false,
  "message": "Authentication required",
  "error_code": "UNAUTHORIZED",
  "details": "Session expired or invalid"
}
```

### 404 - Not Found
```json
{
  "success": false,
  "message": "Resource not found",
  "error_code": "NOT_FOUND",
  "details": "User with ID 'user123' not found"
}
```

---

## 5. Data Models

### User Model
```python
class User:
    user_id: str              # UUID
    email: str                # Unique, lowercase
    password_hash: str        # SHA-256 hash
    full_name: str            # 2-100 chars
    phone: str                # Optional
    is_verified: bool         # Email verified
    otp_code: str             # Current OTP (if pending)
    otp_expiry: datetime      # OTP expiry time
    created_at: datetime      # Account creation time
    profile_picture_url: str  # Optional
```

### Subscription Model
```python
class Subscription:
    subscription_id: str      # Unique ID
    name: str                 # Product name
    description: str          # Long description
    price: float              # USD
    tier: str                 # basic, premium, elite
    features: list            # 5-10 features
    benefits: list            # Benefit objects
    support_level: str        # email, phone, 24/7
    renewable: bool           # Auto-renew option
    renewal_period_days: int  # Usually 365
```

### UserSubscription Model
```python
class UserSubscription:
    purchase_id: str          # Unique purchase ID
    user_id: str              # Reference to user
    subscription_id: str      # Reference to subscription
    amount: float             # Purchase price
    purchase_date: datetime   # When purchased
    valid_from: datetime      # Subscription start
    expires_at: datetime      # Subscription end
    status: str               # active, expired, cancelled
    auto_renew: bool          # Auto-renewal enabled
    geofence_enabled: bool    # Geofencing active
    geofence_locations: list  # Hotel names
```

### Hotel Model
```python
class Hotel:
    hotel_id: str             # Unique ID
    name: str                 # Hotel name
    category: str             # hotel, restaurant, library
    latitude: float           # Coordinates
    longitude: float          # Coordinates
    address: str              # Full address
    phone: str                # Contact phone
    website: str              # Website URL
    rating: float             # 1-5 stars
    reviews: list             # Review objects
    amenities: list           # Feature list
    subscription_benefits: list  # Linked benefits
    geofence_radius_km: float # Geofence radius
```

### Review Model
```python
class Review:
    review_id: str            # Unique ID
    reviewer_name: str        # User name (anonymous)
    rating: float             # 1-5 stars
    comment: str              # Review text
    date: str                 # Review date
```

---

## 6. Example Workflows

### Workflow 1: Complete User Registration

```
1. POST /api/auth/register
   ├─ Input: email, password, name, phone
   ├─ Processing: Hash password, create user, generate OTP
   └─ Output: User ID, OTP sent message

2. POST /api/auth/resend-otp (optional, if user didn't receive)
   ├─ Input: email
   ├─ Processing: Generate new OTP, send email
   └─ Output: New OTP sent message

3. POST /api/auth/verify-otp
   ├─ Input: email, otp_code
   ├─ Processing: Validate OTP, mark email verified
   └─ Output: Verification success, ready to login

4. POST /api/auth/login
   ├─ Input: email, password
   ├─ Processing: Verify credentials, create session
   └─ Output: Session ID, user profile, redirect to marketplace
```

### Workflow 2: Browse and Purchase Subscription

```
1. GET /api/subscriptions
   ├─ Input: Optional filters (tier, search)
   ├─ Processing: Query subscription database
   └─ Output: 3 subscriptions with details

2. GET /api/subscriptions/{id}
   ├─ Input: subscription_id
   ├─ Processing: Get detailed information
   └─ Output: Full subscription details, benefits, features

3. POST /api/subscriptions/purchase
   ├─ Input: subscription_id, session_id
   ├─ Processing: Create purchase record, charge (future)
   └─ Output: Purchase ID, confirmation, email sent

4. GET /api/subscriptions/user/active
   ├─ Input: session_id
   ├─ Processing: Query user purchases
   └─ Output: Active subscriptions with benefits
```

### Workflow 3: Discover Hotels and Activate Geofencing

```
1. GET /api/hotels/nearby
   ├─ Input: user latitude, longitude, radius
   ├─ Processing: Calculate distances, sort by rating
   └─ Output: 4+ hotels with distances and ratings

2. GET /api/hotels/{id}
   ├─ Input: hotel_id
   ├─ Processing: Get full details and reviews
   └─ Output: Hotel info, amenities, benefits, reviews

3. POST /api/subscriptions/{purchase_id}/activate-geofencing
   ├─ Input: session_id, hotel location list
   ├─ Processing: Link geofence to subscription
   └─ Output: Geofence status, circle on map

4. [BACKGROUND] Location Monitoring
   ├─ Input: User GPS location
   ├─ Processing: Check if within geofence radius
   └─ Output: (If match) Send email notification with discount
```

---

## 7. Integration Examples

### JavaScript (Frontend)

```javascript
// Helper function for API calls
async function callAPI(endpoint, method = 'GET', body = null) {
  const options = {
    method,
    headers: {
      'Content-Type': 'application/json'
    }
  };
  
  const sessionId = localStorage.getItem('sessionId');
  if (sessionId) {
    options.headers['Authorization'] = `Bearer ${sessionId}`;
  }
  
  if (body) {
    options.body = JSON.stringify(body);
  }
  
  const response = await fetch(`http://localhost:5000${endpoint}`, options);
  return response.json();
}

// Register user
async function registerUser() {
  const data = await callAPI('/api/auth/register', 'POST', {
    email: 'user@example.com',
    password: 'SecurePass123!',
    full_name: 'John Doe',
    phone: '+91-9876543210'
  });
  console.log(data);
}

// Get subscriptions
async function getSubscriptions() {
  const data = await callAPI('/api/subscriptions?tier=premium');
  console.log(data);
}

// Find nearby hotels
async function getNearbyHotels(lat, lng) {
  const data = await callAPI(
    `/api/hotels/nearby?latitude=${lat}&longitude=${lng}&radius_km=5`
  );
  console.log(data);
}
```

### Python (Backend)

```python
import requests

BASE_URL = "http://localhost:5000/api"

# Register user
response = requests.post(f"{BASE_URL}/auth/register", json={
    "email": "user@example.com",
    "password": "SecurePass123!",
    "full_name": "John Doe",
    "phone": "+91-9876543210"
})
print(response.json())

# Get subscriptions
response = requests.get(f"{BASE_URL}/subscriptions")
subscriptions = response.json()
for sub in subscriptions['subscriptions']:
    print(f"- {sub['name']}: ${sub['price']}")

# Purchase subscription
response = requests.post(
    f"{BASE_URL}/subscriptions/purchase",
    json={
        "subscription_id": "sub_ieee_001",
        "user_id": "user_id_here"
    },
    headers={"Authorization": f"Bearer {session_id}"}
)
print(response.json())
```

---

## 8. Rate Limiting & Quotas

### Request Limits
- **Authentication endpoints**: 10 requests/minute per IP
- **OTP endpoints**: 3 requests/24 hours per email
- **General API**: 100 requests/minute per session
- **Hotel endpoints**: 50 requests/minute per session

### Response Header
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 75
X-RateLimit-Reset: 1644695400
```

---

## 9. Webhooks (Future)

### Supported Events
- `subscription.purchased`: User purchased subscription
- `geofence.entered`: User entered geofenced area
- `review.posted`: New review submitted
- `session.created`: User logged in
- `user.signed_up`: New user registered

### Webhook Payload
```json
{
  "event": "subscription.purchased",
  "timestamp": "2026-02-12T15:30:00Z",
  "data": {
    "purchase_id": "purch_12345678",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "subscription_name": "IEEE Membership Plus",
    "amount": 199.99
  }
}
```

---

## 10. Support & Testing

### Test User Accounts
```
Email: testuser@example.com
Password: TestPass123!
Verified: Yes

Email: newuser@example.com
Password: NewUserPass456!
Verified: No (requires OTP)
```

### Test Subscriptions
```
ID: sub_ieee_001 (IEEE Membership Plus - $199.99)
ID: sub_iei_001 (IEI Club Premium - $299.99)
ID: sub_lib_001 (National Library Elite - $149.99)
```

### Test Hotels
```
ID: hotel_001 (Marriott Hotels & Resorts - 40.7580, -73.9855)
ID: hotel_002 (Hilton Hotels & Resorts - 40.7614, -73.9776)
ID: hotel_003 (Le Bernardin Restaurant - 40.7623, -73.9740)
ID: hotel_004 (National Central Library - 40.7533, -73.9822)
```

---

*API Documentation v2.0*
*Last Updated: 2026-02-12*
*Status: Complete & Ready for Integration*


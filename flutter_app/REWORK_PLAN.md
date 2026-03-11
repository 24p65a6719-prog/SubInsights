# SubInsights — Complete Rework Plan

## Project Objective

**SubInsights** is a location-aware subscription-benefits aggregator. Users add their subscriptions (credit cards, dining passes, memberships) and the app discovers nearby merchants that accept those subscriptions, validates available discount/cashback offers in real time, and pushes notifications when the user dwells at a merchant location long enough.

This rework delivers:

| # | Deliverable | Scope |
|---|-------------|-------|
| 1 | **Frontend ↔ Backend split** | Clean separation — backend services never import UI; UI never touches raw data |
| 2 | **Location simulator** | Drop-pin / list-pick to teleport user to any merchant; distance + dwell timers visualised |
| 3 | **Dwell-time push notifications** | Configurable radius (100 m – 2 km) and dwell (30 s – 10 min); fires real browser/OS push |
| 4 | **Expanded Indian data** | 60+ merchants across 10 cities, 8 domains; 50+ benefits & 25+ subscriptions |
| 5 | **Complete UI rework** | New colour system, glassmorphism cards, animated transitions, dark-ready palette |
| 6 | **Data security & encryption** | AES-256 encrypted storage, PBKDF2 password hashing, session hardening |
| 7 | **Cross-platform** | Single codebase runs on Web (Chrome), Android, iOS with platform-adaptive widgets |

---

## Step-by-Step Execution Plan

### Phase 1 — Backend Restructure (Services & Data layer)

#### Step 1.1 — Expand data: `assets/data/merchants.json`
- **Add 60+ merchants** across 10 Indian cities (Mumbai, Delhi, Bangalore, Hyderabad, Chennai, Kolkata, Pune, Jaipur, Ahmedabad, Kochi)
- **8 domains**: Hotel, Restaurant, Café, Shopping Mall, Electronics, Banking, Pharmacy/Health, Cinema/Entertainment
- Each merchant: accurate lat/lng, real address, phone, website, ratings, city, category

#### Step 1.2 — Expand data: `assets/data/benefits.json`
- **50+ benefit offers** tied to merchants — percentage discounts, flat cashback, BOGO, loyalty points, EMI offers
- Realistic validity windows (2026-01-01 through 2027-12-31)
- Diverse terms & conditions, usage limits, minimum purchase rules

#### Step 1.3 — Expand data: `assets/data/subscriptions.json`
- **25+ subscriptions**: credit cards (HDFC, SBI, ICICI, Axis, Kotak, YES, IndusInd, Amex), dining (Zomato Gold, Swiggy One, EazyDiner), shopping (Amazon Prime, Flipkart Plus, Myntra, Tata Neu, JioMart), entertainment (BookMyShow, PVR Privilege), health (PharmEasy, 1mg)
- Each linked to multiple benefits

#### Step 1.4 — Create `lib/backend/` directory structure
```
lib/
  backend/
    models/        ← pure data classes (no Flutter imports)
    services/      ← business logic, data loading, validation, crypto
    repositories/  ← data access layer (JSON / future API)
  frontend/
    screens/       ← all UI screens
    widgets/       ← reusable UI components
    providers/     ← ChangeNotifiers that bridge backend → UI
    theme/         ← colours, typography, component themes
```

#### Step 1.5 — Refactor services into backend
- Move `data_service.dart`, `offer_validation_service.dart`, `location_service.dart`, `notification_service.dart`, `auth_service.dart` → `lib/backend/services/`
- Move models → `lib/backend/models/`
- Create `lib/backend/repositories/data_repository.dart` to abstract JSON loading
- Ensure **zero Flutter-UI imports** in backend (only `foundation.dart` for `kIsWeb` / `debugPrint`)

#### Step 1.6 — Location Simulator Service
- New `lib/backend/services/location_simulator.dart`
- Features: pick any merchant from list → teleport user there
- Configurable parameters: `dwellRadiusMeters` (default 500), `dwellTimeSeconds` (default 120)
- Real-time countdown timer visible in UI
- Auto-triggers notification when dwell threshold crossed
- Stream-based API: `Stream<SimulationState>` with live distance, elapsed time

#### Step 1.7 — Dwell-Time Notification Engine
- Refactor `notification_service.dart` + `location_service.dart`
- Configurable per-user: dwellRadius (100 m – 2 km), dwellTime (30 s – 10 min)
- On dwell threshold: fire push notification (FCM on web, local on mobile)
- Notification payload includes merchant name, offer count, distance
- De-duplication: don't re-notify same merchant within 30 minutes

#### Step 1.8 — Security & Encryption Layer
- `lib/backend/services/crypto_service.dart`:
  - **PBKDF2** password hashing (100 000 iterations, SHA-256, random 32-byte salt) — replaces simple SHA-256+salt
  - **AES-256-GCM** encryption for sensitive user data stored locally
  - Secure random key generation via `dart:math` `Random.secure()`
  - Session tokens: cryptographic random, 24-hour expiry, tied to device fingerprint
- `lib/backend/services/secure_storage_service.dart`:
  - Wraps `flutter_secure_storage` with encryption layer
  - All user data encrypted at rest
  - Session hardening: token rotation on each use

---

### Phase 2 — Complete UI Rework

#### Step 2.1 — New Theme System (`lib/frontend/theme/`)
**Colour palette** (dark gradient-based, modern feel):
```
Primary:       #6C63FF  (Electric Indigo)
Primary Dark:  #3F3D99  (Deep Indigo)
Secondary:     #00D9A6  (Mint/Teal accent)
Surface:       #F8F9FE  (Ice White)
Card:          #FFFFFF
Background:    Linear gradient #F8F9FE → #EEF0FB
Error:         #FF5252
Success:       #00C853
Warning:       #FFB300
Text Primary:  #1A1D3B  (Charcoal Navy)
Text Sec.:     #6B7080  (Cool Gray)
```

**Typography**: Inter / Poppins font family, clear hierarchy
**Components**: Rounded 20dp cards, subtle shadows, glassmorphism overlays

#### Step 2.2 — Rework Login Screen
- Gradient background (indigo → mint)
- Frosted-glass card for form
- Animated logo with Lottie
- Google Sign-In button with logo
- Smooth transitions between login/signup/forgot-password

#### Step 2.3 — Rework Signup Screen
- Multi-step flow feel (name → email → password)
- Real-time password strength meter (coloured bar)
- Terms checkbox with link
- Matching gradient theme

#### Step 2.4 — Rework Home Screen
- **Hero card**: current location + nearby count + active offers stat
- **Location simulator panel**: city picker + "teleport" button + dwell timer
- **Nearby offers carousel**: horizontal cards with merchant image, distance badge, discount tag
- **Quick actions grid**: 4 icon-buttons (Explore, Map, Subscriptions, Notifications)
- **Top deals section**: vertical list of best offers with swipe actions

#### Step 2.5 — Rework Explore Screen
- Search bar at top with category filter chips
- Grid/list toggle
- Merchant cards with: gradient category badge, star rating, offer count pill, distance (if nearby)
- Smooth hero animations to detail screen

#### Step 2.6 — Rework Map Screen
- Dark-mode tile layer option
- Custom animated markers (pulse on selection)
- Bottom sheet with merchant quick card
- Search overlay
- Filter by category / distance
- User position blue dot with configurable radius circle

#### Step 2.7 — Rework Nearby Screen
- Live distance indicators
- Dwell timer progress bar per merchant (fills as user stays)
- "You're here!" badge when in dwell zone
- Push notification preview card (shows what will fire)
- Shimmer loading state

#### Step 2.8 — Rework Subscriptions Screen
- Tab-based layout: "My Subscriptions" | "Browse All"
- Subscription cards with brand colour, icon, benefit count badge
- Add/Remove with animated toggle
- Detail modal with linked benefits list

#### Step 2.9 — Rework Merchant Detail Screen
- Collapsing header with gradient
- Info section: rating stars, address, contact
- Offers section: validated benefit cards with status chips (✅ Valid, ⚠️ Expiring, ❌ Expired)
- "How to redeem" expandable cards
- Related subscriptions

#### Step 2.10 — Reusable Widget Library (`lib/frontend/widgets/`)
- `glass_card.dart` — frosted glass container
- `gradient_button.dart` — primary CTA button
- `offer_badge.dart` — discount percentage pill
- `dwell_timer_widget.dart` — circular progress for dwell countdown
- `category_chip.dart` — coloured filter chip
- `merchant_card.dart` — standard merchant list item
- `shimmer_loader.dart` — skeleton loading states
- `stat_card.dart` — number + label mini card

---

### Phase 3 — Integration & Polish

#### Step 3.1 — Wire backend → frontend via providers
- `AppState` only calls backend services; never touches JSON/files directly
- Providers expose streams for reactive UI updates
- Location simulator state flows through `SimulationProvider`

#### Step 3.2 — Cross-platform verification
- `flutter analyze` — zero errors, zero warnings
- `flutter build web` — successful
- `flutter build apk` — successful (verify no web-only code leaks)
- `flutter build ios` — verify iOS podfile (requires macOS; structure validated)

#### Step 3.3 — Final testing
- Simulate user at 5 different cities
- Verify dwell notification fires after configured time
- Verify offers validate correctly
- Verify login/signup/forgot-password flows
- Verify Google Sign-In on web

---

## File-by-File Change Manifest

| File | Action |
|------|--------|
| `assets/data/merchants.json` | Replace — 60+ merchants, 10 cities, 8 domains |
| `assets/data/benefits.json` | Replace — 50+ offers with realistic terms |
| `assets/data/subscriptions.json` | Replace — 25+ subscriptions across domains |
| `lib/backend/models/benefit.dart` | Move + enhance |
| `lib/backend/models/merchant.dart` | Move + enhance |
| `lib/backend/models/subscription.dart` | Move + enhance |
| `lib/backend/models/user_model.dart` | Move + enhance with security fields |
| `lib/backend/services/auth_service.dart` | Move + upgrade crypto (PBKDF2/AES) |
| `lib/backend/services/crypto_service.dart` | **New** — encryption utilities |
| `lib/backend/services/data_service.dart` | Move + expand queries |
| `lib/backend/services/location_service.dart` | Move + dwell engine |
| `lib/backend/services/location_simulator.dart` | **New** — simulation engine |
| `lib/backend/services/notification_service.dart` | Move + configurable dwell triggers |
| `lib/backend/services/offer_validation_service.dart` | Move |
| `lib/backend/services/secure_storage_service.dart` | **New** — encrypted storage wrapper |
| `lib/backend/repositories/data_repository.dart` | **New** — JSON data access |
| `lib/frontend/theme/app_theme.dart` | **New** — reworked theme |
| `lib/frontend/theme/app_colors.dart` | **New** — colour constants |
| `lib/frontend/widgets/*.dart` | **New** — 8 reusable components |
| `lib/frontend/screens/*.dart` | **New** — 9 reworked screens |
| `lib/frontend/providers/app_state.dart` | Move + refactor |
| `lib/main.dart` | Update imports to new structure |

---

## Execution Begins Now

Each step above will be implemented in order. Files will be created/edited incrementally with `flutter analyze` verification at each phase boundary.

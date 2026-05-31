# Mini Visitor Management System

A Flutter mobile app with an Express.js mock API for managing office visitors, built as a technical assessment.

---

## Setup & run

### Prerequisites
- Node.js 18+
- Flutter 3.x (`flutter doctor` should pass)
- An Android emulator or physical device

### 1. Start the backend

```bash
cd backend
npm install
node server.js
# API running at http://localhost:3000
```

**Test credentials:** `admin` / `admin123`

### 2. Run the Flutter app

```bash
cd visitor_app
flutter pub get
flutter run
```

> **Note:** The app dynamically selects its API base URL based on the platform. Android emulators connect via `10.0.2.2:3000` (the emulator's localhost alias), while Windows, Web (Chrome/Edge), macOS, and iOS use `localhost:3000` directly. For a physical device on a different network, update `AppConstants.baseUrl` in `lib/core/constants/app_constants.dart` to your machine's LAN IP.

### API endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/login` | No | Returns JWT token |
| GET | `/api/visitors` | Bearer | List all visitors |
| POST | `/api/visitors` | Bearer | Add a visitor |
| GET | `/api/visitors/:id` | Bearer | Get visitor by ID |

---

## Architecture

### Current (mock / assessment)

```
visitor_app/lib/
├── main.dart                   # Entry point
├── app.dart                    # MaterialApp + AuthCubit provider
├── core/
│   ├── api/                    # Dio client factory + endpoint constants
│   ├── constants/              # Base URL
│   ├── theme/                  # Material 3 theme
│   └── router/                 # Named-route generator
└── features/
    ├── auth/
    │   ├── data/               # AuthRepository, User model
    │   ├── cubit/              # AuthCubit + AuthState
    │   └── ui/                 # LoginScreen
    └── visitors/
        ├── data/               # VisitorRepository, Visitor model
        ├── cubit/              # VisitorCubit + VisitorState
        └── ui/                 # List, Add, Details screens
```

State management: Bloc/Cubit for predictable unidirectional data flow, easy to test.  
HTTP: Dio for interceptor-based auth header injection and structured error handling.  
Token storage: in-memory (Cubit state), sufficient for a mock; see the Security section for the production approach.

### Production proposal

| Layer | Current | Production |
|-------|---------|-----------|
| Backend | Express.js single file | NestJS + PostgreSQL, Docker, CI/CD |
| Auth | Hardcoded JWT | OAuth2 / managed auth (Clerk, Auth0) |
| Routing | Manual `Navigator` | GoRouter (deep links, guards, shell routes) |
| HTTP | In-memory Dio client | Retrofit-style typed API + retry + refresh |
| Token storage | Cubit in-memory | `flutter_secure_storage` (Keychain / Keystore) |
| Architecture | Feature-first folders | Clean Architecture (domain/data/presentation layers) |
| Pagination | None (flat list) | Cursor-based pagination, `infinite_scroll_pagination` |
| Offline | None | Drift (SQLite) for local cache |

---

## Entity relationship diagram

![Entity Relationship Diagram](assets/Mini%20Visitor%20Management%20System%20-%20ER%20Diagram.png)

### Production additions
- `status` enum on Visitors: `pending | checked_in | checked_out`
- `checked_in_at`, `checked_out_at` timestamps
- `qr_token` (UUID, time-bound) for QR verification
- `host_user_id` FK: which employee the visitor is meeting
- `purpose` and `company` fields
- Separate `CHECK_IN_EVENTS` table for audit trail

---

## QR code strategy

The visitor details screen currently generates a QR code encoding `{ visitorId, name, visitDate }` using `qr_flutter`.

For production:
1. On visitor registration, generate a unique `qr_token` (UUID v4) stored in the database with a validity window (e.g., visit date ± 1 hour).
2. QR code encodes a signed URL: `https://api.company.com/checkin?token=<qr_token>`.
3. A reception kiosk or security guard's app scans the QR. The server validates the token, checks expiry, and marks the visitor `checked_in`.
4. Token is single-use: invalidated after first scan to prevent replay.
5. Host employee receives a push notification when their visitor checks in.

---

## IoT / access control integration

The check-in endpoint acts as the integration point:

```
Visitor scans QR → POST /api/checkin
  → validate token
  → update status to checked_in
  → publish MQTT event: visitors/checkin { visitorId, door, timestamp }
  → turnstile controller subscribes → unlocks gate for N seconds
  → badge printer subscribes → prints visitor pass
  → notify host via FCM push
```

Protocol choice: MQTT (lightweight pub/sub) for real-time device commands. For cloud-managed deployments, AWS IoT Core or Azure IoT Hub handle certificate management and device scaling.

---

## Security considerations

| Risk | Mitigation |
|------|-----------|
| Token theft | Store in `flutter_secure_storage` (hardware-backed on Android/iOS), never in SharedPreferences |
| MITM | TLS everywhere; certificate pinning in production app |
| Brute force login | Rate limiting (express-rate-limit / API gateway), account lockout after N failures |
| JWT replay | Short expiry (15 min access + refresh token rotation), revocation list for logout |
| Input injection | Server-side validation on all fields; parameterised queries (ORM) |
| Visitor data (PDPA/GDPR) | Data minimisation, retention policy, encryption at rest, right-to-erasure flow |
| QR replay | Single-use tokens with time-bound validity window |
| Insider threat | Role-based access control; audit log on all visitor CRUD operations |

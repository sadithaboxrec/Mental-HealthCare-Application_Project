# MindCare — Mental Healthcare Application

A full-stack mental healthcare platform built with **Flutter** (mobile) and **Flask** (backend). MindCare supports five distinct user roles — Patient, Doctor, Counselor, Guardian, and Admin — connected through Firebase and powered by an on-device/on-server **Explainable AI (XAI)** engine that continuously analyses patient data to surface clinical insights, severity scores, and evidence-backed alerts.

---

## Table of Contents

1. [Overview](#overview)
2. [Key Features](#key-features)
3. [User Roles](#user-roles)
4. [Tech Stack](#tech-stack)
5. [Architecture](#architecture)
6. [Project Structure](#project-structure)
7. [Prerequisites](#prerequisites)
8. [Firebase Setup](#firebase-setup)
9. [Backend Setup (Flask)](#backend-setup-flask)
10. [Flutter App Setup](#flutter-app-setup)
11. [Running the Application](#running-the-application)
12. [Environment Variables & Secrets](#environment-variables--secrets)
13. [API Reference](#api-reference)
14. [XAI Engine](#xai-engine)
15. [Digital Phenotyping](#digital-phenotyping)
16. [Firestore Data Model](#firestore-data-model)
17. [Testing](#testing)
18. [Security Notes](#security-notes)
19. [Contributing](#contributing)

---

## Overview

MindCare digitises the care pathway for mental health patients. Patients log daily moods, write diary entries, chat with their assigned counsellor, and track medication. Doctors receive automated XAI-generated clinical alerts and detailed reports. Guardians observe their patient's wellness trends. Admins manage the entire organisation from a web dashboard.

The platform is built around **privacy-first explainability**: every severity score is backed by a ranked list of evidence snippets, theme counts, and driver contributions so clinicians can audit exactly why the system flagged a patient.

---

## Key Features

| Area | Feature |
|---|---|
| **Authentication** | Firebase Auth · Role-based access control · Persistent sessions |
| **Patient** | Daily mood & log · Diary journaling · Medication tracking · Appointment booking · AI chat counsellor |
| **Doctor** | Patient list & detail · XAI alerts · Clinical report generation (daily/weekly/monthly/yearly/custom) · PDF export · Schedule management |
| **Counsellor** | Dedicated chat interface · Patient overview |
| **Guardian** | Wellness trend monitoring · Guardian log submission |
| **Admin** | Full user management (create/assign/deactivate) · Analytics dashboard · Notification console · Diary & XAI report viewer |
| **XAI Engine** | Lexicon-based NLP · Explainable severity bands (stable/watch/warning/critical) · Primary drivers · Theme counts · Source breakdown · Evidence snippets |
| **Digital Phenotyping** | Location radius · App activity patterns · Mobility analysis · Behavioural signal aggregation |
| **Notifications** | Firebase Cloud Messaging · Medication reminders · Appointment reminders · Water intake prompts · Diary prompts |
| **Clinical Reports** | Auto-generated structured reports · Firestore-persisted · PDF download |

---

## User Roles

```
Admin
  └── Manages all users, views all analytics, controls notifications

Doctor
  └── Views assigned patients, receives XAI alerts, generates clinical reports

Counsellor
  └── Chats with assigned patients, views session history

Guardian
  └── Submits observations, views assigned patient's wellness trend

Patient
  └── Logs daily data, writes diary, chats, tracks medication & appointments
```

Role assignment is managed by Admins through the web portal. Each role sees a completely different UI shell in the Flutter app, routed by GoRouter redirect logic after sign-in.

---

## Tech Stack

### Flutter App
| Package | Purpose |
|---|---|
| `firebase_core` `firebase_auth` `cloud_firestore` `firebase_messaging` | Firebase services |
| `flutter_riverpod` | Reactive state management |
| `go_router` | Declarative, role-aware navigation |
| `phosphor_flutter` | Icon set |
| `google_fonts` | Typography |
| `fl_chart` | Mood & score trend charts |
| `geolocator` | GPS for digital phenotyping |
| `flutter_local_notifications` | In-app notification display |
| `shimmer` | Loading skeleton UX |
| `http` | REST calls to Flask backend |
| `shared_preferences` | Lightweight local persistence |
| `intl` | Date/time formatting |

### Flask Backend
| Package | Purpose |
|---|---|
| `Flask` | Web framework |
| `Flask-Login` | Session management for admin portal |
| `firebase-admin` | Firestore read/write + FCM |
| `APScheduler` | Cron-style background jobs |
| `flasgger` | Swagger / OpenAPI documentation |
| `reportlab` | PDF generation |
| `jsonschema` | Request body validation |
| `requests` | Internal HTTP calls |
| `pytest` `coverage` `pytest-cov` | Testing |
| `python-dotenv` | Environment variable loading |
| `gunicorn` | Production WSGI server |

### Infrastructure
| Service | Use |
|---|---|
| **Firebase Auth** | Identity & sessions |
| **Cloud Firestore** | Real-time NoSQL database |
| **Firebase Cloud Messaging** | Push notifications |
| **Firebase Storage** | Media assets (optional) |

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     Flutter Mobile App                       │
│                                                              │
│  Presentation Layer (Atomic Design)                          │
│   atoms → molecules → organisms → screens                    │
│                                                              │
│  State: Riverpod providers  │  Navigation: GoRouter          │
│  Services: Firestore SDK    │  API: http → Flask             │
└──────────────────────────────────────────────────────────────┘
              │ Firebase SDK           │ REST / JSON
              ▼                        ▼
┌─────────────────────┐   ┌───────────────────────────────────┐
│   Cloud Firestore   │   │         Flask Backend             │
│   Firebase Auth     │   │                                   │
│   Firebase Messaging│   │  Routes → Services → Firestore    │
└─────────────────────┘   │                                   │
                          │  XAI Engine                       │
                          │  ├── Diary analysis               │
                          │  ├── Chat analysis                │
                          │  ├── Daily log signals            │
                          │  ├── Guardian observations        │
                          │  ├── Activity & mobility          │
                          │  └── Medication adherence         │
                          │                                   │
                          │  Scheduler (APScheduler)          │
                          │  ├── Medication reminders         │
                          │  ├── Appointment reminders        │
                          │  └── Wellness prompts             │
                          └───────────────────────────────────┘
```

### Flutter App Layers

```
lib/
├── core/
│   ├── controllers/   # Business logic wrappers (auth, chat, patient…)
│   ├── models/        # Dart data classes with fromMap / toMap
│   ├── services/      # Firestore queries, API calls, phenotyping
│   ├── theme/         # Colors, typography, spacing constants
│   └── utils/         # Date helpers, severity badges, cadence tracker
├── presentation/
│   ├── auth/          # Login screen
│   ├── components/    # Atomic design components
│   │   ├── atoms/
│   │   ├── molecules/
│   │   └── organisms/
│   ├── patient/       # All patient-role screens
│   ├── doctor/        # All doctor-role screens
│   ├── counselor/     # All counsellor-role screens
│   ├── guardian/      # Guardian home screen
│   └── (admin is web-only via Flask portal)
├── providers/         # Riverpod provider declarations
└── router/            # GoRouter config with role-based redirects
```

### Flask Backend Layers

```
Hospital_Administration/
├── routes/        # Blueprint endpoints (auth, admin, doctor_portal, analytics, notifications)
├── controllers/   # User creation / management logic
├── models/        # Firestore-backed user models
├── services/      # Analysis, reporting, notification services
├── templates/     # Jinja2 HTML for admin web portal
├── data/          # Seed JSON (doctors, counsellors, medications, departments)
└── tests/         # Unit + integration + security test suite
```

---

## Project Structure

```
Mental-HealthCare-Application_Project/
│
├── README.md                        ← this file
│
├── mental_health_support_app/       ← Flutter mobile app
│   ├── lib/
│   │   ├── core/
│   │   │   ├── assets/app_assets.dart
│   │   │   ├── controllers/         # auth, chat, doctor, guardian, notification, patient
│   │   │   ├── models/              # appointment, clinical_report, daily_log, diary_entry…
│   │   │   ├── services/            # api_service, auth_service, chat_service, phenotyping…
│   │   │   ├── theme/               # app_colors, app_spacing, app_typography, app_theme
│   │   │   └── utils/
│   │   ├── firebase_options.dart
│   │   ├── main.dart
│   │   ├── presentation/
│   │   │   ├── auth/login_screen.dart
│   │   │   ├── components/          # atoms / molecules / organisms
│   │   │   ├── counselor/           # chat, home
│   │   │   ├── doctor/              # home, patients, reports, schedule
│   │   │   ├── guardian/home/
│   │   │   └── patient/             # care, chat, home, journal, profile
│   │   ├── providers/auth_provider.dart
│   │   └── router/app_router.dart
│   ├── assets/
│   │   ├── brand/                   # Logos
│   │   ├── illustrations/           # SVG/PNG illustrations
│   │   ├── onboarding/              # Onboarding images
│   │   └── states/                  # Empty-state images
│   ├── android/
│   ├── ios/
│   ├── pubspec.yaml
│   └── analysis_options.yaml
│
└── Hospital_Administration/         ← Flask backend + admin portal
    ├── app.py                       # Flask entry point
    ├── config.py                    # Firebase Admin SDK init
    ├── requirements.txt
    ├── pytest.ini
    ├── serviceAccountKey.json       # ⚠ NOT committed — see setup
    ├── routes/
    │   ├── auth_routes.py           # Login / logout / role guard
    │   ├── admin_routes.py          # Full admin dashboard
    │   ├── doctor_portal_routes.py  # Doctor web portal
    │   ├── analytics_routes.py      # XAI & diary analytics API
    │   └── notification_routes.py   # FCM trigger endpoints
    ├── controllers/
    │   ├── admin_controller.py
    │   ├── doctor_controller.py
    │   ├── counselor_controller.py
    │   └── patient_controller.py
    ├── models/
    │   ├── user_model.py
    │   ├── doctor_model.py
    │   ├── counselor_model.py
    │   ├── guardian_model.py
    │   └── patient_model.py
    ├── services/
    │   ├── xai_analysis_service.py       # Main XAI orchestrator
    │   ├── xai_scoring_service.py        # Lexicon scoring engine
    │   ├── xai_utils.py                  # Shared utilities
    │   ├── diary_analysis_service.py     # Diary entry NLP
    │   ├── chat_analysis_service.py      # Chat message NLP
    │   ├── daily_log_analysis_service.py # Mood / sleep / medication signals
    │   ├── guardian_analysis_service.py  # Guardian observation NLP
    │   ├── activity_analysis_service.py  # App activity signals
    │   ├── mobility_analysis_service.py  # Geolocation signals
    │   ├── appointment_analysis_service.py
    │   ├── medication_adherence_service.py
    │   ├── clinical_report_service.py    # Report generation & PDF
    │   └── firebase_service.py           # FCM helpers
    ├── data/
    │   ├── analysis/xai_lexicons.json    # Symptom / theme lexicon
    │   ├── doctor/doctor_seed.json
    │   ├── doctor/medication_catalog.json
    │   ├── counselor/counselor_seed.json
    │   └── shared/{departments,specializations}.json
    ├── templates/                        # Jinja2 HTML for admin portal
    ├── static/mindcare-admin.css
    └── tests/
        ├── unit/
        ├── integration/
        └── security/
```

---

## Prerequisites

### Global Tools
| Tool | Version | Install |
|---|---|---|
| Flutter SDK | ≥ 3.10.7 | https://docs.flutter.dev/get-started/install |
| Dart SDK | ≥ 3.0 (bundled with Flutter) | — |
| Python | ≥ 3.11 | https://www.python.org/downloads/ |
| pip | ≥ 23 | bundled with Python |
| Git | any recent | https://git-scm.com |
| Android Studio / Xcode | latest | for device emulation |
| Firebase CLI | latest | `npm install -g firebase-tools` |
| FlutterFire CLI | latest | `dart pub global activate flutterfire_cli` |
| Node.js | ≥ 18 (for Firebase CLI) | https://nodejs.org |

### Accounts
- **Firebase project** — create one at https://console.firebase.google.com
- **Google account** — for Firebase and Play Store (optional)

---

## Firebase Setup

### 1. Create Firebase Project
1. Go to https://console.firebase.google.com
2. Click **Add project** → name it (e.g. `mindcare-app`) → disable Google Analytics if not needed
3. Enable **Authentication** → Sign-in providers → **Email/Password**
4. Enable **Cloud Firestore** → Start in **production mode** → choose a region
5. Enable **Cloud Messaging** (FCM) — no extra config needed

### 2. Generate Service Account Key (Backend)
1. Firebase Console → Project Settings → **Service accounts**
2. Click **Generate new private key** → download the JSON file
3. Rename it to `serviceAccountKey.json`
4. Place it in `Hospital_Administration/serviceAccountKey.json`
5. **Never commit this file** — it is in `.gitignore`

### 3. Configure Flutter App with FlutterFire CLI
```bash
# Activate the CLI (once globally)
dart pub global activate flutterfire_cli

# Inside the Flutter project root
cd mental_health_support_app

# Log in to Firebase
firebase login

# Configure — this regenerates firebase_options.dart automatically
flutterfire configure --project=<your-firebase-project-id>
```

Select **Android** (and **iOS** / **Web** if needed) when prompted. This writes `lib/firebase_options.dart` with the correct app-specific keys.

### 4. Firestore Security Rules
Deploy the bundled rules from the project root:
```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

The rules enforce:
- Patients can only read/write their own data
- Doctors can read data of their assigned patients
- Admins have full access via backend SDK (bypasses rules)

### 5. Android Configuration
Ensure `mental_health_support_app/android/app/google-services.json` exists (FlutterFire CLI places it automatically). If building manually, download it from Firebase Console → Project Settings → Your apps → Android app.

---

## Backend Setup (Flask)

### 1. Clone and Navigate
```bash
git clone <repo-url>
cd Mental-HealthCare-Application_Project/Hospital_Administration
```

### 2. Create Virtual Environment
```bash
python -m venv venv

# Windows
venv\Scripts\activate

# macOS / Linux
source venv/bin/activate
```

### 3. Install Dependencies
```bash
pip install -r requirements.txt
```

### 4. Place Service Account Key
```bash
# Copy your downloaded serviceAccountKey.json into:
Hospital_Administration/serviceAccountKey.json
```

### 5. Environment Variables (Optional)
Create a `.env` file in `Hospital_Administration/` for production overrides:
```env
FLASK_SECRET_KEY=your-very-long-random-secret-key
FLASK_ENV=development
FIREBASE_CREDENTIAL_PATH=serviceAccountKey.json
```

> In `config.py` the credential path defaults to `serviceAccountKey.json` next to the file. Override `FIREBASE_CREDENTIAL_PATH` for Docker / CI environments.

### 6. Seed Initial Data (Optional)
The admin portal lets you create users manually. Alternatively run seed scripts using the data in `data/`:
- `data/doctor/doctor_seed.json` — sample doctors
- `data/counselor/counselor_seed.json` — sample counsellors
- `data/doctor/medication_catalog.json` — 4 000+ medications

### 7. Run the Development Server
```bash
cd Hospital_Administration
python app.py
```

The server starts at **http://localhost:5000**

Admin portal: http://localhost:5000/auth/login  
Swagger UI: http://localhost:5000/swagger/

Default admin credentials are set by the first admin you create through the CLI or Firestore directly.

---

## Flutter App Setup

### 1. Install Dependencies
```bash
cd mental_health_support_app
flutter pub get
```

### 2. Verify Firebase Options
Ensure `lib/firebase_options.dart` exists. If not, re-run FlutterFire configure:
```bash
flutterfire configure --project=<your-firebase-project-id>
```

### 3. Connect Backend URL
The Flutter app talks to the Flask backend via `lib/core/services/api_service.dart`.

| Platform | Default base URL |
|---|---|
| Android Emulator | `http://10.0.2.2:5000` (auto-detected) |
| iOS Simulator / Web | `http://localhost:5000` (auto-detected) |
| Physical device | Set via `--dart-define=BACKEND_URL=http://<your-lan-ip>:5000` |
| Production | Set via `--dart-define=BACKEND_URL=https://your-api-domain.com` |

**Physical device (example):**
```bash
flutter run --dart-define=BACKEND_URL=http://192.168.1.42:5000
```

### 4. Android Permissions
The app requires the following — already declared in `android/app/src/main/AndroidManifest.xml`:
- `ACCESS_FINE_LOCATION` — digital phenotyping GPS
- `INTERNET` — API + Firebase
- `RECEIVE_BOOT_COMPLETED` — scheduled notifications
- `POST_NOTIFICATIONS` — FCM (Android 13+)

### 5. iOS Permissions
Add to `ios/Runner/Info.plist` if not already present:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>MindCare uses your location to support digital phenotyping features.</string>
```

---

## Running the Application

### Start the Flask backend
```bash
cd Hospital_Administration
source venv/bin/activate   # or venv\Scripts\activate on Windows
python app.py
```

### Run the Flutter app (emulator)
```bash
cd mental_health_support_app
flutter run
```

### Run the Flutter app (physical device)
```bash
flutter run --dart-define=BACKEND_URL=http://<your-machine-ip>:5000
```

### Build release APK
```bash
flutter build apk --release --dart-define=BACKEND_URL=https://your-api.com
```

### Build release AAB (Play Store)
```bash
flutter build appbundle --release --dart-define=BACKEND_URL=https://your-api.com
```

### Run Flask in production (gunicorn)
```bash
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

---

## Environment Variables & Secrets

### Backend (`Hospital_Administration/.env`)
| Variable | Default | Description |
|---|---|---|
| `FLASK_SECRET_KEY` | hardcoded fallback | Session signing key — **change in production** |
| `FLASK_ENV` | `development` | `development` or `production` |
| `FIREBASE_CREDENTIAL_PATH` | `serviceAccountKey.json` | Path to Firebase Admin SDK JSON |

### Flutter (via `--dart-define`)
| Variable | Default | Description |
|---|---|---|
| `BACKEND_URL` | Auto-detected per platform | Base URL of Flask API |

### Files that must NEVER be committed
| File | Reason |
|---|---|
| `Hospital_Administration/serviceAccountKey.json` | Firebase Admin private key — full DB access |
| `Hospital_Administration/.env` | Secrets |
| `mental_health_support_app/android/app/google-services.json` | Firebase Android config (contains API key) |
| `mental_health_support_app/ios/Runner/GoogleService-Info.plist` | Firebase iOS config |

All of the above are excluded in `.gitignore`.

---

## API Reference

The Flask backend exposes both a **REST API** (consumed by the Flutter app) and a **web portal** (for admins and doctors).

Interactive Swagger docs are available at:
```
http://localhost:5000/swagger/
```

### Key REST Endpoints

#### Clinical Reports
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/patients/:uid/clinical-report` | Generate a new clinical report |
| `GET` | `/api/patients/:uid/clinical-reports` | List reports for a patient |
| `GET` | `/api/clinical-reports/:id/pdf` | Download report as PDF |

#### Analytics (XAI)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/analytics/xai/:uid` | Run and return XAI analysis for a patient |
| `GET` | `/analytics/diary/:uid` | Run diary analysis for a patient |
| `GET` | `/analytics/diary` | Run diary analysis for all patients |
| `GET` | `/analytics/xai` | Run XAI analysis for all patients |

#### Notifications
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/notifications/send` | Send a targeted FCM notification |
| `POST` | `/trigger/medication-reminders` | Trigger medication reminder sweep |
| `POST` | `/trigger/appointment-reminders` | Trigger appointment reminder sweep |

#### Admin Portal (HTML)
| Route | Description |
|---|---|
| `/auth/login` | Sign in |
| `/admin/dashboard` | Overview |
| `/admin/patients` | Patient list & management |
| `/admin/doctors` | Doctor list & management |
| `/admin/counselors` | Counsellor list |
| `/admin/analytics` | XAI analytics overview |
| `/admin/notifications` | Notification console |
| `/swagger/` | API documentation |

---

## XAI Engine

The XAI (Explainable AI) engine is the clinical intelligence core. It is entirely lexicon-driven — no ML model training required — making results fully auditable.

### Pipeline

```
Raw patient data (Firestore)
        │
        ├── Diary entries       → diary_analysis_service     → scored items
        ├── Chat messages       → chat_analysis_service      → scored items
        ├── Daily logs          → daily_log_analysis_service → behavioural signals
        ├── Guardian logs       → guardian_analysis_service  → scored items
        ├── App activity        → activity_analysis_service  → behavioural signals
        ├── Geolocations        → mobility_analysis_service  → mobility signals
        ├── Medication events   → medication_adherence_service → adherence signals
        └── Appointments        → appointment_analysis_service → missed/rescheduled signals
                │
                ▼
        xai_analysis_service._build_summary()
                │
                ├── Score aggregation (text + behavioural)
                ├── Severity classification (stable/watch/warning/critical)
                ├── Primary driver ranking
                ├── Theme count merging
                ├── Source breakdown
                └── Evidence selection
                │
                ▼
        XAI Summary dict
        ├── severity / band / score / textConcernScore
        ├── confidence (0.50–0.95 based on data richness)
        ├── primaryDrivers (top 10 with scoreContribution, evidence)
        ├── themeCounts (e.g. {"depression": 4, "anxiety": 2})
        ├── sourceBreakdown (e.g. {"diary": {score, evidenceCount, driverCount}})
        └── evidence (up to 20 anonymised text snippets)
```

### Severity Bands

| Band | Label | Score | Action |
|---|---|---|---|
| 0 | `stable` | 0–1 | Routine monitoring only |
| 1 | `watch` | 2–4 | Include in clinician digest |
| 2 | `warning` | 5–7 | Same-day clinician review required |
| 3 | `critical` | ≥ 8 | Immediate urgent alert required |

Scores are also elevated if `explicitSelfHarm` or `explicitPlanOrPreparation` flags are present in any analysed item.

### Lexicon
`data/analysis/xai_lexicons.json` defines:
- **Themes** — named clinical concern areas (e.g. `depression`, `anxiety`, `self_harm`)
- **Keywords** — weighted terms per theme
- **Scoring rules** — per-keyword score contributions
- **Privacy settings** — max evidence items surfaced

---

## Digital Phenotyping

`phenotyping_service.dart` (Flutter) passively collects behavioural signals:

| Signal | Data Source | Backend Service |
|---|---|---|
| Mobility radius | GPS (geolocator) | `mobility_analysis_service.py` |
| App activity | Interaction timestamps | `activity_analysis_service.py` |
| Sleep proxy | Log timestamps + daily log | `daily_log_analysis_service.py` |
| Medication adherence | Daily log boolean | `medication_adherence_service.py` |
| Mood trend | Daily log scale (1–10) | `daily_log_analysis_service.py` |

All data is written to Firestore and included in XAI analysis on the backend.

---

## Firestore Data Model

### Collections

```
users/{uid}                      # All users (role field distinguishes type)
patients/{uid}                   # Patient profile + assignedDoctor / assignedCounselor
doctors/{uid}                    # Doctor profile + specialization / department
counselors/{uid}                 # Counsellor profile
guardians/{uid}                  # Guardian profile + assignedPatient

diary_entries/{id}               # Patient diary — content, mood, themes
daily_logs/{id}                  # Daily mood/sleep/medication log
guardian_logs/{id}               # Guardian observations
chat_sessions/{id}               # Chat session metadata
  └── messages/{id}              # Individual chat messages

appointments/{id}                # Appointment records
reschedule_requests/{id}         # Reschedule requests + status

medication_adherence_events/{id} # Medication taken/missed events
app_activity_logs/{id}           # App interaction timestamps
geolocations/{id}                # GPS readings

clinical_reports/{id}            # Generated clinical reports
clinical_alerts/{id}             # XAI-triggered clinical alerts
analytics_snapshots/{uid}        # Latest XAI snapshot per patient
report_exports/{id}              # PDF export audit log

notifications/{id}               # In-app notification inbox
```

### Key Fields — `patients/{uid}`
```json
{
  "uid": "string",
  "name": "string",
  "email": "string",
  "role": "patient",
  "assignedDoctor": "doctor-uid",
  "assignedCounselor": "counselor-uid",
  "createdAt": "ISO timestamp",
  "fcmToken": "string"
}
```

### Key Fields — `clinical_reports/{id}`
```json
{
  "patientUid": "string",
  "patientName": "string",
  "doctorUid": "string",
  "type": "monthly",
  "startDate": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD",
  "generatedAt": "ISO timestamp",
  "aggregatedSeverity": "stable|watch|warning|critical",
  "band": 0,
  "score": 0.0,
  "textConcernScore": 0.0,
  "confidence": 0.75,
  "summary": { "action": "...", "screeningNote": "...", "entryCount": 0 },
  "moodTrend": [],
  "adherenceSummary": { "trackedDays": 0, "takenDays": 0, "adherencePercent": null },
  "appointmentSummary": { "total": 0, "byStatus": {}, "rescheduleRequests": 0 },
  "topDrivers": [],
  "themeCounts": {},
  "sourceBreakdown": {},
  "evidence": []
}
```

---

## Testing

### Flutter Tests
```bash
cd mental_health_support_app

# Unit & widget tests
flutter test

# Integration tests (requires running emulator)
flutter test integration_test/
```

### Flask Tests
```bash
cd Hospital_Administration
source venv/bin/activate

# Run full test suite
pytest

# With coverage report
pytest --cov=. --cov-report=html
open htmlcov/index.html   # macOS
# or xdg-open htmlcov/index.html on Linux

# Run specific test category
pytest tests/unit/
pytest tests/integration/
pytest tests/security/
```

Test structure:
```
tests/
├── unit/
│   ├── controllers/   # User management logic
│   ├── models/        # Data model validation
│   ├── services/      # XAI, analysis, clinical report services
│   ├── notifications/ # FCM trigger logic
│   ├── data/          # Seed data integrity
│   └── utils/         # XAI utility functions
├── integration/
│   ├── routes/        # HTTP endpoint smoke tests
│   └── smoke/         # Import and startup checks
└── security/
    └── access_control/ # Role-based access enforcement
```

---

## Security Notes

| Risk | Mitigation |
|---|---|
| `serviceAccountKey.json` in repo | Excluded by `.gitignore` — never commit |
| Hardcoded Flask `secret_key` | Move to `FLASK_SECRET_KEY` env var in production |
| Firestore rules | Deploy `firestore.rules` — patients cannot read each other's data |
| FCM tokens in Firestore | Only readable by the owning patient and their assigned doctor |
| Backend API unauthenticated | `/api/*` endpoints currently have no auth token check — add Firebase ID token verification before production deployment |
| `firebase_options.dart` | Safe to commit (mobile app API keys are not secret by design) |

> **Production checklist**: set `FLASK_SECRET_KEY` via env var, add Firebase ID token middleware to all `/api/*` routes, deploy Firestore rules, serve Flask behind HTTPS (nginx + certbot or a managed platform).

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes with tests
4. Run the full test suite (Flutter + Flask)
5. Push and open a pull request

### Commit Convention
```
feat:     new feature
fix:      bug fix
refactor: code change without feature/fix
docs:     documentation only
test:     tests only
chore:    build/config/tooling
```

### Code Style
- **Flutter/Dart**: `flutter analyze` must pass with no errors. Run `dart format .` before committing.
- **Python**: PEP 8. Run `python -m py_compile *.py` to check for syntax errors.

---

## License

This project is developed for academic and research purposes. All patient data handling must comply with applicable healthcare data regulations (HIPAA, GDPR, or local equivalents) before any clinical deployment.

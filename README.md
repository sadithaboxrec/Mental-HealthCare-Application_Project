# 🧠 Mental Health Care Application

A mobile mental health support system built to monitor patient progress between clinical visits, reduce gaps in care, and provide real-time communication between doctors, patients, counselors, and guardians. Designed with suicide prevention as a core objective by ensuring continuous monitoring, timely medication reminders, instant emotional support, and data-driven clinical decisions.

---

## 📋 About the Project

Traditional mental health care relies heavily on periodic clinic visits, leaving critical gaps in patient monitoring. This application bridges those gaps by capturing daily patient data — mood, sleep, water intake, and medication adherence — and surfacing it to clinicians in an interactive analytics dashboard.

Four roles work together in the system. An admin who is a responsible role in a hospital can creates and manages all accounts through a web dashboard. Doctors prescribe medications, view patient analytics, and manage appointments. Patients log daily health data, access their prescriptions, and connect instantly with a counselor when they need support. Guardians independently observe and log the patient's condition, providing a third-party perspective that helps doctors detect masked distress. Counselors receive real-time notifications when a patient requests support and can begin a chat session immediately.

The system runs automated push notifications for medication reminders, appointment alerts, water intake, and diary prompts — ensuring patients stay on their care plan even between visits.

---

## ✨ Key Features

- **Role-based access** for Doctor, Patient, Counselor, and Guardian
- **Admin web dashboard** to create and manage all accounts
- **Daily mood tracking** 
- **Sleep, water intake, and medication adherence** logging
- **Patient diary** for daily thoughts stored for  AI analysis to detect the sign of self harm, critical level of patient
- **Doctor prescription management** add medicine , dose, meal timing, and time slot scheduling
- **Interactive analytics dashboard** for doctors showing mood charts, water intake, sleep patterns, and medication adherence across any date range
- **Side-by-side patient and guardian data comparison** in analytics to detect actual patient situation.
- **Instant counselor chat** with real-time messaging via Firestore streams
- **Appointment scheduling** with reschedule request and approval workflow
- **Automated push notifications** via Firebase Cloud Messaging with alarm sound
- **Guardian observation logging** for independent third-party patient monitoring
- **Session-persistent login** — users go straight to their dashboard on app open

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Mobile Application | Flutter (Dart) |
| Admin Dashboard | Python Flask |
| Database | Firebase Firestore |
| Authentication | Firebase Authentication |
| Push Notifications | Firebase Cloud Messaging |
| Local Notifications | flutter_local_notifications |
| Task Scheduling | APScheduler |
| Flutter Architecture | Layered — Models, Services, Controllers, Navigation |
| Flask Architecture | MVC — Models, Controllers, Routes, Services |

---

## 💻 How to Install on Your Local Device

### Prerequisites

- [Flutter SDK 3.x or above](https://flutter.dev/docs/get-started/install)
- [Python 3.x](https://www.python.org/downloads/)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- Android Studio or VS Code with Flutter extension
- Android emulator with Google Play or a real Android device

Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

---

### Flutter App

**Step 1 — Clone the repository**
```bash
git clone https://github.com/sadithaboxrec/Mental-HealthCare-Application_Project.git
cd mental_health_support_app
```

**Step 2 — Install dependencies**
```bash
flutter pub get
```

**Step 3 — Connect to Firebase**

Contact the project owner to be added to the Firebase project as an Editor. Then run:
```bash
flutterfire configure
```
Select the project when prompted. This generates `firebase_options.dart` locally on your machine.


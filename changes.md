# UniSphere Project Changelog & Recent Updates

This document tracks all latest features, architectural enhancements, UI/UX changes, and bug fixes across the UniSphere platform for developers and maintainers.

---

## 📌 Latest Release & Updates — August 28, 2026

---

### 1. 👨‍👩‍👦 Dedicated Parent Profile System (`ParentProfileScreen`)
- **New Screen**: Created [`lib/screens/parent/parent_profile_screen.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/screens/parent/parent_profile_screen.dart).
- **Decoupled from Student Profile**: Replaced the previous student profile replication with a tailored Parent & Guardian portal interface showing parent-specific details, emergency contacts, ward count, and account management.
- **Curved Indigo Header Banner**: Pinned top curved royal indigo banner with avatar, guardian name, email, phone, and role badge (`Parent & Guardian Portal`).
- **Liquid Pull-to-Refresh**: Integrated sub-header pull-to-refresh (`AppLiquidPullToRefresh`) animating exclusively underneath the fixed top header banner.
- **Slidable Linked Wards Carousel**:
  - Horizontal `PageView.builder` carousel (`viewportFraction: 0.90`) displaying each linked ward/child card with department, year, semester, register number, and quick actions.
  - Interactive pagination dots dynamically animating with slide index changes.
- **Profile Picture Removal**:
  - Added "Remove Profile Picture" option to bottom modal sheet in both `ProfileScreen` and `ParentProfileScreen`.
  - Full synchronization with Firebase Storage file deletion (`StorageService.deleteFile`) and Firestore database updates across `users`, `students`, `parents`, and `student_profiles`.

---

### 2. 🏢 Dynamic Campus Help & Department Directory
- **Bottom Sheet Modal**: Converted inline directory cards into a clean modal popup accessed via the *Campus Help & Department Directory* setting tile.
- **Dynamic Allocation Lookup (`_getDirectoryContactsForWard`)**:
  - Automatically resolves contacts based on the active student ward's **Department**, **Year**, and **Semester**:
    - **Faculty Advisor / Class Mentor**: Direct phone, email, cabin number, extension, and department allocation.
    - **Head of Department (HOD)**: Department Head name, direct phone/extension, official department email, and office location.
    - **Accounts & Student Fee Desk**: Campus Administrative Office direct helpline and email.
- **Multi-Ward Sibling Switcher**:
  - For parents with multiple registered wards, an interactive choice chip selector allows switching between children (*e.g., Sam vs Saravana*) to instantly display each child's respective Advisor and HOD.
- **One-Tap Actions**: Direct integration with system dialer (`tel:`) and email client (`mailto:`).

---

### 3. 🔔 Institutional Communication & Notification Preferences
- **Bottom Sheet Modal**: Converted bulky inline alert cards into an interactive modal popup accessed via the *Institutional Communication & Alerts* setting tile.
- **Customizable Preference Toggles**:
  - Instant SMS & In-App Attendance Alerts.
  - Semester Fee Deadlines & Invoices.
  - Continuous Assessment Test (CAT) & Semester Results.
  - Institutional Circulars & Campus Notices.

---

### 4. 🛡️ Role Resolution & Strict Dashboard Routing Guards
- **Smart Parent Role Parsing (`UserModel.fromMap`)**:
  - Enhanced `UserModel.fromMap` in [`lib/models/user_model.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/models/user_model.dart) to check `role`, `userRole`, `metadata['role']`, and auto-detect `UserRole.parent` when `wardRegisterNumbers`, `childRegisterNumbers`, or `studentIds` exist.
- **Cross-Collection Verification (`FirebaseAuthService`)**:
  - Added verification against `parents/{uid}` in [`lib/services/firebase_auth_service.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/services/firebase_auth_service.dart) to guarantee parent accounts never fallback to student defaults.
  - Automatically saves parent documents with `userRole: 'parent'` on signup.
- **Strict Router & Dashboard Guards**:
  - Added redirection in [`lib/navigation/app_router.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/navigation/app_router.dart) redirecting parent users attempting to visit `/student` directly to `/parent`.
  - Added in-component guard in [`lib/screens/student/student_dashboard.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/screens/student/student_dashboard.dart) rendering `ParentDashboard()` if the authenticated user has `UserRole.parent`.

---

### 5. 🎨 Onboarding & Authentication Enhancements
- **Hero Artwork & Floating Badges**:
  - Implemented glowing multi-role onboarding carousel with custom artwork, glowing role capsules, and smooth step transitions.
- **Student Register Number Validation**:
  - Enforced exact 12-digit numeric register numbers (`RegExp(r'^[0-9]{12}$')`).
  - Pre-signup database check against institutional records (`ParentService.lookupStudentByRegNo`).
  - Sibling duplicate prevention for parent multi-ward registration.
- **User Session & Smart Greetings (`UserSessionService`)**:
  - Differentiates first-time signups (*"Welcome to UniSphere"*) from returning user logins (*"Welcome Back"*).
  - Preserves per-user login timestamps across sessions.

---

### 6. 📊 Automated Notification Engine & Deduplication
- **Automated Scheduling Engine (`NotificationSchedulerService`)**:
  - Automated evaluation for student fee due dates, parent fee alerts, registered hackathon reminders, and HOD department attendance alerts.
- **Deterministic Deduplication**:
  - Generated composite deduplication keys (`ruleId_recipientUserId_eventId`) with configurable cooldown windows to prevent notification spamming.

---

## 📂 Key Modified & Added Files

| File Path | Description |
|---|---|
| [`lib/screens/parent/parent_profile_screen.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/screens/parent/parent_profile_screen.dart) | Dedicated Parent Profile screen with fixed header, slidable wards carousel, and popup sheets. |
| [`lib/screens/parent/parent_dashboard.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/screens/parent/parent_dashboard.dart) | Connected tab 4 navigation to `ParentProfileScreen`. |
| [`lib/screens/profile/profile_screen.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/screens/profile/profile_screen.dart) | Parent delegation check and profile picture removal with database & storage sync. |
| [`lib/models/user_model.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/models/user_model.dart) | Enhanced role parser with multi-source metadata & ward detection. |
| [`lib/services/firebase_auth_service.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/services/firebase_auth_service.dart) | Parent collection verification and Firestore synchronization. |
| [`lib/services/storage_service.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/services/storage_service.dart) | Added `deleteFile(String path)` for Firebase Storage cleanup. |
| [`lib/services/user_session_service.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/services/user_session_service.dart) | Fresh signup vs returning user session tracking. |
| [`lib/navigation/app_router.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/navigation/app_router.dart) | Strict cross-role redirect guards for `/parent` and `/student`. |
| [`lib/screens/student/student_dashboard.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/screens/student/student_dashboard.dart) | Role guard rendering `ParentDashboard` for parent users. |

---

## 🧪 Testing & Verification Status

- **Test Suite Pass Rate**: **100% (55/55 test suites passing)**
- **Commands Executed**:
  ```bash
  flutter test
  ```
- **Key Test Areas Covered**:
  - `widget_test.dart`: App smoke tests & router flow.
  - `parent_notification_system_test.dart`: Parent notification stream isolation & rule engine.
  - `automated_notification_system_test.dart`: Deduplication key generation & cooldown verification.
  - `user_session_greeting_test.dart`: Fresh signup vs returning login state isolation.
  - `onboarding_screen_test.dart`: Role selection, validation & navigation.

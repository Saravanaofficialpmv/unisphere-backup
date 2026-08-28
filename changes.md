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

### 7. 📸 Production-Ready Profile Photo Upload Pipeline (Firebase Storage + Firestore)
- **Direct Firebase Storage Upload**:
  - Added `StorageService.uploadProfilePhoto({required String userId, required File file})` in [`lib/services/storage_service.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/services/storage_service.dart).
  - Organizes photos under versioned paths: `profile_photos/{userId}/profile_{timestamp}.jpg`.
  - Attaches `image/jpeg` contentType metadata and uploads directly via `FirebaseStorage.instance.ref().putFile()`.
  - Automatically fetches and returns the verified HTTPS download URL.
- **Strict Firestore Sanitization**:
  - Guarded `FirebaseAuthService.saveUserData` in [`lib/services/firebase_auth_service.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/services/firebase_auth_service.dart) to only accept and persist remote URLs starting with `http://` or `https://`.
  - Strips local simulator/device paths (`/Users/...`, `/tmp/...`, `file://...`, `/data/...`) ensuring local paths are **never** persisted to Firestore across `users`, `students`, `parents`, and `student_profiles` collections.
- **End-to-End UI Photo Flow**:
  - Refactored `_pickAndUploadPhoto` in [`ProfileScreen`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/screens/profile/profile_screen.dart) and [`ParentProfileScreen`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/screens/parent/parent_profile_screen.dart):
    - Picks image locally -> uploads to Firebase Storage -> persists HTTPS download URL to Firestore -> deletes old storage photo upon successful replacement.
    - Automatic rollback: deletes newly uploaded Storage file if subsequent Firestore write fails.
    - Prevents double-taps with `_isUploadingPhoto` busy lock.
  - Refactored passport photo upload in [`StudentProfileCompletionSheet`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/widgets/student/student_profile_completion_sheet.dart).
- **Safe Avatar Rendering & Backward Compatibility**:
  - Safeguarded `_buildProfileHeaderAvatar`, `_buildParentAvatar`, `_buildPassportPhotoAvatar`, and `_buildWardPhotoAvatar` across screens.
  - Only triggers network image loads for valid remote URLs (`http://` or `https://`), gracefully displaying default initials/placeholder icons for legacy local paths or empty values without crashing or throwing HTTP exceptions.
- **Storage Security Rules**:
  - Updated [`storage.rules`](file:///Users/saravana/Downloads/unisphere-main-v2/storage.rules) to permit authenticated reads and owner writes for `profile_photos/{userId}/{fileName}` and `profile-photos/{userId}/{fileName}`.

---

### 7. 📸 Parent Photo Inheritance from Student Profile & Relationship Onboarding
- **Student Profile Parent Photos Upload (`StudentProfileCompletionSheet`)**:
  - Enhanced Step 3 (Parent & Guardian Details) in [`lib/widgets/student/student_profile_completion_sheet.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/widgets/student/student_profile_completion_sheet.dart):
    - Added instant camera/gallery photo pickers for both **Father** and **Mother**.
    - Direct Firebase Storage upload via `storageService.uploadProfilePhoto` storing high-resolution HTTPS download URLs.
    - Added photo status badge (`Photo Added ✓`) and interactive circular preview avatars.
    - Synchronized `fatherPhotoUrl` and `motherPhotoUrl` across `student_profiles`, `students`, and `users` Firestore collections via `FirebaseFirestoreService.submitFullStudentProfile`.
- **Parent Onboarding & Registration Relationship Selector**:
  - In [`lib/screens/onboarding/onboarding_screen.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/screens/onboarding/onboarding_screen.dart):
    - Added interactive Relationship Selector chips (**Father**, **Mother**, **Guardian**) with custom icons and haptic feedback in Step 3 for Parents.
    - Forwarded `relationship` in query parameters to `/signup`.
  - In [`lib/screens/auth/auth_screen.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/screens/auth/auth_screen.dart):
    - Added `initialRelationship` parameter and interactive relationship selector in the Parent signup form.
    - Persisted `relationship` in `UserModel`, `metadata['relationship']`, and Firestore `parents` & `users` collections during registration.
  - In [`lib/navigation/app_router.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/navigation/app_router.dart):
    - Passed `initialRelationship: queryParams['relationship']` from `/signup` route to `AuthScreen`.
- **Dynamic Parent Avatar Resolution (`ParentService.resolveParentPhotoFromWards`)**:
  - Added helper in [`lib/services/parent_service.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/services/parent_service.dart) to dynamically resolve the parent's avatar photo:
    - If the parent user hasn't explicitly uploaded their own custom photo, it automatically resolves and uses the corresponding photo uploaded by their student ward based on relationship (*Father -> `fatherPhotoUrl`, Mother -> `motherPhotoUrl`, Guardian -> `guardianPhotoUrl`*).
    - Seamlessly displayed across `ParentProfileScreen`, `ParentDashboard` top banner, `MainSidebar`, and floating navigation sheet.
- **Model Enhancements (`ParentStudentWard`)**:
  - Updated [`lib/models/parent_portal_types.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/models/parent_portal_types.dart) to include `fatherPhotoUrl`, `motherPhotoUrl`, and `guardianPhotoUrl`.

---

## 📂 Key Modified & Added Files

| File Path | Description |
|---|---|
| [`lib/models/parent_portal_types.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/models/parent_portal_types.dart) | Added `fatherPhotoUrl`, `motherPhotoUrl`, `guardianPhotoUrl` to `ParentStudentWard`. |
| [`lib/services/parent_service.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/services/parent_service.dart) | Added `resolveParentPhotoFromWards` and student parent photo extraction. |
| [`lib/widgets/student/student_profile_completion_sheet.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/widgets/student/student_profile_completion_sheet.dart) | Added photo uploaders for Father & Mother with Firebase Storage upload and safe UI previews. |
| [`lib/services/firebase_firestore_service.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/services/firebase_firestore_service.dart) | Synchronized parent photos across `student_profiles`, `students`, and `users`. |
| [`lib/screens/onboarding/onboarding_screen.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/screens/onboarding/onboarding_screen.dart) | Added parent relationship selector chips (Father / Mother / Guardian) in onboarding. |
| [`lib/screens/auth/auth_screen.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/screens/auth/auth_screen.dart) | Added relationship selection and metadata persistence in parent registration. |
| [`lib/navigation/app_router.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/navigation/app_router.dart) | Forwarded relationship query parameter to `AuthScreen`. |
| [`lib/screens/parent/parent_profile_screen.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/screens/parent/parent_profile_screen.dart) | Auto-resolves parent photo from ward's father/mother photo. |
| [`lib/screens/parent/parent_dashboard.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/screens/parent/parent_dashboard.dart) | Passes resolved ward parent photo to `MainSidebar` and navigation sheet. |
| [`lib/services/database_seeder.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/services/database_seeder.dart) | Seeded demo student parent photos and parent relationship. |
| [`test/parent_photo_linkage_test.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/test/parent_photo_linkage_test.dart) | Comprehensive test suite for parent photo linkage & relationship resolution. |
| [`lib/services/storage_service.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/services/storage_service.dart) | Added `uploadProfilePhoto` and enhanced `deleteFile` to handle Firebase Storage URLs safely. |
| [`lib/services/firebase_auth_service.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/services/firebase_auth_service.dart) | Sanitized `saveUserData` to strictly persist valid remote HTTP/HTTPS photo URLs. |
| [`lib/screens/profile/profile_screen.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/screens/profile/profile_screen.dart) | Production-ready photo upload flow with Firebase Storage and safe avatar rendering. |
| [`storage.rules`](file:///Users/saravana/Downloads/unisphere-main-v2/storage.rules) | Added security rules for `profile_photos` path. |
| [`test/profile_photo_upload_test.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/test/profile_photo_upload_test.dart) | Unit test suite for photo upload pathing, URL sanitization, and storage safety. |
| [`lib/models/user_model.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/models/user_model.dart) | Enhanced role parser with multi-source metadata & ward detection. |
| [`lib/screens/student/student_dashboard.dart`](file:///Users/saravana/Downloads/unisphere-main-v2/lib/screens/student/student_dashboard.dart) | Role guard rendering `ParentDashboard` for parent users. |

---

## 🧪 Testing & Verification Status

- **Test Suite Pass Rate**: **100% (66/66 tests passing, 0 failures)**
- **Static Analysis**: **0 issues found (`flutter analyze` clean)**
- **Commands Executed**:
  ```bash
  flutter test
  flutter analyze
  ```
- **Key Test Areas Covered**:
  - `parent_photo_linkage_test.dart`: Parent photo inheritance, relationship resolution (Father/Mother/Guardian) & priority fallbacks.
  - `profile_photo_upload_test.dart`: Profile photo storage safety, URL sanitization & UserModel copy.
  - `widget_test.dart`: App smoke tests & router flow.
  - `parent_notification_system_test.dart`: Parent notification stream isolation & rule engine.
  - `automated_notification_system_test.dart`: Deduplication key generation & cooldown verification.
  - `user_session_greeting_test.dart`: Fresh signup vs returning login state isolation.
  - `parent_multi_child_test.dart`: Sibling link, ward resolution & multi-child parsing.
  - `onboarding_screen_test.dart`: Role selection, validation & navigation.



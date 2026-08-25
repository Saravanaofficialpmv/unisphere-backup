# UNISPHERE SRM — Developer Handbook & UI/UX Guidelines

> **Welcome to the Unisphere Development Team!**  
> This handbook is your daily guide to building screens in **UNISPHERE CMS** (`unisphere-main-v2`).  
> Everything you need—colors, buttons, cards, loading spinners, and coding rules—is already built for you.  
> **Follow this guide so all 4 portals look and feel like one unified, high-quality application.**

---

## 📌 Quick Summary for Beginners (The 5 Golden Rules)

1. **NEVER hardcode colors** like `Color(0xFF2563EB)`. Always use `AppColors.primary`, `AppColors.success`, etc.
2. **NEVER build a screen header from scratch**. Always put `UnisphereHeaderCard` at the top of your screen.
3. **NEVER use raw `CircularProgressIndicator()` in buttons**. Use `Loader.button()` or `Loader.page()`.
4. **NEVER copy-paste entire files or navigation bars**. Look inside `lib/widgets/common/` first.
5. **Always test on Mobile (< 800px) and Desktop (>= 800px)** before submitting a Pull Request.

---

## 1. Project Overview & Folder Structure

Our app is built with **Flutter**, **Riverpod** (for state), and **GoRouter** (for navigation). It connects to **Firebase** and **Supabase**.

```
lib/
├── core/
│   ├── constants/       # 🎨 COLORS & CONSTANTS (AppColors, AppDepartments)
│   └── theme/           # 🎭 THEME & ANIMATIONS (AppTheme, AppAnimations)
├── navigation/          # 🧭 ROUTER (app_router.dart)
├── models/              # 📦 DATA MODELS (UserModel, StudentProfile, etc.)
├── providers/           # ⚡ RIVERPOD PROVIDERS (Gradebook, Notifications, etc.)
├── services/            # 🌐 API & DATABASE (Firestore, Auth, Storage, etc.)
├── controllers/         # 🧠 BUSINESS LOGIC (HackathonController, etc.)
├── screens/             # 📱 ALL APP SCREENS (Separated by Portal)
│   ├── student/         # 🟦 Student Portal Screens
│   ├── staff/           # 🟪 Faculty / Staff Portal Screens
│   ├── hod/             # 🟧 HOD Portal Screens
│   ├── parent/          # 🟩 Parent Portal Screens
│   ├── admin/           # 🟥 Admin Portal Screens
│   ├── auth/            # Login & Signup Screens
│   └── features/        # Shared screens (Hackathons, Certifications, Fees, etc.)
└── widgets/             # 🧩 REUSABLE WIDGETS
    ├── common/          # ⭐ Universal widgets (Header cards, Loaders, Sidebar, Glass card)
    ├── student/         # Student-specific widgets
    ├── parent/          # Parent-specific widgets
    ├── hackathons/      # Hackathon dialogs & cards
    └── exams/           # Exam cards & hall ticket modal
```

---

## 2. Color Palette Cheat Sheet

All colors live in `lib/core/constants/app_colors.dart`. Import it at the top of your file:
```dart
import 'package:unisphere/core/constants/app_colors.dart';
```

### 🎨 2.1 Brand & Neutral Colors

| What to Use | Token Name | Hex Code | When to Use It |
|---|---|---|---|
| 🟦 **Brand Blue** | `AppColors.primary` | `#2563EB` | Primary buttons, active tabs, main header gradient |
| 🔷 **Light Blue** | `AppColors.primaryLight` | `#3B82F6` | Hover states, button gradient highlights |
| 🔵 **Dark Blue** | `AppColors.primaryDark` | `#1D4ED8` | Selected pill borders, header card background |
| 🩵 **Soft Blue Tint** | `AppColors.primarySubtle` | `#EEF2FF` | Icon circle background, subtle tag background |
| ⚪ **Pure White** | `AppColors.background` | `#FFFFFF` | Page canvas, card backgrounds |
| 🪨 **Off-White / Slate 50** | `AppColors.backgroundSubtle`| `#F8FAFC` | Screen background behind cards, table rows |
| 🔘 **Gray Surface** | `AppColors.surfaceSecondary`| `#F1F5F9` | Search bars, filter pill background |
| ⬛ **Main Text (Dark)** | `AppColors.textPrimary` | `#0F172A` | Titles, bold headings, primary readable text |
| ◽ **Secondary Text** | `AppColors.textSecondary` | `#64748B` | Subtitles, descriptions, input labels |
| ▫️ **Muted Text / Hint** | `AppColors.textTertiary` | `#94A3B8` | Input placeholder text, timestamps |
| ➖ **Border Line** | `AppColors.border` | `#E2E8F0` | Card borders, input field outlines |

---

### 👑 2.2 Portal Role Colors (Every Portal Has Its Own Color)

* 🟦 **Student Portal**: `AppColors.studentRole` (`#2563EB` — Royal Blue)
* 🟪 **Faculty / Staff Portal**: `AppColors.staffRole` (`#7C3AED` — Royal Purple)
* 🟧 **HOD Department Portal**: `AppColors.hodRole` (`#D97706` — Deep Amber)
* 🟩 **Parent Portal**: `AppColors.parentRole` (`#059669` — Emerald Teal)
* 🟥 **Admin Control Portal**: `AppColors.adminRole` (`#DC2626` — Crimson Red)

---

### 🚦 2.3 Status & Semantic Colors (Success, Error, Warning)

| Status | Main Color | Light Background Tint | Example Usage |
|---|---|---|---|
| 🟢 **Success / Passed** | `AppColors.success` (`#10B981`) | `AppColors.successLight` (`#E8F5E9`) | Attendance > 75%, Form saved, Approved |
| 🟡 **Warning / Pending** | `AppColors.warning` (`#F59E0B`) | `AppColors.warningLight` (`#FEF3C7`) | Safe margin, Pending approvals, Due soon |
| 🔴 **Error / Critical** | `AppColors.error` (`#EF4444`) | `AppColors.errorLight` (`#FEE2E2`) | Attendance < 75%, Validation error, Rejected |
| 🔵 **Info / Notice** | `AppColors.info` (`#3B82F6`) | `AppColors.infoLight` (`#E0F2FE`) | General announcements, info badges |

```dart
// ❌ WRONG (Do not do this)
Container(color: Color(0xFF10B981))
Text('Approved', style: TextStyle(color: Colors.green))

// ✅ CORRECT (Always do this)
Container(color: AppColors.successLight)
Text('Approved', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold))
```

---

## 3. Common Mistakes to Avoid

| Severity | Mistake Found in Code | Why It's Bad | What to Do Instead |
|---|---|---|---|
| 🔴 **HIGH** | Writing `Color(0xFF...)` directly in widgets | Inconsistent colors, dark mode breaks | Use `AppColors.<token>` |
| 🔴 **HIGH** | Duplicating navigation bars or sheets | 1,500+ lines of wasted duplicate code | Use the shared widgets in `lib/widgets/common/` |
| 🔴 **HIGH** | Using raw `CircularProgressIndicator()` in buttons | Sizes & colors look messy and misaligned | Use `Loader.button(size: 20)` |
| 🟡 **MED** | Hardcoding input borders (e.g. `borderRadius: 8`) | Inputs look different across pages | Standard is `BorderRadius.circular(12)` |
| 🟡 **MED** | Using `ScaffoldMessenger` with plain red boxes | Ugly square notifications | Use floating rounded SnackBars with `AppColors.success` / `error` |
| 🟡 **MED** | Writing raw `Text('No data')` in the middle of page | Poor empty state UX | Use `AppEmptyState` with an icon & action button |
| 🟢 **LOW** | Using deprecated `.withOpacity(0.5)` | Generates compile warnings | Use `.withValues(alpha: 0.5)` |

---

## 4. Ready-to-Use UI Templates (Copy & Paste)

### 4.1 Page Header (`UnisphereHeaderCard`)
Place this at the top of any sub-page or detail screen:

```dart
import 'package:flutter/material.dart';
import 'package:unisphere/widgets/common/unisphere_header_card.dart';

Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          // ⭐ 1. THE STANDARD HEADER CARD
          UnisphereHeaderCard(
            title: 'Examinations & Hall Ticket',
            subtitle: 'End Semester & Internal Assessment Schedules',
            onBack: () => Navigator.of(context).pop(),
            onInfoPressed: () {
              // Optional: show info dialog or bottom sheet
            },
          ),
          
          // 2. YOUR PAGE CONTENT
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Your cards here
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
```

---

### 4.2 Standard List / Data Card (`AppCardPressable`)
Use this for list items, subjects, assignments, or clickable tiles. It includes a smooth tap animation:

```dart
import 'package:flutter/material.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/core/theme/app_animations.dart';

Widget buildCourseCard({
  required String title,
  required String code,
  required String faculty,
  required VoidCallback onTap,
}) {
  return AppCardPressable(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.border, width: 1),
    color: AppColors.cardBackground,
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        // Left Icon Box
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primarySubtle,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        // Title and Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$code • $faculty',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        // Right Arrow
        const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
      ],
    ),
  );
}
```

---

### 4.3 Frosted Glass Greeting / Highlight Banner (`AppleGlassCard`)
Use this for welcome greetings or high-priority hero summaries:

```dart
import 'package:flutter/material.dart';
import 'package:unisphere/widgets/common/apple_glass_card.dart';

// Blue Hero Banner
AppleGlassCard.blueBanner(
  padding: const EdgeInsets.all(20.0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Welcome back, Saran!',
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      const Text(
        'B.Tech AI & Data Science • Semester 6',
        style: TextStyle(color: Color(0xFFBFDBFE), fontSize: 12),
      ),
    ],
  ),
)
```

---

### 4.4 Buttons (Primary, Secondary, Destructive, Filter Chips)

```dart
import 'package:flutter/material.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/widgets/common/custom_loader.dart';

// 1. PRIMARY SUBMIT BUTTON (With Loading State)
ElevatedButton(
  onPressed: isLoading ? null : _handleSave,
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 0,
  ),
  child: isLoading
      ? const Loader.button(size: 20)
      : const Text('Submit Assignment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
)

// 2. SECONDARY / CANCEL BUTTON
OutlinedButton(
  onPressed: () => Navigator.pop(context),
  style: OutlinedButton.styleFrom(
    foregroundColor: AppColors.textSecondary,
    side: const BorderSide(color: AppColors.border),
    minimumSize: const Size(double.infinity, 48),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
)

// 3. DESTRUCTIVE / DELETE BUTTON
ElevatedButton(
  onPressed: _handleDelete,
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 48),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  child: const Text('Delete Record', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
)

// 4. PILL FILTER CHIP (For Tabs & Filter bars)
GestureDetector(
  onTap: () => setState(() => _selectedFilter = 'All'),
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: isSelected ? AppColors.primary : AppColors.surfaceSecondary,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      'All Students',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
    ),
  ),
)
```

---

### 4.5 Form Input Fields (`TextFormField`)

```dart
TextFormField(
  controller: _nameController,
  decoration: InputDecoration(
    labelText: 'Full Name',
    hintText: 'e.g. Saran Kumar',
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error),
    ),
  ),
  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a name' : null,
)
```

---

### 4.6 Loading States (Skeletons & Spinners)

```dart
import 'package:unisphere/widgets/common/custom_loader.dart';

// 1. When a full screen is loading data:
if (isLoading) {
  return const Loader.page(label: 'Loading student marks...');
}

// 2. When a list is loading, show shimmer placeholders (better UX):
if (isLoadingList) {
  return AppSkeletonLoader.list(itemCount: 5);
}

// 3. For async wrapper with auto debounce, error retry, and empty state:
return DataLoaderView<List<Assignment>>(
  isLoading: isLoading,
  errorMessage: errorText,
  onRetry: _fetchAssignments,
  isEmpty: assignments.isEmpty,
  emptyWidget: const AppEmptyState(
    icon: Icons.assignment_outlined,
    title: 'No Assignments Found',
    subtitle: 'You have no pending assignments for this semester.',
  ),
  child: ListView.builder(...),
);
```

---

### 4.7 Standard Empty State (`AppEmptyState`)

Whenever a list or search result has no items, display this:

```dart
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: AppColors.surfaceSecondary,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

### 4.8 Standard Success & Error Toast Messages

```dart
// SUCCESS TOAST (Green Floating Bubble)
void showSuccessToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.success,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ),
  );
}

// ERROR TOAST (Red Floating Bubble)
void showErrorToast(BuildContext context, String errorMessage) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.error,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      content: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(errorMessage, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ),
  );
}
```

---

## 5. Developer Team Ownership & Responsibilities

Here is the exact task allocation for the 4 developers:

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                               DEVELOPER PORTAL OWNERSHIP MATRIX                                 │
├──────────────┬────────────────────────────────┬───────────────────────────┬─────────────────────┤
│ Developer    │ Portals & Feature Ownership    │ Shared Responsibilities   │ Lead Review Focus   │
├──────────────┼────────────────────────────────┼───────────────────────────┼─────────────────────┤
│ 1. Lead /    │ • Student Portal & Dashboard   │ • Design System (`core/`) │ • All PR UI reviews │
│    UI-UX     │ • Gradebook & CGPA Planner     │ • Common Widgets          │ • Architecture &    │
│              │ • Resume Engine & PYQ Bank     │ • App Router & Shells     │   Routing Changes   │
│              │ • Shared Features (Hackathon,  │ • Release Packaging       │ • State Models & DB │
│              │   LeetCode, GitHub, Certs)     │                           │   Schema Governance │
├──────────────┼────────────────────────────────┼───────────────────────────┼─────────────────────┤
│ 2. Faculty   │ • Staff Dashboard & Details    │ • Shared Tasks & Exporters│ • Marks upload      │
│    Developer │ • Marks Upload & Attendance    │ • Student Directory Table │   validation flows  │
│              │ • Assignment Management        │ • NPTEL / Resume Review   │ • Attendance batch  │
│              │ • Question Paper Upload        │   Shared Interfaces       │   marking accuracy  │
│              │ • Submission Review Center     │                           │                     │
├──────────────┼────────────────────────────────┼───────────────────────────┼─────────────────────┤
│ 3. HOD       │ • HOD Shell & Dashboard        │ • Department Vision Sheet │ • Charter & CO/PO   │
│    Developer │ • Staff & Student Governance   │ • Academic Schedule Card  │   upload integrity  │
│              │ • Syllabus & Charter Upload    │ • Photo Album Manager     │ • Leave/OD approval │
│              │ • Leave / OD Approval Workflows│ • Notification Composer   │   security rules    │
│              │ • Department Analytics Reports │                           │                     │
├──────────────┼────────────────────────────────┼───────────────────────────┼─────────────────────┤
│ 4. Parent +  │ • Parent Dashboard & Wards     │ • Auth & Onboarding Flow  │ • Role Permission   │
│    Admin     │ • Child Attendance / CGPA / Fee│ • User Management Module  │   Control (RBAC)    │
│    Developer │ • Admin Dashboard & RBAC Rules │ • Notification Automation │ • Parent-Student    │
│              │ • Department & System Settings │ • System Health & Reports │   linkage security  │
└──────────────┴────────────────────────────────┴───────────────────────────┴─────────────────────┘
```

---

## 6. Daily Development Workflow for Freshers

### Step 1: Creating your Feature Branch
Never write code directly on `main` or `develop`. Create a branch from `develop`:
```bash
git checkout develop
git pull origin develop
git checkout -b feat/student-attendance-fix
```

### Step 2: Running the Project
```bash
flutter pub get
flutter run
```

### Step 3: Check for Lint & Code Errors
Before committing, always run:
```bash
flutter analyze
```
Fix all warnings and errors until it says `No issues found!`.

### Step 4: Commit & Push
```bash
git add .
git commit -m "feat(student): standardize attendance card and colors"
git push origin feat/student-attendance-fix
```

### Step 5: Open a Pull Request (PR)
1. Open PR against the **`develop`** branch (NOT `main`).
2. Copy and paste the checklist below into your PR description.
3. Tag the **Lead Developer** for UI review.

---

## 7. Pull Request Checklist (Copy-Paste this into every PR)

```markdown
## 📋 Developer PR Checklist

### UI / UX Compliance
- [ ] Used `AppColors.*` tokens (No raw `Color(0xFF...)` hardcoded).
- [ ] Screen has `UnisphereHeaderCard` at the top with back button.
- [ ] Buttons use `Loader.button(size: 20)` for async loading states.
- [ ] Lists have empty state handling using `AppEmptyState`.
- [ ] Toasts/SnackBars use floating rounded style with `AppColors.success` or `AppColors.error`.

### Responsive Layout & Code Quality
- [ ] Tested on Mobile width (<800px) and Desktop width (>=800px).
- [ ] Ran `flutter analyze` and got 0 errors / 0 warnings.
- [ ] No `print()` statements left in code.
- [ ] Checked `lib/widgets/common/` to avoid duplicate code.
```

---

## 8. Summary of Top 5 Things to Fix in the Codebase

1. **Delete `lib/screens/admin/admin_sidebar.dart`**: It is unused code (`AdminShell` already uses `MainSidebar`).
2. **Consolidate Navigation Bars**: Replace duplicate `student_floating_nav_bar.dart` and `parent_floating_nav_bar.dart` with a single shared widget in `lib/widgets/common/`.
3. **Consolidate Drawer Sheets**: Replace duplicate `student_navigation_sheet.dart` and `parent_navigation_sheet.dart` with a single shared widget.
4. **Replace Raw Spinners**: Search for `CircularProgressIndicator` in your module and replace with `Loader.button()` or `Loader.inline()`.
5. **Clean up Colors**: Replace inline hex codes (e.g. `Color(0xFF16A34A)`) with `AppColors.success`.

---

## 9. Quick Widget Reference (Where is everything?)

| Widget Name | File Path | What it is |
|---|---|---|
| `UnisphereHeaderCard` | `lib/widgets/common/unisphere_header_card.dart` | Royal blue header for sub-pages |
| `AppleGlassCard` | `lib/widgets/common/apple_glass_card.dart` | Frosted glass cards and greeting banners |
| `Loader` | `lib/widgets/common/custom_loader.dart` | Animated character loader (`assets/tibsy-dp.gif`) |
| `DataLoaderView` | `lib/widgets/common/custom_loader.dart` | Full page loader wrapper with timeout safety |
| `AppSkeletonLoader` | `lib/widgets/common/custom_loader.dart` | Shimmer placeholder for lists and cards |
| `MainSidebar` | `lib/widgets/common/main_sidebar.dart` | Desktop 280px navigation sidebar |
| `NotificationSheet` | `lib/widgets/common/notification_sheet.dart` | Slide-up modal for institutional notices |
| `DepartmentVisionSheet` | `lib/widgets/common/department_vision_sheet.dart` | Department Vision, Mission, and PEOs sheet |
| `AppCircularGauge` | `lib/widgets/common/app_progress_indicators.dart` | Reliable circular attendance meter |
| `AppLinearProgressBar` | `lib/widgets/common/app_progress_indicators.dart` | Reliable linear progress bar |
| `AppLiquidPullToRefresh` | `lib/widgets/common/app_liquid_pull_to_refresh.dart` | Smooth pull-to-refresh container |
| `AppCardPressable` | `lib/core/theme/app_animations.dart` | Tap-scale wrapper for list cards |
| `AppPressable` | `lib/core/theme/app_animations.dart` | Tap-scale wrapper for buttons & icons |

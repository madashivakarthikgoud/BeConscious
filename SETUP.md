# BeConscious - Setup Guide

## Quick Start (Works Immediately - No Firebase Needed)

```bash
# 1. Navigate to project folder
cd BeConscious

# 2. Generate Flutter project files (won't overwrite your lib/ code)
flutter create --org com.shivakarthik --project-name beconscious .

# 3. Install dependencies
flutter pub get

# 4. Run on device or emulator
flutter run

# 5. Build release APK
flutter build apk --release
# APK at: build/app/outputs/flutter-apk/app-release.apk
```

The app works fully offline with Hive local storage. All features work without Firebase.

---

## Firebase Setup (For Google Account Cloud Sync)

### Step 1: Create Firebase Project
1. Go to https://console.firebase.google.com
2. Click "Add Project" → Name it "BeConscious"
3. Disable Google Analytics (not needed) → Create Project

### Step 2: Add Android App
1. In Firebase console → Click Android icon
2. Package name: `com.shivakarthik.beconscious`
3. App nickname: `BeConscious`
4. SHA-1 (for Google Sign-In):
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Copy the SHA1 from the debug variant
5. Download `google-services.json`
6. Place it in: `android/app/google-services.json`

### Step 3: Enable Services
1. **Authentication**: Go to Build → Authentication → Sign-in method → Enable "Google"
2. **Firestore**: Go to Build → Firestore Database → Create database → Start in test mode

### Step 4: Update Android Build Files

**`android/build.gradle`** — Add to buildscript dependencies:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.2'
    }
}
```

**`android/app/build.gradle`** — Add at bottom:
```gradle
apply plugin: 'com.google.gms.google-services'
```

Also set minSdkVersion to 23:
```gradle
defaultConfig {
    minSdkVersion 23
}
```

### Step 5: Uncomment Firebase in Code

**`pubspec.yaml`** — Uncomment these lines:
```yaml
  firebase_core: ^3.3.0
  firebase_auth: ^5.1.4
  cloud_firestore: ^5.2.1
  google_sign_in: ^6.2.1
```

**`lib/main.dart`** — Uncomment:
```dart
import 'package:firebase_core/firebase_core.dart';
// and
await Firebase.initializeApp();
```

### Step 6: Run
```bash
flutter pub get
flutter run
```

---

## Enable USB Debugging on Realme GT6
1. Settings → About Phone → Tap "Build Number" 7 times
2. Settings → Additional Settings → Developer Options
3. Enable "USB Debugging"
4. Connect USB → Allow debugging when prompted

---

## File Structure
```
lib/
├── main.dart                              # App entry point
├── core/
│   ├── constants/app_constants.dart       # Currency formatting, dates
│   ├── theme/app_theme.dart               # Dark/Light themes (AMOLED)
│   └── router/app_router.dart             # All navigation routes
├── data/
│   ├── models/
│   │   ├── transaction_model.dart         # Expense/Income model
│   │   ├── loan_model.dart                # Loan + interest calculations
│   │   └── savings_model.dart             # Savings goal model
│   └── datasources/local/
│       └── local_database.dart            # Hive local storage
├── presentation/
│   ├── providers/app_providers.dart       # All Riverpod state providers
│   ├── widgets/shell_screen.dart          # Bottom nav + FAB
│   └── screens/
│       ├── home/home_screen.dart          # Dashboard
│       ├── transactions/
│       │   ├── transactions_screen.dart   # Transaction list + filters
│       │   └── add_transaction_screen.dart # Add/Edit transaction
│       ├── loans/
│       │   ├── loans_screen.dart          # Loan list (Borrowed/Lent)
│       │   ├── add_loan_screen.dart       # Add/Edit loan
│       │   └── loan_detail_screen.dart    # Full loan breakdown
│       ├── savings/
│       │   ├── savings_screen.dart        # Savings goals list
│       │   ├── add_savings_screen.dart    # Create goal
│       │   └── savings_detail_screen.dart # Goal progress + contributions
│       ├── analytics/analytics_screen.dart # Charts & reports
│       └── settings/settings_screen.dart  # Export, manage tags/persons
└── services/
    ├── auth_service.dart                  # Google Sign-In (after Firebase)
    ├── sync_service.dart                  # Cloud sync (after Firebase)
    └── backup_service.dart                # JSON/CSV export
```


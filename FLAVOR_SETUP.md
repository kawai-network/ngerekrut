# Multi-Flavor Setup Guide

This project supports **two separate apps** from a single codebase:

## 📱 Apps

1. **NgeRekrut** (Recruiter App)
   - Package ID: `com.ngerekrut.recruiter`
   - For: Employers/Recruiters
   - Features: Job posting, candidate screening, AI hiring assistant

2. **NgeKerja** (Job Seeker App)
   - Package ID: `com.ngerekrut.jobseeker`
   - For: Job seekers/candidates
   - Features: Job search, application tracking, interview prep, AI career coach

## 🚀 Running the Apps

### Android

```bash
# Recruiter app
flutter run --flavor recruiter -t lib/main_recruiter.dart

# Job Seeker app
flutter run --flavor jobseeker -t lib/main_jobseeker.dart
```

### Build APK

```bash
# Recruiter APK
flutter build apk --flavor recruiter -t lib/main_recruiter.dart

# Job Seeker APK
flutter build apk --flavor jobseeker -t lib/main_jobseeker.dart
```

### iOS

iOS requires Firebase configuration (see below). Once configured:

```bash
# Recruiter app
flutter run --flavor recruiter -t lib/main_recruiter.dart

# Job Seeker app
flutter run --flavor jobseeker -t lib/main_jobseeker.dart
```

## ⚙️ Configuration Required

### 1. Firebase Setup

#### Android
You need to add **both package names** to your Firebase project and download the updated `google-services.json`:

1. Go to Firebase Console → Your Project → Project Settings
2. Add two Android apps:
   - Package name: `com.ngerekrut.recruiter`
   - Package name: `com.ngerekrut.jobseeker`
3. Download the updated `google-services.json` and replace `android/app/google-services.json`

#### iOS
1. Add two iOS apps to Firebase:
   - Bundle ID: `com.ngerekrut.recruiter`
   - Bundle ID: `com.ngerekrut.jobseeker`
2. Download `GoogleService-Info.plist` for each
3. You'll need to configure Xcode to use the correct plist based on the scheme

### 2. Environment Variables

Both apps share the same `.env` file. Add any flavor-specific configs using `--dart-define`:

```bash
# Recruiter with specific API endpoint
flutter run --flavor recruiter \
  -t lib/main_recruiter.dart \
  --dart-define=API_BASE_URL=https://api-recruiter.example.com

# Job Seeker with specific API endpoint
flutter run --flavor jobseeker \
  -t lib/main_jobseeker.dart \
  --dart-define=API_BASE_URL=https://api-jobseeker.example.com
```

## 📂 File Structure

```
lib/
├── flavors/
│   ├── app_flavor_config.dart      # Flavor definitions
│   ├── flavor_environment.dart     # Environment config
│   └── flavor_manager.dart         # Global flavor accessor
├── main.dart                       # Original (shared code)
├── main_recruiter.dart            # Recruiter entry point
├── main_jobseeker.dart            # Job Seeker entry point
└── screens/
    ├── job_seeker_home_screen.dart # Job Seeker home
    └── ...                         # Other screens
```

## 🎨 Customization

### App Colors
Edit `lib/flavors/app_flavor_config.dart`:

```dart
static const recruiter = AppFlavorConfig(
  primaryColor: '0xFF18CD5B',  // Green
  // ...
);

static const jobSeeker = AppFlavorConfig(
  primaryColor: '0xFF6366F1',  // Purple
  // ...
);
```

### App Name
- **Android**: Controlled in `android/app/build.gradle.kts` via `resValue("string", "app_name", "...")`
- **iOS**: Controlled via Xcode schemes and Info.plist

### Features
Each flavor has its own `enabledFeatures` list. Use `FlavorManager.flavor.enabledFeatures` to conditionally show/hide features.

## 🔧 Troubleshooting

### "No matching client found for package name"
- You need to add the package names to Firebase and update `google-services.json`

### iOS build fails with Firebase errors
- Configure separate `GoogleService-Info.plist` files for each scheme
- See: https://firebase.flutter.dev/docs/manual/multiple-firebase-projects/

### Different API endpoints for each flavor
Use `--dart-define`:
```bash
flutter run --flavor recruiter --dart-define=API_URL=https://recruiter.api.com
flutter run --flavor jobseeker --dart-define=API_URL=https://jobseeker.api.com
```

## 📝 Next Steps

1. ✅ Configure Firebase for both package names
2. ✅ Set up different app icons for each flavor (optional)
3. ✅ Add separate analytics tracking for each app
4. ✅ Configure different push notification settings
5. ✅ Set up CI/CD pipelines for both flavors

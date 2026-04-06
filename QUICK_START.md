# 🚀 Quick Start - Multi-Flavor Apps

## ✅ Setup Complete!

Your project now supports **2 separate apps**:

1. **NgeRekrut** (Recruiter) - `com.ngerekrut.recruiter`
2. **NgeKerja** (Job Seeker) - `com.ngerekrut.jobseeker`

## 📱 Run Commands

### Android
```bash
# Recruiter App
flutter run --flavor recruiter -t lib/main_recruiter.dart

# Job Seeker App  
flutter run --flavor jobseeker -t lib/main_jobseeker.dart
```

### Build APK for Release
```bash
# Recruiter
flutter build apk --flavor recruiter -t lib/main_recruiter.dart --release

# Job Seeker
flutter build apk --flavor jobseeker -t lib/main_jobseeker.dart --release
```

## ⚠️ Before Running

You need to configure Firebase for both package names:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `ngerekrut`
3. Add 2 Android apps with these package names:
   - `com.ngerekrut.recruiter`
   - `com.ngerekrut.jobseeker`
4. Download the updated `google-services.json`
5. Replace the file at `android/app/google-services.json`

**Note:** I've already added placeholder entries in `google-services.json`, but you'll get the proper `mobilesdk_app_id` from Firebase Console.

## 📂 What Was Created

```
lib/
├── flavors/
│   ├── app_flavor_config.dart       # ✅ Config for both apps
│   ├── flavor_environment.dart      # ✅ Environment vars
│   └── flavor_manager.dart          # ✅ Global flavor access
├── main_recruiter.dart             # ✅ Recruiter entry point
├── main_jobseeker.dart             # ✅ Job Seeker entry point
└── screens/
    └── job_seeker_home_screen.dart # ✅ Job Seeker UI

android/
└── app/
    ├── build.gradle.kts            # ✅ Updated with flavors
    └── google-services.json        # ✅ Updated with both packages

ios/
└── Runner.xcodeproj/
    └── xcshareddata/
        └── xcschemes/
            ├── Recruiter.xcscheme   # ✅ iOS scheme
            └── JobSeeker.xcscheme   # ✅ iOS scheme

FLAVOR_SETUP.md                    # ✅ Full documentation
```

## 🎨 Differences Between Apps

| Feature | Recruiter (NgeRekrut) | Job Seeker (NgeKerja) |
|---------|----------------------|----------------------|
| **Color** | Green (#18CD5B) | Purple (#6366F1) |
| **Features** | Job posting, Screening, Hiring | Job search, Applications, Interview prep |
| **Target** | Employers | Job seekers |

## 🔧 Next Steps

1. **Test the apps:**
   ```bash
   flutter run --flavor recruiter -t lib/main_recruiter.dart
   flutter run --flavor jobseeker -t lib/main_jobseeker.dart
   ```

2. **Customize Job Seeker features:** Edit `lib/screens/job_seeker_home_screen.dart`

3. **Set up different app icons** (optional):
   - Android: Add flavor-specific resources in `android/app/src/recruiter/` and `android/app/src/jobseeker/`
   - iOS: Configure in Xcode schemes

4. **Configure separate APIs:** Use `--dart-define` for different endpoints:
   ```bash
   flutter run --flavor recruiter --dart-define=API_URL=https://recruiter.api.com
   flutter run --flavor jobseeker --dart-define=API_URL=https://jobseeker.api.com
   ```

## 📖 Full Documentation

See `FLAVOR_SETUP.md` for detailed setup instructions and troubleshooting.

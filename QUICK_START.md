# Multi-Flavor Quick Start

Status saat ini: wiring flavor dan Firebase default sudah ada, tetapi build release masih butuh signing yang valid dan validasi iOS di mesin dengan full Xcode.

## Android

Debug run:

```bash
flutter run --flavor recruiter -t lib/main_recruiter.dart
flutter run --flavor jobseeker -t lib/main_jobseeker.dart
```

Release build:

1. Copy `android/key.properties.example` menjadi `android/key.properties`
2. Isi path ke keystore dan credential release
3. Jika ingin override project Firebase default, isi `FIREBASE_*` via `--dart-define`
4. Jalankan build:

```bash
flutter build apk --flavor recruiter -t lib/main_recruiter.dart --release
flutter build apk --flavor jobseeker -t lib/main_jobseeker.dart --release
```

## iOS

Flavor iOS sekarang memakai build configurations terpisah:

- `Debug-recruiter`, `Release-recruiter`, `Profile-recruiter`
- `Debug-jobseeker`, `Release-jobseeker`, `Profile-jobseeker`

Run:

```bash
flutter run --flavor recruiter -t lib/main_recruiter.dart
flutter run --flavor jobseeker -t lib/main_jobseeker.dart
```

## Firebase

Flavor apps sekarang punya default Firebase config yang valid. `--dart-define` hanya dipakai jika Anda ingin override.

Recruiter:

```bash
--dart-define=FIREBASE_RECRUITER_API_KEY=...
--dart-define=FIREBASE_RECRUITER_APP_ID=...
--dart-define=FIREBASE_RECRUITER_MESSAGING_SENDER_ID=...
--dart-define=FIREBASE_RECRUITER_PROJECT_ID=...
--dart-define=FIREBASE_RECRUITER_STORAGE_BUCKET=...
--dart-define=FIREBASE_RECRUITER_IOS_BUNDLE_ID=com.ngerekrut.recruiter
```

Job seeker:

```bash
--dart-define=FIREBASE_JOBSEEKER_API_KEY=...
--dart-define=FIREBASE_JOBSEEKER_APP_ID=...
--dart-define=FIREBASE_JOBSEEKER_MESSAGING_SENDER_ID=...
--dart-define=FIREBASE_JOBSEEKER_PROJECT_ID=...
--dart-define=FIREBASE_JOBSEEKER_STORAGE_BUCKET=...
--dart-define=FIREBASE_JOBSEEKER_IOS_BUNDLE_ID=com.ngerekrut.jobseeker
```

Jika values di atas tidak diisi, flavor akan memakai default config yang sudah ditanam di repo.

## API / Env

Contoh:

```bash
flutter run --flavor recruiter -t lib/main_recruiter.dart \
  --dart-define=API_BASE_URL=https://api-recruiter.example.com
```

Detail lebih lengkap ada di `FLAVOR_SETUP.md`.

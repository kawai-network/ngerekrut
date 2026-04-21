# Multi-Flavor Setup Guide

Project ini mendukung dua aplikasi dari satu codebase:

1. `NgeRekrut`
   Package / bundle id:
   `com.ngerekrut.recruiter`
2. `NgeKerja`
   Package / bundle id:
   `com.ngerekrut.jobseeker`

## Yang Sudah Dikerjakan

- Android product flavor `recruiter` dan `jobseeker`
- Entry point terpisah di `lib/main_recruiter.dart` dan `lib/main_jobseeker.dart`
- iOS build configurations dan schemes untuk kedua flavor
- App display name dan bundle identifier iOS per flavor
- Global flavor manager + environment runtime
- Android release signing scaffold via `android/key.properties`

## Yang Masih Wajib Diisi Sebelum Release

### 1. Firebase override credentials opsional

Default Firebase config untuk recruiter dan jobseeker sudah tertanam. Set `--dart-define` berikut hanya kalau ingin override:

- `FIREBASE_RECRUITER_API_KEY`
- `FIREBASE_RECRUITER_APP_ID`
- `FIREBASE_RECRUITER_MESSAGING_SENDER_ID`
- `FIREBASE_RECRUITER_PROJECT_ID`
- `FIREBASE_RECRUITER_STORAGE_BUCKET`
- `FIREBASE_RECRUITER_IOS_BUNDLE_ID`
- `FIREBASE_JOBSEEKER_API_KEY`
- `FIREBASE_JOBSEEKER_APP_ID`
- `FIREBASE_JOBSEEKER_MESSAGING_SENDER_ID`
- `FIREBASE_JOBSEEKER_PROJECT_ID`
- `FIREBASE_JOBSEEKER_STORAGE_BUCKET`
- `FIREBASE_JOBSEEKER_IOS_BUNDLE_ID`

Optional fields:

- `FIREBASE_*_AUTH_DOMAIN`
- `FIREBASE_*_DATABASE_URL`
- `FIREBASE_*_MEASUREMENT_ID`

Jika credential tidak diisi, flavor akan memakai default config Firebase yang sekarang valid untuk project `ngerekrut`.

### 2. Firebase native config untuk CI

Android dan iOS sekarang memakai model berikut:

- Android: satu `android/app/google-services.json` yang memuat beberapa `client` untuk:
  - `com.ngerekrut.recruiter`
  - `com.ngerekrut.jobseeker`
- iOS: plist terpisah per flavor:
  - `ios/Runner/GoogleService-Info-Recruiter.plist`
  - `ios/Runner/GoogleService-Info-JobSeeker.plist`

GitHub Secrets yang relevan:

- `GOOGLE_SERVICES_JSON`
- `GOOGLE_SERVICE_INFO_PLIST_RECRUITER`
- `GOOGLE_SERVICE_INFO_PLIST_JOBSEEKER`

Script helper untuk generate/update secrets:

```bash
bash scripts/setup-firebase-secrets.sh
bash scripts/setup-firebase-secrets.sh --auto
```

Catatan:

- workflow Android CI saat ini hanya memakai `GOOGLE_SERVICES_JSON`
- secret plist iOS sudah disiapkan untuk pipeline iOS flavor-aware, walau belum dipakai workflow aktif

### 3. Android release signing

Copy:

```bash
cp android/key.properties.example android/key.properties
```

Lalu isi:

- `storeFile`
- `storePassword`
- `keyAlias`
- `keyPassword`

### 4. Product scope Job Seeker

UI home job seeker sudah dibedakan, tapi flow bisnisnya masih sederhana. Jangan launch sebagai produk publik kalau feature set inti belum dipastikan.

## Menjalankan Flavor

### Android

```bash
flutter run --flavor recruiter -t lib/main_recruiter.dart
flutter run --flavor jobseeker -t lib/main_jobseeker.dart
```

### iOS

```bash
flutter run --flavor recruiter -t lib/main_recruiter.dart
flutter run --flavor jobseeker -t lib/main_jobseeker.dart
```

## API Base URL

Flavor environment tersedia via `FlavorManager.environment`.

Contoh:

```bash
flutter run --flavor jobseeker -t lib/main_jobseeker.dart \
  --dart-define=API_BASE_URL=https://api-jobseeker.example.com
```

## Catatan

- `firebase_options.dart` masih ada untuk app lama/default, tetapi flavor apps sekarang memakai `FlavorFirebaseOptions`
- `android/app/google-services.json` sekarang harus memuat app lama + recruiter + jobseeker sekaligus
- Google Sign-In Android bergantung pada `oauth_client` di file itu, jadi setelah update SHA fingerprint di Firebase Console file ini harus diunduh ulang

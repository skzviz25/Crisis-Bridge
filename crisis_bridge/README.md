# SafExit – Complete Flutter App Documentation

---

## 1. Architecture Overview

SafExit follows a **feature-first clean architecture**:

```
lib/
├── core/
│   ├── constants/app_constants.dart     # minWalkDistance, collection names
│   └── theme/app_theme.dart             # Dark theme, colors
├── features/
│   ├── auth/
│   │   ├── role_select_screen.dart      # First screen – Staff or User
│   │   └── staff_login_screen.dart      # Login / auto-register staff
│   ├── staff/
│   │   ├── staff_home_screen.dart       # Staff dashboard
│   │   ├── map_builder_screen.dart      # GPS-based map creation + QR gen
│   │   ├── map_update_screen.dart       # Load, edit, mark danger/exit
│   │   └── incident_dashboard_screen.dart # Live SOS alerts + contacts
│   └── user/
│       ├── user_home_screen.dart        # Scan QR, SOS shortcut
│       ├── qr_scanner_screen.dart       # flutter_zxing scanner
│       ├── map_view_screen.dart         # Live map + route + realtime danger
│       └── sos_screen.dart              # SOS form → Firestore write
├── shared/
│   ├── models/
│   │   ├── floor_map_model.dart         # FloorMapModel + FloorAreaModel
│   │   ├── incident_model.dart          # SOS incident
│   │   ├── staff_model.dart
│   │   └── qr_payload_model.dart        # JSON encode/decode for QR
│   └── services/
│       ├── auth_service.dart            # Firebase Auth login/register
│       ├── sync_service.dart            # All Firestore reads/writes/streams
│       ├── location_service.dart        # geolocator wrapper
│       ├── permission_service.dart      # camera + location permissions
│       └── route_service.dart           # Greedy BFS safe route algorithm
└── main.dart                            # Firebase init + AppRouter
```

---

## 2. Folder Tree (full)

```
safexit/
├── android/
│   └── app/
│       ├── google-services.json         ← YOU ADD THIS
│       └── src/main/AndroidManifest.xml ← add permissions (see §6)
├── lib/  (see above)
├── pubspec.yaml
└── README.md
```

---

## 3. Firestore Collection Structure

### `floorMaps/{mapId}`
```json
{
  "id": "abc123",
  "propertyId": "property-demo",
  "floor": 1,
  "floorLabel": "Floor 1",
  "areas": [
    {
      "id": "uuid-1",
      "name": "Lobby",
      "lat": 13.082680,
      "lng": 80.270718,
      "isDanger": false,
      "isExit": false
    },
    {
      "id": "uuid-2",
      "name": "Main Exit",
      "lat": 13.082750,
      "lng": 80.270850,
      "isDanger": false,
      "isExit": true
    }
  ]
}
```

### `incidents/{incidentId}`
```json
{
  "id": "uuid",
  "propertyId": "property-demo",
  "mapId": "abc123",
  "areaName": "Room 201",
  "floor": 2,
  "senderRole": "user",
  "message": "Smoke in hallway",
  "status": "open",           // open | acknowledged | resolved
  "createdAt": "2025-01-01T10:00:00.000Z"
}
```

### `staff/{uid}`
```json
{
  "id": "firebase-auth-uid",
  "name": "John",
  "email": "john@hotel.com"
}
```

---

## 4. QR Payload Format

The QR encodes a JSON string:
```json
{"propertyId":"property-demo","mapId":"abc123","floor":1}
```
Parsed by `QrPayloadModel.tryParse(rawString)`.

---

## 5. Route Flow

### Staff
```
Role Select → (permissions) → Staff Login/Register → Staff Home
  ├── Make the Map → GPS-walk, mark areas, save, Generate QR
  ├── Update Map → load floor, rename/delete/mark danger/exit, save
  └── Incident Dashboard → live SOS stream, acknowledge/resolve
```

### User
```
Role Select → (permissions) → User Home
  └── Scan QR → QrScannerScreen → MapViewScreen
        ├── Select current area → safe route auto-calculated
        ├── Danger areas shown in red (realtime updates from Firestore)
        └── SOS button → SosScreen → Firestore incident write → staff alerted
```

---

## 6. Step-by-Step Firebase Setup

### Step 1 – Create Firebase Project
1. Go to https://console.firebase.google.com
2. Click **Add project** → name it "safexit"
3. Disable Google Analytics (optional) → **Create project**

### Step 2 – Add Android App
1. In Firebase console → Project settings → **Add app** → Android
2. Android package name: `com.example.safexit`
3. Download `google-services.json`
4. Place it at: `android/app/google-services.json`

### Step 3 – Enable Firebase Auth
1. Firebase console → **Authentication** → Get started
2. Enable **Email/Password** provider

### Step 4 – Enable Firestore
1. Firebase console → **Firestore Database** → Create database
2. Choose **Start in test mode** (for development)
3. Select a region close to you → **Enable**

### Step 5 – Firestore Security Rules (production)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /floorMaps/{mapId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    match /incidents/{incidentId} {
      allow read: if request.auth != null;
      allow create: if true;
      allow update: if request.auth != null;
    }
    match /staff/{uid} {
      allow read, write: if request.auth.uid == uid;
    }
  }
}
```

### Step 6 – Install FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
```
This generates `lib/firebase_options.dart`. Then in `main.dart`, uncomment:
```dart
import 'firebase_options.dart';
// and in main():
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

---

## 7. Android Setup

### android/app/build.gradle – add at bottom of file
```gradle
apply plugin: 'com.google.gms.google-services'
```

### android/build.gradle – add to dependencies
```gradle
classpath 'com.google.gms:google-services:4.4.1'
```

### android/app/src/main/AndroidManifest.xml – add inside `<manifest>`
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

### android/app/src/main/AndroidManifest.xml – inside `<application>`
```xml
<meta-data
  android:name="com.google.android.geo.API_KEY"
  android:value="YOUR_KEY_IF_USING_MAPS"/>
```

### Minimum SDK – android/app/build.gradle
```gradle
minSdkVersion 21
```

### flutter_zxing native build (important!)
Add to `android/app/build.gradle` inside `android {}`:
```gradle
packagingOptions {
    pickFirst 'lib/x86/libc++_shared.so'
    pickFirst 'lib/x86_64/libc++_shared.so'
    pickFirst 'lib/armeabi-v7a/libc++_shared.so'
    pickFirst 'lib/arm64-v8a/libc++_shared.so'
}
```

---

## 8. Run & Debug

```bash
# Install dependencies
flutter pub get

# Run on Android
flutter run

# Run with verbose logs
flutter run -v

# Build APK
flutter build apk --release
```

---

## 9. Common Error Fixes

| Error | Fix |
|-------|-----|
| `google-services.json not found` | Place file at `android/app/google-services.json` |
| `FirebaseApp not initialized` | Call `Firebase.initializeApp()` in `main()` before `runApp()` |
| `Permission denied` | Add permissions to AndroidManifest.xml; test on real device for GPS |
| `flutter_zxing build failure` | Set `minSdkVersion 21`; add packagingOptions for `.so` conflicts |
| `MissingPluginException` | Run `flutter clean && flutter pub get` |
| `Location always returns null` | Enable GPS on device; test on physical device not emulator |
| `Firestore permission-denied` | Set Firestore rules to test mode or update security rules |
| `QR not scanning` | Ensure good lighting; hold phone steady 20–30cm from QR |

---

## 10. Extending Later

- **Push Notifications**: Add `firebase_messaging` → trigger on new `incidents` document
- **Authentication**: Already wired via `firebase_auth` in `AuthService`
- **Multiple Properties**: Replace hardcoded `property-demo` with a property picker screen
- **Real-time Location**: Use `locationService.positionStream()` for live GPS dot on map
- **Floor Map Visual**: Replace list-based map with a `CustomPaint` canvas using `lat/lng` offsets
- **Offline Support**: Add `hive` or `shared_preferences` for caching last-loaded map

# Crisis Bridge 🚨

> Indoor emergency coordination platform for hospitality buildings

## What it does
- Staff build digital floor maps with danger zones
- Guests scan QR codes to load live maps instantly
- Dijkstra pathfinding routes around active hazards
- One-tap SOS sends GPS location to staff dashboard in realtime

## Tech stack
- Flutter (Dart) — cross-platform Android/iOS
- Firebase Firestore — realtime data sync
- Firebase Auth — staff authentication
- flutter_zxing — QR generation and scanning
- geolocator — GPS for SOS reports
- Cloud Functions (Node.js/TypeScript) — push notifications

## Setup
```bash
# Flutter
cd crisis_bridge
flutter pub get
flutterfire configure --project=YOUR_PROJECT_ID
flutter run

# Backend
cd crisis_bridge_backend
npm install
npm run build
firebase deploy --only functions
```


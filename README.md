# Svinobook

Svinobook is a Flutter social messenger with Firebase authentication, Firestore chat, media messages, and WebRTC audio/video calls.

## Stack

- Flutter 3.47.1 and Dart 3.11+
- Firebase Auth, Firestore, Storage, and Messaging
- `flutter_webrtc` with Firestore signaling and Google STUN
- `image_picker`, `video_player`, and cached image loading

## Run locally

```bash
flutter pub get
flutter run -d chrome
```

WebRTC requires camera and microphone permission. Browser calls work when both users are authenticated and the chat ID contains both user IDs.

## Firebase

Build and deploy with:

```bash
flutter build web --release
firebase deploy --only hosting,firestore -P svinobook
```

Hosting URL: https://svinobook.web.app

For GitHub Actions, create a Firebase CLI token with `firebase login:ci`, then add it in repository settings as `FIREBASE_TOKEN`. The deploy workflow uses it only for pushes to `main`.

## Architecture

`views` and `widgets` handle UI. `FirestoreService` owns chat and document operations. `MediaService` picks and uploads media through `StorageService`; message documents store `type` and `url`. `CallService` creates WebRTC peer connections and stores offers, answers, and ICE candidates in `calls/{callId}`. `HomeScreen` listens for incoming calls and presents `IncomingCallScreen`.

Firestore reads and writes are restricted by `firestore.rules`; call documents are accessible only to their caller and callee. Firebase carries signaling and metadata, while WebRTC carries audio/video peer-to-peer.

## Tests

```bash
flutter analyze
flutter test
flutter test --coverage
```

The suite includes focused tests for media upload/picking and call state transitions using mocks and a fake Firestore. Coverage is written to `coverage/lcov.info`; the current suite is intentionally focused on service behavior and does not claim full UI or WebRTC coverage.

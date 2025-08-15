# Firebase Configuration Setup

This document provides instructions for configuring Firebase for the Real-Time Chat application.

## Prerequisites

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication and Firestore Database in your Firebase project

## Android Configuration

1. In the Firebase Console, add an Android app to your project
2. Use the package name: `com.survildhaduk.flutter_realtime_chat.flutter_real_time_chat`
3. Download the `google-services.json` file
4. Replace the placeholder file at `android/app/google-services.json` with your downloaded file

## iOS Configuration

1. In the Firebase Console, add an iOS app to your project
2. Use the bundle ID: `com.survildhaduk.flutter_realtime_chat.flutter_real_time_chat`
3. Download the `GoogleService-Info.plist` file
4. Replace the placeholder file at `ios/Runner/GoogleService-Info.plist` with your downloaded file

## Firebase Services Setup

### Authentication

1. Go to Authentication > Sign-in method in Firebase Console
2. Enable Email/Password authentication

### Firestore Database

1. Go to Firestore Database in Firebase Console
2. Create database in test mode (for development)
3. Set up the following collections structure:
   - `users` - for user profiles
   - `chatRooms` - for chat room information
   - `messages` - for chat messages

### Security Rules (Development)

For development, you can use these basic Firestore rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Allow authenticated users to read/write chat rooms
    match /chatRooms/{roomId} {
      allow read, write: if request.auth != null;
    }

    // Allow authenticated users to read/write messages
    match /messages/{messageId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Verification

After replacing the configuration files, run:

```bash
flutter clean
flutter pub get
flutter run
```

The app should start successfully with "Firebase initialized successfully!" message.

## Troubleshooting

- Make sure package names/bundle IDs match exactly
- Ensure Firebase services are enabled in the console
- Check that configuration files are in the correct locations
- Run `flutter clean` after updating configuration files

# Skill Tracker App

A Flutter application for tracking skills and learning progress, built for IT students.

## Features
- **Authentication**: Secure login and signup using Firebase Auth.
- **Dashboard**: View tracked skills and quick summary.
- **Skill Management**: Add, edit, and delete skills. Set target hours.
- **Session Logging**: Log daily learning time with notes.
- **Progress Tracking**: Visualize weekly progress with charts.

## Prerequisites
- Flutter SDK installed.
- a Firebase Project created on the [Firebase Console](https://console.firebase.google.com/).

## Setup Instructions

1. **Clone/Open the project**:
   Navigate to the project directory:
   ```bash
   cd skill_tracker
   ```

2. **Firebase Configuration**:
   *This is critical for the app to run.*
   - Go to your Firebase Console.
   - Create a project (if you haven't).
   - Add an Android app (get `google-services.json`) and/or iOS app (get `GoogleService-Info.plist`).
   - Enable **Authentication** (Email/Password provider).
   - **Firestore Database Setup**:
     1. Go to **Build** > **Firestore Database**.
     2. Click **Create Database**.
     3. Select a location (e.g., `us-central1`).
     4. Choose **Start in Test Mode** (this allows read/write access for 30 days).
        - *Note: The app expects to read/write to `users/{uid}/skills`.*
        - *The collections will be created automatically by the app; you do not need to create them manually.*
   - Place `google-services.json` in `android/app/`.
   - Place `GoogleService-Info.plist` in `ios/Runner/`.
   - **Google Sign-In Setup**:
     - **Android**: Generate your SHA-1 key (`keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`) and add it to your Firebase Project settings under the Android app.
     - **iOS**: Ensure the `REVERSE_CLIENT_ID` from your `GoogleService-Info.plist` is added as a URL Scheme in iOS project settings (Runner -> Info -> URL Types).

3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the App**:
   ```bash
   flutter run
   ```

## Project Structure
- `lib/main.dart`: Entry point.
- `lib/screens/`: UI screens (Auth, Dashboard, Skills, Progress).
- `lib/services/`: Firebase Auth and Firestore logic.
- `lib/models/`: Data models (Skill, LearningSession).
- `lib/widgets/`: Reusable widgets.

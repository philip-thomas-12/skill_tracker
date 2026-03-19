# skill_tracker

A new Flutter project.

## Setup API Keys

To run this project, you need to set up your own API keys for Gemini and Firebase:

1.  make a file named `assets/.env.example` file in the project.
2.  Create a copy of it in the same folder named `assets/.env`.
3.  Open `assets/.env` and replace the placeholder values with your actual API keys:
    *   `GEMINI_API_KEY`: Get your key from [Google AI Studio](https://aistudio.google.com/app/apikey).
    *   `FIREBASE_API_KEY_WEB`: Get your key from the Firebase Console (Project Settings > General).
    *   `FIREBASE_API_KEY_ANDROID`: Get your key from the Firebase Console.
4.  **Important**: Never commit your `.env` file to version control. It is already added to `.gitignore`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

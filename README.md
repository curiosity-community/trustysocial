# Trusty Social - A Trusted Social Media Platform

Trusty is an innovative platform aimed at strengthening community solidarity and creating a secure social media environment. Through its advanced artificial intelligence infrastructure, it automatically detects and blocks fake accounts and harmful content. With its specialized tools and features, it makes social interactions more reliable and transparent.

Our Flutter-based application delivers modern features like real-time chat, push notifications, and user interactions with a security-focused approach.

![Trusty Banner](./releases/screenshots/banner.png)

<p align="center">
  <a href="https://curiosity.tech/trusty">
    <img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" alt="Get it on Google Play" height="80"/>
    <br>
    <img src="https://developer.apple.com/app-store/marketing/guidelines/images/badge-download-on-the-app-store.svg" alt="Download on the App Store" height="55"/>
  </a>
</p>

## Features

- User authentication (Email, Google Sign-in)
- Real-time messaging
- Push notifications
- Feed posts with images
- Like, comment and retweet functionality
- User profiles
- Follow/Unfollow system
- QR code profile sharing
- Dark/Light mode
- Multi-language support
- Tweet translations
- Bookmark system

## Tech Stack

- Flutter
- Firebase (Auth, Realtime Database, Storage, Analytics)
- Provider for state management
- Google Cloud Messaging for notifications
- Video Player
- Dynamic Links

## Getting Started

1. Clone the repository
```bash
git clone https://github.com/curiositytech/trusty.git
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure Firebase
- Create a Firebase project
- Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
- Enable Authentication, Realtime Database, and Storage

Firebase Emulator (For local development)
```bash
firebase init
```
Select Emulators and select the following:
- Authentication Emulator
- Functions Emulator
- Database Emulator
- Storage Emulator

export FIREBASE_AUTH_EMULATOR_HOST="localhost:9099"
export FIREBASE_DATABASE_EMULATOR_HOST="localhost:9000"
export FIREBASE_STORAGE_EMULATOR_HOST="localhost:9199"

4. Run the app
```bash
flutter run
```

## Environment Setup

1. Copy template files to create your local configuration:
```bash
cp .env.template .env
cp ios/Runner/Info.template.plist ios/Runner/Info.plist
cp google-services.template.json google-services.json
cp GoogleService-Info.template.plist ios/Runner/GoogleService-Info.plist
```

2. Update the copied files with your actual configuration values:
- `.env`: Add your Firebase credentials and API keys
- `Info.plist`: Update with your Firebase client ID
- `google-services.json`: Add your Android Firebase configuration
- `GoogleService-Info.plist`: Add your iOS Firebase configuration

⚠️ IMPORTANT: Never commit the actual configuration files, only commit the template versions!

Minimum requirements:
- Flutter SDK: >=2.12.0
- Dart: >=2.12.0
- Firebase project
- CocoaPods: >=1.16.2 (for iOS development)

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License.

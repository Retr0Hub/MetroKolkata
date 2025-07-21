# Getting Started 🚀

This guide will walk you through setting up the MetroKolkata Flutter application on your local machine.

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

### Required Software

- **Flutter SDK** (3.8.0 or later)
  - [Installation Guide](https://flutter.dev/docs/get-started/install)
- **Dart SDK** (comes with Flutter)
- **Android Studio** or **VS Code** with Flutter extensions
- **Git** for version control

### Platform-Specific Requirements

#### For Android Development
- **Android Studio** with Android SDK
- **Java Development Kit (JDK)** 8 or later
- **Android device** or emulator for testing

#### For iOS Development (macOS only)
- **Xcode** (latest version)
- **iOS Simulator** or physical iOS device
- **CocoaPods** (`sudo gem install cocoapods`)

#### For Web Development
- **Chrome** browser for testing
- Web support is enabled by default in Flutter

## 🔧 Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/Retr0Hub/MetroKolkata.git
cd MetroKolkata
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Verify Flutter Installation

```bash
flutter doctor
```

This command checks your environment and displays a report of the status of your Flutter installation.

### 4. Configure API Keys

#### Google Maps API Key

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS (if targeting iOS)
   - Maps JavaScript API (if targeting web)
4. Create credentials (API Key)
5. Configure the API key:

**For Android:**
```bash
# Navigate to android directory
cd android

# Copy the example properties file
cp keys.properties.example keys.properties

# Edit keys.properties and add your API key
echo "MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY_HERE" > keys.properties
```

**For iOS:**
Edit `ios/Runner/AppDelegate.swift` and add your API key.

**For Web:**
Edit `web/index.html` and add your API key.

### 5. Firebase Configuration

#### Firebase Project Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Enable Authentication and Cloud Firestore
4. Download configuration files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS
   - Web config for Flutter Web

#### Firebase CLI Setup
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
firebase init
```

### 6. Platform-Specific Setup

#### Android Setup
```bash
# Place google-services.json in android/app/
cp path/to/google-services.json android/app/

# Build for Android
flutter build apk
```

#### iOS Setup (macOS only)
```bash
# Place GoogleService-Info.plist in ios/Runner/
cp path/to/GoogleService-Info.plist ios/Runner/

# Install iOS dependencies
cd ios && pod install && cd ..

# Build for iOS
flutter build ios
```

#### Web Setup
```bash
# Build for web
flutter build web

# Serve locally
flutter run -d chrome
```

## 🚀 Running the Application

### Development Mode

```bash
# Run on connected device/emulator
flutter run

# Run on specific device
flutter devices  # List available devices
flutter run -d device_id

# Run with hot reload (default in debug mode)
flutter run --hot-reload
```

### Production Builds

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release

# Web
flutter build web --release
```

## 🛠️ Development Environment Setup

### VS Code Extensions
- Flutter
- Dart
- Bracket Pair Colorizer
- Flutter Intl
- Flutter Widget Snippets

### Android Studio Plugins
- Flutter
- Dart
- Firebase

### Recommended Settings

#### VS Code `settings.json`
```json
{
  "dart.openDevTools": "flutter",
  "dart.previewFlutterUiGuides": true,
  "dart.previewFlutterUiGuidesCustomTracking": true,
  "flutter.showWebRecorderButton": true
}
```

## 🔍 Verification

After setup, verify everything works:

```bash
# Check Flutter installation
flutter doctor -v

# Run tests
flutter test

# Analyze code
flutter analyze

# Check app performance
flutter run --profile
```

## 📱 Testing on Devices

### Android
```bash
# List connected devices
adb devices

# Install and run
flutter install
```

### iOS
```bash
# List iOS devices
xcrun xctrace list devices

# Run on iOS simulator
open -a Simulator
flutter run
```

### Web
```bash
# Run on web
flutter run -d chrome --web-port=8080
```

## 🐛 Common Issues

### Flutter Issues
- **Issue**: `flutter doctor` shows issues
- **Solution**: Follow the suggestions provided by `flutter doctor`

### API Key Issues
- **Issue**: Maps not loading
- **Solution**: Verify API key is correct and APIs are enabled

### Firebase Issues
- **Issue**: Authentication not working
- **Solution**: Check Firebase configuration files are in correct locations

### Build Issues
- **Issue**: Build fails
- **Solution**: 
  ```bash
  flutter clean
  flutter pub get
  flutter run
  ```

## 📚 Next Steps

Once you have the app running:

1. Explore the [Architecture](Architecture) to understand the codebase
2. Check out [Features](Features) for detailed feature documentation
3. Read [API Configuration](API-Configuration) for advanced setup
4. Learn about [Contributing](Contributing) to contribute to the project

## 🆘 Need Help?

- Check the [Troubleshooting](Troubleshooting) guide
- Open an [issue](https://github.com/Retr0Hub/MetroKolkata/issues) on GitHub
- Join our [discussions](https://github.com/Retr0Hub/MetroKolkata/discussions)

---

*Happy coding! 🎉*
# API Configuration 🔧

This guide provides detailed instructions for configuring the external APIs and services required by MetroKolkata.

## 🗺️ Google Maps API Setup

### Overview
MetroKolkata uses Google Maps to display metro stations and provide interactive map functionality. Proper API configuration is essential for the app to function correctly.

### Prerequisites
- Google Cloud Platform (GCP) account
- Active billing account (required for Maps API)
- Basic understanding of GCP console

### Step 1: Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click **"Create Project"** or select an existing project
3. Enter a project name (e.g., "MetroKolkata-Maps")
4. Select your billing account
5. Click **"Create"**

### Step 2: Enable Required APIs

Enable the following APIs in your GCP project:

#### For Android
```bash
# Maps SDK for Android
https://console.cloud.google.com/apis/library/maps-android-backend.googleapis.com

# Places API (optional, for enhanced search)
https://console.cloud.google.com/apis/library/places-backend.googleapis.com
```

#### For iOS
```bash
# Maps SDK for iOS
https://console.cloud.google.com/apis/library/maps-ios-backend.googleapis.com
```

#### For Web
```bash
# Maps JavaScript API
https://console.cloud.google.com/apis/library/maps-backend.googleapis.com

# Maps Embed API
https://console.cloud.google.com/apis/library/maps-embed-backend.googleapis.com
```

### Step 3: Create API Credentials

1. Navigate to **"Credentials"** in the API & Services section
2. Click **"Create Credentials"** → **"API Key"**
3. Copy the generated API key
4. Click **"Restrict Key"** for security

### Step 4: Restrict API Key (Recommended)

#### Application Restrictions
Choose the appropriate restriction:

**For Android:**
- Select **"Android apps"**
- Add package name: `com.example.kolkatametro`
- Add SHA-1 certificate fingerprint

**For iOS:**
- Select **"iOS apps"**
- Add bundle identifier: `com.example.kolkatametro`

**For Web:**
- Select **"HTTP referrers (web sites)"**
- Add your domain(s): `https://yourdomain.com/*`

#### API Restrictions
- Select **"Restrict key"**
- Choose only the APIs you enabled earlier

### Step 5: Configure API Keys in the App

#### Android Configuration

1. Navigate to `android/` directory
2. Copy the example properties file:
   ```bash
   cp keys.properties.example keys.properties
   ```
3. Edit `android/keys.properties`:
   ```properties
   MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY_HERE
   ```

4. Verify `android/app/build.gradle` includes:
   ```gradle
   android {
       defaultConfig {
           resValue "string", "google_maps_key", (project.findProperty("MAPS_API_KEY") ?: "")
       }
   }
   ```

5. Check `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="@string/google_maps_key" />
   ```

#### iOS Configuration

1. Open `ios/Runner/AppDelegate.swift`
2. Add your API key:
   ```swift
   import GoogleMaps

   @UIApplicationMain
   @objc class AppDelegate: FlutterAppDelegate {
     override func application(
       _ application: UIApplication,
       didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
     ) -> Bool {
       GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_HERE")
       GeneratedPluginRegistrant.register(with: self)
       return super.application(application, didFinishLaunchingWithOptions: launchOptions)
     }
   }
   ```

#### Web Configuration

1. Edit `web/index.html`
2. Add the Maps JavaScript API script:
   ```html
   <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY_HERE"></script>
   ```

### Step 6: Test API Configuration

Run the following commands to verify setup:

```bash
# Test on Android
flutter run -d android

# Test on iOS (macOS only)
flutter run -d ios

# Test on web
flutter run -d chrome
```

### Troubleshooting Google Maps

#### Common Issues

**Maps not loading:**
- Verify API key is correct
- Check if required APIs are enabled
- Ensure billing is set up correctly
- Verify application restrictions match your app

**"This page didn't load Google Maps correctly" error:**
- Check browser console for specific error messages
- Verify web API key restrictions
- Ensure JavaScript API is enabled

**Android debug vs release keys:**
- Use debug SHA-1 for development
- Add release SHA-1 for production builds
- Generate SHA-1 using: `keytool -list -v -keystore ~/.android/debug.keystore`

---

## 🔥 Firebase Configuration

### Overview
Firebase provides authentication, real-time database, and cloud storage services for MetroKolkata.

### Prerequisites
- Google account
- Access to Firebase Console
- Flutter project setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Create a project"**
3. Enter project name (e.g., "MetroKolkata")
4. Enable Google Analytics (optional but recommended)
5. Select or create Analytics account
6. Click **"Create project"**

### Step 2: Add Apps to Firebase Project

#### Android App Configuration

1. Click **"Add app"** → **Android icon**
2. Enter package name: `com.example.kolkatametro`
3. Enter app nickname: "MetroKolkata Android"
4. Add SHA-1 certificate (for Google Sign-In)
5. Click **"Register app"**
6. Download `google-services.json`
7. Place file in `android/app/` directory

#### iOS App Configuration

1. Click **"Add app"** → **iOS icon**
2. Enter bundle ID: `com.example.kolkatametro`
3. Enter app nickname: "MetroKolkata iOS"
4. Click **"Register app"**
5. Download `GoogleService-Info.plist`
6. Add file to `ios/Runner/` in Xcode

#### Web App Configuration

1. Click **"Add app"** → **Web icon**
2. Enter app nickname: "MetroKolkata Web"
3. Check **"Set up Firebase Hosting"** (optional)
4. Click **"Register app"**
5. Copy the Firebase config object
6. Add to your web app initialization

### Step 3: Enable Authentication

1. Go to **"Authentication"** in Firebase Console
2. Click **"Get started"**
3. Go to **"Sign-in method"** tab
4. Enable the following providers:

#### Google Sign-In
- Click **"Google"**
- Toggle **"Enable"**
- Add project support email
- Download updated config files

#### Email/Password
- Click **"Email/Password"**
- Toggle **"Enable"**
- Optionally enable **"Email link (passwordless sign-in)"**

#### Phone Authentication
- Click **"Phone"**
- Toggle **"Enable"**
- Add authorized domains for testing

### Step 4: Set Up Cloud Firestore

1. Go to **"Firestore Database"** in Firebase Console
2. Click **"Create database"**
3. Choose **"Start in test mode"** (for development)
4. Select a location close to your users
5. Click **"Done"**

#### Configure Security Rules

For development, use test rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

For production, implement proper security rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public metro data
    match /metro_stations/{stationId} {
      allow read: if true;
      allow write: if false; // Only admins can write
    }
  }
}
```

### Step 5: Install Firebase CLI

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
cd /path/to/MetroKolkata
firebase init
```

Select the following features:
- **Firestore**: Configure security rules and indexes
- **Hosting**: Configure hosting (for web deployment)
- **Storage**: Configure Cloud Storage security rules

### Step 6: Configure Flutter Firebase

#### Install FlutterFire CLI

```bash
# Activate FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your Flutter project
flutterfire configure
```

This will automatically:
- Generate `firebase_options.dart`
- Configure platform-specific settings
- Update dependencies

#### Manual Configuration (Alternative)

If automatic configuration doesn't work, manually add to `lib/firebase_options.dart`:

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'your-web-api-key',
    appId: 'your-web-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'your-project-id',
    authDomain: 'your-project-id.firebaseapp.com',
    storageBucket: 'your-project-id.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'your-android-api-key',
    appId: 'your-android-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'your-project-id',
    storageBucket: 'your-project-id.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'your-ios-api-key',
    appId: 'your-ios-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'your-project-id',
    storageBucket: 'your-project-id.appspot.com',
    iosClientId: 'your-ios-client-id',
    iosBundleId: 'com.example.kolkatametro',
  );
}
```

### Step 7: Test Firebase Configuration

```bash
# Run the app to test Firebase initialization
flutter run

# Check Firebase initialization in main.dart
```

Verify Firebase initialization in your app:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```

### Troubleshooting Firebase

#### Common Issues

**Firebase initialization failed:**
- Check configuration files are in correct locations
- Verify package names/bundle IDs match Firebase project
- Ensure dependencies are properly installed

**Authentication not working:**
- Verify SHA-1 certificates are added to Firebase project
- Check if authentication providers are enabled
- Ensure Google Sign-In configuration is complete

**Firestore permission denied:**
- Review security rules
- Ensure user is authenticated before accessing Firestore
- Check if user has proper permissions for the requested data

---

## 🔐 API Security Best Practices

### API Key Security

#### Do's
- **Restrict API keys** to specific platforms and APIs
- **Use environment variables** for sensitive keys
- **Rotate keys regularly** for production apps
- **Monitor API usage** through cloud console
- **Set up billing alerts** to prevent unexpected charges

#### Don'ts
- **Never commit API keys** to version control
- **Don't use unrestricted keys** in production
- **Avoid hardcoding keys** in source code
- **Don't share keys** across multiple projects unnecessarily

### Firebase Security

#### Authentication Security
- **Enable multi-factor authentication** for admin accounts
- **Use security rules** to protect Firestore data
- **Implement proper session management**
- **Monitor authentication logs** for suspicious activity

#### Data Security
- **Encrypt sensitive data** before storing in Firestore
- **Use security rules** to validate data
- **Implement rate limiting** to prevent abuse
- **Regular security audits** of rules and configurations

### Environment Configuration

#### Development vs Production

**Development:**
```dart
class Config {
  static const bool isDevelopment = true;
  static const String mapsApiKey = 'development-maps-key';
  static const String firebaseProjectId = 'dev-project-id';
}
```

**Production:**
```dart
class Config {
  static const bool isDevelopment = false;
  static const String mapsApiKey = 'production-maps-key';
  static const String firebaseProjectId = 'prod-project-id';
}
```

---

## 📊 Monitoring and Analytics

### Google Cloud Monitoring

1. Enable **Cloud Monitoring** in GCP
2. Set up **alerting policies** for API usage
3. Monitor **quota consumption**
4. Track **error rates** and **latency**

### Firebase Analytics

1. Enable **Google Analytics** in Firebase
2. Track **user engagement** and **app performance**
3. Monitor **crash reports** with Crashlytics
4. Set up **custom events** for key user actions

### Cost Management

#### Maps API Costs
- Monitor daily usage through GCP console
- Set up billing alerts
- Optimize API calls to reduce costs
- Use caching to minimize requests

#### Firebase Costs
- Monitor Firestore read/write operations
- Optimize database queries
- Use Firebase Analytics to track usage patterns
- Set up budget alerts

---

*Proper API configuration is crucial for the optimal performance and security of MetroKolkata. Always follow security best practices and monitor your usage regularly.*
# Kolkata Metro App - Enhanced Authentication Setup

This document provides a comprehensive guide for setting up and using the enhanced authentication features in the Kolkata Metro app, including email OTP generation during signup, 2-factor authentication (2FA) for login, and biometric authentication.

## 🔐 Features Implemented

### 1. Email OTP Generation During Signup
- **6-digit OTP** sent to user's email during registration
- **10-minute expiration** for security
- **Beautiful email templates** with Kolkata Metro branding
- **Resend functionality** with cooldown timer
- **Secure storage** using Flutter Secure Storage

### 2. Two-Factor Authentication (2FA)
- **Optional 2FA** that users can enable/disable
- **Email-based OTP** for second factor
- **Automatic OTP sending** during login if 2FA is enabled
- **Settings management** through Security Settings screen

### 3. Biometric Authentication
- **Fingerprint recognition** on supported devices
- **Face ID/Face recognition** on supported devices
- **Fallback to password** when biometric fails
- **Device compatibility checking**
- **User preference management**

## 📱 Setup Instructions

### Prerequisites
1. **Flutter SDK** (version 3.8.0 or higher)
2. **Firebase project** with Authentication and Firestore enabled
3. **Email service** credentials for SMTP (Gmail recommended)

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure Email Service
Update the email configuration in `lib/services/auth_service.dart`:

```dart
// Replace these with your actual email credentials
static const String _senderEmail = 'your-app-email@gmail.com';
static const String _senderPassword = 'your-app-password';
```

**For Gmail:**
1. Enable 2-factor authentication on your Gmail account
2. Generate an app-specific password
3. Use this app password in the configuration

### 3. Platform-Specific Setup

#### Android Setup
The app automatically includes the required permissions:
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
```

#### iOS Setup
The app includes Face ID usage description:
```xml
<key>NSFaceIDUsageDescription</key>
<string>This app uses Face ID for secure authentication to access your Kolkata Metro account.</string>
```

### 4. Firebase Configuration
Ensure your Firestore security rules allow reading and writing user documents:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 🚀 Usage Guide

### Signup Process with Email OTP
1. User fills out the signup form
2. App sends 6-digit OTP to user's email
3. User enters OTP in the verification screen
4. Account is created after successful OTP verification

### Login with 2FA
1. User enters email and password
2. If 2FA is enabled, OTP is sent to user's email
3. User enters OTP to complete login
4. Optional biometric authentication prompt if enabled

### Biometric Authentication
1. Users can enable biometric authentication in Security Settings
2. Supported methods: Fingerprint, Face ID, Touch ID
3. Automatic fallback to password if biometric fails
4. Works with 2FA for enhanced security

## 🔧 Key Components

### AuthService (`lib/services/auth_service.dart`)
Central service handling all authentication operations:
- OTP generation and verification
- Email sending
- Biometric authentication
- 2FA management
- User preferences

### Enhanced OTP Verification Screen (`lib/enhanced_otp_verification_screen.dart`)
Beautiful OTP input screen with:
- PIN-style input fields
- Auto-verification
- Resend functionality
- Timer display

### Biometric Auth Screen (`lib/biometric_auth_screen.dart`)
Dedicated biometric authentication interface:
- Device capability detection
- Multiple biometric type support
- Error handling
- Fallback options

### Security Settings Screen (`lib/security_settings_screen.dart`)
User-friendly interface for managing security preferences:
- Toggle 2FA on/off
- Toggle biometric authentication
- Security tips and information

## 📧 Email Configuration Options

### Gmail SMTP
```dart
final smtpServer = gmail('your-email@gmail.com', 'your-app-password');
```

### Custom SMTP
```dart
final smtpServer = SmtpServer(
  'smtp.your-provider.com',
  port: 587,
  username: 'your-email@your-provider.com',
  password: 'your-password',
);
```

### Email Templates
The app includes beautiful HTML email templates with:
- Kolkata Metro branding
- Responsive design
- Clear OTP display
- Security information

## 🔒 Security Features

### OTP Security
- **6-digit random codes** generated using crypto-secure methods
- **10-minute expiration** to prevent replay attacks
- **Secure storage** using Flutter Secure Storage
- **Rate limiting** to prevent spam

### Biometric Security
- **Local device authentication** - no biometric data leaves the device
- **Platform-specific implementation** using native APIs
- **Error handling** for various failure scenarios
- **User consent required** before enabling

### 2FA Security
- **Optional implementation** - users can choose to enable
- **Email-based** for universal compatibility
- **Secure token management**
- **Easy disable option**

## 🛠️ Troubleshooting

### Email Not Sending
1. Check SMTP credentials
2. Verify Gmail app password is correct
3. Ensure "Less secure app access" is enabled (if using basic auth)
4. Check network connectivity

### Biometric Not Working
1. Verify device supports biometric authentication
2. Check if biometrics are enrolled on the device
3. Ensure proper permissions are granted
4. Try fallback authentication method

### OTP Verification Failing
1. Check if OTP has expired (10-minute limit)
2. Verify correct email address
3. Check spam/junk folder
4. Try resending OTP

## 📱 User Experience

### Signup Flow
1. **Form Input** → **Email Verification** → **OTP Entry** → **Account Creation**

### Login Flow
1. **Credentials Entry** → **2FA (if enabled)** → **Biometric (if enabled)** → **Home Screen**

### Security Management
Users can access security settings through the profile screen to:
- Enable/disable 2FA
- Enable/disable biometric authentication
- View security tips

## 🔄 Migration Notes

If upgrading from a previous version:
1. Existing users will have 2FA and biometric authentication disabled by default
2. Users can enable these features through Security Settings
3. No data migration required for authentication features

## 📞 Support

For issues related to authentication features:
1. Check this documentation first
2. Verify all configuration steps are completed
3. Test on a physical device for biometric features
4. Check Firebase console for authentication logs

## 🌟 Future Enhancements

Planned improvements:
- SMS-based OTP as an alternative to email
- Hardware security key support
- Advanced threat detection
- Multi-device management
- Backup codes for 2FA

---

**Note**: Always test authentication features on physical devices, especially biometric authentication, as emulators may not fully support these features.
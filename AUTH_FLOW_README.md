# Kolkata Metro Authentication Flow

This document describes the complete authentication flow implemented in the Kolkata Metro app.

## Overview

The app implements a modern, secure authentication flow with the following features:
- Mobile number-based authentication
- OTP verification via SMS
- PIN-based security
- Biometric authentication support
- Session management

## Authentication Flow

### 1. First-Time Users

**Steps:**
1. **Mobile Number Input** (`MobileNumberScreen`)
   - User enters their mobile number
   - Validation for Indian mobile numbers (10 digits, starting with 6-9)
   - Sends OTP to the provided number

2. **OTP Verification** (`OtpVerificationScreen`)
   - User enters 6-digit OTP received via SMS
   - OTP validation with expiration (10 minutes)
   - Resend functionality with 60-second cooldown

3. **Sign Up Form** (`SignupFormScreen`)
   - Collects user information:
     - Full Name (required)
     - Gender (Male/Female/Other)
     - Email (optional)
   - Saves user profile to Firebase

4. **PIN Setup** (`PinSetupScreen`)
   - User creates a 6-digit PIN
   - PIN confirmation to prevent typos
   - PIN is hashed before storage
   - Stores session locally

**Result:** Account created + PIN set for future logins

### 2. Returning Users (App Not Logged In)

**Steps:**
1. **Mobile Number Input** (`MobileNumberScreen`)
   - Same as first-time users
   - `isFirstTimeUser` flag set to `false`

2. **OTP Verification** (`OtpVerificationScreen`)
   - Same verification process
   - Checks if user exists in database

3. **PIN Verification** (`PinSetupScreen`)
   - User enters existing PIN
   - Biometric authentication option (if available)
   - "Forgot PIN?" option for PIN reset

**Result:** User logged in and redirected to Home

### 3. Already Logged-In Users (App Installed)

**Steps:**
1. **App Launch** (`AuthDecisionScreen`)
   - Checks for existing session
   - If session exists, shows PIN verification screen

2. **PIN Verification** (`PinSetupScreen`)
   - User enters PIN
   - Biometric unlock option (Fingerprint/FaceID)
   - PIN failure → "Reset using OTP" fallback

**Result:** Direct access to Home screen

## PIN Reset Flow

### Forgot PIN Process

1. **Forgot PIN Screen** (`ForgotPinScreen`)
   - User requests PIN reset
   - Shows security information

2. **OTP Verification** (`OtpVerificationScreen`)
   - Sends OTP to registered mobile number
   - Verifies user identity

3. **New PIN Setup** (`PinSetupScreen`)
   - User creates new PIN
   - PIN confirmation
   - Updates stored PIN

## Screen Details

### MobileNumberScreen
- **Purpose:** Mobile number input and validation
- **Features:**
  - Indian mobile number validation
  - Country code (+91) prefix
  - Loading states
  - Error handling

### OtpVerificationScreen
- **Purpose:** OTP verification with PIN code fields
- **Features:**
  - 6-digit PIN input
  - Auto-submit on completion
  - Resend timer (60 seconds)
  - Error handling

### SignupFormScreen
- **Purpose:** User profile creation
- **Features:**
  - Form validation
  - Gender selection
  - Optional email field
  - Modern UI with theme consistency

### PinSetupScreen
- **Purpose:** PIN creation and verification
- **Features:**
  - 6-digit PIN input
  - PIN confirmation dialog
  - Biometric authentication
  - Forgot PIN option
  - Session storage

### ForgotPinScreen
- **Purpose:** PIN reset initiation
- **Features:**
  - Security information
  - OTP-based reset
  - User guidance

### AuthDecisionScreen
- **Purpose:** App launch and session management
- **Features:**
  - Session checking
  - Loading states
  - Welcome screen for new users
  - PIN verification for returning users

## Security Features

### PIN Security
- **Hashing:** PINs are hashed using SHA-256 before storage
- **Local Storage:** PIN hashes stored in secure storage
- **Database Storage:** PIN hashes also stored in Firebase
- **Expiration:** OTPs expire after 10 minutes

### Biometric Authentication
- **Availability Check:** Verifies device support
- **Fallback:** PIN authentication if biometric fails
- **User Choice:** Optional biometric setup

### Session Management
- **Local Storage:** User session stored in SharedPreferences
- **Secure Storage:** Sensitive data in FlutterSecureStorage
- **Auto-login:** Session persistence across app launches

## Theme Consistency

All screens follow the app's design system:
- **Colors:** Primary green (#00C853), dark theme support
- **Typography:** Google Fonts Poppins
- **Components:** Consistent button styles, input fields, and spacing
- **Animations:** Smooth transitions and loading states

## Dependencies

The auth flow uses these key dependencies:
- `pin_code_fields`: For OTP input
- `local_auth`: For biometric authentication
- `flutter_secure_storage`: For secure data storage
- `shared_preferences`: For session management
- `crypto`: For PIN hashing
- `firebase_auth` & `cloud_firestore`: For backend authentication and data storage

## Testing

### Development Testing
- Use console logs to see OTP codes (remove in production)
- Skip to home option available in development mode
- Test both light and dark themes

### Production Considerations
- Integrate real SMS service (Twilio, etc.)
- Remove debug logs and skip options
- Implement proper error handling
- Add analytics and crash reporting

## Future Enhancements

1. **Multi-factor Authentication:** Add email verification as additional factor
2. **Social Login:** Google, Facebook integration
3. **Advanced Security:** Device fingerprinting, location-based security
4. **Offline Support:** Basic functionality without internet
5. **Accessibility:** Screen reader support, high contrast modes
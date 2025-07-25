import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Email configuration - In production, use environment variables
  static const String _emailHost = 'smtp.gmail.com';
  static const String _emailPort = '587';
  static const String _senderEmail = 'your-app-email@gmail.com'; // Replace with your app email
  static const String _senderPassword = 'your-app-password'; // Replace with your app password

  // Generate a 6-digit OTP
  String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Send OTP via email
  Future<bool> sendEmailOTP(String email, String otp, {String? userName}) async {
    try {
      final smtpServer = gmail(_senderEmail, _senderPassword);
      
      final message = Message()
        ..from = Address(_senderEmail, 'Kolkata Metro')
        ..recipients.add(email)
        ..subject = 'Your Kolkata Metro Verification Code'
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <div style="background-color: #1976d2; color: white; padding: 20px; text-align: center;">
              <h1>Kolkata Metro</h1>
            </div>
            <div style="padding: 20px;">
              <h2>Email Verification</h2>
              ${userName != null ? '<p>Hi $userName,</p>' : ''}
              <p>Your verification code is:</p>
              <div style="background-color: #f5f5f5; padding: 15px; margin: 20px 0; text-align: center; font-size: 24px; font-weight: bold; letter-spacing: 2px;">
                $otp
              </div>
              <p>This code will expire in 10 minutes.</p>
              <p>If you didn't request this code, please ignore this email.</p>
            </div>
            <div style="background-color: #f5f5f5; padding: 10px; text-align: center; font-size: 12px; color: #666;">
              <p>© 2024 Kolkata Metro. All rights reserved.</p>
            </div>
          </div>
        ''';

      await send(message, smtpServer);
      return true;
    } catch (e) {
      print('Error sending email OTP: $e');
      return false;
    }
  }

  // Store OTP securely with expiration
  Future<void> storeOTP(String email, String otp) async {
    final expirationTime = DateTime.now().add(const Duration(minutes: 10));
    final otpData = {
      'otp': otp,
      'expiration': expirationTime.millisecondsSinceEpoch,
    };
    
    await _secureStorage.write(
      key: 'otp_$email',
      value: jsonEncode(otpData),
    );
  }

  // Verify OTP
  Future<bool> verifyOTP(String email, String enteredOTP) async {
    try {
      final storedData = await _secureStorage.read(key: 'otp_$email');
      if (storedData == null) return false;

      final otpData = jsonDecode(storedData);
      final storedOTP = otpData['otp'];
      final expiration = DateTime.fromMillisecondsSinceEpoch(otpData['expiration']);

      // Check if OTP has expired
      if (DateTime.now().isAfter(expiration)) {
        await _secureStorage.delete(key: 'otp_$email');
        return false;
      }

      // Verify OTP
      final isValid = storedOTP == enteredOTP;
      if (isValid) {
        await _secureStorage.delete(key: 'otp_$email');
      }

      return isValid;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }

  // Send OTP for signup
  Future<bool> sendSignupOTP(String email, String userName) async {
    final otp = generateOTP();
    final emailSent = await sendEmailOTP(email, otp, userName: userName);
    
    if (emailSent) {
      await storeOTP(email, otp);
      return true;
    }
    return false;
  }

  // Send OTP for 2FA login
  Future<bool> send2FAOTP(String email) async {
    final otp = generateOTP();
    final emailSent = await sendEmailOTP(email, otp);
    
    if (emailSent) {
      await storeOTP(email, otp);
      return true;
    }
    return false;
  }

  // Sign up with email and password after OTP verification
  Future<UserCredential?> signUpWithEmailPassword(
    String email, 
    String password, 
    String name
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(name);
        
        // Store user data in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'twoFactorEnabled': false,
          'biometricEnabled': false,
        });
      }

      return userCredential;
    } catch (e) {
      print('Error signing up: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  // Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access Kolkata Metro',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return isAuthenticated;
    } on PlatformException catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }

  // Enable biometric authentication for user
  Future<bool> enableBiometricAuth(String userId) async {
    try {
      final isAuthenticated = await authenticateWithBiometrics();
      if (isAuthenticated) {
        await _firestore.collection('users').doc(userId).update({
          'biometricEnabled': true,
        });
        
        // Store biometric preference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometric_enabled_$userId', true);
        
        return true;
      }
      return false;
    } catch (e) {
      print('Error enabling biometric auth: $e');
      return false;
    }
  }

  // Disable biometric authentication
  Future<bool> disableBiometricAuth(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'biometricEnabled': false,
      });
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled_$userId', false);
      
      return true;
    } catch (e) {
      print('Error disabling biometric auth: $e');
      return false;
    }
  }

  // Check if user has biometric enabled
  Future<bool> isBiometricEnabledForUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('biometric_enabled_$userId') ?? false;
    } catch (e) {
      print('Error checking biometric status: $e');
      return false;
    }
  }

  // Enable 2FA for user
  Future<bool> enable2FA(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'twoFactorEnabled': true,
      });
      return true;
    } catch (e) {
      print('Error enabling 2FA: $e');
      return false;
    }
  }

  // Disable 2FA for user
  Future<bool> disable2FA(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'twoFactorEnabled': false,
      });
      return true;
    } catch (e) {
      print('Error disabling 2FA: $e');
      return false;
    }
  }

  // Check if user has 2FA enabled
  Future<bool> is2FAEnabledForUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['twoFactorEnabled'] ?? false;
    } catch (e) {
      print('Error checking 2FA status: $e');
      return false;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
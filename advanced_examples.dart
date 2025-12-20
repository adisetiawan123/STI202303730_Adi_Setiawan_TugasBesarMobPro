// Advanced Implementation Examples
// Gunakan sebagai referensi untuk fitur-fitur tambahan

// ==========================================
// EXAMPLE 1: Integrate dengan Firebase Auth
// ==========================================

/*
// auth_service.dart - Enhanced version dengan Firebase

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';

Future<void> initializeFirebase() async {
  await Firebase.initializeApp();
}

// Login dengan Firebase Email/Password
Future<User?> loginWithFirebaseEmail(String email, String password) async {
  try {
    final result = await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final fbUser = result.user;
    if (fbUser != null) {
      final user = User(
        id: fbUser.uid,
        email: fbUser.email!,
        name: fbUser.displayName,
        loginMethod: 'email',
      );
      
      _currentUser = user;
      await _saveUserToStorage(user);
      return user;
    }
    return null;
  } on fb.FirebaseAuthException catch (e) {
    print('Firebase Auth Error: ${e.message}');
    return null;
  }
}

// Register dengan Firebase
Future<User?> registerWithFirebase(
  String email,
  String password,
  String name,
) async {
  try {
    final result = await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final fbUser = result.user;
    if (fbUser != null) {
      await fbUser.updateDisplayName(name);
      await fbUser.updatePhotoURL(null);
      
      final user = User(
        id: fbUser.uid,
        email: fbUser.email!,
        name: name,
        loginMethod: 'email',
      );
      
      _currentUser = user;
      await _saveUserToStorage(user);
      return user;
    }
    return null;
  } on fb.FirebaseAuthException catch (e) {
    print('Firebase Registration Error: ${e.message}');
    return null;
  }
}

// Reset password
Future<void> resetPassword(String email) async {
  try {
    await fb.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    print('Password reset email sent to $email');
  } on fb.FirebaseAuthException catch (e) {
    print('Reset Password Error: ${e.message}');
  }
}
*/

// ==========================================
// EXAMPLE 2: State Management dengan Provider
// ==========================================

/*
// lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final currentUserProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return UserNotifier(authService);
});

class UserNotifier extends StateNotifier<User?> {
  final AuthService _authService;

  UserNotifier(this._authService) : super(null) {
    _init();
  }

  Future<void> _init() async {
    await _authService.init();
    state = _authService.currentUser;
  }

  Future<void> loginWithGoogle() async {
    final user = await _authService.loginWithGoogle();
    if (user != null) {
      state = user;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = null;
  }
}

// Usage dalam widget:
final user = ref.watch(currentUserProvider);

if (user != null) {
  // Show user profile
} else {
  // Show login prompt
}
*/

// ==========================================
// EXAMPLE 3: Biometric Authentication
// ==========================================

/*
// lib/services/biometric_auth.dart

import 'package:local_auth/local_auth.dart';

class BiometricAuth {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> canAuthenticate() async {
    final isDeviceSupported = await _localAuth.canCheckBiometrics;
    final isDeviceSecure = await _localAuth.deviceSupportedAuthenticators();
    return isDeviceSupported || isDeviceSecure;
  }

  Future<bool> authenticate(String reason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      print('Biometric Auth Error: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _localAuth.getAvailableBiometrics();
  }
}

// Usage:
final biometricAuth = BiometricAuth();
final isAuthenticated = await biometricAuth.authenticate('Use biometric to login');
*/

// ==========================================
// EXAMPLE 4: Social Media Login Helper
// ==========================================

/*
// lib/utils/social_login_helper.dart

class SocialLoginHelper {
  // Extract common data dari berbagai provider
  static Map<String, dynamic> extractUserData(
    dynamic socialUser,
    String provider,
  ) {
    switch (provider.toLowerCase()) {
      case 'google':
        return {
          'id': socialUser.id,
          'email': socialUser.email,
          'name': socialUser.displayName,
          'photoUrl': socialUser.photoUrl,
        };
      
      case 'facebook':
        return {
          'id': socialUser.id,
          'email': socialUser.email,
          'name': socialUser.name,
          'photoUrl': socialUser.photoUrl,
        };
      
      case 'apple':
        return {
          'id': socialUser.userIdentifier,
          'email': socialUser.email,
          'name': socialUser.fullName?.givenName,
          'photoUrl': null,
        };
      
      default:
        return {};
    }
  }

  // Get provider icon
  static IconData getProviderIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
        return Icons.g_mobiledata;
      case 'facebook':
        return Icons.facebook;
      case 'apple':
        return Icons.apple;
      case 'github':
        return Icons.code;
      default:
        return Icons.account_circle;
    }
  }

  // Get provider color
  static Color getProviderColor(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
        return Color(0xFFDB4437);
      case 'facebook':
        return Color(0xFF1877F2);
      case 'apple':
        return Color(0xFF000000);
      case 'github':
        return Color(0xFF333333);
      default:
        return Colors.grey;
    }
  }
}
*/

// ==========================================
// EXAMPLE 5: Session Management
// ==========================================

/*
// lib/services/session_manager.dart

class SessionManager {
  static const sessionTimeout = Duration(hours: 1);
  
  DateTime? _lastActivity;
  late Timer _inactivityTimer;

  SessionManager() {
    _recordActivity();
  }

  void _recordActivity() {
    _lastActivity = DateTime.now();
    _resetInactivityTimer();
  }

  void _resetInactivityTimer() {
    _inactivityTimer.cancel();
    _inactivityTimer = Timer(sessionTimeout, _onSessionTimeout);
  }

  void _onSessionTimeout() {
    print('Session timeout - logging out user');
    // Trigger logout
  }

  bool isSessionValid() {
    if (_lastActivity == null) return false;
    return DateTime.now().difference(_lastActivity!) < sessionTimeout;
  }

  void dispose() {
    _inactivityTimer.cancel();
  }
}
*/

// ==========================================
// EXAMPLE 6: Authentication Interceptor
// ==========================================

/*
// lib/utils/auth_interceptor.dart

import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final AuthService authService;

  AuthInterceptor(this.authService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (authService.isLoggedIn) {
      // Add auth token to header
      options.headers['Authorization'] = 'Bearer ${authService.currentUser?.id}';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired - logout user
      authService.logout();
    }
    super.onError(err, handler);
  }
}
*/

// ==========================================
// EXAMPLE 7: User Profile Update
// ==========================================

/*
// Extended auth_service.dart

Future<bool> updateUserProfile({
  required String name,
  String? photoUrl,
}) async {
  if (!isLoggedIn) return false;

  try {
    _currentUser = _currentUser!.copyWith(
      name: name,
      photoUrl: photoUrl,
    );
    
    await _saveUserToStorage(_currentUser!);
    return true;
  } catch (e) {
    print('Update Profile Error: $e');
    return false;
  }
}

Future<bool> changePassword(String oldPassword, String newPassword) async {
  // Implementasi password change
  // Gunakan Firebase Auth atau backend API
  return false;
}
*/

// ==========================================
// EXAMPLE 8: Login Analytics
// ==========================================

/*
// Track login events untuk analytics

class LoginAnalytics {
  static void trackLoginEvent(String method) {
    // Send to analytics service (Firebase Analytics, Mixpanel, etc)
    print('Login Event: User logged in with $method');
    
    // Example dengan Firebase Analytics:
    // analytics.logEvent(
    //   name: 'user_login',
    //   parameters: {'method': method},
    // );
  }

  static void trackLogoutEvent() {
    print('Logout Event: User logged out');
  }

  static void trackLoginError(String method, String error) {
    print('Login Error: Method=$method, Error=$error');
  }
}
*/

// ==========================================
// NOTES
// ==========================================

/*
Fitur-fitur yang bisa ditambahkan:
1. Two-Factor Authentication (2FA)
2. Biometric authentication (fingerprint, face)
3. OAuth2 dengan berbagai provider (Apple, GitHub, LinkedIn)
4. Session management & timeout
5. Password strength validation
6. Remember me functionality
7. Login history & device management
8. Account recovery & backup codes
9. Single Sign-On (SSO)
10. Role-based access control (RBAC)

Untuk production:
- Gunakan HTTPS untuk semua komunikasi
- Implement certificate pinning
- Use secure token storage
- Implement refresh token mechanism
- Add rate limiting untuk login attempts
- Monitor suspicious login activity
- Implement audit logging
*/

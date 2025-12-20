import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();

  factory FirebaseAuthService() => _instance;

  FirebaseAuthService._internal();

  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? _currentUser;
  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;

    final fbUser = _firebaseAuth.currentUser;
    if (fbUser != null) {
      _currentUser = User(
        id: fbUser.uid,
        email: fbUser.email ?? '',
        name: fbUser.displayName,
        photoUrl: fbUser.photoURL,
        loginMethod: 'firebase',
        role: _prefs.getString('current_user_role') ?? 'user',
      );
      return;
    }

    // Fallback: try to restore user from SharedPreferences keys
    final storedId = _prefs.getString('current_user_id');
    final storedEmail = _prefs.getString('current_user_email');
    if (storedId != null && storedEmail != null) {
      _currentUser = User(
        id: storedId,
        email: storedEmail,
        name: _prefs.getString('current_user_name') ?? '',
        photoUrl: _prefs.getString('current_user_photo'),
        loginMethod: _prefs.getString('current_user_method') ?? 'email',
        role: _prefs.getString('current_user_role') ?? 'user',
      );
      return;
    }

    // Additional fallback: support legacy AuthService 'user_data' format
    final legacy = _prefs.getString('user_data');
    if (legacy != null && legacy.isNotEmpty) {
      final map = <String, String>{};
      final pairs = legacy.split(',');
      for (var pair in pairs) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          final key = parts[0].replaceAll('"', '').trim();
          final value = parts[1].replaceAll('"', '').trim();
          map[key] = value;
        }
      }
      if (map.containsKey('email')) {
        _currentUser = User(
          id: map['id'] ?? map['email']!.replaceAll('@', '_'),
          email: map['email'] ?? '',
          name: map['name'],
          photoUrl: map['photoUrl'],
          loginMethod: map['loginMethod'] ?? 'email',
          role: map['role'] ?? 'user',
        );
      }
    }
  }

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Register dengan Email
  Future<User?> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.updateDisplayName(name);

      final user = User(
        id: userCredential.user?.uid ?? '',
        email: email,
        name: name,
        photoUrl: userCredential.user?.photoURL,
        loginMethod: 'email',
        role: 'user',
      );

      _currentUser = user;
      await _saveUserToStorage(user);
      debugPrint('✓ Register sukses: $email');
      return user;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('Firebase Register Error: ${e.message}');
      return null;
    }
  }

  // Login dengan Email
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fbUser = userCredential.user;
      if (fbUser != null) {
        final user = User(
          id: fbUser.uid,
          email: fbUser.email ?? '',
          name: fbUser.displayName,
          photoUrl: fbUser.photoURL,
          loginMethod: 'email',
          role: 'user',
        );

        _currentUser = user;
        await _saveUserToStorage(user);
        debugPrint('✓ Email login sukses: ${fbUser.email}');
        return user;
      }
      return null;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('Firebase Login Error: ${e.message}');
      return null;
    }
  }

  // Login dengan Google (REAL)
  Future<User?> loginWithGoogle() async {
    try {
      debugPrint('Starting Google Sign-In...');

      // Sign out previous session
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google sign-in dibatalkan');
        return null;
      }

      debugPrint('Google user: ${googleUser.email}');

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final fbUser = userCredential.user;

      if (fbUser != null) {
        final user = User(
          id: fbUser.uid,
          email: fbUser.email ?? '',
          name: fbUser.displayName,
          photoUrl: fbUser.photoURL,
          loginMethod: 'google',
          role: 'user',
        );

        _currentUser = user;
        await _saveUserToStorage(user);
        debugPrint('✓ Google login sukses: ${fbUser.email}');
        return user;
      }

      return null;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error (Google): ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error Google login: $e');
      return null;
    }
  }

  // Login sebagai Admin (DEMO - hardcoded credentials)
  Future<User?> loginAsAdmin(String username, String password) async {
    try {
      // Hardcoded admin credentials untuk demo
      if (username == 'admin' && password == 'admin123') {
        final user = User(
          id: 'admin_${DateTime.now().millisecondsSinceEpoch}',
          email: 'admin@travel-wisata-lokal.local',
          name: 'Admin',
          photoUrl: null,
          loginMethod: 'admin_demo',
          role: 'admin',
        );

        _currentUser = user;
        await _saveUserToStorage(user);
        debugPrint('✓ Admin login sukses');
        return user;
      } else {
        debugPrint('Admin credentials invalid');
        return null;
      }
    } catch (e) {
      debugPrint('Error admin login: $e');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      _currentUser = null;
      await _prefs.remove('current_user_id');
      await _prefs.remove('current_user_email');
      await _prefs.remove('current_user_name');
      await _prefs.remove('current_user_method');
      await _prefs.remove('current_user_role');
      await _prefs.remove('current_user_photo');
      await _prefs.remove('user_data');
      debugPrint('✓ Logout sukses');
    } catch (e) {
      debugPrint('Error logout: $e');
    }
  }

  // Reset Password
  Future<bool> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      debugPrint('✓ Password reset link sent to $email');
      return true;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('Reset Password Error: ${e.message}');
      return false;
    }
  }

  // Update User Profile
  Future<bool> updateUserProfile(String name, String? photoUrl) async {
    try {
      final fbUser = _firebaseAuth.currentUser;
      if (fbUser != null) {
        await fbUser.updateDisplayName(name);
        if (photoUrl != null) {
          await fbUser.updatePhotoURL(photoUrl);
        }

        _currentUser = User(
          id: fbUser.uid,
          email: fbUser.email ?? '',
          name: name,
          photoUrl: photoUrl ?? fbUser.photoURL,
          loginMethod: _currentUser?.loginMethod ?? 'email',
          role: _currentUser?.role ?? 'user',
        );

        await _saveUserToStorage(_currentUser!);
        debugPrint('✓ Profile updated');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  // Private helper methods
  Future<void> _saveUserToStorage(User user) async {
    await _prefs.setString('current_user_id', user.id);
    await _prefs.setString('current_user_email', user.email);
    await _prefs.setString('current_user_name', user.name ?? '');
    await _prefs.setString('current_user_photo', user.photoUrl ?? '');
    await _prefs.setString('current_user_method', user.loginMethod);
    await _prefs.setString('current_user_role', user.role);
  }
}

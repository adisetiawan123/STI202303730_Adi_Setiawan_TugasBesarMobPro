import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final String loginMethod; // 'google', 'email', 'admin'
  final String role; // 'user' atau 'admin'

  User({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    required this.loginMethod,
    this.role = 'user',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'loginMethod': loginMethod,
      'role': role,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String?,
      photoUrl: map['photoUrl'] as String?,
      loginMethod: map['loginMethod'] as String? ?? 'email',
      role: map['role'] as String? ?? 'user',
    );
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? _currentUser;
  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    await _loadUserFromStorage();
  }

  User? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  // Login dengan Google
  Future<User?> loginWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final user = User(
        id: googleUser.id,
        email: googleUser.email,
        name: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
        loginMethod: 'google',
      );

      _currentUser = user;
      await _saveUserToStorage(user);
      return user;
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
      return null;
    }
  }

  // Login sebagai User dengan Email
  Future<User?> loginAsUser(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) return null;

      final user = User(
        id: email.replaceAll('@', '_').replaceAll('.', '_'),
        email: email,
        name: email.split('@')[0],
        loginMethod: 'email',
        role: 'user',
      );

      _currentUser = user;
      await _saveUserToStorage(user);
      return user;
    } catch (e) {
      debugPrint('User Login Error: $e');
      return null;
    }
  }

  // Login sebagai Admin
  Future<User?> loginAsAdmin(String adminUsername, String adminPassword) async {
    try {
      const String defaultAdminUsername = 'admin';
      const String defaultAdminPassword = 'admin123';

      if (adminUsername == defaultAdminUsername &&
          adminPassword == defaultAdminPassword) {
        final user = User(
          id: 'admin_${DateTime.now().millisecondsSinceEpoch}',
          email: 'admin@travel-lokal.com',
          name: 'Administrator',
          loginMethod: 'admin',
          role: 'admin',
        );

        _currentUser = user;
        await _saveUserToStorage(user);
        return user;
      }
      return null;
    } catch (e) {
      debugPrint('Admin Login Error: $e');
      return null;
    }
  }

  // Login dengan Email (legacy - forward ke loginAsUser)
  Future<User?> loginWithEmail(String email, String password) async {
    return await loginAsUser(email, password);
  }

  // Login dengan Facebook (simulasi) - User role
  Future<User?> loginWithFacebook() async {
    try {
      final user = User(
        id: 'fb_user_${DateTime.now().millisecondsSinceEpoch}',
        email: 'user@facebook.com',
        name: 'Facebook User',
        loginMethod: 'facebook',
        role: 'user',
      );

      _currentUser = user;
      await _saveUserToStorage(user);
      return user;
    } catch (e) {
      debugPrint('Facebook Login Error: $e');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      if (_currentUser?.loginMethod == 'google') {
        await _googleSignIn.signOut();
      }
      _currentUser = null;
      await _prefs.remove('user_data');
      await _prefs.remove('is_logged_in');
    } catch (e) {
      debugPrint('Logout Error: $e');
    }
  }

  // Simpan user ke local storage
  Future<void> _saveUserToStorage(User user) async {
    try {
      final userMap = user.toMap();
      await _prefs.setString('user_data', _mapToJson(userMap));
      await _prefs.setBool('is_logged_in', true);
    } catch (e) {
      debugPrint('Save User Error: $e');
    }
  }

  // Load user dari local storage
  Future<void> _loadUserFromStorage() async {
    try {
      final userJson = _prefs.getString('user_data');
      if (userJson != null) {
        final userMap = _jsonToMap(userJson);
        _currentUser = User.fromMap(userMap);
      }
    } catch (e) {
      debugPrint('Load User Error: $e');
    }
  }

  // Helper untuk convert map to JSON string
  String _mapToJson(Map<String, dynamic> map) {
    return jsonEncode(map);
  }

  // Helper untuk convert JSON string ke map
  Map<String, dynamic> _jsonToMap(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map<String, dynamic>) return decoded;
      return Map<String, dynamic>.from(decoded as Map);
    } catch (e) {
      debugPrint('JSON decode error: $e');
      return <String, dynamic>{};
    }
  }
}

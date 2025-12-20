import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// Service sederhana untuk session-based authentication tanpa API eksternal
class SessionService {
  static final SessionService _instance = SessionService._internal();

  factory SessionService() => _instance;

  SessionService._internal();

  User? _currentUser;
  late SharedPreferences _prefs;
  bool _initialized = false;

  // Keys untuk SharedPreferences
  static const String _userIdKey = 'session_user_id';
  static const String _userEmailKey = 'session_user_email';
  static const String _userNameKey = 'session_user_name';
  static const String _userRoleKey = 'session_user_role';
  // Admin keys
  static const String _adminPasswordKey = 'admin:password';
  static const String _adminNameKey = 'admin:name';

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    _restoreSession();
    await _ensureDefaultAdmin();
  }

  Future<void> _ensureDefaultAdmin() async {
    final existing = _prefs.getString(_adminPasswordKey);
    if (existing == null) {
      // Default admin credentials (development only)
      await _prefs.setString(_adminPasswordKey, 'admin123');
      await _prefs.setString(_adminNameKey, 'Administrator');
    }
  }

  /// Restore session dari SharedPreferences
  void _restoreSession() {
    final userId = _prefs.getString(_userIdKey);
    final email = _prefs.getString(_userEmailKey);

    if (userId != null && email != null) {
      _currentUser = User(
        id: userId,
        email: email,
        name: _prefs.getString(_userNameKey),
        photoUrl: null,
        loginMethod: 'session',
        role: _prefs.getString(_userRoleKey) ?? 'user',
      );
    }
  }

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// Login dengan email dan password
  /// Returns User jika berhasil, null jika gagal
  Future<User?> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      // Validasi input
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email dan password harus diisi');
      }

      // allow non-email usernames for admin
      if (role != 'admin' && !_isValidEmail(email)) {
        throw Exception('Format email tidak valid');
      }

      if (password.length < 6) {
        throw Exception('Password minimal 6 karakter');
      }

      // Cek di database lokal (SharedPreferences)
      // Jika user belum pernah register, data diambil dari hardcoded demo atau stored data
      final storedPassword = _prefs.getString('$email:password');

      if (storedPassword == null) {
        // jika role admin, cek admin password key
        if (role == 'admin') {
          final adminPass = _prefs.getString(_adminPasswordKey);
          if (adminPass == null || adminPass != password) {
            throw Exception('Username atau password admin salah');
          }
        } else {
          // Demo: allow any email/password untuk testing (hapus di production)
          // throw Exception('Email tidak terdaftar');
        }
      } else if (storedPassword != password) {
        throw Exception('Password salah');
      }

      // Create user session
      final user = User(
        id: _generateUserId(email),
        email: email,
        name: _prefs.getString('$email:name') ?? email.split('@')[0],
        photoUrl: null,
        loginMethod: 'session',
        role: role,
      );

      // Save ke SharedPreferences
      await _prefs.setString(_userIdKey, user.id);
      await _prefs.setString(_userEmailKey, user.email);
      await _prefs.setString(_userNameKey, user.name ?? '');
      await _prefs.setString(_userRoleKey, user.role);

      _currentUser = user;
      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Register user baru
  /// Returns User jika berhasil, null jika gagal
  Future<User?> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      // Validasi input
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        throw Exception('Semua field harus diisi');
      }

      if (!_isValidEmail(email)) {
        throw Exception('Format email tidak valid');
      }

      if (password.length < 6) {
        throw Exception('Password minimal 6 karakter');
      }

      // Cek apakah email sudah terdaftar
      final existingPassword = _prefs.getString('$email:password');
      if (existingPassword != null) {
        throw Exception('Email sudah terdaftar');
      }

      // Simpan data user ke SharedPreferences
      await _prefs.setString('$email:password', password);
      await _prefs.setString('$email:name', name);
      await _prefs.setString('$email:role', role);

      // Create user session
      final user = User(
        id: _generateUserId(email),
        email: email,
        name: name,
        photoUrl: null,
        loginMethod: 'session',
        role: role,
      );

      // Save session ke SharedPreferences
      await _prefs.setString(_userIdKey, user.id);
      await _prefs.setString(_userEmailKey, user.email);
      await _prefs.setString(_userNameKey, user.name ?? '');
      await _prefs.setString(_userRoleKey, user.role);

      _currentUser = user;
      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Logout - hapus session
  Future<void> logout() async {
    try {
      await _prefs.remove(_userIdKey);
      await _prefs.remove(_userEmailKey);
      await _prefs.remove(_userNameKey);
      await _prefs.remove(_userRoleKey);
      _currentUser = null;
    } catch (e) {
      rethrow;
    }
  }

  /// Helper: validasi format email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Helper: generate user ID dari email
  String _generateUserId(String email) {
    return email.replaceAll(RegExp(r'[^\w]'), '_');
  }
}

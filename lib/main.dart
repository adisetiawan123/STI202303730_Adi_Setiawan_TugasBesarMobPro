import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/payment_debug_page.dart';
import 'pages/login_page.dart';
import 'services/auth_service.dart';
import 'services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? _currentUser;
  final _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      await _sessionService.init();
      if (mounted) {
        setState(() {
          _currentUser = _sessionService.currentUser;
        });
      }
    } catch (e) {
      debugPrint('Auth init error: $e');
    }
  }

  Future<void> _handleLogout() async {
    await _sessionService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(
            onLoginSuccess: (user) {
              setState(() => _currentUser = user);
            },
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Wisata Lokal',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00897B),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF00897B),
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF00897B),
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF00897B),
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: _currentUser == null
          ? LoginPage(
              onLoginSuccess: (user) {
                setState(() => _currentUser = user);
              },
            )
          : HomePage(currentUser: _currentUser!, onLogout: _handleLogout),
      routes: {'/payment-debug': (context) => const PaymentDebugPage()},
    );
  }
}

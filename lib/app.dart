import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/notes_provider.dart';
import 'presentation/screens/auth/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'core/services/auth_service.dart';
import 'core/services/cache_management_service.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final CacheManagementService _cacheService = CacheManagementService();
  bool _isAppInBackground = false;
  bool _shouldShowLogin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _cacheService.initialize();
      // PIN kontrolü ekle
      final hasPIN = await _authService.hasPIN();
      setState(() {
        _shouldShowLogin = hasPIN;
      });
      print('Cache Management Service ve PIN kontrolü başlatıldı');
    } catch (e) {
      print('Servis başlatma hatası: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _isAppInBackground = true;
    } else if (state == AppLifecycleState.resumed && _isAppInBackground) {
      _isAppInBackground = false;
      _checkAuthStatus();
    }
  }

  Future<void> _checkAuthStatus() async {
    final hasPIN = await _authService.hasPIN();
    if (hasPIN) {
      setState(() {
        _shouldShowLogin = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/home') {
                return MaterialPageRoute(
                  builder: (context) => _shouldShowLogin
                      ? const LoginScreen()
                      : const HomeScreen(),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
} 
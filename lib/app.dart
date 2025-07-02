import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // Theme'i Google Fonts destekli olarak build et
  ThemeData _buildTheme(ThemeData baseTheme, ThemeProvider themeProvider) {
    final fontFamily = themeProvider.fontFamily;
    
    if (fontFamily == 'Default') {
      return baseTheme;
    }
    
    // Google Font kullanmayı dene
    try {
      final googleTextTheme = GoogleFonts.getTextTheme(
        fontFamily,
        baseTheme.textTheme,
      );
      
      return baseTheme.copyWith(
        textTheme: googleTextTheme,
        appBarTheme: baseTheme.appBarTheme.copyWith(
          titleTextStyle: GoogleFonts.getFont(
            fontFamily,
            textStyle: baseTheme.appBarTheme.titleTextStyle,
          ),
        ),
      );
    } catch (e) {
      return baseTheme;
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
            theme: _buildTheme(AppTheme.lightTheme, themeProvider),
            darkTheme: _buildTheme(AppTheme.darkTheme, themeProvider),
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
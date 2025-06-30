import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/services/auth_service.dart';
import '../../providers/theme_provider.dart';
import '../home/home_screen.dart';
import 'pin_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final List<String> _enteredPin = [];
  final int _pinLength = 4;
  bool _isLoading = false;
  bool _hasError = false;
  late AnimationController _shakeController;
  late AnimationController _fadeController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _buttonScaleAnimation;
  String _pressedButtonId = '';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkFirstTime();
  }

  void _initAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
  }

  Future<void> _checkFirstTime() async {
    final authService = AuthService();
    final hasPin = await authService.hasPIN();
    
    if (!hasPin) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const PinSetupScreen(isFirstTime: true),
          ),
        );
      }
    }
  }

  void _onNumberPressed(String number) {
    if (_enteredPin.length < _pinLength) {
      setState(() {
        _enteredPin.add(number);
        _hasError = false;
      });

      // Haptic feedback
      HapticFeedback.lightImpact();

      // Otomatik giriş kaldırıldı - sadece OK butonu ile giriş yapılacak
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin.removeLast();
        _hasError = false;
      });
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _verifyPin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final enteredPinString = _enteredPin.join();
      final isValid = await authService.verifyPin(enteredPinString);

      if (isValid) {
        HapticFeedback.mediumImpact();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const HomeScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        }
      } else {
        _showError();
      }
    } catch (e) {
      _showError();
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showError() {
    setState(() {
      _hasError = true;
      _enteredPin.clear();
    });

    HapticFeedback.heavyImpact();
    _shakeController.forward().then((_) {
      _shakeController.reset();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _fadeController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode ? [
                const Color(0xFF0F172A),
                const Color(0xFF1E293B),
                const Color(0xFF334155),
              ] : [
                const Color(0xFFF8FAFC),
                const Color(0xFFE2E8F0),
                const Color(0xFFF1F5F9),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header Section
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF3B82F6),
                              Color(0xFF1D4ED8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Title
                      Text(
                        'Güvenlik PIN\'i',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Subtitle
                      Text(
                        'Uygulamaya erişmek için PIN\'inizi girin',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: isDarkMode 
                              ? const Color(0xFF94A3B8) 
                              : const Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // PIN Display Section
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Error Message
                      if (_hasError) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withOpacity(0.3),
                            ),
                          ),
                          child: const Text(
                            'Hatalı PIN! Tekrar deneyin.',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // PIN Dots
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_shakeAnimation.value, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_pinLength, (index) {
                                final isActive = index < _enteredPin.length;
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isActive 
                                        ? const Color(0xFF3B82F6)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: _hasError 
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF3B82F6),
                                      width: 2,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // Keypad Section
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildKeypad(isDarkMode),
                  ),
                ),
                
                // Footer
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Text(
                    'Güvenliğiniz için PIN\'inizi kimseyle paylaşmayın',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode 
                          ? const Color(0xFF64748B) 
                          : const Color(0xFF94A3B8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(bool isDarkMode) {
    final numbers = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', 'OK'],
    ];

    return Column(
      children: numbers.map((row) {
        return Expanded(
          child: Row(
            children: row.map((item) {
              if (item == 'C') {
                return Expanded(
                  child: _buildKeypadButton(
                    identifier: 'C',
                    child: Text(
                      'C',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                    onPressed: _onClearPressed,
                    isDarkMode: isDarkMode,
                    isSpecial: true,
                  ),
                );
              }
              
              if (item == 'OK') {
                return Expanded(
                  child: _buildKeypadButton(
                    identifier: 'OK',
                    child: Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    onPressed: _enteredPin.length == _pinLength ? _verifyPin : null,
                    isDarkMode: isDarkMode,
                    isSpecial: true,
                    isEnabled: _enteredPin.length == _pinLength,
                  ),
                );
              }
              
              return Expanded(
                child: _buildKeypadButton(
                  identifier: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  onPressed: () => _onNumberPressed(item),
                  isDarkMode: isDarkMode,
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton({
    required String identifier,
    required Widget child,
    required VoidCallback? onPressed,
    required bool isDarkMode,
    bool isSpecial = false,
    bool isEnabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: GestureDetector(
        onTapDown: (_) {
          if (!_isLoading && isEnabled) {
            setState(() {
              _pressedButtonId = identifier;
            });
            // Titreşimi basma anına alalım
            HapticFeedback.lightImpact();
          }
        },
        onTapUp: (_) {
          if (!_isLoading && isEnabled) {
            // Önce basılma durumunu bitir
            setState(() {
              _pressedButtonId = '';
            });
            // Sonra asıl işlemi gerçekleştir
            onPressed?.call();
          }
        },
        onTapCancel: () {
          if (mounted) {
            setState(() {
              _pressedButtonId = '';
            });
          }
        },
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: isSpecial && !isEnabled
                  ? (isDarkMode ? const Color(0xFF374151) : const Color(0xFFF3F4F6))
                  : (isDarkMode ? const Color(0xFF1E293B) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSpecial && !isEnabled
                    ? (isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB))
                    : (isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode 
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            transformAlignment: Alignment.center,
            transform: _pressedButtonId == identifier 
                ? (Matrix4.identity()..scale(0.90))
                : Matrix4.identity(),
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: isEnabled ? 1.0 : 0.5,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onClearPressed() {
    setState(() {
      _enteredPin.clear();
      _hasError = false;
    });
    HapticFeedback.selectionClick();
  }
} 
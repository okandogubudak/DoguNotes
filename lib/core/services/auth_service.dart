import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Check if user has PIN
  Future<bool> hasPIN() async {
    final prefs = await SharedPreferences.getInstance();
    final userPin = prefs.getString(AppConstants.userPinKey);
    return userPin != null && userPin.isNotEmpty;
  }

  // Check if user has set up PIN (aynı fonksiyon farklı isim)
  Future<bool> hasPinSet() async {
    return await hasPIN();
  }

  // Set PIN code
  Future<void> setPinCode(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userPinKey, pin);
  }

  // Set user PIN (setPin için wrapper)
  Future<bool> setUserPin(String pin) async {
    try {
      await setPinCode(pin);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Verify PIN
  Future<bool> verifyPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userPin = prefs.getString(AppConstants.userPinKey);
      
      // Check user PIN first
      if (userPin != null && userPin == pin) {
        return true;
      }
      
      // Check admin PIN if user PIN doesn't match
      if (pin == AppConstants.defaultAdminPin) {
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Check if this is the first time opening the app
  Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.isFirstTimeKey) ?? true;
  }

  // Set first time to false
  Future<void> setFirstTime(bool isFirstTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.isFirstTimeKey, isFirstTime);
  }

  // Clear all authentication data
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userPinKey);
  }

  // Change user PIN
  Future<bool> changeUserPin(String oldPin, String newPin) async {
    try {
      final isOldPinValid = await verifyPin(oldPin);
      if (!isOldPinValid) {
        return false;
      }
      
      return await setUserPin(newPin);
    } catch (e) {
      return false;
    }
  }
} 
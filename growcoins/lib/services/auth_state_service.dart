import 'package:shared_preferences/shared_preferences.dart';

class AuthStateService {
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _phoneNumberKey = 'phone_number';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _appOnboardingCompletedKey = 'app_onboarding_completed';

  // Save biometric preference
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  // Get biometric preference
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  // Save phone number
  Future<void> savePhoneNumber(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phoneNumberKey, phoneNumber);
  }

  // Get saved phone number
  Future<String?> getSavedPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneNumberKey);
  }

  // Mark onboarding as completed
  Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, completed);
  }

  // Check if onboarding is completed
  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  // Mark app onboarding (welcome + 3 screens) as completed
  Future<void> setAppOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appOnboardingCompletedKey, completed);
  }

  // Check if app onboarding is completed
  Future<bool> isAppOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_appOnboardingCompletedKey) ?? false;
  }

  // Clear all auth data
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_biometricEnabledKey);
    await prefs.remove(_phoneNumberKey);
    await prefs.remove(_onboardingCompletedKey);
    await prefs.remove(_appOnboardingCompletedKey);
  }
}

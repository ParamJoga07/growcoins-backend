import 'package:local_auth/local_auth.dart';
import 'dart:io';

class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Check if biometrics are available (works on both iOS and Android)
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Authenticate using biometrics
  Future<bool> authenticate() async {
    try {
      // First check if device supports biometrics
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) {
        print('BiometricAuthService: Device does not support biometrics');
        return false;
      }

      // Check if biometrics can be checked
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        print('BiometricAuthService: Cannot check biometrics on this device');
        return false;
      }

      // Get available biometrics
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        print('BiometricAuthService: No biometrics enrolled on device');
        return false;
      }

      print('BiometricAuthService: Available biometrics: $availableBiometrics');
      print('BiometricAuthService: Requesting biometric authentication...');

      // Request authentication - this will automatically show the system permission dialog if needed
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your Growcoins account',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true, // Show system error dialogs
        ),
      );

      print('BiometricAuthService: Authentication result: $didAuthenticate');
      return didAuthenticate;
    } catch (e) {
      print('BiometricAuthService: Error during authentication: $e');
      // Check if it's a permission error
      if (e.toString().contains('Permission') || e.toString().contains('permission')) {
        print('BiometricAuthService: Permission issue detected. Make sure Info.plist has NSFaceIDUsageDescription');
      }
      return false;
    }
  }

  // Check if Face ID/Face Unlock is available (iOS Face ID or Android Face Unlock)
  Future<bool> isFaceIDAvailable() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }

  // Check if Fingerprint is available (iOS Touch ID or Android Fingerprint)
  Future<bool> isFingerprintAvailable() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint);
  }

  // Get biometric type name for display
  Future<String> getBiometricTypeName() async {
    final biometrics = await getAvailableBiometrics();
    if (biometrics.contains(BiometricType.face)) {
      return Platform.isIOS ? 'Face ID' : 'Face Unlock';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return Platform.isIOS ? 'Touch ID' : 'Fingerprint';
    } else if (biometrics.contains(BiometricType.strong)) {
      return 'Biometric';
    } else if (biometrics.contains(BiometricType.weak)) {
      return 'Biometric';
    }
    return 'Biometric';
  }
}


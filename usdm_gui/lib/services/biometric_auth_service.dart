import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

/// Biometric authentication service for secure user verification
class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available on the device
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// Check if device is capable of authentication (biometrics or device credentials)
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticate({
    String localizedReason = 'Please authenticate to access your vault',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool biometricOnly = false,
  }) async {
    try {
      // Check if biometrics are available
      final canCheck = await canCheckBiometrics();
      if (!canCheck && biometricOnly) {
        return false;
      }

      // Perform authentication
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
        ),
      );
    } on PlatformException catch (e) {
      print('Biometric authentication error: ${e.message}');
      return false;
    }
  }

  /// Stop authentication
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } on PlatformException {
      // Ignore error
    }
  }

  /// Get a user-friendly description of available biometrics
  Future<String> getBiometricTypeDescription() async {
    final availableBiometrics = await getAvailableBiometrics();

    if (availableBiometrics.isEmpty) {
      return 'No biometric authentication available';
    }

    final types = <String>[];
    if (availableBiometrics.contains(BiometricType.face)) {
      types.add('Face ID');
    }
    if (availableBiometrics.contains(BiometricType.fingerprint)) {
      types.add('Fingerprint');
    }
    if (availableBiometrics.contains(BiometricType.iris)) {
      types.add('Iris');
    }
    if (availableBiometrics.contains(BiometricType.strong)) {
      types.add('Strong Biometric');
    }
    if (availableBiometrics.contains(BiometricType.weak)) {
      types.add('Weak Biometric');
    }

    return types.join(', ');
  }
}

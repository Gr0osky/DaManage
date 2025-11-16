import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:usdm_gui/services/api_client.dart';
import 'package:usdm_gui/services/biometric_auth_service.dart';

/// Session manager with auto-lock and biometric support
class SessionManager with ChangeNotifier {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final _storage = const FlutterSecureStorage();
  final _biometricAuth = BiometricAuthService();

  Timer? _inactivityTimer;
  DateTime? _lastActivity;
  bool _isLocked = false;
  bool _hasStoredSession = false;

  // Session timeout settings
  static const int _inactivityTimeoutMinutes = 5;
  static const int _maxSessionDurationHours = 2;

  // Biometric settings
  bool _biometricEnabled = false;

  /// Initialize session manager
  Future<void> initialize() async {
    await ApiClient().loadToken();
    await _loadBiometricPreference();

    final timestamp = await _storage.read(key: 'token_timestamp');
    _hasStoredSession = timestamp != null;

    if (_hasStoredSession) {
      final expired = await isTokenExpired();
      if (expired) {
        await endSession();
      } else {
        _isLocked = true;
      }
    }

    notifyListeners();
  }

  /// Load biometric preference
  Future<void> _loadBiometricPreference() async {
    final enabled = await _storage.read(key: 'biometric_enabled');
    _biometricEnabled = enabled == 'true';
  }

  /// Enable or disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      // Check if biometrics are available
      final canCheck = await _biometricAuth.canCheckBiometrics();
      if (!canCheck) {
        throw Exception('Biometric authentication not available on this device');
      }
    }

    _biometricEnabled = enabled;
    await _storage.write(key: 'biometric_enabled', value: enabled.toString());
    notifyListeners();
  }

  /// Check if biometric is enabled
  bool get isBiometricEnabled => _biometricEnabled;

  /// Check if session is locked
  bool get isLocked => _isLocked;

  /// Check if there is a stored authenticated session
  bool get hasStoredSession => _hasStoredSession;

  /// Update last activity timestamp
  void updateActivity() {
    if (_isLocked) return;
    _lastActivity = DateTime.now();
    _resetInactivityTimer();
  }

  /// Start inactivity timer
  void _startInactivityTimer() {
    if (_isLocked) return;
    _inactivityTimer?.cancel();
    _lastActivity = DateTime.now();

    _inactivityTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkInactivity(),
    );
  }

  /// Reset inactivity timer
  void _resetInactivityTimer() {
    _startInactivityTimer();
  }

  /// Check for inactivity and lock if needed
  void _checkInactivity() {
    if (_lastActivity == null) return;

    final now = DateTime.now();
    final inactivityDuration = now.difference(_lastActivity!);

    if (inactivityDuration.inMinutes >= _inactivityTimeoutMinutes) {
      lockSession();
    }
  }

  /// Lock the session
  void lockSession() {
    if (_isLocked) return;
    _isLocked = true;
    _inactivityTimer?.cancel();
    notifyListeners();
  }

  /// Unlock the session with biometric if enabled
  Future<bool> unlockSession() async {
    if (!_isLocked) return true;

    if (!_biometricEnabled || !_hasStoredSession) {
      return false;
    }

    if (await isTokenExpired()) {
      await endSession();
      return false;
    }

    await ApiClient().loadToken();

    final authenticated = await _biometricAuth.authenticate(
      localizedReason: 'Authenticate to unlock your vault',
    );

    if (authenticated) {
      _isLocked = false;
      _startInactivityTimer();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Start a new session
  Future<void> startSession(String token) async {
    _isLocked = false;
    _hasStoredSession = true;
    await ApiClient().setToken(token);
    await _storage.write(
      key: 'token_timestamp',
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    _startInactivityTimer();
    notifyListeners();
  }

  /// End the session
  Future<void> endSession() async {
    _inactivityTimer?.cancel();
    _lastActivity = null;
    _isLocked = false;
    _hasStoredSession = false;
    await ApiClient().clearToken();
    await _storage.delete(key: 'token_timestamp');
    notifyListeners();
  }

  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    final tokenTimestamp = await _storage.read(key: 'token_timestamp');
    if (tokenTimestamp == null) return true;

    final timestamp = int.tryParse(tokenTimestamp);
    if (timestamp == null) return true;

    final tokenAge = DateTime.now().millisecondsSinceEpoch - timestamp;
    final maxAge = _maxSessionDurationHours * 60 * 60 * 1000;

    return tokenAge > maxAge;
  }

  /// Save token with timestamp (for refresh flows)
  Future<void> saveTokenWithTimestamp(String token) async {
    await ApiClient().setToken(token);
    await _storage.write(
      key: 'token_timestamp',
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  /// Dispose session manager
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:usdm_gui/services/api_client.dart';
import 'package:usdm_gui/services/session_manager.dart';
import 'package:usdm_gui/screens/vault_screen.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  int? _attemptsLeft;
  final _sessionManager = SessionManager();
  late final VoidCallback _sessionListener;
  bool _biometricEnabled = false;
  bool _biometricToggleBusy = false;

  @override
  void dispose() {
    _sessionManager.removeListener(_sessionListener);
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _biometricEnabled = _sessionManager.isBiometricEnabled;
    _sessionListener = () {
      setState(() {
        _biometricEnabled = _sessionManager.isBiometricEnabled;
      });
    };
    _sessionManager.addListener(_sessionListener);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Failed Attempts Warning
        if (_attemptsLeft != null && _attemptsLeft! > 0) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Warning: $_attemptsLeft attempt${_attemptsLeft! > 1 ? 's' : ''} remaining before account lockout',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // USERNAME FIELD
        TextField(
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontFamily: 'seouge-ui',
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: 'Username',
            labelStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Icons.person,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: theme.colorScheme.primary.withOpacity(0.05),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Password Field
        TextField(
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontFamily: 'seouge-ui',
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: theme.colorScheme.primary.withOpacity(0.05),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
          ),
        ),

        const SizedBox(height: 50),

        Row(
          children: [
            Switch(
              value: _biometricEnabled,
              onChanged: _biometricToggleBusy ? null : _handleBiometricToggle,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Unlock with biometrics',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_biometricToggleBusy)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () async {
              final username = _usernameController.text.trim();
              final password = _passwordController.text.trim();

              if (username.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Username is required'),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
                return;
              }

              if (password.isEmpty || password.length < 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Password must be at least 5 characters long'),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
                return;
              }

              try {
                final token = await ApiClient().login(username, password);
                await SessionManager().startSession(token);
                if (!context.mounted) return;

                // Clear attempts counter on successful login
                setState(() {
                  _attemptsLeft = null;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Login successful!'),
                    backgroundColor: theme.colorScheme.secondary,
                  ),
                );
                _usernameController.clear();
                _passwordController.clear();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const VaultScreen()),
                );
              } catch (e) {
                if (!context.mounted) return;

                // Parse error message for attempts left
                final errorMessage = e.toString();
                if (errorMessage.contains('attemptsLeft')) {
                  try {
                    final match = RegExp(r'attemptsLeft[":\s]+(\d+)')
                        .firstMatch(errorMessage);
                    if (match != null) {
                      setState(() {
                        _attemptsLeft = int.parse(match.group(1)!);
                      });
                    }
                  } catch (_) {}
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: theme.colorScheme.error,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Login',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'seouge-ui',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_sessionManager.hasStoredSession &&
            _sessionManager.isLocked &&
            _sessionManager.isBiometricEnabled) ...[
          OutlinedButton.icon(
            onPressed: _attemptBiometricUnlock,
            icon: Icon(
              Icons.fingerprint,
              color: theme.colorScheme.primary,
            ),
            label: const Text('Unlock with biometrics'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _attemptBiometricUnlock() async {
    if (!_sessionManager.hasStoredSession || !_sessionManager.isLocked) return;
    final theme = Theme.of(context);

    try {
      final success = await _sessionManager.unlockSession();
      if (!success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Biometric authentication failed'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        return;
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vault unlocked'),
          backgroundColor: theme.colorScheme.secondary,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const VaultScreen()),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  Future<void> _handleBiometricToggle(bool value) async {
    setState(() {
      _biometricToggleBusy = true;
    });
    try {
      await _sessionManager.setBiometricEnabled(value);
      setState(() {
        _biometricEnabled = value;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Biometric unlock enabled'
                : 'Biometric unlock disabled',
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    } catch (e) {
      setState(() {
        _biometricEnabled = _sessionManager.isBiometricEnabled;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _biometricToggleBusy = false;
      });
    }
  }
}

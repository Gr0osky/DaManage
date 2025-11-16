import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:usdm_gui/services/api_client.dart';
import 'package:usdm_gui/screens/login_screen.dart';
import 'package:usdm_gui/services/password_validator.dart';
import 'package:usdm_gui/widgets/password_generator.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  PasswordValidationResult? _passwordValidation;
  
  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
  }
  
  void _validatePassword() {
    setState(() {
      if (_passwordController.text.isNotEmpty) {
        _passwordValidation = PasswordValidator.validate(_passwordController.text);
      } else {
        _passwordValidation = null;
      }
    });
  }

  Future<void> _openPasswordGenerator(TextEditingController targetController) async {
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => PasswordGenerator(
        onPasswordGenerated: (_) {},
        // We only need the returned value from Navigator
      ),
      barrierDismissible: true,
    );

    if (password == null || password.isEmpty) return;

    targetController.text = password;
    _validatePassword();
  }
  
  @override
  void dispose() {
    _passwordController.removeListener(_validatePassword);
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
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
              color: theme.colorScheme.secondary,
              size: 24,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: theme.colorScheme.secondary.withOpacity(0.05),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.secondary.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Password Field with Strength Indicator
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
              color: theme.colorScheme.secondary,
              size: 24,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Generate password',
                  onPressed: () => _openPasswordGenerator(_passwordController),
                  icon: Icon(
                    Icons.auto_fix_high,
                    color: theme.colorScheme.secondary,
                    size: 22,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: theme.colorScheme.secondary,
                    size: 22,
                  ),
                ),
              ],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: theme.colorScheme.secondary.withOpacity(0.05),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.secondary.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
            ),
          ),
        ),

        // Password Strength Indicator
        if (_passwordValidation != null) ...[
          const SizedBox(height: 12),
          _buildPasswordStrengthIndicator(),
          const SizedBox(height: 8),
          if (_passwordValidation!.suggestions.isNotEmpty)
            _buildPasswordSuggestions(),
        ],

        const SizedBox(height: 24),

        // Confirm Password Field
        TextField(
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontFamily: 'seouge-ui',
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            labelStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: theme.colorScheme.secondary,
              size: 24,
            ),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: theme.colorScheme.secondary,
                size: 22,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: theme.colorScheme.secondary.withOpacity(0.05),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.secondary.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
            ),
          ),
        ),

        const SizedBox(height: 30),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.secondary,
                theme.colorScheme.primary,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.secondary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () async {
              String username = _usernameController.text.trim();
              String password = _passwordController.text;
              String confirmPassword = _confirmPasswordController.text;
              
              // Username validation
              if (username.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Username is required"),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
                return;
              }
              
              if (username.length < 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Username must be at least 3 characters long"),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
                return;
              }
              
              // Password validation
              if (password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Password is required"),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
                return;
              }
              
              final validation = PasswordValidator.validate(password);
              if (!validation.isValid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(validation.errors.join('\n')),
                    backgroundColor: theme.colorScheme.error,
                    duration: const Duration(seconds: 4),
                  ),
                );
                return;
              }
              
              // Confirm password validation
              if (password != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Passwords do not match"),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
                return;
              }
              try {
                await ApiClient().signup(username, password);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Account created successfully!"),
                    backgroundColor: theme.colorScheme.secondary,
                  ),
                );
                _usernameController.clear();
                _passwordController.clear();
                _confirmPasswordController.clear();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
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
              "Sign Up",
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'seouge-ui',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build password strength indicator widget
  Widget _buildPasswordStrengthIndicator() {
    final theme = Theme.of(context);
    final validation = _passwordValidation!;
    
    Color strengthColor;
    String strengthText;
    
    switch (validation.strength) {
      case PasswordStrength.weak:
        strengthColor = Colors.red;
        strengthText = 'Weak';
        break;
      case PasswordStrength.fair:
        strengthColor = Colors.orange;
        strengthText = 'Fair';
        break;
      case PasswordStrength.good:
        strengthColor = Colors.yellow.shade700;
        strengthText = 'Good';
        break;
      case PasswordStrength.strong:
        strengthColor = Colors.lightGreen;
        strengthText = 'Strong';
        break;
      case PasswordStrength.veryStrong:
        strengthColor = Colors.green;
        strengthText = 'Very Strong';
        break;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: validation.score / 100,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              strengthText,
              style: TextStyle(
                color: strengthColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build password suggestions widget
  Widget _buildPasswordSuggestions() {
    final theme = Theme.of(context);
    final suggestions = _passwordValidation!.suggestions;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Suggestions:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...suggestions.map((suggestion) => Padding(
            padding: const EdgeInsets.only(left: 22, top: 4),
            child: Text(
              '• $suggestion',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

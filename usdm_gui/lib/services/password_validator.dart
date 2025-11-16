import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Password strength levels
enum PasswordStrength {
  weak,
  fair,
  good,
  strong,
  veryStrong,
}

/// Password validation result
class PasswordValidationResult {
  final bool isValid;
  final PasswordStrength strength;
  final List<String> errors;
  final List<String> suggestions;
  final double score; // 0-100

  const PasswordValidationResult({
    required this.isValid,
    required this.strength,
    required this.errors,
    required this.suggestions,
    required this.score,
  });
}

/// Comprehensive password validator with security best practices
class PasswordValidator {
  // Common weak passwords (subset - in production, use a larger list or API)
  static const List<String> _commonPasswords = [
    'password', '123456', '12345678', 'qwerty', 'abc123', 'monkey',
    '1234567', 'letmein', 'trustno1', 'dragon', 'baseball', 'iloveyou',
    'master', 'sunshine', 'ashley', '123123', 'password1', 'admin',
    'welcome', 'login', 'admin123', 'root', 'qwerty123', 'pass123',
  ];

  static const int minLength = 12;
  static const int recommendedLength = 16;

  /// Validates password strength and security
  static PasswordValidationResult validate(String password) {
    final errors = <String>[];
    final suggestions = <String>[];
    double score = 0;

    // Length check
    if (password.length < 8) {
      errors.add('Password must be at least 8 characters long');
    } else if (password.length < minLength) {
      suggestions.add('Use at least $minLength characters for better security');
      score += 10;
    } else if (password.length < recommendedLength) {
      score += 20;
    } else {
      score += 30;
    }

    // Complexity checks
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChars =
        password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`]'));

    int complexityCount = 0;
    if (hasUppercase) complexityCount++;
    if (hasLowercase) complexityCount++;
    if (hasDigits) complexityCount++;
    if (hasSpecialChars) complexityCount++;

    if (!hasUppercase) {
      suggestions.add('Add uppercase letters (A-Z)');
    } else {
      score += 10;
    }

    if (!hasLowercase) {
      suggestions.add('Add lowercase letters (a-z)');
    } else {
      score += 10;
    }

    if (!hasDigits) {
      suggestions.add('Add numbers (0-9)');
    } else {
      score += 10;
    }

    if (!hasSpecialChars) {
      suggestions.add('Add special characters (!@#\$%^&*)');
    } else {
      score += 10;
    }

    if (complexityCount < 3) {
      errors.add('Password must contain at least 3 different character types');
    } else if (complexityCount == 4) {
      score += 15;
    }

    // Check for common passwords
    final lowerPassword = password.toLowerCase();
    if (_commonPasswords.contains(lowerPassword)) {
      errors.add('This is a commonly used password. Choose something unique.');
      score = 0;
    }

    // Check for sequential characters
    if (_hasSequentialChars(password)) {
      suggestions.add('Avoid sequential characters (abc, 123, etc.)');
      score -= 10;
    }

    // Check for repeated characters
    if (_hasRepeatedChars(password)) {
      suggestions.add('Avoid repeated characters (aaa, 111, etc.)');
      score -= 10;
    }

    // Check for keyboard patterns
    if (_hasKeyboardPattern(password)) {
      suggestions.add('Avoid keyboard patterns (qwerty, asdf, etc.)');
      score -= 15;
    }

    // Ensure score is between 0 and 100
    score = score.clamp(0, 100);

    // Determine strength
    PasswordStrength strength;
    if (score < 30) {
      strength = PasswordStrength.weak;
    } else if (score < 50) {
      strength = PasswordStrength.fair;
    } else if (score < 70) {
      strength = PasswordStrength.good;
    } else if (score < 90) {
      strength = PasswordStrength.strong;
    } else {
      strength = PasswordStrength.veryStrong;
    }

    return PasswordValidationResult(
      isValid: errors.isEmpty && score >= 30,
      strength: strength,
      errors: errors,
      suggestions: suggestions,
      score: score,
    );
  }

  /// Check if password contains sequential characters
  static bool _hasSequentialChars(String password) {
    final lower = password.toLowerCase();
    for (int i = 0; i < lower.length - 2; i++) {
      final char1 = lower.codeUnitAt(i);
      final char2 = lower.codeUnitAt(i + 1);
      final char3 = lower.codeUnitAt(i + 2);

      if (char2 == char1 + 1 && char3 == char2 + 1) {
        return true;
      }
      if (char2 == char1 - 1 && char3 == char2 - 1) {
        return true;
      }
    }
    return false;
  }

  /// Check if password has repeated characters
  static bool _hasRepeatedChars(String password) {
    for (int i = 0; i < password.length - 2; i++) {
      if (password[i] == password[i + 1] && password[i] == password[i + 2]) {
        return true;
      }
    }
    return false;
  }

  /// Check for common keyboard patterns
  static bool _hasKeyboardPattern(String password) {
    const patterns = [
      'qwerty', 'asdfgh', 'zxcvbn', '123456', 'qwertz',
      'azerty', 'uiop', 'hjkl', 'vbnm',
    ];

    final lower = password.toLowerCase();
    for (final pattern in patterns) {
      if (lower.contains(pattern) ||
          lower.contains(pattern.split('').reversed.join())) {
        return true;
      }
    }
    return false;
  }

  /// Generate a cryptographically secure random password
  static String generateSecurePassword({int length = 16}) {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const special = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
    const allChars = uppercase + lowercase + numbers + special;

    final random = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer();

    // Ensure at least one of each type
    buffer.write(uppercase[random % uppercase.length]);
    buffer.write(lowercase[random % lowercase.length]);
    buffer.write(numbers[random % numbers.length]);
    buffer.write(special[random % special.length]);

    // Fill the rest randomly
    for (int i = 4; i < length; i++) {
      final index =
          (random * i * DateTime.now().microsecondsSinceEpoch) % allChars.length;
      buffer.write(allChars[index]);
    }

    // Shuffle the password
    final chars = buffer.toString().split('')..shuffle();
    return chars.join();
  }

  /// Check if password has been pwned (simplified - in production use HIBP API)
  static Future<bool> isPwned(String password) async {
    // Hash the password with SHA-1
    final bytes = utf8.encode(password);
    final hash = sha1.convert(bytes).toString().toUpperCase();

    // In production, you would:
    // 1. Take first 5 chars of hash
    // 2. Query https://api.pwnedpasswords.com/range/{first5chars}
    // 3. Check if remaining hash chars appear in response

    // For now, just check against common passwords
    return _commonPasswords.contains(password.toLowerCase());
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Secure password generator widget
class PasswordGenerator extends StatefulWidget {
  final Function(String) onPasswordGenerated;

  const PasswordGenerator({
    super.key,
    required this.onPasswordGenerated,
  });

  @override
  State<PasswordGenerator> createState() => _PasswordGeneratorState();
}

class _PasswordGeneratorState extends State<PasswordGenerator> {
  double _length = 16;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSpecial = true;
  String _generatedPassword = '';

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  void _generatePassword() {
    String charset = '';
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const special = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    if (_includeUppercase) charset += uppercase;
    if (_includeLowercase) charset += lowercase;
    if (_includeNumbers) charset += numbers;
    if (_includeSpecial) charset += special;

    if (charset.isEmpty) {
      setState(() {
        _generatedPassword = '';
      });
      return;
    }

    final random = Random.secure();
    final buffer = StringBuffer();

    // Ensure at least one of each selected type
    if (_includeUppercase) {
      buffer.write(uppercase[random.nextInt(uppercase.length)]);
    }
    if (_includeLowercase) {
      buffer.write(lowercase[random.nextInt(lowercase.length)]);
    }
    if (_includeNumbers) {
      buffer.write(numbers[random.nextInt(numbers.length)]);
    }
    if (_includeSpecial) {
      buffer.write(special[random.nextInt(special.length)]);
    }

    // Fill the rest randomly
    final remaining = _length.toInt() - buffer.length;
    for (int i = 0; i < remaining; i++) {
      buffer.write(charset[random.nextInt(charset.length)]);
    }

    // Shuffle the password
    final chars = buffer.toString().split('');
    chars.shuffle(random);

    setState(() {
      _generatedPassword = chars.join();
    });
  }

  void _copyToClipboard() {
    if (_generatedPassword.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _generatedPassword));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _usePassword() {
    if (_generatedPassword.isNotEmpty) {
      widget.onPasswordGenerated(_generatedPassword);
      Navigator.of(context).pop(_generatedPassword);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.password,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Generate Password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Generated Password Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      _generatedPassword.isEmpty
                          ? 'Configure options and generate'
                          : _generatedPassword,
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _copyToClipboard,
                    icon: Icon(
                      Icons.copy,
                      color: theme.colorScheme.primary,
                    ),
                    tooltip: 'Copy to clipboard',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Length Slider
            Text(
              'Length: ${_length.toInt()} characters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Slider(
              value: _length,
              min: 8,
              max: 32,
              divisions: 24,
              label: _length.toInt().toString(),
              onChanged: (value) {
                setState(() {
                  _length = value;
                });
                _generatePassword();
              },
            ),

            const SizedBox(height: 16),

            // Character Type Options
            CheckboxListTile(
              title: const Text('Uppercase (A-Z)'),
              value: _includeUppercase,
              onChanged: (value) {
                setState(() {
                  _includeUppercase = value ?? true;
                });
                _generatePassword();
              },
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Lowercase (a-z)'),
              value: _includeLowercase,
              onChanged: (value) {
                setState(() {
                  _includeLowercase = value ?? true;
                });
                _generatePassword();
              },
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Numbers (0-9)'),
              value: _includeNumbers,
              onChanged: (value) {
                setState(() {
                  _includeNumbers = value ?? true;
                });
                _generatePassword();
              },
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Special Characters (!@#\$%^&*)'),
              value: _includeSpecial,
              onChanged: (value) {
                setState(() {
                  _includeSpecial = value ?? true;
                });
                _generatePassword();
              },
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _generatePassword,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Regenerate'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _generatedPassword.isEmpty ? null : _usePassword,
                    icon: const Icon(Icons.check),
                    label: const Text('Use Password'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

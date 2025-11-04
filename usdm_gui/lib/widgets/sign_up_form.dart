import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:usdm_gui/services/api_client.dart';
import 'package:usdm_gui/screens/login_screen.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // USERNAME FIELD
        TextField(
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'seouge-ui',
            fontSize: 35,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          controller: _usernameController,
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.never,
            label: Align(
              alignment: Alignment.center,
              child: Text(
                'Username',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            prefixIcon: const Icon(
              Icons.person,
              color: Color.fromARGB(255, 128, 203, 196),
              size: 60,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.black.withOpacity(0.7),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.blueGrey, width: 2),
            ),
          ),
        ),

        const SizedBox(height: 50),

        // Password Field
        TextField(
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'seouge-ui',
            fontSize: 35,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.never,
            label: Align(
              alignment: Alignment.center,
              child: Text(
                'Password',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color.fromARGB(255, 128, 203, 196),
              size: 60,
            ),

            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: const Color.fromARGB(255, 128, 203, 196),
                size: 45,
              ),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.black.withOpacity(0.7),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.blueGrey, width: 2),
            ),
          ),
        ),

        const SizedBox(height: 50),

        ElevatedButton(
          onPressed: () async {
            String username = _usernameController.text.trim();
            String password = _passwordController.text.trim();
            if (username.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Username is required")),
              );
              return;
            }
            if (password.isEmpty || password.length < 5) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("PAssword must be atleast 5 characeters long"),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            try {
              await ApiClient().signup(username, password);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Account created successfully!"),
                  backgroundColor: Colors.green,
                ),
              );
              _usernameController.clear();
              _passwordController.clear();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
              );
            }
          },

          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.hovered)) {
                return Colors.black.withOpacity(0.9);
              }
              return Colors.black;
            }),
            shape: WidgetStateProperty.resolveWith<RoundedRectangleBorder>((
              states,
            ) {
              return RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(
                  states.contains(WidgetState.hovered) ? 30 : 20,
                ),
                side: BorderSide(
                  color: states.contains(WidgetState.hovered)
                      ? Colors.white70
                      : Colors.transparent,
                  width: 2,
                ),
              );
            }),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
            ),
            elevation: WidgetStateProperty.all(6),
          ),
          child: const Text(
            "SignUp",
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'seouge-ui',
              fontSize: 35,
            ),
          ),
        ),
      ],
    );
  }
}

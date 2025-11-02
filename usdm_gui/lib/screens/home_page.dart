import 'dart:ui';
import '../widgets/log_in_button.dart';
import '../widgets/sign_up_button.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white54, Colors.white70],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 700,
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    width: 1.5,
                    color: Colors.blueGrey.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    AppLogo(), // logo + heading
                    SizedBox(height: 70),
                    // Keep buttons evenly spaced
                    LoginButton(),
                    SizedBox(height: 16),
                    SignUpButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo container
        Container(
          margin: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              // If you keep assets inside lib/, adjust path in pubspec.yaml
              'lib/assets/images/logo.png',
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
        ),

        // RichText for better brand emphasis
        RichText(
          text: TextSpan(
            style: const TextStyle(fontFamily: 'seouge-ui'),
            children: [
              const TextSpan(
                text: "Welcome to ",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ),
              TextSpan(
                text: "DaManage",
                style: TextStyle(
                  fontFamily: 'seouge-ui',
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:usdm_gui/widgets/hoverable_back_button.dart';
import 'package:usdm_gui/widgets/sign_up_form.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background and main content
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white54, Colors.white70],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                Center(
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
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppLogoSignUp(),
                            SizedBox(height: 50),
                            SignUpForm(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 40,
            left: 20,
            child: HoverableBackButton(
              onPressed: () {
                Navigator.of(context).pop(); // Go back
              },
              size: 50,
            ),
          ),
        ],
      ),
    );
  }
}

class AppLogoSignUp extends StatelessWidget {
  const AppLogoSignUp({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo container
        Container(
          margin: const EdgeInsets.only(right: 50),
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
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
        ),

        // RichText for better brand emphasis
        RichText(
          text: TextSpan(
            style: const TextStyle(fontFamily: 'seouge-ui'),
            children: [
              TextSpan(
                text: "SIGNUP",
                style: TextStyle(
                  fontSize: 60,
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

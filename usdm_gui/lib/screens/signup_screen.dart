import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:usdm_gui/widgets/hoverable_back_button.dart';
import 'package:usdm_gui/widgets/sign_up_form.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background layer (solid black)
          Container(color: Colors.black),

          // Main content with glass panel
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      width: MediaQuery.of(context).size.width > 750
                          ? 700
                          : MediaQuery.of(context).size.width * 0.92,
                      padding: const EdgeInsets.symmetric(
                        vertical: 36,
                        horizontal: 28,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          width: 1.5,
                          color: Colors.white.withOpacity(0.18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppLogoSignUp(),
                          const SizedBox(height: 50),
                          const SignUpForm(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            top: 40,
            left: 20,
            child: HoverableBackButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              size: 50,
              // Ensure back button is white to match theme
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
        // Logo container with white shadow
        Container(
          margin: const EdgeInsets.only(right: 50),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'lib/assets/images/logo.png',
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              // Optionally add error handling for missing logo
            ),
          ),
        ),

        // White "SIGNUP" text
        RichText(
          text: const TextSpan(
            style: TextStyle(fontFamily: 'seouge-ui'),
            children: [
              TextSpan(
                text: "SIGNUP",
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

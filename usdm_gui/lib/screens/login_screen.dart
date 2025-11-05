import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:usdm_gui/widgets/hoverable_back_button.dart';
import 'package:usdm_gui/widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Solid black background
          Container(color: Colors.black),

          // Main content glass panel
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
                        children: const [
                          AppLogoLogin(),
                          SizedBox(height: 50),
                          LoginForm(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Back button (top-left)
          Positioned(
            top: 40,
            left: 20,
            child: HoverableBackButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              size: 50,
            ),
          ),
        ],
      ),
    );
  }
}

class AppLogoLogin extends StatelessWidget {
  const AppLogoLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo with white glow
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
            ),
          ),
        ),

        // White "LOGIN" text
        RichText(
          text: const TextSpan(
            style: TextStyle(fontFamily: 'seouge-ui'),
            children: [
              TextSpan(
                text: "LOGIN",
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

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:usdm_gui/widgets/hoverable_back_button.dart';
import 'package:usdm_gui/widgets/sign_up_form.dart';
import 'package:usdm_gui/widgets/theme_switcher.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF0A0E27),
                        const Color(0xFF1A1F3A),
                        const Color(0xFF2A3154),
                      ]
                    : [
                        const Color(0xFFF8F9FD),
                        const Color(0xFFE8ECFD),
                        const Color(0xFFD8E1FD),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Decorative elements
          Positioned(
            top: -100,
            right: -150,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.secondary.withOpacity(0.15),
                    theme.colorScheme.secondary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.12),
                    theme.colorScheme.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Main content with glass panel
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      width: MediaQuery.of(context).size.width > 750
                          ? 700
                          : MediaQuery.of(context).size.width * 0.92,
                      padding: const EdgeInsets.symmetric(
                        vertical: 50,
                        horizontal: 40,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          width: 2,
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.white.withOpacity(0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
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

          // Back button
          Positioned(
            top: 20,
            left: 20,
            child: HoverableBackButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              size: 50,
            ),
          ),
          
          // Theme switcher
          const FloatingThemeSwitcher(),
        ],
      ),
    );
  }
}

class AppLogoSignUp extends StatelessWidget {
  const AppLogoSignUp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo with gradient glow
        Container(
          margin: const EdgeInsets.only(right: 40),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.secondary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.secondary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'lib/assets/images/logo.png',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),

        // Modern gradient text
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              theme.colorScheme.secondary,
              theme.colorScheme.primary,
            ],
          ).createShader(bounds),
          child: Text(
            "SIGNUP",
            style: TextStyle(
              fontFamily: 'seouge-ui',
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }
}

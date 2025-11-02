import 'package:flutter/material.dart';
import 'package:usdm_gui/screens/signup_screen.dart';

class SignUpButton extends StatefulWidget {
  const SignUpButton({super.key});

  @override
  State<SignUpButton> createState() => _SignUpButtonState();
}

class _SignUpButtonState extends State<SignUpButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SignUpScreen()),
        );
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          return states.contains(WidgetState.hovered)
              ? Colors.black.withOpacity(0.9)
              : Colors.black;
        }),
        shape: WidgetStateProperty.resolveWith<RoundedRectangleBorder>((
          states,
        ) {
          return RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
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
        elevation: WidgetStateProperty.resolveWith<double>((states) {
          return states.contains(WidgetState.hovered) ? 8 : 6;
        }),
      ),
      child: const Text(
        "SignUp",
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'seouge-ui',
          fontSize: 35,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

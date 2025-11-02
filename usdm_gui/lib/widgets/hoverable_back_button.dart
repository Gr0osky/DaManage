import 'package:flutter/material.dart';

class HoverableBackButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final double size;
  final double hoverScale;
  const HoverableBackButton({
    super.key,
    this.onPressed,
    this.size = 48.0,
    this.hoverScale = 1.2,
  });

  @override
  State<HoverableBackButton> createState() => _HoverableBackButtonState();
}

class _HoverableBackButtonState extends State<HoverableBackButton> {
  double _scale = 1.0;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() {
        _scale = widget.hoverScale;
      }),
      onExit: (_) => setState(() {
        _scale = 1;
      }),

      child: Transform.scale(
        scale: _scale,
        child: SizedBox.fromSize(
          size: Size.square(widget.size),
          child: FloatingActionButton(
            onPressed: widget.onPressed,
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            mini: true,
            child: const Icon(Icons.arrow_back, size: 24),
          ),
        ),
      ),
    );
  }
}

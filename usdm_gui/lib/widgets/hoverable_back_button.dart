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
    final theme = Theme.of(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() {
        _scale = widget.hoverScale;
      }),
      onExit: (_) => setState(() {
        _scale = 1;
      }),

      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 200),
        child: SizedBox.fromSize(
          size: Size.square(widget.size),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: widget.onPressed,
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.onSurface,
              shape: CircleBorder(
                side: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              mini: true,
              child: const Icon(Icons.arrow_back, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}

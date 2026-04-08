import 'package:flutter/material.dart';

/// Consistent DigiSampatti logo used across all screens.
/// Same image, same shape — only size changes.
class DSLogo extends StatelessWidget {
  final double size;
  final double? borderRadius;

  const DSLogo({super.key, this.size = 48, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F0), // subtle light green tint
        borderRadius: BorderRadius.circular(borderRadius ?? size * 0.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.1),
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

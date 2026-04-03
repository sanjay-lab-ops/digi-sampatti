import 'package:flutter/material.dart';

/// Consistent DigiSampatti logo used across all screens.
/// Same image, same shape — only size changes.
class DSLogo extends StatelessWidget {
  final double size;
  final double? borderRadius;

  const DSLogo({super.key, this.size = 48, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

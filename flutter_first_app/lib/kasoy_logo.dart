import 'package:flutter/material.dart';

/// Displays the real Kasoy logo image (the black square version with the
/// spray gun, car outline, "KASOY" and "PAINTING SHOP" text baked in).
class KasoyLogo extends StatelessWidget {
  const KasoyLogo({super.key, this.size = 120, this.showText = true});

  final double size;
  // Kept for backwards compatibility with existing call sites; the real
  // logo image already includes the text, so this no longer changes output.
  final bool showText;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/images/main_logo.jpg',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

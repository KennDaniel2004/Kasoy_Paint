/// Formats a numeric amount as Philippine Peso, e.g. 24000.0 -> "₱24,000".
///
/// Uses the Philippine peso sign (U+20B1) directly so no intl package
/// dependency is required.
String formatPhp(num amount) {
  final rounded = amount.round();
  final digits = rounded.toString();
  final buffer = StringBuffer();

  for (int i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }

  return '₱$buffer';
}
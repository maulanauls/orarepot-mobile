String formatIdr(int value, {bool withSign = false}) {
  final negative = value < 0;
  final abs = value.abs();
  final digits = abs.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  final body = 'IDR $buffer';
  if (withSign) return negative ? '-$body' : (value > 0 ? '+$body' : body);
  return negative ? '-$body' : body;
}

String formatIdrPlain(int value) => formatIdr(value.abs());

/// Normalize phone like orappob checkout target builder.
String normalizePhoneTarget(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  if (digits.startsWith('62')) return '0${digits.substring(2)}';
  if (digits.startsWith('0')) return digits;
  return '0$digits';
}

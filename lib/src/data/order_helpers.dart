import 'models/biller_models.dart';

String paymentMethodLabel(String? method) {
  return switch (method) {
    'MENUKU_KOIN' => 'Koin',
    'MENUKU_KOIN+MIDTRANS' => 'Koin + QRIS',
    'QRIS' || 'MIDTRANS' => 'QRIS',
    _ => (method == null || method.isEmpty) ? '-' : method,
  };
}

String orderTargetLabel(BillerOrder order) {
  final module = (order.moduleName ?? '').toUpperCase();
  if (module.contains('GAME')) return 'User ID';
  if (module.contains('PLN')) return 'ID pelanggan';
  return 'Nomor';
}

/// Convert any parsed instant to fixed GMT+7 (WIB), independent of device TZ.
DateTime toWib(DateTime parsed) {
  return parsed.toUtc().add(const Duration(hours: 7));
}

String formatOrderTimeWib(String? iso) {
  if (iso == null || iso.trim().isEmpty) return '-';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  final wib = toWib(parsed);
  final d = wib.day.toString().padLeft(2, '0');
  final m = wib.month.toString().padLeft(2, '0');
  final y = wib.year;
  final hh = wib.hour.toString().padLeft(2, '0');
  final mm = wib.minute.toString().padLeft(2, '0');
  return '$d/$m/$y $hh:$mm WIB';
}

String? countdownText(String? expiresAtIso, DateTime now) {
  if (expiresAtIso == null || expiresAtIso.isEmpty) return null;
  final expires = DateTime.tryParse(expiresAtIso);
  if (expires == null) return null;
  final left = expires.difference(now);
  if (left.isNegative) return '00:00';
  final minutes = left.inMinutes;
  final seconds = left.inSeconds.remainder(60);
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

/// Prefer EMV `qr_string` for local QR; fall back to gateway image URL.
String? qrPayload(BillerOrder order) {
  final payload = order.qrString?.trim();
  if (payload != null && payload.isNotEmpty) return payload;
  return null;
}

String? qrFallbackUrl(BillerOrder order) {
  final url = order.qrUrl?.trim();
  if (url != null && url.isNotEmpty) return url;
  return null;
}

String payChoiceLabel(PayOption choice) {
  if (choice.method == 'MENUKU_KOIN' && choice.qris > 0) return 'Koin + QRIS';
  return choice.title;
}

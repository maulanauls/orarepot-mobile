import 'package:flutter_test/flutter_test.dart';
import 'package:orarepot/src/data/models/biller_models.dart';
import 'package:orarepot/src/data/order_helpers.dart';

void main() {
  test('paymentMethodLabel maps known methods', () {
    expect(paymentMethodLabel('QRIS'), 'QRIS');
    expect(paymentMethodLabel('MENUKU_KOIN'), 'Koin');
    expect(paymentMethodLabel('MENUKU_KOIN+MIDTRANS'), 'Koin + QRIS');
  });

  test('countdownText formats remaining time', () {
    final now = DateTime.utc(2026, 1, 1, 12, 0, 0);
    final expires = DateTime.utc(2026, 1, 1, 12, 5, 7).toIso8601String();
    expect(countdownText(expires, now), '05:07');
  });

  test('formatOrderTimeWib uses fixed GMT+7', () {
    expect(formatOrderTimeWib('2026-01-01T00:00:00Z'), '01/01/2026 07:00 WIB');
    expect(formatOrderTimeWib('2026-11-17T06:34:00Z'), '17/11/2026 13:34 WIB');
  });

  test('toWib shifts UTC by +7 hours', () {
    final wib = toWib(DateTime.utc(2026, 11, 17, 6, 34));
    expect(wib.hour, 13);
    expect(wib.day, 17);
  });

  test('qrPayload prefers qr_string', () {
    const order = BillerOrder(
      billingCode: 'ABC',
      stage: OrderStage.waiting,
      status: 'WAITING',
      total: 1000,
      createdAt: '2026-01-01T00:00:00Z',
      walletBalance: 0,
      qrString: '00020101',
      qrUrl: 'https://example.com/qr.png',
    );
    expect(qrPayload(order), '00020101');
    expect(qrFallbackUrl(order), 'https://example.com/qr.png');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:orarepot/src/common_widgets/provider_logo.dart';

void main() {
  test('resolveProviderLogoUrl prefers API logo_url', () {
    expect(
      resolveProviderLogoUrl('Telkomsel', 'https://example.com/tsel.png'),
      'https://example.com/tsel.png',
    );
  });

  test('resolveProviderLogoUrl falls back to idn-finlogos CDN like web/be', () {
    expect(
      resolveProviderLogoUrl('Telkomsel'),
      'https://cdn.jsdelivr.net/npm/idn-finlogos@2.5.0/dist/icons/telkomsel.svg',
    );
    expect(
      resolveProviderLogoUrl('by.U'),
      'https://cdn.jsdelivr.net/npm/idn-finlogos@2.5.0/dist/icons/by-u.svg',
    );
    expect(
      resolveProviderLogoUrl('IM3'),
      'https://cdn.jsdelivr.net/npm/idn-finlogos@2.5.0/dist/icons/im3.svg',
    );
    expect(resolveProviderLogoUrl('Unknown Brand'), isNull);
  });
}

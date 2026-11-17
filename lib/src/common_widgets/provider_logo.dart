import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/ora_palette.dart';

const _logoCdn = 'https://cdn.jsdelivr.net/npm/idn-finlogos@2.5.0/dist/icons';

/// Same slug map as orarepot-be `logo_url()` — used when API omits `logo_url`.
String? providerLogoSlug(String brand) {
  final key = brand.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
  return switch (key) {
    'TELKOMSEL' || 'TSEL' || 'SIMPATI' => 'telkomsel',
    'XL' || 'XLAXIATA' => 'xl',
    'AXIS' => 'axis',
    'TRI' || 'THREE' => 'tri',
    'INDOSAT' || 'IM3' || 'MENTARI' => 'im3',
    'SMARTFREN' => 'smartfren',
    'BYU' => 'by-u',
    'DANA' => 'dana',
    'GOPAY' => 'gopay',
    'OVO' => 'ovo',
    'LINKAJA' => 'linkaja',
    'PLN' || 'PLNTOKEN' || 'TOKENPLN' => 'pln',
    _ => null,
  };
}

String? resolveProviderLogoUrl(String brand, [String? logoUrl]) {
  final fromApi = logoUrl?.trim();
  if (fromApi != null && fromApi.isNotEmpty) return fromApi;
  final slug = providerLogoSlug(brand);
  if (slug == null) return null;
  return '$_logoCdn/$slug.svg';
}

bool _isSvg(String src) {
  final path = src.split('?').first.toLowerCase();
  return path.endsWith('.svg') || src.contains('/icons/');
}

/// Provider mark matching orappob `ProviderLogo` (white tile + logo, or 2-letter fallback).
class ProviderLogo extends StatelessWidget {
  const ProviderLogo({
    super.key,
    required this.name,
    this.src,
    this.cover = false,
  });

  final String name;
  final String? src;
  final bool cover;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    final url = resolveProviderLogoUrl(name, src);
    final width = cover ? 92.0 : 34.0;
    final height = cover ? 92.0 : 28.0;

    if (url == null) {
      return _ProviderMark(name: name, width: width, height: height, ora: ora);
    }

    if (_isSvg(url)) {
      return Container(
        width: width,
        height: height,
        padding: cover ? EdgeInsets.zero : const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: cover ? ora.panel : Colors.white,
          borderRadius: BorderRadius.circular(cover ? 8 : 3),
        ),
        child: SvgPicture.network(
          url,
          fit: cover ? BoxFit.cover : BoxFit.contain,
          placeholderBuilder: (_) => const SizedBox.expand(),
          errorBuilder: (context, error, stackTrace) => _ProviderMark(
            name: name,
            width: width,
            height: height,
            ora: ora,
            bare: true,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(cover ? 8 : 3),
      child: Container(
        width: width,
        height: height,
        color: cover ? ora.panel : Colors.white,
        padding: cover ? EdgeInsets.zero : const EdgeInsets.all(2),
        child: Image.network(
          url,
          fit: cover ? BoxFit.cover : BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _ProviderMark(
            name: name,
            width: width,
            height: height,
            ora: ora,
            bare: true,
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(width: width, height: height);
          },
        ),
      ),
    );
  }
}

class _ProviderMark extends StatelessWidget {
  const _ProviderMark({
    required this.name,
    required this.width,
    required this.height,
    required this.ora,
    this.bare = false,
  });

  final String name;
  final double width;
  final double height;
  final OraPalette ora;
  final bool bare;

  @override
  Widget build(BuildContext context) {
    final mark = name.trim().isEmpty
        ? '?'
        : name.trim().substring(0, name.trim().length >= 2 ? 2 : 1).toUpperCase();
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      color: bare ? Colors.transparent : ora.field,
      child: Text(
        mark,
        style: TextStyle(
          color: ora.text,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

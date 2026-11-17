import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/ora_palette.dart';

enum CategoryIconName { semua, pulsa, data, pln, game, digital }

CategoryIconName iconForKind(String kind) {
  final key = kind.trim().toLowerCase();
  return switch (key) {
    'pulsa' => CategoryIconName.pulsa,
    'data' => CategoryIconName.data,
    'pln' => CategoryIconName.pln,
    'game' => CategoryIconName.game,
    'emoney' || 'digital' || 'e-money' => CategoryIconName.digital,
    _ => CategoryIconName.digital,
  };
}

/// Lime-bordered category mark — same idea as orappob `CategoryIcon`.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.name, this.size = 29});

  final CategoryIconName name;
  final double size;

  String? get _asset => switch (name) {
        CategoryIconName.pulsa => 'assets/icons/pulsa-orp.svg',
        CategoryIconName.data => 'assets/icons/paket-data-orp.svg',
        CategoryIconName.pln => 'assets/icons/pln-orp.svg',
        CategoryIconName.game => 'assets/icons/game-orp.svg',
        CategoryIconName.digital => 'assets/icons/digital-orp.svg',
        CategoryIconName.semua => null,
      };

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Color.lerp(ora.lime, ora.line, 0.45)!),
      ),
      child: name == CategoryIconName.semua
          ? Icon(Icons.add, size: size * 0.55, color: ora.lime)
          : SvgPicture.asset(
              _asset!,
              width: size * 0.55,
              height: size * 0.55,
              colorFilter: ColorFilter.mode(ora.lime, BlendMode.srcIn),
            ),
    );
  }
}

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

String categoryIllustrationAsset(CategoryIconName name) {
  return switch (name) {
    CategoryIconName.pulsa => 'assets/illustrations/categories/pulsa.jpg',
    CategoryIconName.data => 'assets/illustrations/categories/data.jpg',
    CategoryIconName.pln => 'assets/illustrations/categories/pln.jpg',
    CategoryIconName.game => 'assets/illustrations/categories/game.jpg',
    CategoryIconName.digital => 'assets/illustrations/categories/digital.jpg',
    CategoryIconName.semua => 'assets/illustrations/categories/semua.jpg',
  };
}

/// Soft wash behind each category illustration card.
Color categoryWash(CategoryIconName name, OraPalette ora) {
  return switch (name) {
    CategoryIconName.pulsa => Color.lerp(ora.lime, ora.panel, 0.92)!,
    CategoryIconName.data => Color.lerp(ora.lime, ora.panel, 0.93)!,
    CategoryIconName.pln => Color.lerp(ora.warning, ora.panel, 0.93)!,
    CategoryIconName.game => Color.lerp(const Color(0xFF7C5CFF), ora.panel, 0.93)!,
    CategoryIconName.digital => Color.lerp(ora.success, ora.panel, 0.93)!,
    CategoryIconName.semua => Color.lerp(ora.lime, ora.panel, 0.91)!,
  };
}

/// Soft-3D illustration for home category cards.
class CategoryIllustration extends StatelessWidget {
  const CategoryIllustration({super.key, required this.name});

  final CategoryIconName name;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        categoryIllustrationAsset(name),
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => ColoredBox(
          color: categoryWash(name, context.ora),
          child: Icon(Icons.image_outlined, color: context.ora.muted, size: 36),
        ),
      ),
    );
  }
}

/// Compact lime-bordered mark — used outside the home grid.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.name, this.size = 52});

  final CategoryIconName name;
  final double size;

  String? get _outlineAsset => switch (name) {
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
          ? Icon(Icons.add, size: size * 0.58, color: ora.lime)
          : SvgPicture.asset(
              _outlineAsset!,
              width: size * 0.58,
              height: size * 0.58,
              colorFilter: ColorFilter.mode(ora.lime, BlendMode.srcIn),
            ),
    );
  }
}

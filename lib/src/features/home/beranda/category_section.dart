import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common_widgets/category_icon.dart';
import '../../../common_widgets/skeleton.dart';
import '../../../data/models/biller_models.dart';
import '../../../theme/ora_palette.dart';

class HomeCategoryChip {
  const HomeCategoryChip({
    required this.keyName,
    required this.kind,
    required this.hint,
    required this.label,
    required this.icon,
  });

  final String keyName;
  final String kind;
  final String hint;
  final String label;
  final CategoryIconName icon;
}

String categoryChipHint(int brandCount) {
  if (brandCount <= 0) return 'SIAP KIRIM';
  return '$brandCount PROVIDER';
}

/// Home chips from `/biller/catalog` rows — labels/kinds come from the API.
List<HomeCategoryChip> buildHomeChips(List<CatalogCategory> categories) {
  final totalBrands = categories.fold<int>(0, (sum, item) => sum + item.brands.length);
  final chips = <HomeCategoryChip>[
    HomeCategoryChip(
      keyName: 'semua',
      kind: 'semua',
      hint: totalBrands > 0 ? '$totalBrands+ ITEMS' : 'SEMUA PRODUK',
      label: 'Semua produk',
      icon: CategoryIconName.semua,
    ),
  ];
  for (final category in categories) {
    // Skip empty catalog rows — no providers means no card in Kategori pilihan.
    if (category.brands.isEmpty) continue;
    final label = category.label.trim().isNotEmpty
        ? category.label.trim()
        : category.kind.trim();
    if (label.isEmpty) continue;
    chips.add(
      HomeCategoryChip(
        keyName: category.id.isNotEmpty ? category.id : category.kind,
        kind: category.kind,
        hint: categoryChipHint(category.brands.length),
        label: label,
        icon: iconForKind(category.kind),
      ),
    );
  }
  return chips;
}

/// Web-style inventory module: eyebrow + "Kategori pilihan." + category chips.
class CategorySection extends StatelessWidget {
  const CategorySection({
    super.key,
    required this.chips,
    required this.loading,
    this.error,
    required this.onTap,
  });

  final List<HomeCategoryChip> chips;
  final bool loading;
  final String? error;
  final ValueChanged<HomeCategoryChip> onTap;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 17, height: 1, color: ora.lime),
            const SizedBox(width: 9),
            Text(
              'INVENTORY MODULE',
              style: GoogleFonts.poppins(
                color: ora.muted2,
                fontSize: 9,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 34,
              height: 1.05,
              fontWeight: FontWeight.w600,
              letterSpacing: -1.2,
              color: ora.text,
            ),
            children: [
              const TextSpan(text: 'Kategori '),
              TextSpan(text: 'pilihan.', style: TextStyle(color: ora.lime)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Akses instan ribuan inventaris digital siap kirim.',
          style: GoogleFonts.poppins(color: ora.muted, fontSize: 12, height: 1.55),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          ApiAlertText(error!),
        ],
        const SizedBox(height: 18),
        if (loading || error != null)
          GridView.count(
            key: const Key('category-skeleton'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.84,
            children: const [
              _CategorySkeletonCard(),
              _CategorySkeletonCard(),
              _CategorySkeletonCard(),
              _CategorySkeletonCard(),
              _CategorySkeletonCard(),
              _CategorySkeletonCard(),
            ],
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: chips.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.84,
            ),
            itemBuilder: (context, index) {
              final chip = chips[index];
              return _CategoryChipCard(chip: chip, onTap: () => onTap(chip));
            },
          ),
      ],
    );
  }
}

class _CategorySkeletonCard extends StatelessWidget {
  const _CategorySkeletonCard();

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: ora.panel,
        border: Border.all(color: ora.line),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: SkeletonBox(radius: 12)),
          SizedBox(height: 10),
          SkeletonBox(width: 64, height: 8),
          SizedBox(height: 8),
          SkeletonBox(width: 96, height: 12),
        ],
      ),
    );
  }
}

class _CategoryChipCard extends StatelessWidget {
  const _CategoryChipCard({required this.chip, required this.onTap});

  final HomeCategoryChip chip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Material(
      color: ora.panel,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          decoration: BoxDecoration(
            border: Border.all(color: ora.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CategoryIllustration(name: chip.icon),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ora.panel.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '↗',
                          style: TextStyle(
                            color: ora.lime,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                chip.hint,
                style: GoogleFonts.poppins(
                  color: ora.muted2,
                  fontSize: 8,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                chip.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: ora.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Web workflow strip under categories.
class WorkflowSection extends StatelessWidget {
  const WorkflowSection({super.key, this.onTryTap});

  final VoidCallback? onTryTap;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    final steps = const [
      ('01', 'Pilih layanan', 'Pulsa, data, token, atau voucher digital.'),
      ('02', 'Isi ID pelanggan', 'Validasi ringan sebelum order dikirim.'),
      ('03', 'Checkout instan', 'Siap diintegrasikan dengan payment gateway.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: ora.line.withValues(alpha: 0.7)),
        const SizedBox(height: 28),
        Row(
          children: [
            Container(width: 17, height: 1, color: ora.lime),
            const SizedBox(width: 9),
            Text(
              'BUILT FOR SPEED',
              style: GoogleFonts.poppins(
                color: ora.muted2,
                fontSize: 9,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 30,
              height: 1.08,
              fontWeight: FontWeight.w600,
              letterSpacing: -1.1,
              color: ora.text,
            ),
            children: [
              const TextSpan(text: 'Satu dashboard.\n'),
              TextSpan(text: 'Lebih sedikit repot.', style: TextStyle(color: ora.lime)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Mulai dari top-up pertama sampai transaksi berulang, semua alur dibuat singkat dan transparan.',
          style: GoogleFonts.poppins(color: ora.muted, fontSize: 12, height: 1.6),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTryTap,
          child: Text(
            'Coba transaksi mock  ↗',
            style: GoogleFonts.poppins(
              color: ora.lime,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < steps.length; i++)
          _WorkflowStep(
            index: steps[i].$1,
            title: steps[i].$2,
            detail: steps[i].$3,
            active: i == 1,
          ),
      ],
    );
  }
}

class _WorkflowStep extends StatelessWidget {
  const _WorkflowStep({
    required this.index,
    required this.title,
    required this.detail,
    required this.active,
  });

  final String index;
  final String title;
  final String detail;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: active ? Color.lerp(ora.lime, ora.panel, 0.92) : Colors.transparent,
        border: Border(
          left: BorderSide(color: active ? ora.lime : ora.line, width: active ? 2 : 1),
          bottom: BorderSide(color: ora.line),
        ),
      ),
      child: Opacity(
        opacity: active ? 1 : 0.5,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              index,
              style: GoogleFonts.poppins(
                color: ora.lime,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: ora.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: GoogleFonts.poppins(color: ora.muted, fontSize: 11, height: 1.45),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

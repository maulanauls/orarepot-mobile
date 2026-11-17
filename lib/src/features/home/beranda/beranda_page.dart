import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app_config.dart';
import '../../../common_widgets/ora_logo.dart';
import '../../../common_widgets/theme_toggle.dart';
import '../../../data/api_client.dart';
import '../../../data/app_scope.dart';
import '../../../data/models/biller_models.dart';
import '../../../theme/ora_palette.dart';
import '../../pulse/pulse_page.dart';
import 'category_section.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key, required this.config});

  final AppConfig config;

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  final _scrollController = ScrollController();
  final _categoriesKey = GlobalKey();

  List<HomeCategoryChip> chips = const [];
  bool loadingCatalog = true;
  String? catalogError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCatalog());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      loadingCatalog = true;
      catalogError = null;
    });
    try {
      final rows = await AppScope.read(context).catalog.fetchCatalog();
      if (!mounted) return;
      setState(() {
        chips = buildHomeChips(rows);
        loadingCatalog = false;
        catalogError = null;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() {
        chips = buildHomeChips(const <CatalogCategory>[]);
        loadingCatalog = false;
        catalogError = 'Kategori belum bisa dimuat.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        chips = buildHomeChips(const <CatalogCategory>[]);
        loadingCatalog = false;
        catalogError = 'Kategori belum bisa dimuat.';
      });
    }
  }

  void _openOrder({String kind = 'pulsa'}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PulsePage(initialKind: kind)),
    );
  }

  void _scrollToCategories() {
    final ctx = _categoriesKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _openChip(HomeCategoryChip chip) {
    final kind = chip.kind.trim().toLowerCase();
    if (kind == 'semua') {
      _openOrder();
      return;
    }
    if (kind == 'pulsa' || kind == 'data' || kind == 'pln' || kind == 'game') {
      _openOrder(kind: kind);
      return;
    }
    if (kind == 'emoney' || kind == 'digital' || kind == 'e-money') {
      _openOrder(kind: 'pulsa');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${chip.label} segera hadir.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    final theme = AppScope.of(context).theme;

    return ColoredBox(
      color: ora.bg,
      child: SafeArea(
        child: RefreshIndicator(
          color: ora.lime,
          onRefresh: _loadCatalog,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _BrandBar(
                      envCode: widget.config.environmentCode,
                      themeToggle: ThemeToggle(controller: theme),
                    ),
                    const SizedBox(height: 12),
                    const _SystemBar(),
                    const SizedBox(height: 28),
                    _HeroSection(
                      onBuy: () => _openOrder(),
                      onBrowse: _scrollToCategories,
                    ),
                    const SizedBox(height: 36),
                    KeyedSubtree(
                      key: _categoriesKey,
                      child: CategorySection(
                        chips: chips,
                        loading: loadingCatalog,
                        error: catalogError,
                        onTap: _openChip,
                      ),
                    ),
                    const SizedBox(height: 8),
                    WorkflowSection(onTryTap: () => _openOrder()),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandBar extends StatelessWidget {
  const _BrandBar({required this.envCode, required this.themeToggle});

  final String envCode;
  final Widget themeToggle;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Row(
      children: [
        const OraLogo(height: 34),
        const Spacer(),
        themeToggle,
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: ora.line),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            envCode,
            style: GoogleFonts.poppins(
              color: ora.lime,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _SystemBar extends StatelessWidget {
  const _SystemBar();

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: ora.line.withValues(alpha: 0.7)),
          bottom: BorderSide(color: ora.line.withValues(alpha: 0.7)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: ora.lime,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: ora.lime.withValues(alpha: 0.55), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'SEMUA SISTEM NORMAL',
              style: GoogleFonts.poppins(
                color: ora.lime,
                fontSize: 9,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            'API 0.8s',
            style: GoogleFonts.poppins(color: ora.muted2, fontSize: 9, letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }
}

/// Web home hero: eyebrow + headline + CTAs + quick stats.
class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.onBuy, required this.onBrowse});

  final VoidCallback onBuy;
  final VoidCallback onBrowse;

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
              'TOKO PULSA ORA REPOT',
              style: GoogleFonts.poppins(
                color: ora.muted2,
                fontSize: 9,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 36,
              height: 1.02,
              fontWeight: FontWeight.w600,
              letterSpacing: -1.4,
              color: ora.text,
            ),
            children: [
              const TextSpan(text: 'Beli pulsa,\nkuota, dan\n'),
              TextSpan(text: 'voucher game.', style: TextStyle(color: ora.lime)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Token listrik juga ada di sini. Isi nomor, pilih nominal, lalu bayar. Masuk sendiri, tanpa antre.',
          style: GoogleFonts.poppins(color: ora.muted, fontSize: 13, height: 1.55),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: onBuy,
                style: FilledButton.styleFrom(
                  backgroundColor: ora.lime,
                  foregroundColor: ora.onLime,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(),
                ),
                child: Text(
                  'Beli sekarang  ↗',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: onBrowse,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ora.text,
                  side: BorderSide(color: ora.line),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(),
                ),
                child: Text(
                  '▶  Lihat produk',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

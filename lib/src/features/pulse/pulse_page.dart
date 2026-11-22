import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common_widgets/primary_button.dart';
import '../../common_widgets/provider_logo.dart';
import '../../common_widgets/skeleton.dart';
import '../../constants/money.dart';
import '../../data/api_client.dart';
import '../../data/app_scope.dart';
import '../../data/models/biller_models.dart';
import '../../theme/ora_palette.dart';
import '../auth/sign_in_sheet.dart';
import '../order/order_page.dart';

/// Instant-order flow styled like orappob Terminal Instant Order.
class PulsePage extends StatefulWidget {
  const PulsePage({super.key, this.initialKind = 'pulsa'});

  final String initialKind;

  @override
  State<PulsePage> createState() => _PulsePageState();
}

class _PulsePageState extends State<PulsePage> {
  final phoneController = TextEditingController();

  List<CatalogCategory> categories = const [];
  CatalogCategory? category;
  String brand = '';
  List<CatalogProduct> products = const [];
  String? selectedLookupIdf;

  bool catalogLoading = true;
  bool productsLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCatalog());
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      catalogLoading = true;
      error = null;
    });
    try {
      final rows = (await AppScope.read(context).catalog.fetchCatalog())
          .where((c) => c.brands.isNotEmpty)
          .toList();
      final preferredKind = widget.initialKind.trim().toLowerCase();
      final preferred = preferredKind.isEmpty
          ? const <CatalogCategory>[]
          : rows.where((c) => c.kind == preferredKind).toList();
      // Prefer requested kind from API; otherwise first row that has providers.
      final picked = preferred.isNotEmpty
          ? preferred.first
          : rows.isNotEmpty
              ? rows.first
              : const CatalogCategory(id: '', key: '', label: '', kind: '');
      if (!mounted) return;
      setState(() {
        categories = rows;
        category = picked.id.isEmpty ? null : picked;
        brand = picked.brands.isNotEmpty ? picked.brands.first.name : '';
        catalogLoading = false;
      });
      if (picked.id.isNotEmpty && brand.isNotEmpty) await _loadProducts();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        catalogLoading = false;
        error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        catalogLoading = false;
        error = 'Katalog belum bisa dimuat.';
      });
    }
  }

  Future<void> _loadProducts() async {
    final cat = category;
    if (cat == null || brand.isEmpty) {
      setState(() {
        products = const [];
        selectedLookupIdf = null;
      });
      return;
    }
    setState(() {
      productsLoading = true;
      error = null;
    });
    try {
      final rows = await AppScope.read(context).catalog.fetchProducts(
            moduleId: cat.id,
            brand: brand,
          );
      if (!mounted) return;
      setState(() {
        products = rows;
        selectedLookupIdf = rows.isNotEmpty ? rows.first.lookupIdf : null;
        productsLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        products = const [];
        selectedLookupIdf = null;
        productsLoading = false;
        error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        products = const [];
        selectedLookupIdf = null;
        productsLoading = false;
        error = 'Nominal belum bisa dimuat.';
      });
    }
  }

  void _chooseCategory(CatalogCategory next) {
    setState(() {
      category = next;
      brand = next.brands.isNotEmpty ? next.brands.first.name : '';
      products = const [];
      selectedLookupIdf = null;
    });
    if (brand.isNotEmpty) _loadProducts();
  }

  CatalogProduct? get selected {
    for (final product in products) {
      if (product.lookupIdf == selectedLookupIdf) return product;
    }
    return null;
  }

  Future<void> _continue() async {
    final product = selected;
    final target = normalizePhoneTarget(phoneController.text);
    if (target.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nomor pelanggan minimal 9 digit.')),
      );
      return;
    }
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih nominal terlebih dahulu.')),
      );
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: context.ora.panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ReviewSheet(
        categoryLabel: category?.label ?? 'Pulsa',
        brand: brand,
        phone: target,
        product: product,
      ),
    );
    if (confirmed != true || !mounted) return;
    await _createOrder(product.lookupIdf, target);
  }

  Future<void> _createOrder(String lookupIdf, String target) async {
    final services = AppScope.read(context);
    if (!services.authStore.isSignedIn) {
      final ok = await showSignInSheet(context);
      if (!ok || !mounted) return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final order = await services.orders.createOrder(lookupIdf: lookupIdf, target: target);
      if (!mounted) return;
      Navigator.pop(context); // loading dialog
      await openOrderPage(
        context,
        billingCode: order.billingCode,
        initialOrder: order,
      );
    } on AuthRequiredException {
      if (!mounted) return;
      Navigator.pop(context);
      final ok = await showSignInSheet(context);
      if (ok && mounted) await _createOrder(lookupIdf, target);
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuat pesanan.')),
      );
    }
  }

  String _money(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return 'Rp $buffer';
  }

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    final product = selected;
    final tabs = categories.isEmpty && category != null ? [category!] : categories;
    final catalogHold = catalogLoading || (categories.isEmpty && error != null);
    final productsHold = catalogHold || productsLoading || (error != null && products.isEmpty);

    return Scaffold(
      backgroundColor: ora.bg,
      appBar: AppBar(
        backgroundColor: ora.bg,
        title: Text(
          'TERMINAL INSTANT ORDER',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.6),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            onPressed: catalogLoading ? null : _loadCatalog,
            icon: Icon(Icons.refresh_rounded, color: ora.lime),
          ),
        ],
      ),
      body: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        decoration: BoxDecoration(
                          color: ora.panel,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ora.line),
                          boxShadow: const [
                            BoxShadow(color: Color(0x44000000), blurRadius: 24, offset: Offset(0, 12)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (error != null) ...[
                              ApiAlertText(error!),
                              const SizedBox(height: 12),
                            ],
                            if (catalogHold) ...[
                              const _PulseTabSkeleton(),
                              const SizedBox(height: 18),
                              const _PulseProviderSkeleton(),
                            ] else
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final tab in tabs)
                                    _ServiceTab(
                                      label: tab.label.toUpperCase(),
                                      selected: category?.id == tab.id,
                                      onTap: () => _chooseCategory(tab),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (!catalogHold && category != null) ...[
                              Text(
                                'PILIH PROVIDER',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.7,
                                  color: ora.muted2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (category!.brands.isEmpty)
                                Text(
                                  'Provider untuk kategori ini belum tersedia.',
                                  style: GoogleFonts.poppins(color: ora.muted, fontSize: 12),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final item in category!.brands)
                                      _ProviderChip(
                                        label: item.name,
                                        logoUrl: item.logoUrl,
                                        selected: item.name == brand,
                                        onTap: () {
                                          setState(() => brand = item.name);
                                          _loadProducts();
                                        },
                                      ),
                                  ],
                                ),
                              const SizedBox(height: 18),
                            ],
                            Text(
                              'NOMOR HANDPHONE / ID PELANGGAN',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.7,
                                color: ora.muted2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              cursorColor: ora.lime,
                              style: GoogleFonts.poppins(color: ora.text, fontSize: 14),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: ora.field,
                                hintText: '812 0000 0000',
                                hintStyle: GoogleFonts.poppins(color: ora.muted, fontSize: 14),
                                prefixText: '+62  ',
                                prefixStyle: GoogleFonts.poppins(color: ora.text, fontSize: 14),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Text(
                                  'PILIH NOMINAL',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.7,
                                    color: ora.muted2,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: productsLoading ? null : _loadProducts,
                                  child: Text(
                                    'Update harga ↻',
                                    style: GoogleFonts.poppins(
                                      color: ora.lime,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (productsHold)
                              const _PulseNominalSkeleton()
                            else if (products.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  'Nominal belum tersedia untuk provider ini.',
                                  style: GoogleFonts.poppins(color: ora.muted, fontSize: 12),
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: products.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 1.55,
                                ),
                                itemBuilder: (context, index) {
                                  final option = products[index];
                                  final selectedCard = option.lookupIdf == selectedLookupIdf;
                                  return GestureDetector(
                                    onTap: () => setState(() => selectedLookupIdf = option.lookupIdf),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: selectedCard
                                            ? Color.lerp(ora.lime, ora.field, 0.82)
                                            : ora.field,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: selectedCard ? ora.lime : ora.line,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (option.popular)
                                            Align(
                                              alignment: Alignment.topRight,
                                              child: Text(
                                                'TERPOPULER',
                                                style: GoogleFonts.poppins(
                                                  color: ora.lime,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                            ),
                                          Text(
                                            option.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: ora.text,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _money(option.price),
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: ora.lime,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 18),
                            Divider(color: ora.line, height: 1),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TOTAL TAGIHAN',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: ora.muted2,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      product == null ? '—' : _money(product.price),
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w500,
                                        color: ora.text,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: 150,
                                  child: PrimaryButton(
                                    label: 'SIAP CHECKOUT  ↗',
                                    onPressed: catalogLoading || productsLoading ? null : _continue,
                                    enabled: !catalogLoading && !productsLoading,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Masukkan nomor pelanggan minimal 9 digit untuk lanjut checkout.',
                              style: GoogleFonts.poppins(color: ora.muted2, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _PulseTabSkeleton extends StatelessWidget {
  const _PulseTabSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SkeletonBox(width: 72, height: 14),
        SizedBox(width: 16),
        SkeletonBox(width: 64, height: 14),
        SizedBox(width: 16),
        SkeletonBox(width: 88, height: 14),
        SizedBox(width: 16),
        SkeletonBox(width: 70, height: 14),
      ],
    );
  }
}

class _PulseProviderSkeleton extends StatelessWidget {
  const _PulseProviderSkeleton();

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(width: 110, height: 10, radius: 2),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 132,
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: ora.field,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: ora.line),
              ),
              child: const SkeletonBox(width: 88, height: 12),
            ),
            const SizedBox(width: 8),
            Container(
              width: 132,
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: ora.field,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: ora.line),
              ),
              child: const SkeletonBox(width: 88, height: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _PulseNominalSkeleton extends StatelessWidget {
  const _PulseNominalSkeleton();

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.55,
      children: List.generate(4, (_) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ora.field,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: ora.line),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SkeletonBox(width: 92, height: 12),
              SizedBox(height: 10),
              SkeletonBox(width: 64, height: 16),
            ],
          ),
        );
      }),
    );
  }
}

class _ServiceTab extends StatelessWidget {
  const _ServiceTab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? ora.lime : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.4,
            color: selected ? ora.lime : ora.muted2,
          ),
        ),
      ),
    );
  }
}

class _ProviderChip extends StatelessWidget {
  const _ProviderChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.logoUrl,
  });

  final String label;
  final String? logoUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Material(
      color: ora.field,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: selected ? ora.lime : ora.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProviderLogo(name: label, src: logoUrl),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.3,
                  color: selected ? ora.lime : ora.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewSheet extends StatelessWidget {
  const _ReviewSheet({
    required this.categoryLabel,
    required this.brand,
    required this.phone,
    required this.product,
  });

  final String categoryLabel;
  final String brand;
  final String phone;
  final CatalogProduct product;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 22, 20, MediaQuery.viewInsetsOf(context).bottom + 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: ora.line, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Periksa pesanan',
            style: GoogleFonts.poppins(fontSize: 21, fontWeight: FontWeight.w700, color: ora.text),
          ),
          const SizedBox(height: 6),
          Text(
            'Pastikan detail berikut sudah benar sebelum lanjut.',
            style: GoogleFonts.poppins(color: ora.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _ReviewRow(label: 'Layanan', value: categoryLabel),
          _ReviewRow(label: 'Provider', value: brand),
          _ReviewRow(label: 'Nomor', value: phone),
          _ReviewRow(label: 'Produk', value: product.name),
          _ReviewRow(label: 'Total', value: formatIdrPlain(product.price)),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Buat pesanan  ↗',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: ora.muted, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: ora.text),
            ),
          ),
        ],
      ),
    );
  }
}

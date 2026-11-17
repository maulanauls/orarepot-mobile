import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common_widgets/primary_button.dart';
import '../../common_widgets/skeleton.dart';
import '../../constants/money.dart';
import '../../data/api_client.dart';
import '../../data/app_scope.dart';
import '../../data/models/biller_models.dart';
import '../../data/order_helpers.dart';
import '../../theme/ora_palette.dart';
import '../auth/sign_in_sheet.dart';
import 'qris_panel.dart';

const _pollInterval = Duration(seconds: 4);

class OrderPage extends StatefulWidget {
  const OrderPage({
    super.key,
    required this.billingCode,
    this.initialOrder,
  });

  final String billingCode;
  final BillerOrder? initialOrder;

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  BillerOrder? order;
  PayOption? choice;
  bool confirming = false;
  bool busy = false;
  bool needsLogin = false;
  String? error;
  Timer? _poll;
  Timer? _tick;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    order = widget.initialOrder;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  void _syncTimers() {
    final stage = order?.stage;
    final shouldPoll = stage == OrderStage.waiting || stage == OrderStage.processing;
    if (shouldPoll) {
      _poll ??= Timer.periodic(_pollInterval, (_) => _load(silent: true));
    } else {
      _poll?.cancel();
      _poll = null;
    }

    final shouldTick = stage == OrderStage.waiting && (order?.expiresAt?.isNotEmpty ?? false);
    if (shouldTick) {
      _tick ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _now = DateTime.now());
      });
    } else {
      _tick?.cancel();
      _tick = null;
    }
  }

  Future<void> _load({bool silent = false}) async {
    final services = AppScope.read(context);
    if (!services.authStore.isSignedIn) {
      setState(() {
        needsLogin = true;
        if (!silent) error = null;
      });
      return;
    }

    try {
      final next = await services.orders.getOrder(widget.billingCode);
      if (!mounted) return;
      setState(() {
        order = next;
        needsLogin = false;
        if (!silent) error = null;
        choice ??= _defaultPayOption(next);
      });
      _syncTimers();
    } on AuthRequiredException {
      if (!mounted) return;
      setState(() => needsLogin = true);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (!silent) setState(() => error = e.message);
    } catch (_) {
      if (!mounted) return;
      if (!silent) setState(() => error = 'Pesanan belum bisa dimuat.');
    }
  }

  PayOption? _defaultPayOption(BillerOrder next) {
    if (next.stage != OrderStage.unpaid) return null;
    final options = next.paymentOptions.where((o) => o.available).toList();
    if (options.isEmpty) return null;
    for (final option in options) {
      if (option.method.toUpperCase() == 'QRIS') return option;
    }
    return options.first;
  }

  Future<void> _ensureLogin() async {
    final ok = await showSignInSheet(context);
    if (ok && mounted) {
      setState(() => needsLogin = false);
      await _load();
    }
  }

  Future<void> _pay() async {
    final selected = choice;
    if (selected == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final next = await AppScope.read(context).orders.payOrder(
            code: widget.billingCode,
            method: selected.method,
          );
      if (!mounted) return;
      setState(() {
        order = next;
        confirming = false;
        choice = null;
        busy = false;
      });
      _syncTimers();
      // Midtrans charge may return qr_url only after present(); refresh once if waiting without QR.
      if (next.stage == OrderStage.waiting &&
          (next.qrString == null || next.qrString!.isEmpty) &&
          (next.qrUrl == null || next.qrUrl!.isEmpty)) {
        await _load(silent: true);
      }
    } on AuthRequiredException {
      if (!mounted) return;
      setState(() {
        busy = false;
        needsLogin = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        error = e.message;
      });
      await _load(silent: true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        busy = false;
        error = 'Pembayaran gagal.';
      });
      await _load(silent: true);
    }
  }

  Future<void> _reorder() async {
    final current = order;
    final lookup = current?.lookupIdf;
    final target = current?.target;
    if (lookup == null || lookup.isEmpty || target == null || target.isEmpty) return;

    setState(() {
      busy = true;
      error = null;
    });
    try {
      final next = await AppScope.read(context).orders.createOrder(
            lookupIdf: lookup,
            target: target,
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => OrderPage(billingCode: next.billingCode, initialOrder: next),
        ),
      );
    } on AuthRequiredException {
      if (!mounted) return;
      setState(() {
        busy = false;
        needsLogin = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        busy = false;
        error = 'Pesanan gagal dibuat.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    final code = widget.billingCode;

    return Scaffold(
      backgroundColor: ora.bg,
      appBar: AppBar(
        backgroundColor: ora.bg,
        foregroundColor: ora.text,
        elevation: 0,
        title: Text(
          'Pembayaran',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      body: needsLogin
          ? _LoginGate(code: code, onSignIn: _ensureLogin)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Text(
                    'NO. PESANAN',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                      color: ora.muted2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          code,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: ora.text,
                          ),
                        ),
                      ),
                      if (order != null) _StageBadge(stage: order!.stage),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (order == null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ora.panel,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ora.line),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 120, height: 12),
                          SizedBox(height: 14),
                          SkeletonBox(width: double.infinity, height: 18),
                          SizedBox(height: 10),
                          SkeletonBox(width: 180, height: 14),
                          SizedBox(height: 18),
                          SkeletonBox(width: double.infinity, height: 48, radius: 8),
                        ],
                      ),
                    ),
                  if (order != null) ...[
                    _SummaryCard(order: order!),
                    const SizedBox(height: 14),
                    _ActionCard(
                      order: order!,
                      choice: choice,
                      confirming: confirming,
                      busy: busy,
                      now: _now,
                      onSelect: (option) => setState(() => choice = option),
                      onContinue: () {
                        if (choice == null) return;
                        setState(() => confirming = true);
                      },
                      onBack: () => setState(() => confirming = false),
                      onPay: _pay,
                      onReorder: _reorder,
                      onHome: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    ApiAlertText(error!),
                  ],
                ],
              ),
            ),
    );
  }
}

class _LoginGate extends StatelessWidget {
  const _LoginGate({required this.code, required this.onSignIn});

  final String code;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Masuk dulu',
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: ora.text),
          ),
          const SizedBox(height: 8),
          Text(
            'Pesanan $code hanya bisa dilihat oleh pemiliknya.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ora.muted),
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Masuk', onPressed: onSignIn),
        ],
      ),
    );
  }
}

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.stage});

  final OrderStage stage;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    final color = switch (stage) {
      OrderStage.success => ora.success,
      OrderStage.failed || OrderStage.expired => ora.danger,
      OrderStage.waiting || OrderStage.processing => ora.warning,
      OrderStage.unpaid => ora.lime,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        orderStageLabel(stage),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.order});

  final BillerOrder order;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    final product = [
      order.brand,
      order.productName,
    ].whereType<String>().where((e) => e.trim().isNotEmpty).join(' · ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ora.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ora.line),
      ),
      child: Column(
        children: [
          _Kv(label: 'Produk', value: product.isEmpty ? '-' : product),
          _Kv(label: orderTargetLabel(order), value: order.target?.isNotEmpty == true ? order.target! : '-'),
          _Kv(label: 'Total', value: formatIdrPlain(order.total)),
          if (order.paymentMethod != null && order.paymentMethod!.isNotEmpty)
            _Kv(label: 'Metode', value: paymentMethodLabel(order.paymentMethod)),
          if (order.koinUsed > 0)
            _Kv(label: 'Dibayar koin', value: '${order.koinUsed.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')} Koin'),
          if (order.qrisAmount != null)
            _Kv(label: 'Dibayar QRIS', value: formatIdrPlain(order.qrisAmount!)),
          _Kv(label: 'Dibuat', value: formatOrderTimeWib(order.createdAt), last: true),
        ],
      ),
    );
  }
}

class _Kv extends StatelessWidget {
  const _Kv({required this.label, required this.value, this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(fontSize: 12, color: ora.muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ora.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.order,
    required this.choice,
    required this.confirming,
    required this.busy,
    required this.now,
    required this.onSelect,
    required this.onContinue,
    required this.onBack,
    required this.onPay,
    required this.onReorder,
    required this.onHome,
  });

  final BillerOrder order;
  final PayOption? choice;
  final bool confirming;
  final bool busy;
  final DateTime now;
  final ValueChanged<PayOption> onSelect;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final VoidCallback onPay;
  final VoidCallback onReorder;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ora.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ora.line),
      ),
      child: switch (order.stage) {
        OrderStage.unpaid => confirming && choice != null
            ? _ConfirmPay(
                order: order,
                choice: choice!,
                busy: busy,
                onBack: onBack,
                onPay: onPay,
              )
            : _PickPay(
                order: order,
                choice: choice,
                onSelect: onSelect,
                onContinue: onContinue,
              ),
        OrderStage.waiting => QrisPanel(order: order, now: now),
        OrderStage.processing => _StatusBlock(
            title: 'Pembayaran berhasil',
            body: 'Pesanan sedang diproses. Biasanya masuk 1–3 menit, paling lama 60 menit.',
            hint: 'Pembayaran No. Pesanan ${order.billingCode} sudah berhasil. Tidak perlu konfirmasi lagi.',
          ),
        OrderStage.success => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusBlock(
                title: 'Transaksi berhasil',
                body: '${order.productName ?? 'Produk'} untuk ${order.target ?? '-'} sudah masuk.',
              ),
              if (order.sn != null && order.sn!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _Kv(label: 'SN', value: order.sn!, last: true),
              ],
              const SizedBox(height: 16),
              _EndActions(busy: busy, onHome: onHome, onReorder: onReorder, canReorder: _canReorder),
            ],
          ),
        OrderStage.failed => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusBlock(
                title: 'Transaksi gagal',
                body: 'Saldo pembayaranmu dikembalikan ke Koin. Silakan coba lagi.',
                hint: order.message,
              ),
              const SizedBox(height: 16),
              _EndActions(busy: busy, onHome: onHome, onReorder: onReorder, canReorder: _canReorder),
            ],
          ),
        OrderStage.expired => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusBlock(
                title: 'Pesanan kedaluwarsa',
                body: order.koinUsed > 0
                    ? 'Koin yang dipakai sudah dikembalikan. Buat pesanan baru dengan produk dan tujuan yang sama.'
                    : 'Buat pesanan baru dengan produk dan tujuan yang sama.',
              ),
              const SizedBox(height: 16),
              _EndActions(busy: busy, onHome: onHome, onReorder: onReorder, canReorder: _canReorder),
            ],
          ),
      },
    );
  }

  bool get _canReorder =>
      (order.lookupIdf?.isNotEmpty ?? false) && (order.target?.isNotEmpty ?? false);
}

class _PickPay extends StatelessWidget {
  const _PickPay({
    required this.order,
    required this.choice,
    required this.onSelect,
    required this.onContinue,
  });

  final BillerOrder order;
  final PayOption? choice;
  final ValueChanged<PayOption> onSelect;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih pembayaran',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: ora.text),
        ),
        const SizedBox(height: 8),
        Text(
          order.walletBalance > 0
              ? 'Kamu punya ${order.walletBalance} Koin. Pakai koin untuk pesanan ini?'
              : 'Pilih metode pembayaran.',
          style: TextStyle(fontSize: 13, color: ora.muted, height: 1.4),
        ),
        const SizedBox(height: 14),
        for (final option in order.paymentOptions) ...[
          _PayOptionTile(
            option: option,
            selected: choice?.method == option.method,
            onTap: option.available ? () => onSelect(option) : null,
          ),
          const SizedBox(height: 10),
        ],
        if (order.paymentOptions.isEmpty)
          Text(
            'Metode pembayaran belum tersedia untuk pesanan ini.',
            style: TextStyle(color: ora.muted, fontSize: 13),
          ),
        const SizedBox(height: 8),
        PrimaryButton(
          label: 'Lanjut',
          enabled: choice != null,
          onPressed: onContinue,
        ),
      ],
    );
  }
}

class _PayOptionTile extends StatelessWidget {
  const _PayOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PayOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    final enabled = onTap != null;
    return Material(
      color: selected ? ora.lime.withValues(alpha: 0.12) : ora.field,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? ora.lime : ora.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option.title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: enabled ? ora.text : ora.muted2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                enabled ? option.label : 'Saldo koin kamu 0',
                style: TextStyle(fontSize: 12, color: ora.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmPay extends StatelessWidget {
  const _ConfirmPay({
    required this.order,
    required this.choice,
    required this.busy,
    required this.onBack,
    required this.onPay,
  });

  final BillerOrder order;
  final PayOption choice;
  final bool busy;
  final VoidCallback onBack;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Konfirmasi pembayaran',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: ora.text),
        ),
        const SizedBox(height: 8),
        Text(
          '${order.productName ?? 'Produk'} untuk ${order.target ?? '-'}. '
          'Total ${formatIdrPlain(order.total)} dengan metode ${payChoiceLabel(choice)}.',
          style: TextStyle(fontSize: 13, color: ora.muted, height: 1.4),
        ),
        const SizedBox(height: 14),
        if (choice.koin > 0) _Kv(label: 'Koin dipakai', value: '${choice.koin} Koin'),
        if (choice.qris > 0) _Kv(label: 'Bayar QRIS', value: formatIdrPlain(choice.qris), last: true),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: busy ? null : onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ora.text,
                  side: BorderSide(color: ora.line),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('Ubah'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: PrimaryButton(
                label: busy ? 'Memproses...' : 'Ya, bayar',
                enabled: !busy,
                onPressed: onPay,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusBlock extends StatelessWidget {
  const _StatusBlock({required this.title, required this.body, this.hint});

  final String title;
  final String body;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: ora.text),
        ),
        if (hint != null && hint!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(hint!, style: TextStyle(fontSize: 13, color: ora.success, height: 1.4)),
        ],
        const SizedBox(height: 8),
        Text(body, style: TextStyle(fontSize: 13, color: ora.muted, height: 1.4)),
      ],
    );
  }
}

class _EndActions extends StatelessWidget {
  const _EndActions({
    required this.busy,
    required this.onHome,
    required this.onReorder,
    required this.canReorder,
  });

  final bool busy;
  final VoidCallback onHome;
  final VoidCallback onReorder;
  final bool canReorder;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Column(
      children: [
        OutlinedButton(
          onPressed: busy ? null : onHome,
          style: OutlinedButton.styleFrom(
            foregroundColor: ora.text,
            side: BorderSide(color: ora.line),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: const Text('Menu utama'),
        ),
        if (canReorder) ...[
          const SizedBox(height: 10),
          PrimaryButton(
            label: busy ? 'Membuat...' : 'Pesan lagi',
            enabled: !busy,
            onPressed: onReorder,
          ),
        ],
      ],
    );
  }
}

/// Opens order payment for a billing code.
Future<void> openOrderPage(
  BuildContext context, {
  required String billingCode,
  BillerOrder? initialOrder,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => OrderPage(billingCode: billingCode, initialOrder: initialOrder),
    ),
  );
}

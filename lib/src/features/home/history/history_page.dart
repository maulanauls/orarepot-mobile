import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../common_widgets/no_data_state.dart';
import '../../../common_widgets/skeleton.dart';
import '../../../constants/money.dart';
import '../../../theme/ora_palette.dart';
import '../../../data/api_client.dart';
import '../../../data/app_scope.dart';
import '../../../data/models/biller_models.dart';
import '../../order/order_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime from = DateTime.now().subtract(const Duration(days: 7));
  DateTime to = DateTime.now();
  List<BillerOrder> orders = const [];
  bool loading = false;
  String? error;
  bool signedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final services = AppScope.read(context);
    setState(() {
      signedIn = services.authStore.isSignedIn;
      loading = signedIn;
      error = null;
    });
    if (!signedIn) {
      setState(() => orders = const []);
      return;
    }
    try {
      final page = await services.orders.listOrders(limit: 50);
      if (!mounted) return;
      setState(() {
        orders = page.orders;
        loading = false;
      });
    } on AuthRequiredException {
      if (!mounted) return;
      setState(() {
        signedIn = false;
        loading = false;
        orders = const [];
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Riwayat belum bisa dimuat.';
      });
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? from : to;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        from = picked;
        if (to.isBefore(from)) to = from;
      } else {
        to = picked;
        if (from.isAfter(to)) from = to;
      }
    });
  }

  DateTime? _parseCreated(String raw) {
    return DateTime.tryParse(raw);
  }

  List<BillerOrder> get filtered {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
    return orders.where((order) {
      final created = _parseCreated(order.createdAt);
      if (created == null) return true;
      return !created.isBefore(start) && !created.isAfter(end);
    }).toList();
  }

  Map<String, List<BillerOrder>> get grouped {
    final formatter = DateFormat('MMMM, d yyyy');
    final map = <String, List<BillerOrder>>{};
    for (final order in filtered) {
      final created = _parseCreated(order.createdAt) ?? DateTime.now();
      final key = formatter.format(created);
      map.putIfAbsent(key, () => []).add(order);
    }
    return map;
  }

  int get successCount =>
      filtered.where((o) => o.stage == OrderStage.success).length;
  int get pendingCount => filtered
      .where((o) => o.stage == OrderStage.unpaid || o.stage == OrderStage.waiting || o.stage == OrderStage.processing)
      .length;
  int get failedCount =>
      filtered.where((o) => o.stage == OrderStage.failed || o.stage == OrderStage.expired).length;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    final dateFmt = DateFormat('MMMM, d yyyy');
    final groups = grouped;
    final holdList = orders.isEmpty && (loading || error != null);

    return ColoredBox(
      color: ora.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'History',
                      style: TextStyle(
                        color: ora.text,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _load,
                    icon: Icon(Icons.refresh_rounded, color: ora.lime),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'From ${dateFmt.format(from)}',
                      onTap: () => _pickDate(isFrom: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateField(
                      label: 'To ${dateFmt.format(to)}',
                      onTap: () => _pickDate(isFrom: false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _SummaryChip(color: ora.success, value: '$successCount sukses')),
                  const SizedBox(width: 8),
                  Expanded(child: _SummaryChip(color: ora.warning, value: '$pendingCount proses')),
                  const SizedBox(width: 8),
                  Expanded(child: _SummaryChip(color: ora.danger, value: '$failedCount gagal')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: ora.bg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: !signedIn || (!holdList && groups.isEmpty)
                    ? const NoDataState()
                    : holdList
                        ? ListView(
                            padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                            children: [
                              if (error != null) ...[
                                ApiAlertText(error!),
                                const SizedBox(height: 14),
                              ],
                              const _HistorySkeleton(),
                            ],
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                              children: [
                                if (error != null) ...[
                                  ApiAlertText(error!),
                                  const SizedBox(height: 14),
                                ],
                                for (final entry in groups.entries) ...[
                                  Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: ora.text,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  for (final order in entry.value) ...[
                                    _HistoryRow(
                                      order: order,
                                      onTap: order.billingCode.isEmpty
                                          ? null
                                          : () => openOrderPage(
                                                context,
                                                billingCode: order.billingCode,
                                                initialOrder: order,
                                              ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  const SizedBox(height: 8),
                                ],
                              ],
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Column(
      children: List.generate(4, (index) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ora.panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ora.line),
          ),
          child: const Row(
            children: [
              SkeletonBox(width: 36, height: 36, radius: 18),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 140, height: 12),
                    SizedBox(height: 8),
                    SkeletonBox(width: 96, height: 10),
                  ],
                ),
              ),
              SizedBox(width: 12),
              SkeletonBox(width: 64, height: 12),
            ],
          ),
        );
      }),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Material(
      color: ora.panel,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ora.text,
                  ),
                ),
              ),
              Icon(Icons.calendar_today_outlined, size: 16, color: ora.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.color, required this.value});

  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: ora.panel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: ora.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.order, this.onTap});

  final BillerOrder order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    final created = DateTime.tryParse(order.createdAt);
    final time = created == null
        ? order.createdAt
        : DateFormat('HH:mm · MMM d yyyy').format(created);
    final ok = order.stage == OrderStage.success;
    final title = order.sn?.isNotEmpty == true
        ? order.sn!
        : (order.billingCode.isNotEmpty ? order.billingCode : order.productName ?? 'Pesanan');

    return Material(
      color: ora.panel,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ora.line),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (ok ? ora.success : ora.warning).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  ok ? Icons.check_rounded : Icons.schedule_rounded,
                  color: ok ? ora.success : ora.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: ora.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${orderStageLabel(order.stage)} · $time',
                      style: TextStyle(fontSize: 11, color: ora.muted),
                    ),
                  ],
                ),
              ),
              Text(
                formatIdr(-order.total.abs(), withSign: true),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: ora.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

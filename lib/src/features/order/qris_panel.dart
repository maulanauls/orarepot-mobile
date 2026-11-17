import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common_widgets/skeleton.dart';
import '../../constants/money.dart';
import '../../data/models/biller_models.dart';
import '../../data/order_helpers.dart';
import '../../theme/ora_palette.dart';

/// Midtrans QRIS panel: local EMV QR, gateway image URL, open/share fallbacks.
class QrisPanel extends StatefulWidget {
  const QrisPanel({
    super.key,
    required this.order,
    required this.now,
  });

  final BillerOrder order;
  final DateTime now;

  @override
  State<QrisPanel> createState() => _QrisPanelState();
}

class _QrisPanelState extends State<QrisPanel> {
  Uint8List? _fetchedBytes;
  bool _fetching = false;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    _maybeFetchGatewayImage();
  }

  @override
  void didUpdateWidget(covariant QrisPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.qrUrl != widget.order.qrUrl ||
        oldWidget.order.qrString != widget.order.qrString) {
      _fetchedBytes = null;
      _fetchError = null;
      _maybeFetchGatewayImage();
    }
  }

  Future<void> _maybeFetchGatewayImage() async {
    final payload = qrPayload(widget.order);
    final url = qrFallbackUrl(widget.order);
    if (payload != null || url == null || _fetching) return;
    setState(() {
      _fetching = true;
      _fetchError = null;
    });
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          response.bodyBytes.isNotEmpty) {
        setState(() {
          _fetchedBytes = response.bodyBytes;
          _fetching = false;
        });
      } else {
        setState(() {
          _fetching = false;
          _fetchError = 'Gambar QR belum bisa dimuat.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _fetching = false;
        _fetchError = 'Gambar QR belum bisa dimuat.';
      });
    }
  }

  Future<void> _openQrUrl() async {
    final url = qrFallbackUrl(widget.order);
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka tautan QR.')),
      );
    }
  }

  Future<void> _copyAmount() async {
    final amount = widget.order.qrisAmount ?? widget.order.total;
    await Clipboard.setData(ClipboardData(text: '$amount'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nominal ${formatIdrPlain(amount)} disalin.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    final order = widget.order;
    final amount = order.qrisAmount ?? order.total;
    final left = countdownText(order.expiresAt, widget.now);
    final payload = qrPayload(order);
    final fallbackUrl = qrFallbackUrl(order);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scan QRIS',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: ora.text),
        ),
        const SizedBox(height: 8),
        Text(
          'Bayar ${formatIdrPlain(amount)} sebelum ${formatOrderTimeWib(order.expiresAt)}'
          '${left != null ? ' (sisa $left)' : ''}.',
          style: TextStyle(fontSize: 13, color: ora.muted, height: 1.4),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ora.line),
            ),
            child: _buildQr(payload, fallbackUrl),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyAmount,
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Salin nominal'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ora.text,
                  side: BorderSide(color: ora.line),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
            if (fallbackUrl != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openQrUrl,
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Buka QR'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ora.text,
                    side: BorderSide(color: ora.line),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Text('1. Buka aplikasi bank, e-wallet, atau lainnya.', style: TextStyle(fontSize: 13, color: ora.text)),
        const SizedBox(height: 6),
        Text('2. Scan atau unggah gambar kode QR.', style: TextStyle(fontSize: 13, color: ora.text)),
        const SizedBox(height: 6),
        Text('3. Periksa kembali total pembayaran.', style: TextStyle(fontSize: 13, color: ora.text)),
        const SizedBox(height: 6),
        Text('4. Selesaikan pembayaran.', style: TextStyle(fontSize: 13, color: ora.text)),
        const SizedBox(height: 12),
        Text(
          'Status QRIS dicek otomatis setiap beberapa detik setelah Midtrans settle.',
          style: TextStyle(fontSize: 12, color: ora.muted2),
        ),
      ],
    );
  }

  Widget _buildQr(String? payload, String? fallbackUrl) {
    if (payload != null) {
      return QrImageView(
        data: payload,
        size: 240,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      );
    }

    if (_fetchedBytes != null) {
      return Image.memory(
        _fetchedBytes!,
        width: 240,
        height: 240,
        fit: BoxFit.contain,
      );
    }

    if (fallbackUrl != null) {
      return Image.network(
        fallbackUrl,
        width: 240,
        height: 240,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const _QrSkeleton();
        },
        errorBuilder: (context, error, stackTrace) {
          return const _QrSkeleton(message: 'Gambar QR belum bisa dimuat.');
        },
      );
    }

    return _QrSkeleton(message: _fetchError);
  }
}

class _QrSkeleton extends StatelessWidget {
  const _QrSkeleton({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SkeletonBox(width: 168, height: 168, radius: 8, onLight: true),
          if (message != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ApiAlertText(message!),
            ),
          ],
        ],
      ),
    );
  }
}

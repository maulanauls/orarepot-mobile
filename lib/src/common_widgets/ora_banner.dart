import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/ora_palette.dart';

enum OraBannerType { success, info, error }

/// Floating alert matching the product toast design (success / info / error).
class OraBanner extends StatelessWidget {
  const OraBanner({
    super.key,
    required this.type,
    required this.title,
    this.message,
    this.onRetry,
    this.onDismiss,
    this.retryLabel = 'Retry',
    this.dismissLabel = 'Dismiss',
  });

  final OraBannerType type;
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final String retryLabel;
  final String dismissLabel;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = _scheme(ora, isDark);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
        decoration: BoxDecoration(
          color: scheme.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: scheme.iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(scheme.icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.title,
                      height: 1.3,
                    ),
                  ),
                  if (message != null && message!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      message!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        height: 1.45,
                        color: scheme.body,
                      ),
                    ),
                  ],
                  if (type == OraBannerType.error &&
                      (onRetry != null || onDismiss != null)) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (onRetry != null)
                          GestureDetector(
                            onTap: onRetry,
                            child: Text(
                              retryLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: scheme.action,
                              ),
                            ),
                          ),
                        if (onRetry != null && onDismiss != null)
                          const SizedBox(width: 18),
                        if (onDismiss != null)
                          GestureDetector(
                            onTap: onDismiss,
                            child: Text(
                              dismissLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: scheme.body,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (onDismiss != null)
              InkWell(
                onTap: onDismiss,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 18, color: scheme.body),
                ),
              ),
          ],
        ),
      ),
    );
  }

  _BannerScheme _scheme(OraPalette ora, bool isDark) {
    return switch (type) {
      OraBannerType.success => _BannerScheme(
          background: isDark ? const Color(0xFF12251C) : const Color(0xFFEAF8F0),
          border: isDark ? const Color(0xFF1F3D2E) : const Color(0xFFCDEBD9),
          iconBg: const Color(0xFF16A34A),
          icon: Icons.check_rounded,
          title: isDark ? ora.text : const Color(0xFF0C1413),
          body: isDark ? ora.muted : const Color(0xFF4E6460),
          action: ora.lime,
        ),
      OraBannerType.info => _BannerScheme(
          background: isDark ? const Color(0xFF152028) : const Color(0xFFEEF3F7),
          border: isDark ? const Color(0xFF243140) : const Color(0xFFD5DEE6),
          iconBg: const Color(0xFF3B82F6),
          icon: Icons.info_rounded,
          title: isDark ? ora.text : const Color(0xFF0C1413),
          body: isDark ? ora.muted : const Color(0xFF4E6460),
          action: const Color(0xFF3B82F6),
        ),
      OraBannerType.error => _BannerScheme(
          background: isDark ? const Color(0xFF2A1616) : const Color(0xFFFDECEC),
          border: isDark ? const Color(0xFF4A2424) : const Color(0xFFF3CACA),
          iconBg: const Color(0xFFDC2626),
          icon: Icons.close_rounded,
          title: isDark ? ora.text : const Color(0xFF0C1413),
          body: isDark ? ora.muted : const Color(0xFF5C4A4A),
          action: const Color(0xFF2563EB),
        ),
    };
  }
}

class _BannerScheme {
  const _BannerScheme({
    required this.background,
    required this.border,
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
  });

  final Color background;
  final Color border;
  final Color iconBg;
  final IconData icon;
  final Color title;
  final Color body;
  final Color action;
}

OverlayEntry? _activeBanner;

/// Shows a floating banner above the current route (works over bottom sheets).
void showOraBanner(
  BuildContext context, {
  required OraBannerType type,
  required String title,
  String? message,
  VoidCallback? onRetry,
  String retryLabel = 'Retry',
  String dismissLabel = 'Dismiss',
  Duration? autoDismiss,
}) {
  hideOraBanner();

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  late final OverlayEntry entry;
  void dismiss() {
    if (_activeBanner == entry) {
      entry.remove();
      _activeBanner = null;
    }
  }

  entry = OverlayEntry(
    builder: (ctx) {
      final top = MediaQuery.paddingOf(ctx).top + 12;
      return Positioned(
        top: top,
        left: 16,
        right: 16,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * -12),
                child: child,
              ),
            );
          },
          child: OraBanner(
            type: type,
            title: title,
            message: message,
            retryLabel: retryLabel,
            dismissLabel: dismissLabel,
            onRetry: onRetry == null
                ? null
                : () {
                    dismiss();
                    onRetry();
                  },
            onDismiss: dismiss,
          ),
        ),
      );
    },
  );

  _activeBanner = entry;
  overlay.insert(entry);

  final timeout = autoDismiss ??
      (type == OraBannerType.error ? null : const Duration(seconds: 3));
  if (timeout != null) {
    Future<void>.delayed(timeout, dismiss);
  }
}

void hideOraBanner() {
  _activeBanner?.remove();
  _activeBanner = null;
}

void showOraError(
  BuildContext context, {
  String title = 'Something went wrong',
  required String message,
  VoidCallback? onRetry,
  String retryLabel = 'Retry',
  String dismissLabel = 'Dismiss',
}) {
  showOraBanner(
    context,
    type: OraBannerType.error,
    title: title,
    message: message,
    onRetry: onRetry,
    retryLabel: retryLabel,
    dismissLabel: dismissLabel,
  );
}

void showOraSuccess(
  BuildContext context, {
  required String title,
  String? message,
}) {
  showOraBanner(
    context,
    type: OraBannerType.success,
    title: title,
    message: message,
  );
}

void showOraInfo(
  BuildContext context, {
  required String title,
  String? message,
}) {
  showOraBanner(
    context,
    type: OraBannerType.info,
    title: title,
    message: message,
  );
}

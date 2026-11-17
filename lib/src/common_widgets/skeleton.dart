import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/ora_palette.dart';

/// Short alert kept beside a skeleton when a request fails.
class ApiAlertText extends StatelessWidget {
  const ApiAlertText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Text(
      message,
      style: GoogleFonts.poppins(color: ora.danger, fontSize: 12, height: 1.45),
    );
  }
}

/// Theme-aware shimmer block. Stays on screen when the request fails.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = 4,
    this.onLight = false,
  });

  final double? width;
  final double? height;
  final double radius;

  /// Use on a surface that stays white, such as a QR pad.
  final bool onLight;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    final base = widget.onLight ? const Color(0xFFE6EEEA) : ora.field;
    final shine = widget.onLight
        ? const Color(0xFFF7FBF8)
        : Color.lerp(ora.field, ora.text, context.isOraDark ? 0.16 : 0.1)!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final travel = -1.4 + (_controller.value * 2.8);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(travel, -0.2),
              end: Alignment(travel + 1.2, 0.2),
              colors: [base, shine, base],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

/// Global floating debug FAB. Must be placed as a direct [Stack] child
/// (returns [Positioned]). Drag snaps to left/right; double-tap hides.
class DraggableDebugButton extends StatefulWidget {
  const DraggableDebugButton({super.key, required this.onInspectorTap});

  final VoidCallback onInspectorTap;

  @override
  State<DraggableDebugButton> createState() => _DraggableDebugButtonState();
}

class _DraggableDebugButtonState extends State<DraggableDebugButton> {
  static const double _size = 48;
  static const double _revealSize = 36;
  static const double _margin = 12;

  Offset _offset = Offset.zero;
  bool _initialized = false;
  bool _hidden = false;

  void _ensureInitialPosition(Size screen, EdgeInsets padding) {
    if (_initialized) return;
    _initialized = true;
    _offset = Offset(
      screen.width - _size - _margin,
      (screen.height * 0.45).clamp(
        padding.top + _margin,
        screen.height - _size - padding.bottom - _margin,
      ),
    );
  }

  void _snapToEdge(Size screen, EdgeInsets padding) {
    final midX = screen.width / 2;
    final x = (_offset.dx + _size / 2) < midX
        ? _margin
        : screen.width - _size - _margin;
    final y = _offset.dy.clamp(
      padding.top + _margin,
      screen.height - _size - padding.bottom - _margin,
    );
    setState(() => _offset = Offset(x, y));
  }

  Widget _circleButton({
    required double size,
    required IconData icon,
    required double iconSize,
    required Color iconColor,
    required VoidCallback onTap,
    VoidCallback? onDoubleTap,
    GestureDragUpdateCallback? onPanUpdate,
    GestureDragEndCallback? onPanEnd,
  }) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: Material(
        color: const Color(0xFF1A1A1A),
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: Colors.black54,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: iconSize, color: iconColor),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    final padding = media.padding;
    _ensureInitialPosition(screen, padding);

    if (_hidden) {
      return Positioned(
        right: _margin,
        bottom: padding.bottom + _margin,
        child: _circleButton(
          size: _revealSize,
          icon: Icons.bug_report,
          iconSize: 18,
          iconColor: Colors.white.withValues(alpha: 0.65),
          onTap: () => setState(() => _hidden = false),
        ),
      );
    }

    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: _circleButton(
        size: _size,
        icon: Icons.bug_report,
        iconSize: 24,
        iconColor: const Color(0xFF4ADE80),
        onTap: widget.onInspectorTap,
        onDoubleTap: () => setState(() => _hidden = true),
        onPanUpdate: (details) {
          setState(() {
            _offset = Offset(
              (_offset.dx + details.delta.dx).clamp(0.0, screen.width - _size),
              (_offset.dy + details.delta.dy).clamp(0.0, screen.height - _size),
            );
          });
        },
        onPanEnd: (_) => _snapToEdge(screen, padding),
      ),
    );
  }
}

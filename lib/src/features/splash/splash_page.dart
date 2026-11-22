import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../../app_config.dart';
import '../../common_widgets/ora_logo.dart';

/// Animated launch screen: Lottie ripple + OraRepot mark, then hands off to [onReady].
class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    required this.config,
    required this.boot,
    required this.onReady,
  });

  final AppConfig config;
  final Future<void> boot;
  final VoidCallback onReady;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  static const _minVisible = Duration(milliseconds: 2200);

  late final AnimationController _lottie = AnimationController(vsync: this);
  late final AnimationController _brand = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _brandFade = CurvedAnimation(
    parent: _brand,
    curve: Curves.easeOutCubic,
  );
  late final Animation<double> _brandRise = Tween<double>(begin: 18, end: 0).animate(
    CurvedAnimation(parent: _brand, curve: Curves.easeOutCubic),
  );

  bool _bootDone = false;
  bool _animDone = false;
  bool _finished = false;
  DateTime? _shownAt;

  @override
  void initState() {
    super.initState();
    _shownAt = DateTime.now();
    _brand.forward();
    widget.boot.then((_) {
      if (!mounted) return;
      _bootDone = true;
      _tryFinish();
    });
    // Safety: if Lottie fails to load/complete, still leave splash.
    Future<void>.delayed(const Duration(seconds: 5), () {
      if (!mounted || _finished) return;
      _animDone = true;
      _tryFinish();
    });
  }

  @override
  void dispose() {
    _lottie.dispose();
    _brand.dispose();
    super.dispose();
  }

  Future<void> _tryFinish() async {
    if (_finished || !_bootDone || !_animDone) return;
    final elapsed = DateTime.now().difference(_shownAt ?? DateTime.now());
    final wait = _minVisible - elapsed;
    if (wait > Duration.zero) {
      await Future<void>.delayed(wait);
    }
    if (!mounted || _finished) return;
    _finished = true;
    widget.onReady();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0C1413);
    final muted = const Color(0xFF9AAB9E);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.15),
                    radius: 1.05,
                    colors: [
                      const Color(0xFF0F6B66).withValues(alpha: 0.22),
                      bg,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _brand,
                builder: (context, child) {
                  return Opacity(
                    opacity: _brandFade.value,
                    child: Transform.translate(
                      offset: Offset(0, _brandRise.value),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Lottie.asset(
                            'assets/lottie/splash.json',
                            controller: _lottie,
                            fit: BoxFit.contain,
                            onLoaded: (composition) {
                              _lottie
                                ..duration = composition.duration
                                ..forward().whenComplete(() {
                                  if (!mounted) return;
                                  _animDone = true;
                                  _tryFinish();
                                });
                            },
                          ),
                          const OraLogo(iconOnly: true, height: 64),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const OraLogo(height: 34),
                    const SizedBox(height: 14),
                    Text(
                      'Digital top-up, tanpa repot.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: muted,
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _EnvChip(code: widget.config.environmentCode),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: FadeTransition(
                opacity: _brandFade,
                child: Text(
                  'ORAREPOT',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: muted.withValues(alpha: 0.55),
                    fontSize: 10,
                    letterSpacing: 2.4,
                    fontWeight: FontWeight.w600,
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

class _EnvChip extends StatelessWidget {
  const _EnvChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final label = code.trim().isEmpty ? 'SIT' : code.trim().toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFC6E800).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFC6E800).withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: const Color(0xFFC6E800),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_config.dart';
import 'src/common_widgets/draggable_debug_button.dart';
import 'src/data/app_scope.dart';
import 'src/features/home/home_shell.dart';
import 'src/features/splash/splash_page.dart';
import 'src/theme/app_theme.dart';

class OraRepotPpobApp extends StatefulWidget {
  const OraRepotPpobApp({
    super.key,
    required this.config,
    this.showSplash = true,
  });

  final AppConfig config;

  /// When false, skip the animated splash (used by widget tests).
  final bool showSplash;

  @override
  State<OraRepotPpobApp> createState() => _OraRepotPpobAppState();
}

class _OraRepotPpobAppState extends State<OraRepotPpobApp> {
  late final AppServices services = AppServices.create(widget.config);
  late final Future<void> boot = Future.wait([
    services.authStore.load(),
    services.theme.load(),
  ]);
  late bool _ready = !widget.showSplash;

  @override
  void initState() {
    super.initState();
    services.theme.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    services.theme.removeListener(_onThemeChanged);
    services.theme.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _onSplashReady() {
    if (!mounted || _ready) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: MaterialApp(
        navigatorKey: services.alice?.navigatorKey,
        debugShowCheckedModeBanner: false,
        title: '${widget.config.appName} ${widget.config.environmentCode}',
        locale: const Locale('id'),
        supportedLocales: const [Locale('id'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: services.theme.mode,
        builder: (context, child) {
          return Stack(
            children: [
              child ?? const SizedBox.shrink(),
              if (services.alice != null)
                DraggableDebugButton(onInspectorTap: services.alice!.show),
            ],
          );
        },
        home: _ready
            ? HomeShell(config: widget.config)
            : SplashPage(
                config: widget.config,
                boot: boot,
                onReady: _onSplashReady,
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'app_config.dart';
import 'src/common_widgets/draggable_debug_button.dart';
import 'src/data/app_scope.dart';
import 'src/features/home/home_shell.dart';
import 'src/theme/app_theme.dart';

class OraRepotPpobApp extends StatefulWidget {
  const OraRepotPpobApp({super.key, required this.config});

  final AppConfig config;

  @override
  State<OraRepotPpobApp> createState() => _OraRepotPpobAppState();
}

class _OraRepotPpobAppState extends State<OraRepotPpobApp> {
  late final AppServices services = AppServices.create(widget.config);
  late final Future<void> boot = Future.wait([
    services.authStore.load(),
    services.theme.load(),
  ]);

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

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: MaterialApp(
        navigatorKey: services.alice?.navigatorKey,
        debugShowCheckedModeBanner: false,
        title: '${widget.config.appName} ${widget.config.environmentCode}',
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
        home: FutureBuilder<void>(
          future: boot,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return HomeShell(config: widget.config);
          },
        ),
      ),
    );
  }
}

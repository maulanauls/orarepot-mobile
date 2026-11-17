import 'package:alice/alice.dart';
import 'package:alice/model/alice_configuration.dart';
import 'package:alice_http/alice_http_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app_config.dart';

/// HTTP inspector (Alice). Enabled for non-prod / debug builds only.
class AliceInspector {
  AliceInspector._(this.alice, this.httpAdapter);

  final Alice alice;
  final AliceHttpAdapter httpAdapter;

  GlobalKey<NavigatorState>? get navigatorKey => alice.getNavigatorKey();

  void show() => alice.showInspector();

  /// Alice notifications need a platform plugin; skip under widget tests.
  static bool get _inFlutterTest {
    final binding = WidgetsBinding.instance.runtimeType.toString();
    return binding.contains('TestWidgetsFlutterBinding') ||
        binding.contains('AutomatedTestWidgetsFlutterBinding');
  }

  /// Returns null in production release builds and under `flutter test`.
  static AliceInspector? create(AppConfig config) {
    final enabled = kDebugMode || !config.isProduction;
    if (!enabled || _inFlutterTest) return null;

    final httpAdapter = AliceHttpAdapter();
    final alice = Alice(
      configuration: AliceConfiguration(
        showNotification: true,
        showInspectorOnShake: true,
        showShareButton: true,
      ),
    )..addAdapter(httpAdapter);

    return AliceInspector._(alice, httpAdapter);
  }
}

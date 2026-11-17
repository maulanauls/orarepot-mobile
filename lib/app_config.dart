import 'package:flutter/foundation.dart';

enum AppEnvironment { sit, uat, prod }

extension AppEnvironmentX on AppEnvironment {
  String get code => name.toUpperCase();
  String get flavor => name;
  String get label => switch (this) {
        AppEnvironment.sit => 'System Integration Testing',
        AppEnvironment.uat => 'User Acceptance Testing',
        AppEnvironment.prod => 'Production',
      };
}

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.appName,
    required this.googleClientId,
  });

  final AppEnvironment environment;
  final String apiBaseUrl;
  final String appName;

  /// Web OAuth client ID (same as orappob `NEXT_PUBLIC_GOOGLE_CLIENT_ID`).
  /// Used as `GoogleSignIn.serverClientId` so backend can exchange `{ code }`.
  final String googleClientId;

  bool get isProduction => environment == AppEnvironment.prod;
  String get environmentCode => environment.code;

  static AppConfig fromBuildEnvironment() {
    const rawEnvironment = String.fromEnvironment('APP_ENV', defaultValue: 'SIT');
    // Use api.orarepot.com — *.orarepot.tikngroup.com serves a cert for
    // topup.orarepot.com and fails TLS hostname verification on device.
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api.orarepot.com',
    );
    const appName = String.fromEnvironment('APP_NAME', defaultValue: 'ora repot');
    // Same web client as orappob/.env.local — override with --dart-define if needed.
    const googleClientId = String.fromEnvironment(
      'GOOGLE_CLIENT_ID',
      defaultValue:
          '569539983389-ue1egs1g4rivgo1csjn9ci734h1qopdc.apps.googleusercontent.com',
    );

    final normalized = rawEnvironment.trim().toLowerCase();
    final environment = switch (normalized) {
      'uat' => AppEnvironment.uat,
      'prod' || 'production' => AppEnvironment.prod,
      _ => AppEnvironment.sit,
    };

    debugPrint('OraRepot ${environment.code} configured for $apiBaseUrl');
    return AppConfig(
      environment: environment,
      apiBaseUrl: apiBaseUrl,
      appName: appName,
      googleClientId: googleClientId,
    );
  }
}

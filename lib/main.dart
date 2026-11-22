import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app_config.dart';
import 'ppob_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id');
  runApp(OraRepotPpobApp(config: AppConfig.fromBuildEnvironment()));
}

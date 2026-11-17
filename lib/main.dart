import 'package:flutter/material.dart';

import 'app_config.dart';
import 'ppob_app.dart';

void main() {
  runApp(OraRepotPpobApp(config: AppConfig.fromBuildEnvironment()));
}

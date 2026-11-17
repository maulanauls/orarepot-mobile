import 'package:flutter/material.dart';

import '../../theme/ora_palette.dart';
import 'auth_page.dart';

/// Opens auth as a modal bottom sheet (sign-in / register).
Future<bool> showSignInSheet(
  BuildContext context, {
  AuthMode initialMode = AuthMode.signIn,
}) async {
  final ora = OraPalette.of(context);
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: ora.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final height = MediaQuery.sizeOf(sheetContext).height;
      return SizedBox(
        height: height * 0.92,
        child: AuthPage(initialMode: initialMode),
      );
    },
  );
  return result == true;
}

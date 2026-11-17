# OraRepot PPOB Flutter architecture

## Intent

Rebuild the design’s wallet UX into `orarepot-mobile` with:

- **Layout / flows** from `replica/screens/design-home-pulse-history.png`
- **Brand / concept** from orappob (ora repot, lime `#C6E800`, PPOB catalog)
- **Folder fundamentals** from Agenin base-product (`features/home`, theme constants, shell) — clean-room, not a port of Agenin screens

## Stack

Flutter Material 3, local seed data first. `AppConfig` from `--dart-define` for SIT/UAT/PROD. `intl` for history date labels.

## Structure

```
lib/
  main.dart
  app_config.dart
  ppob_app.dart
  src/
    constants/colors.dart, catalog.dart
    theme/app_theme.dart
    common_widgets/ora_logo.dart, primary_button.dart
    features/
      home/home_shell.dart
      home/beranda/beranda_page.dart
      home/history/history_page.dart
      home/customer/customer_page.dart
      home/profil/profil_page.dart
      pulse/pulse_page.dart
```

## Build order

1. Theme tokens + shell + S01/S02/S03 with seed data — done
2. Review sheet + stub CTAs — done
3. Catalog/auth/payment repositories — next

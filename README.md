# OraRepot Mobile PPOB

A Flutter mobile conversion of the user-supplied PPOB concept. The app focuses on a fast digital-service purchase flow: choose a service, enter the customer target, select a denomination, review, and continue to payment.

The implementation is clean-room and original. It uses the reference package for product behavior and information architecture only; it does not ship the reference source code, provider logos, SVGs, copy, or private endpoints.

## Included mobile experience

The home screen is a dark, terminal-inspired PPOB dashboard with an original OraRepot mark, environment badge, system status, quick order card, service tabs, denomination selection, and trust indicators. Bottom navigation includes Beranda, Produk, Aktivitas, and Akun. The transaction CTA validates the target and opens an original review sheet; payment is currently a demo handoff until a gateway is connected.

The clean-room recon and implementation evidence are in [`replica/`](replica/), including the screen inventory, feature matrix, architecture notes, and build log.

## Environment builds

Android flavors produce isolated package IDs:

- `com.tikngroup.orarepot.orarepot.sit`
- `com.tikngroup.orarepot.orarepot.uat`
- `com.tikngroup.orarepot.orarepot.prod`

Build with Ansible:

```bash
./scripts/build_env.sh SIT apk
./scripts/build_env.sh UAT apk
./scripts/build_env.sh PROD appbundle
```

The playbook runs dependency installation, analysis, tests, and the selected Flutter build. Artifacts and `build-metadata.txt` are copied to `dist/<environment>/`. See [`ansible/README.md`](ansible/README.md) for the environment matrix and release-signing notes.

For keystore generation, local signing, package/branding injection, and protected CI/CD setup, see [`docs/PROD_SIGNING.md`](docs/PROD_SIGNING.md).

## Local development

```bash
flutter pub get
flutter run --flavor sit \
  --dart-define=APP_ENV=SIT \
  --dart-define=API_BASE_URL=https://api.orarepot.com \
  --dart-define=APP_NAME=ORAREPOT
flutter test
```

Use `https://api.orarepot.com` (valid TLS). Do **not** point the app at `*.orarepot.tikngroup.com` — those hosts serve a certificate for `topup.orarepot.com` and Flutter rejects the HTTPS handshake.

Runtime values are read in `lib/app_config.dart`. API endpoints and payment credentials should be supplied through environment-specific CI/Ansible secrets, not committed to source. The project archive contains the original machine-local Flutter metadata from the upload; regenerate `android/local.properties` on each build machine.

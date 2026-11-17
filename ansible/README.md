# OraRepot environment builds

This project has three Android Flutter flavors:

| Environment | Flutter flavor | Android application ID | API default |
| --- | --- | --- | --- |
| SIT | `sit` | `com.tikngroup.orarepot.orarepot.sit` | `https://api.orarepot.com` |
| UAT | `uat` | `com.tikngroup.orarepot.orarepot.uat` | `https://api.orarepot.com` |
| PROD | `prod` | `com.tikngroup.orarepot.orarepot.prod` | `https://api.orarepot.com` |

The `{ENV}` suffix is normalized to lowercase for Android application IDs and iOS bundle identifiers. The visible environment remains uppercase in the app UI and build metadata.

## Ansible CLI (full)

Run from the **repository root**:

```bash
ansible-playbook \
  -i ansible/inventory.ini \
  ansible/build.yml \
  -e app_env=<SIT|UAT|PROD> \
  [-e build_format=<apk|appbundle>] \
  [-e app_version=<version[+build]>] \
  [-e app_build=<number>] \
  [-e api_base_url=<url>] \
  [-e google_client_id=<web-oauth-client-id>]
```

Put `\` at the end of every continued line (except the last), or zsh will treat the next `-e` as a separate command.

### Parameters (`-e`)

| Extra var | Required | Values / format | Default | Notes |
| --- | --- | --- | --- | --- |
| `app_env` | **Yes** | `SIT`, `UAT`, `PROD` (case-insensitive) | — | Selects Flutter flavor, `APP_ENV` dart-define, API URL map key, and output folder `dist/<env>/`. |
| `build_format` | No | `apk`, `appbundle` | `apk` | `apk` → `.apk`; `appbundle` → Play Store `.aab`. |
| `app_version` | No | `1.2.3` or `1.2.3+42` | *(from `pubspec.yaml`)* | Maps to Flutter `--build-name` (and optionally `--build-number` when `+N` is present). |
| `app_build` | No | integer string, e.g. `42` | *(from `pubspec.yaml` or `app_version` suffix)* | Maps to Flutter `--build-number` (Android `versionCode`). Wins over the `+N` part of `app_version` when both are set. |
| `api_base_url` | No | URL, e.g. `https://api.orarepot.com` | from `api_urls[app_env]` in `build.yml` | Overrides `API_BASE_URL` dart-define. Alias: `app_base_url`. |
| `google_client_id` | No | Web OAuth client ID | orappob `NEXT_PUBLIC_GOOGLE_CLIENT_ID` | Passed as `GOOGLE_CLIENT_ID` dart-define (`GoogleSignIn.serverClientId`). |

### Version resolution

| You pass | Flutter flags |
| --- | --- |
| *(omit both)* | Uses `pubspec.yaml` `version:` (currently `1.0.0+1`) |
| `-e app_version=1.2.3` | `--build-name 1.2.3` |
| `-e app_version=1.2.3+42` | `--build-name 1.2.3 --build-number 42` |
| `-e app_version=1.2.3 -e app_build=42` | `--build-name 1.2.3 --build-number 42` |
| `-e app_version=1.2.3+9 -e app_build=42` | `--build-name 1.2.3 --build-number 42` (`app_build` wins) |

### Environment variables (PROD signing)

Required only when `app_env=PROD`:

| Env var | Required for PROD | Description |
| --- | --- | --- |
| `ORAREPOT_KEYSTORE_FILE` | **Yes** | Absolute path to the upload keystore (`.jks` / `.keystore`). |
| `ORAREPOT_KEYSTORE_PASSWORD` | **Yes** | Keystore password. |
| `ORAREPOT_KEY_ALIAS` | **Yes** | Key alias inside the keystore. |
| `ORAREPOT_KEY_PASSWORD` | **Yes** | Key password. |

Do not commit credentials or keystore files into this repository. See `docs/PROD_SIGNING.md`.

### Inventory

| File | Host | Connection |
| --- | --- | --- |
| `ansible/inventory.ini` | `localhost` in group `build_hosts` | `local` (build runs on the machine that invokes Ansible) |

### What the playbook does

1. Validates `app_env` and `build_format`
2. For PROD: asserts signing env vars and that the keystore file exists
3. Creates `dist/<env>/`
4. Resolves `--build-name` / `--build-number` from `app_version` / `app_build`
5. `flutter pub get`
6. `dart analyze`
7. `flutter test`
8. `flutter build apk|appbundle --flavor <env> …`
9. Copies artifact to `dist/<env>/orarepot-<ENV>.apk` or `.aab`
10. Writes `dist/<env>/build-metadata.txt`

### Dart defines injected at build time

| Define | Source |
| --- | --- |
| `APP_ENV` | `app_env` (uppercase) |
| `API_BASE_URL` | `api_base_url` / `app_base_url` if set, else `api_urls[app_env]` in `build.yml` |
| `APP_NAME` | fixed `OraRepot` |
| `GOOGLE_CLIENT_ID` | `google_client_id` or orappob web client default |

### Examples

**SIT APK (defaults):**

```bash
ansible-playbook -i ansible/inventory.ini ansible/build.yml \
  -e app_env=SIT
```

**SIT APK with version + API override:**

```bash
ansible-playbook -i ansible/inventory.ini ansible/build.yml \
  -e app_env=SIT \
  -e api_base_url=https://api.orarepot.com \
  -e build_format=apk \
  -e app_version=1.0.1 \
  -e app_build=11
```

**UAT APK with explicit version:**

```bash
ansible-playbook -i ansible/inventory.ini ansible/build.yml \
  -e app_env=UAT \
  -e build_format=apk \
  -e app_version=1.2.3+10
```

**UAT APK with separate build number:**

```bash
ansible-playbook -i ansible/inventory.ini ansible/build.yml \
  -e app_env=UAT \
  -e build_format=apk \
  -e app_version=1.2.3 \
  -e app_build=10
```

**PROD App Bundle (signing via env):**

```bash
export ORAREPOT_KEYSTORE_FILE=/absolute/path/to/orarepot-upload.jks
export ORAREPOT_KEYSTORE_PASSWORD=...
export ORAREPOT_KEY_ALIAS=orarepot-upload
export ORAREPOT_KEY_PASSWORD=...

ansible-playbook -i ansible/inventory.ini ansible/build.yml \
  -e app_env=PROD \
  -e build_format=appbundle \
  -e app_version=1.2.3 \
  -e app_build=42
```

**Full one-liner (all extras):**

```bash
ansible-playbook -i ansible/inventory.ini ansible/build.yml \
  -e app_env=PROD \
  -e build_format=appbundle \
  -e app_version=1.2.3 \
  -e app_build=42
```

### Outputs

| Path | Contents |
| --- | --- |
| `dist/<env>/orarepot-<ENV>.apk` | When `build_format=apk` |
| `dist/<env>/orarepot-<ENV>.aab` | When `build_format=appbundle` |
| `dist/<env>/build-metadata.txt` | `application`, `environment`, `flavor`, `application_id`, `api_base_url`, `artifact`, `build_name`, `build_number` |

## Wrapper script

Thin wrapper around the same playbook (env + format only; pass version via Ansible `-e` if needed):

```bash
./scripts/build_env.sh SIT apk
./scripts/build_env.sh UAT apk
./scripts/build_env.sh PROD appbundle
```

Equivalent Ansible:

```bash
ansible-playbook -i ansible/inventory.ini ansible/build.yml \
  -e app_env=UAT -e build_format=apk
```

## Runtime configuration

The app reads `APP_ENV`, `API_BASE_URL`, and `APP_NAME` from `--dart-define`. Defaults are SIT-safe. Do not commit credentials or signing keys into this repository.

## Branding

The OraRepot brand system is defined in `lib/ppob_app.dart` and uses a dark terminal-inspired palette, electric-lime accent, custom vector mark, environment-aware status marker, quick-order card, catalog shell, and review sheet. The Android launcher icon is `android/app/src/main/res/drawable/ic_orarepot.xml`.

## Release signing

Gradle reads `ORAREPOT_KEYSTORE_*` from the environment for release builds. Local non-PROD builds can use the debug signing config. Never put keystore passwords in this repository. Details: `docs/PROD_SIGNING.md`.

## iOS note

The archive has a single Xcode Runner target and no flavor schemes. The Ansible playbook builds Android artifacts only until iOS schemes, provisioning profiles, and signing identities are supplied. Once available, add SIT/UAT/PROD schemes with `PRODUCT_BUNDLE_IDENTIFIER` values matching the table and invoke `flutter build ipa --flavor <flavor>` with the same dart-defines / version flags.

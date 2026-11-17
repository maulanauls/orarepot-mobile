# PROD Android signing and CI/CD

This project uses the Android application ID `com.tikngroup.orarepot.orarepot.prod` for the PROD flavor. The keystore and passwords are never stored in Git.

## 1. Create the upload keystore

For a new Play Console app, generate an upload key on a secured workstation or in a controlled secrets-preparation job:

```bash
keytool -genkeypair -v \
  -keystore orarepot-upload.jks \
  -storetype PKCS12 \
  -alias orarepot-upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

Record the keystore password, key password, and alias in your team password manager. Do not commit `orarepot-upload.jks`, `key.properties`, or these passwords. For Google Play, register this certificate as the upload key when Play App Signing is enabled. To inspect the certificate fingerprints:

```bash
keytool -list -v \
  -keystore orarepot-upload.jks \
  -alias orarepot-upload
```

Keep a secured backup of the keystore. Losing the upload key requires a Play Console upload-key reset; losing an app-signing key can be much more serious.

## 2. Local developer setup

Copy the checked-in template and replace every placeholder:

```bash
cp android/key.properties.example android/key.properties
```

The file uses these names:

```properties
ORAREPOT_KEYSTORE_FILE=/absolute/path/to/orarepot-upload.jks
ORAREPOT_KEYSTORE_PASSWORD=...
ORAREPOT_KEY_ALIAS=orarepot-upload
ORAREPOT_KEY_PASSWORD=...
```

`android/key.properties` is ignored by Git. The Gradle file loads environment variables first and falls back to this local file. A local release build can then be created with:

```bash
flutter build appbundle \
  --release \
  --flavor prod \
  --dart-define=APP_ENV=PROD \
  --dart-define=API_BASE_URL=https://api.orarepot.com \
  --dart-define=APP_NAME=OraRepot
```

## 3. How package IDs and branding are injected

`android/app/build.gradle.kts` defines one `environment` flavor dimension. The base application ID is `com.tikngroup.orarepot.orarepot`; each flavor adds a lowercase suffix:

| Build | Flavor | Final package ID | Android label |
| --- | --- | --- | --- |
| SIT | `sit` | `com.tikngroup.orarepot.orarepot.sit` | `OraRepot SIT` |
| UAT | `uat` | `com.tikngroup.orarepot.orarepot.uat` | `OraRepot UAT` |
| PROD | `prod` | `com.tikngroup.orarepot.orarepot.prod` | `OraRepot` |

The flavor uses `resValue("string", "app_name", ...)`, and `AndroidManifest.xml` reads `@string/app_name`. All flavors use the original vector launcher icon at `android/app/src/main/res/drawable/ic_orarepot.xml`.

The Ansible playbook passes the runtime values as Dart compile-time defines:

```text
APP_ENV=SIT|UAT|PROD
API_BASE_URL=https://api.orarepot.com
APP_NAME=OraRepot
```

`lib/app_config.dart` reads these values with `String.fromEnvironment`. The app uses `APP_ENV` for the visible environment badge and uses the API URL for the environment-specific runtime configuration. The Android flavor controls the package ID; `APP_ENV` controls the app's runtime identity. Both must be supplied together.

## 4. CI secret setup

Create these CI secrets or protected variables:

```text
ORAREPOT_KEYSTORE_B64       Base64 contents of orarepot-upload.jks
ORAREPOT_KEYSTORE_PASSWORD  Keystore password
ORAREPOT_KEY_ALIAS          orarepot-upload
ORAREPOT_KEY_PASSWORD       Key password
```

In the build job, decode the keystore into an ephemeral runner path and export the four variables consumed by Gradle and Ansible. Example shell setup:

```bash
mkdir -p "$RUNNER_TEMP/orarepot-signing"
printf '%s' "$ORAREPOT_KEYSTORE_B64" | base64 --decode \
  > "$RUNNER_TEMP/orarepot-signing/orarepot-upload.jks"
chmod 600 "$RUNNER_TEMP/orarepot-signing/orarepot-upload.jks"
export ORAREPOT_KEYSTORE_FILE="$RUNNER_TEMP/orarepot-signing/orarepot-upload.jks"
export ORAREPOT_KEYSTORE_PASSWORD="$ORAREPOT_KEYSTORE_PASSWORD_SECRET"
export ORAREPOT_KEY_ALIAS="$ORAREPOT_KEY_ALIAS_SECRET"
export ORAREPOT_KEY_PASSWORD="$ORAREPOT_KEY_PASSWORD_SECRET"
```

Use your CI provider's secret mechanism to populate the `*_SECRET` values; do not echo them. Restrict PROD secrets to protected branches, protected environments, or manual approvals.

## 5. Run the Ansible pipeline

From the Flutter project root:

```bash
./scripts/build_env.sh PROD appbundle
```

The wrapper calls:

```bash
ansible-playbook -i ansible/inventory.ini ansible/build.yml \
  -e app_env=PROD \
  -e build_format=appbundle
```

The playbook installs dependencies, runs `flutter analyze` and `flutter test`, validates all PROD signing variables and the keystore file, builds `prodRelease`, and copies the bundle to `dist/prod/orarepot-PROD.aab`. It also writes `dist/prod/build-metadata.txt` without including passwords.

For non-production validation, use the same pipeline with `SIT` or `UAT`. Those environments can use a CI signing key or local debug fallback, but release artifacts intended for distribution should still use a controlled upload key.

## 6. CI/CD safeguards

Build PROD only from a protected branch or an approved release tag. Mark the signing variables as masked and protected. Keep the keystore path outside the repository, delete the temporary file in an `always`/`post` cleanup step, and archive only the AAB plus `build-metadata.txt`. Never upload `android/key.properties`, Gradle logs containing command lines, or the keystore itself as a pipeline artifact.

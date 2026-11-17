import java.io.FileInputStream
import java.util.Properties

val signingProperties = Properties()
val signingPropertiesFile = rootProject.file("key.properties")
if (signingPropertiesFile.exists()) {
    signingProperties.load(FileInputStream(signingPropertiesFile))
}

fun signingValue(name: String): String? {
    return System.getenv(name)?.takeIf { it.isNotBlank() }
        ?: signingProperties.getProperty(name)?.takeIf { it.isNotBlank() }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.tikngroup.orarepot.orarepot"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by alice → flutter_local_notifications on newer AGP.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.tikngroup.orarepot.orarepot"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"
    productFlavors {
        create("sit") {
            dimension = "environment"
            applicationIdSuffix = ".sit"
            resValue("string", "app_name", "OraRepot SIT")
        }
        create("uat") {
            dimension = "environment"
            applicationIdSuffix = ".uat"
            resValue("string", "app_name", "OraRepot UAT")
        }
        create("prod") {
            dimension = "environment"
            applicationIdSuffix = ".prod"
            resValue("string", "app_name", "OraRepot")
        }
    }

    signingConfigs {
        create("release") {
            val keystoreFile = signingValue("ORAREPOT_KEYSTORE_FILE")
            val keystorePassword = signingValue("ORAREPOT_KEYSTORE_PASSWORD")
            val keyAlias = signingValue("ORAREPOT_KEY_ALIAS")
            val keyPassword = signingValue("ORAREPOT_KEY_PASSWORD")

            if (keystoreFile != null && keystorePassword != null && keyAlias != null && keyPassword != null) {
                storeFile = file(keystoreFile)
                storePassword = keystorePassword
                this.keyAlias = keyAlias
                this.keyPassword = keyPassword
            }
        }
    }

    buildTypes {
        release {
            // Local non-PROD builds may still use debug signing. CI validates
            // signing inputs before a PROD build is allowed to start.
            val releaseSigning = signingConfigs.getByName("release")
            signingConfig = if (releaseSigning.storeFile != null) {
                releaseSigning
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

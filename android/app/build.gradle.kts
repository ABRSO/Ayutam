import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Explicit opt-in only — never silently fall back to the debug certificate for
// distributable release builds (ADR-021).
val allowDebugReleaseSigning =
    (findProperty("ayutam.allowDebugReleaseSigning") as String?) == "true" ||
        System.getenv("AYUTAM_ALLOW_DEBUG_RELEASE_SIGNING") == "1"

android {
    namespace = "com.ayutam.ayutam"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.ayutam.ayutam"
        // Android 10+ (API 29) per product spec.
        minSdk = 29
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                // storeFile paths in key.properties are relative to android/.
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Permanent Ayutam release certificate via android/key.properties
            // (local) or CI secrets → key.properties (ADR-021). Never commit
            // the keystore or passwords. Debug/profile stay on the debug
            // keystore. Missing key.properties fails release builds unless
            // -Payutam.allowDebugReleaseSigning=true (or env
            // AYUTAM_ALLOW_DEBUG_RELEASE_SIGNING=1) is set explicitly.
            signingConfig =
                when {
                    hasReleaseKeystore -> signingConfigs.getByName("release")
                    allowDebugReleaseSigning -> signingConfigs.getByName("debug")
                    else -> null
                }
        }
    }
}

afterEvaluate {
    tasks.matching { task ->
        val n = task.name
        (n.startsWith("assemble") || n.startsWith("bundle") || n.startsWith("package")) &&
            n.contains("Release")
    }.configureEach {
        doFirst {
            if (!hasReleaseKeystore && !allowDebugReleaseSigning) {
                throw GradleException(
                    "Release builds require android/key.properties (ADR-021). " +
                        "Copy android/key.properties.example and configure the permanent " +
                        "release keystore, or pass -Payutam.allowDebugReleaseSigning=true " +
                        "(flutter: --android-project-arg=-Payutam.allowDebugReleaseSigning=true) " +
                        "or set AYUTAM_ALLOW_DEBUG_RELEASE_SIGNING=1 for a non-distributable " +
                        "debug-signed release-mode build.",
                )
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core-ktx:1.15.0")
}

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

fun isReleasePackagingTask(name: String): Boolean {
    val isRelease = name.contains("Release")
    val isPackaging =
        name.startsWith("assemble") ||
            name.startsWith("bundle") ||
            name.startsWith("package") ||
            name.startsWith("sign")
    return isRelease && isPackaging
}

fun requirePermanentReleaseSigning() {
    val alias = keystoreProperties.getProperty("keyAlias").orEmpty()
    val keyPassword = keystoreProperties.getProperty("keyPassword").orEmpty()
    val storePassword = keystoreProperties.getProperty("storePassword").orEmpty()
    val storeRel = keystoreProperties.getProperty("storeFile").orEmpty()
    if (alias.isBlank() || keyPassword.isBlank() || storePassword.isBlank() || storeRel.isBlank()) {
        throw GradleException(
            "android/key.properties is incomplete (need keyAlias, keyPassword, " +
                "storePassword, storeFile). Copy android/key.properties.example.",
        )
    }
    val storeFile = rootProject.file(storeRel)
    if (!storeFile.isFile) {
        throw GradleException(
            "Release keystore not found at android/$storeRel (ADR-021). " +
                "Place the JKS next to key.properties or fix storeFile.",
        )
    }
}

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
        if (hasReleaseKeystore) {
            create("release") {
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
            // keystore. Missing or incomplete key.properties fails release
            // builds unless -Payutam.allowDebugReleaseSigning=true (or env
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

gradle.taskGraph.whenReady {
    val buildingRelease = gradle.taskGraph.allTasks.any { isReleasePackagingTask(it.name) }
    if (!buildingRelease) {
        return@whenReady
    }
    if (!hasReleaseKeystore && allowDebugReleaseSigning) {
        return@whenReady
    }
    if (!hasReleaseKeystore) {
        throw GradleException(
            "Release builds require android/key.properties (ADR-021). " +
                "Copy android/key.properties.example and configure the permanent " +
                "release keystore, or pass -Payutam.allowDebugReleaseSigning=true " +
                "(flutter: --android-project-arg=-Payutam.allowDebugReleaseSigning=true) " +
                "or set AYUTAM_ALLOW_DEBUG_RELEASE_SIGNING=1 for a non-distributable " +
                "debug-signed release-mode build.",
        )
    }
    requirePermanentReleaseSigning()
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

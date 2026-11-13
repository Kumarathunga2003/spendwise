
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // Flutter plugin must be applied after the Android plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

// Read release signing information from android/key.properties.
// Passwords are not stored in this Gradle file.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(
        FileInputStream(keystorePropertiesFile)
    )
}

android {
    namespace = "com.example.spendwise"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Permanent Google Play application ID.
        applicationId = "com.kumarathunga.spendwise"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        // Keep the app version in pubspec.yaml.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Signing configuration for Google Play release builds.
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties
                .getProperty("storeFile")
                ?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            proguardFiles("proguard-rules.pro")
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// 📂 android/app/build.gradle.kts

// 🔴 CHINCHE FIRMA 0 — imports necesarios para leer key.properties
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")

    // 🔴 CHINCHE FIREBASE 1 — ACTIVA Google Services (Firebase)
    id("com.google.gms.google-services")
}

// 🔴 CHINCHE FIRMA 1 — leer key.properties (NO borrar este bloque)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.matchy.matchy20.flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        // 🔴 CHINCHE FIRMA 2 — RELEASE: usa key.properties si existe
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
            // Si NO existe key.properties, no revienta aquí; solo no firmará release.
        }
    }

    defaultConfig {
        applicationId = "com.matchy.matchy20.flutter"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            // 🔴 CHINCHE FIRMA 3 — release usa firma real solo si hay key.properties
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }

            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

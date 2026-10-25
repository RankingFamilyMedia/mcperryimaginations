plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mcperryimaginations.autoyaad"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_17.toString() }

    defaultConfig {
        applicationId = "com.mcperryimaginations.autoyaad"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["ADMOB_APP_ID"] =
            project.findProperty("ADMOB_APP_ID")
                ?: "ca-app-pub-3940256099942544~3347511713"
    }

    buildTypes {
        release {
            // Replace with your upload keystore before Play Store production release.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter { source = "../.." }

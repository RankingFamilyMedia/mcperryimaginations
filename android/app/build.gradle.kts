import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (!keystorePropertiesFile.exists()) {
    throw GradleException(
        "Missing android/key.properties. Copy android/key.properties.example and configure the production upload keystore.")
}
FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }

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
            signingConfig = signingConfigs.create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
}

flutter { source = "../.." }

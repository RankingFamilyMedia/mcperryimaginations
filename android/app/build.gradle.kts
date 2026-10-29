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

val cmsMode = providers.gradleProperty("cmsMode").map { it.toBoolean() }.orElse(false).get()
val partnerMode = providers.gradleProperty("partnerMode").map { it.toBoolean() }.orElse(false).get()
if (cmsMode && partnerMode) {
    throw GradleException("cmsMode and partnerMode cannot both be enabled")
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
        applicationId = when {
            partnerMode -> "com.mcperryimaginations.autoyaad.publisher"
            cmsMode -> "com.mcperryimaginations.autoyaad.cms"
            else -> "com.mcperryimaginations.autoyaad"
        }
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue(
            "string",
            "app_name",
            when {
                partnerMode -> "AutoYaad Publisher"
                cmsMode -> "AutoYaad CMS"
                else -> "AutoYaad Ghana"
            })
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

import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.kimi.my_daily_task"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        jvmToolchain(17) // Use Java 17 for Kotlin DSL
    }

    defaultConfig {
        applicationId = "com.kimi.my_daily_task"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Load signing info from key.properties
    val keystorePropertiesFile = File(rootDir, "key.properties")

    if (!keystorePropertiesFile.exists()) {
        throw GradleException("key.properties file not found at ${keystorePropertiesFile.absolutePath}")
    }

    val keystoreProperties = Properties().apply {
        load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
                ?: throw GradleException("keyAlias not found in key.properties")
            keyPassword = keystoreProperties.getProperty("keyPassword")
                ?: throw GradleException("keyPassword not found in key.properties")
            storeFile = File(keystoreProperties.getProperty("storeFile")
                ?: throw GradleException("storeFile not found in key.properties"))
            storePassword = keystoreProperties.getProperty("storePassword")
                ?: throw GradleException("storePassword not found in key.properties")
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android plugin.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.kellytrendz.amplifymusic"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    // Allow toggling debug minification via gradle property 'enableDebugMinify'
    val enableDebugMinify: Boolean =
        (project.findProperty("enableDebugMinify") as String?)?.toBoolean() ?: true

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.kellytrendz.amplifymusic"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            // Enable R8 code shrinking and obfuscation
            isMinifyEnabled = true
            isShrinkResources = true

            // Use R8 proguard rules
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // Signing with debug keys for now
            signingConfig = signingConfigs.getByName("debug")
        }

        debug {
            // Control R8 for debug builds via 'enableDebugMinify' Gradle property
            isMinifyEnabled = enableDebugMinify
            isShrinkResources = enableDebugMinify
            // Add debug info for crash analysis
            isDebuggable = true
        }
    }

    // Suppress Kotlin compilation warnings from incompatible plugins
    kotlinOptions {
        jvmTarget = "17"
        allWarningsAsErrors = false
        suppressWarnings = true
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
    // Play Core for SplitInstall / deferred components used by Flutter embedding
    implementation("com.google.android.play:core:1.10.3")
}

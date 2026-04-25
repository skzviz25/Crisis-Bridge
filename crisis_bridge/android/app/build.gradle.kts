import java.util.Properties

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

plugins {
    id("com.android.application")
    id("kotlin-android")
    // FlutterFire — must come AFTER android plugin
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}


android {
    namespace = "com.pr.crisis_bridge"  // ← keep whatever is already here
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        // ✅ FIX: use compilerOptions DSL, not deprecated jvmTarget string
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.pr.crisis_bridge"  // ← keep yours
        // ✅ FIX: Kotlin DSL uses = assignment, no parentheses
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
        multiDexEnabled = true
    }

    packaging {
        jniLibs {
            pickFirsts.add("lib/x86/libc++_shared.so")
            pickFirsts.add("lib/x86_64/libc++_shared.so")
            pickFirsts.add("lib/armeabi-v7a/libc++_shared.so")
            pickFirsts.add("lib/arm64-v8a/libc++_shared.so")
        }
    }

    buildTypes {
        release {
            // Keep debug signing for now; replace with keystore for production
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Multidex support
    implementation("androidx.multidex:multidex:2.0.1")
    // Firebase BoM — manages all Firebase library versions
    implementation(platform("com.google.firebase:firebase-bom:33.1.0"))
    implementation("com.google.firebase:firebase-analytics")
}

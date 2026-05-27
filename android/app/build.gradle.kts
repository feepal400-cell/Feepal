plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.main_dart"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.main_dart"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        multiDexEnabled = true

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        missingDimensionStrategy("default", "production")
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            
            // --- NEW: Added this line to enforce your ProGuard rules ---
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

   // --- AUTOMATIC APK RENAMING BLOCK ---
   applicationVariants.all {
       val variant = this
       variant.outputs.all {
           val output = this as com.android.build.gradle.internal.api.ApkVariantOutputImpl
           val appName = "feepal"
           val version = variant.versionName
           
           // NEW: Check for an architecture/ABI filter (when using --split-per-abi)
           val abi = output.filters.find { it.filterType == "ABI" }?.identifier
           val abiSuffix = if (abi != null) "-$abi" else ""
           
           // Safely names the file based on the build type
           output.outputFileName = "$appName-v$version$abiSuffix.apk"
       }
   }
    
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
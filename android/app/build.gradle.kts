// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.mrenes.odaklist"
    compileSdk = 35
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Bildirim ve Timezone paketleri için gerekli Java 8 ayarı
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.mrenes.odaklist"
        
        // MİNİMUM SDK 21 OLMALI
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Uygulama boyutu için gerekli
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")

            isMinifyEnabled = true 
            isShrinkResources = true
            
            // BURASI ÇOK ÖNEMLİ: Oluşturduğumuz kural dosyasını gösteriyoruz
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Bu satır hatayı çözen sihirli değnek (Java 8 uyumluluğu)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("androidx.multidex:multidex:2.0.1")
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.event_app_3"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"
    

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.event_app_3"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildFeatures {
        viewBinding = true
    }

    // Включите поддержку десугаринга
    compileOptions {
        isCoreLibraryDesugaringEnabled = true // Используйте это вместо coreLibraryDesugaringEnabled
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.13.0"))
    
    // Добавьте зависимость для десугаринга
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") // Убедитесь, что используете актуальную версию

    // Другие зависимости
}

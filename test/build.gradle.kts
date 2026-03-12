plugins {
    alias(libs.plugins.agp.app)
}

val androidTargetSdkVersion: Int by rootProject.extra
val androidMinSdkVersion: Int by rootProject.extra
val androidBuildToolsVersion: String by rootProject.extra
val androidCompileSdkVersion: Int by rootProject.extra
val androidNdkVersion: String by rootProject.extra
val androidCmakeVersion: String by rootProject.extra

android {
    namespace = "org.lsposed.lsplant.test"
    compileSdk = androidCompileSdkVersion
    ndkVersion = androidNdkVersion
    buildToolsVersion = androidBuildToolsVersion

    buildFeatures { buildConfig = false }

    defaultConfig {
        applicationId = "org.lsposed.lsplant"
        minSdk = androidMinSdkVersion
        targetSdk = androidTargetSdkVersion
        versionCode = 1
        versionName = "1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        debug {
            isDebuggable = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    testOptions {}
}

dependencies {
    androidTestImplementation(libs.test.ext.junit)
    androidTestImplementation(libs.test.runner)
    androidTestImplementation(libs.test.espresso)
}

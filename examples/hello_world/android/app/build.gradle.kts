// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "io.flutter.examples.hello_world"
    compileSdk = flutter.compileSdkVersion

    // Flutter's CI installs the NDK at a non-standard path.
    // This non-standard structure is initially created by
    // https://github.com/flutter/engine/blob/3.27.0/tools/android_sdk/create_cipd_packages.sh.
    val systemNdkPath: String? = System.getenv("ANDROID_NDK_PATH")
    if (systemNdkPath != null) {
        ndkVersion = flutter.ndkVersion
        ndkPath = systemNdkPath
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    defaultConfig {
        applicationId = "io.flutter.examples.hello_world"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        named("release") {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

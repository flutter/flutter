// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

group = "dev.flutter.plugins.integration_test"
version = "1.0-SNAPSHOT"

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
    }
}

plugins {
    id("com.android.library")
}

rootProject.allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// project.getTasks().withType(JavaCompile){
//     options.compilerArgs << "-Xlint:all" << "-Werror"
// }

android {
    namespace = "dev.flutter.integration_test"
    compileSdk = 34

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    defaultConfig {
        minSdk = 21
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles("lib-proguard-rules.txt")
    }

    dependencies {
        // TODO(egarciad): These dependencies should not be added to release builds.
        // https://github.com/flutter/flutter/issues/56591
        testImplementation("junit:junit:4.13.2")
        testImplementation("org.mockito:mockito-inline:5.1.0")

        api("androidx.test:runner:1.5+")
        api("androidx.test:rules:1.2+")
        api("androidx.test.espresso:espresso-core:3.2+")
        api("androidx.test.uiautomator:uiautomator:2.2+")
        api("androidx.test:monitor:1.7+")

        implementation("com.google.guava:guava:28.1-android")
    }
}

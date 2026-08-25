// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@file:Suppress("DSL_SCOPE_VIOLATION")

plugins {
    `java-gradle-plugin`
    groovy
    kotlin("jvm") version "1.9.24"
}

group = "dev.flutter.plugin"
version = "1.0.0"

tasks.validatePlugins {
    enableStricterValidation.set(true)
}

gradlePlugin {
    plugins {
        create("flutterPlugin") {
            id = "dev.flutter.flutter-gradle-plugin"
            implementationClass = "com.flutter.gradle.FlutterPlugin"
        }
        create("flutterAppPluginLoaderPlugin") {
            id = "dev.flutter.flutter-plugin-loader"
            implementationClass = "com.flutter.gradle.FlutterAppPluginLoaderPlugin"
        }
    }
}

tasks.withType<JavaCompile> {
    options.release.set(11)
}

tasks.test {
    useJUnitPlatform()
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    kotlinOptions {
        jvmTarget = "11"
    }
}

// NOTE: Repositories are intentionally NOT declared here because this build
// prefers settings repositories (dependencyResolutionManagement.repositoriesMode).
// Declare repositories in the root settings.gradle(.kts) used when running the build.

dependencies {
    // Gradle API types (compile-time only)
    compileOnly(gradleApi())

    // Android Gradle Plugin types (compile-time only)
    // Keep this in sync with the AGP version used by your Android projects.
    compileOnly("com.android.tools.build:gradle:8.3.2")

    // Provide Gradle Kotlin DSL helpers on the compile classpath so Kotlin sources
    // using Kotlin-DSL extension functions (args, from, into, serviceOf, etc.) compile.
    implementation(gradleKotlinDsl())

    // Provide Kotlin Gradle plugin classes at compile time for reflection/inspection.
    // This helps code that references Kotlin plugin types during compilation.
    compileOnly("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")

    // AndroidX annotation
    compileOnly("androidx.annotation:annotation-jvm:1.9.1")

    // Kotlin stdlib for compile-time resolution if needed
    compileOnly(kotlin("stdlib"))

    // Kotlin serialization (runtime for plugin tests or plugin runtime if required)
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.4.0")

    // Test dependencies
    testImplementation(kotlin("test"))
    testImplementation("com.android.tools.build:gradle:8.3.2")
    testImplementation("org.mockito:mockito-core:5.8.0")
    testImplementation("io.mockk:mockk:1.13.16")
}

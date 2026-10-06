// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    `java-gradle-plugin`
    groovy
    `kotlin-dsl`
    kotlin("jvm") version "2.2.20"
}

group = "dev.flutter.plugin"
version = "1.0.0"

// Optional: enable stricter validation, to ensure Gradle configuration is correct
tasks.validatePlugins {
    enableStricterValidation.set(true)
}

gradlePlugin {
    plugins {
        // The "flutterPlugin" name isn't used anywhere.
        create("flutterPlugin") {
            id = "dev.flutter.flutter-gradle-plugin"
            implementationClass = "com.flutter.gradle.FlutterPlugin"
        }
        // The "flutterAppPluginLoaderPlugin" name isn't used anywhere.
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

// https://stackoverflow.com/questions/55456176/unresolved-reference-compilekotlin-in-build-gradle-kts
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_11)
    }
}

// The AGP version to compile and test against. Namespaced with `flutter.internal.` to
// avoid collision with user app properties when evaluated as an included build.
val agpVersion: String = providers.gradleProperty("flutter.internal.agpVersion").getOrElse("9.1.1")

dependencies {
    // Versions available https://mvnrepository.com/artifact/androidx.annotation/annotation-jvm.
    // Version release notes https://developer.android.com/jetpack/androidx/releases/annotation
    compileOnly("androidx.annotation:annotation-jvm:1.9.1")
    // When bumping, also update:
    //  * KGP error version in packages/flutter_tools/gradle/src/main/kotlin/DependencyVersionChecker.kt
    implementation("org.jetbrains.kotlin:kotlin-gradle-plugin:2.4.10")
    // 1.11.0 is built with Kotlin 2.3.20. Update to 1.12.0 (built with Kotlin 2.4.10) once it is stable.
    // https://github.com/Kotlin/kotlinx.serialization/releases for kotlin version compatibility.
    // All kotlinx implementation dependencies must work with the oldest kotlin supported versions.
    // Defined in packages/flutter_tools/gradle/src/main/kotlin/DependencyVersionChecker.kt
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.11.0")
    // When bumping the default agpVersion above, also update:
    //  * AGP version constants in packages/flutter_tools/lib/src/android/gradle_utils.dart
    //  * ndkVersion constant in packages/flutter_tools/lib/src/android/gradle_utils.dart
    //  * ndkVersion in FlutterExtension in packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt
    compileOnly("com.android.tools.build:gradle:$agpVersion")

    testImplementation(kotlin("test"))
    testImplementation("com.android.tools.build:gradle:$agpVersion")
    // MockK bundles Byte Buddy for inline mocking. Byte Buddy must support the
    // JDK that runs the tests (Java 25 requires Byte Buddy >= 1.17.5).
    testImplementation("io.mockk:mockk:1.14.11")
}

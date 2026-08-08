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

// The AGP version the Flutter Gradle Plugin compiles and tests against. CI additionally runs
// this build with -PagpVersion=<AGP 9 line> to catch public-DSL binary incompatibilities
// between the AGP major versions the plugin supports (see AgpCommonExtensionWrapper).
val agpVersion: String = providers.gradleProperty("agpVersion").getOrElse("8.11.1")

dependencies {
    // Versions available https://mvnrepository.com/artifact/androidx.annotation/annotation-jvm.
    // Version release notes https://developer.android.com/jetpack/androidx/releases/annotation
    compileOnly("androidx.annotation:annotation-jvm:1.9.1")
    // When bumping, also update:
    //  * KGP error version in packages/flutter_tools/gradle/src/main/kotlin/DependencyVersionChecker.kt
    implementation("org.jetbrains.kotlin:kotlin-gradle-plugin:2.0.0")
    // Update to 1.8.0 when min kotlin is 2.1
    // https://github.com/Kotlin/kotlinx.serialization/releases for kotlin version compatibility.
    // All kotlinx implementation dependencies must work with the oldest kotlin supported versions.
    // Defined in packages/flutter_tools/gradle/src/main/kotlin/DependencyVersionChecker.kt
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.4.0")
    // The Flutter Gradle Plugin compiles against AGP's public API artifact only. AGP 10
    // removes access to AGP internals entirely, so this dependency choice is also the
    // compile-time proof that no internal API is used (see
    // docs/platforms/android/Migrating-Flutter-Gradle-Plugin-to-AGP-public-API.md).
    // When bumping the default agpVersion above, also update:
    //  * AGP version constants in packages/flutter_tools/lib/src/android/gradle_utils.dart
    //  * ndkVersion constant in packages/flutter_tools/lib/src/android/gradle_utils.dart
    //  * ndkVersion in FlutterExtension in packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt
    compileOnly("com.android.tools.build:gradle-api:$agpVersion")

    testImplementation(kotlin("test"))
    testImplementation("com.android.tools.build:gradle-api:$agpVersion")
    testImplementation("org.mockito:mockito-core:5.8.0")
    testImplementation("io.mockk:mockk:1.13.16")
}

// CommonExtension is binary-incompatible between AGP 8 and 9, which is why DSL access is
// routed through AgpCommonExtensionWrapper. If the compiler emits a reference to
// CommonExtension as the owner of a call, the plugin breaks on one of the two AGP lines at
// runtime even though it compiles on both. Fail fast if such a reference appears in the
// main bytecode (test bytecode intentionally references AGP types directly).
val validateNoCommonExtensionInBytecode by tasks.registering {
    description =
        "Checks that no compiled main class references com.android.build.api.dsl.CommonExtension."
    dependsOn(tasks.named("compileKotlin"))
    val classesDir = layout.buildDirectory.dir("classes/kotlin/main")
    doLast {
        val needle = "com/android/build/api/dsl/CommonExtension".toByteArray(Charsets.ISO_8859_1)
        val offenders =
            classesDir
                .get()
                .asFile
                .walkTopDown()
                .filter { it.isFile && it.extension == "class" }
                .filter { file ->
                    val bytes = file.readBytes()
                    (0..bytes.size - needle.size).any { start ->
                        needle.indices.all { i -> bytes[start + i] == needle[i] }
                    }
                }.map { it.name }
                .toList()
        if (offenders.isNotEmpty()) {
            throw GradleException(
                "CommonExtension must not be referenced from Flutter Gradle Plugin bytecode " +
                    "(it is binary-incompatible between AGP 8 and 9). Route DSL access through " +
                    "AgpCommonExtensionWrapper instead. Offending classes: $offenders"
            )
        }
    }
}

// Attached to `test` (not just `check`) because CI drives this build through `gradlew test`
// (see packages/flutter_tools/test/integration.shard/android_run_flutter_gradle_plugin_tests_test.dart).
tasks.test {
    dependsOn(validateNoCommonExtensionInBytecode)
}

tasks.named("check") {
    dependsOn(validateNoCommonExtensionInBytecode)
}

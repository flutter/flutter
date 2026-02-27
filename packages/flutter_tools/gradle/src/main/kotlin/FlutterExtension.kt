// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import org.gradle.api.GradleException

/**
 * For apps only. Provides the flutter extension used in the app-level Gradle
 * build file (app/build.gradle or app/build.gradle.kts).
 *
 * The versions specified here should match the values in
 * packages/flutter_tools/lib/src/android/gradle_utils.dart, so when bumping,
 * make sure to update the versions specified there.
 *
 * Learn more about extensions in Gradle:
 *  * https://docs.gradle.org/8.0.2/userguide/custom_plugins.html#sec:getting_input_from_the_build
 */
@Suppress("unused") // The values in this class are used in Flutter developers app-level build.gradle file.
open class FlutterExtension {
    /** Sets the compileSdkVersion used by default in Flutter app projects. */
    val compileSdkVersion: Int = 36

    /** Sets the minSdkVersion used by default in Flutter app projects. */
    val minSdkVersion: Int = 24

    /**
     * Sets the targetSdkVersion used by default in Flutter app projects.
     * targetSdkVersion should always be the latest available stable version.
     *
     * See https://developer.android.com/guide/topics/manifest/uses-sdk-element.
     */
    val targetSdkVersion: Int = 36

    /**
     * Sets the ndkVersion used by default in Flutter app projects.
     * Chosen as default version of the AGP version found in packages/flutter_tools/gradle/build.gradle.kts
     * and in packages/flutter_tools/gradle/build.gradle.kts as found in
     * https://developer.android.com/studio/projects/install-ndk#default-ndk-per-agp.
     */
    val ndkVersion: String = "28.2.13676358"

    /**
     * Specifies the relative directory to the Flutter project directory.
     * In an app project, this is ../.. since the app's Gradle build file is under android/app.
     */
    var source: String? = "../.."

    /** Allows to override the target file. Otherwise, the target is lib/main.dart. */
    var target: String? = null

    /** The versionCode that was read from app's local.properties. */
    var flutterVersionCode: String? = null

    /** The versionName that was read from app's local.properties. */
    var flutterVersionName: String? = null

    /** Returns flutterVersionCode as an integer with error handling. */
    fun getVersionCode(): Int {
        val versionCode =
            flutterVersionCode
                ?: throw GradleException("flutterVersionCode must not be null.")

        return versionCode.toIntOrNull()
            ?: throw GradleException("flutterVersionCode must be an integer.")
    }

    /** Returns flutterVersionName with error handling. */
    fun getVersionName(): String =
        flutterVersionName
            ?: throw GradleException("flutterVersionName must not be null.")

    // The default getter name that Kotlin creates conflicts with the above methods.
    @get:JvmName("getVersionCodeProperty")
    val versionCode: Int
        get() = getVersionCode()

    // The default getter name that Kotlin creates conflicts with the above methods.
    @get:JvmName("getVersionNameProperty")
    val versionName: String
        get() = getVersionName()
}

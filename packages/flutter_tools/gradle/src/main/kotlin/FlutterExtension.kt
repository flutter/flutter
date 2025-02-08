// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

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
class FlutterExtension(var target: String = null) {
    /** Sets the compileSdkVersion used by default in Flutter app projects. */
    val compileSdkVersion: Int = 35

    /** Sets the minSdkVersion used by default in Flutter app projects. */
    val minSdkVersion: Int = 21

    /**
     * Sets the targetSdkVersion used by default in Flutter app projects.
     * targetSdkVersion should always be the latest available stable version.
     *
     * See https://developer.android.com/guide/topics/manifest/uses-sdk-element.
     */
    val targetSdkVersion: Int = 35

    /**
     * Sets the ndkVersion used by default in Flutter app projects.
     * Chosen as default version of the AGP version below as found in
     * https://developer.android.com/studio/projects/install-ndk#default-ndk-per-agp.
     */
    val ndkVersion: String = "26.3.11579264"

    /**
     * Specifies the relative directory to the Flutter project directory.
     * In an app project, this is ../.. since the app's Gradle build file is under android/app.
     */
    var source: String = "../.."

    /** The versionCode that was read from app's local.properties. */
    var flutterVersionCode: Int = null

    /** The versionName that was read from app's local.properties. */
    var flutterVersionName: String = null

    /** Returns flutterVersionCode as an integer with error handling. */
    fun getVersionCode(): Int {
        if (flutterVersionCode == null) {
            throw Exception("flutterVersionCode must not be null.")
        }

        if (!flutterVersionCode.isNumber()) {
            throw Exception("flutterVersionCode must be an integer.")
        }

        return flutterVersionCode
    }

    /** Returns flutterVersionName with error handling. */
    fun getVersionName(): String {
        if (flutterVersionName == null) {
            throw Exception("flutterVersionName must not be null.")
        }

        return flutterVersionName
    }
}
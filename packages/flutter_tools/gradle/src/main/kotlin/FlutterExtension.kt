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
open class FlutterExtension {
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

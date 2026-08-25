// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import org.gradle.api.Plugin
import org.gradle.api.initialization.Settings
import org.gradle.api.plugins.ExtraPropertiesExtension
import java.io.File
import java.nio.file.Paths
import java.util.Properties

private const val FLUTTER_SDK_PATH = "flutterSdkPath"

/**
 * This plugin applies the native plugin loader script (../scripts/native_plugin_loader.gradle.kts)
 * and then configures the main project to `include` each of the loaded flutter plugins.
 *
 * This class is used by packages/flutter_tools/gradle/build.gradle.kts.
 */
@Suppress("unused")
class FlutterAppPluginLoaderPlugin : Plugin<Settings> {
    override fun apply(settings: Settings) {
        val flutterProjectRoot: File = settings.settingsDir.parentFile

        // Use the ExtraPropertiesExtension from the Settings' extensions.
        val ext: ExtraPropertiesExtension = settings.extensions.extraProperties

        // Ensure flutterSdkPath is available in the settings extra properties.
        if (!ext.has(FLUTTER_SDK_PATH)) {
            val properties = Properties()
            val localPropertiesFile = File(settings.rootProject.projectDir, "local.properties")
            if (!localPropertiesFile.exists()) {
                throw IllegalStateException("local.properties not found and $FLUTTER_SDK_PATH not set")
            }
            localPropertiesFile.inputStream().use { properties.load(it) }
            val flutterSdk = properties.getProperty("flutter.sdk")?.trim()
            if (flutterSdk.isNullOrEmpty()) {
                throw IllegalStateException("flutter.sdk not set in local.properties")
            }
            ext.set(FLUTTER_SDK_PATH, flutterSdk)
        }

        // Resolve the flutter SDK path from the extra properties
        val flutterSdkPath = ext.get(FLUTTER_SDK_PATH) as? String
            ?: throw IllegalStateException("$FLUTTER_SDK_PATH is not a string")

        // Locate the native_plugin_loader script inside the flutter_tools gradle scripts directory.
        val loaderScriptFile = Paths.get(
            flutterSdkPath,
            "packages",
            "flutter_tools",
            "gradle",
            "src",
            "main",
            "scripts",
            "native_plugin_loader.gradle.kts"
        ).toFile()

        if (!loaderScriptFile.exists()) {
            throw IllegalStateException("native_plugin_loader.gradle.kts not found at: ${loaderScriptFile.absolutePath}")
        }

        // Apply the script file to the Settings using the map-based apply form to avoid Kotlin-DSL receiver issues.
        settings.apply {
            apply(mapOf("from" to loaderScriptFile))
        }

        // Use the ExtraPropertiesExtension instance when calling the reflection bridge.
        // NativePluginLoaderReflectionBridge.getPlugins returns a collection of maps describing plugins.
        val plugins = NativePluginLoaderReflectionBridge.getPlugins(ext, flutterProjectRoot)

        plugins.forEach { androidPlugin ->
            val pluginPath = androidPlugin["path"] as? String
                ?: throw IllegalStateException("Plugin path missing for plugin entry: $androidPlugin")
            val pluginDirectory = File(pluginPath, "android")
            check(pluginDirectory.exists()) { "Plugin directory does not exist: ${pluginDirectory.absolutePath}" }

            val pluginName = androidPlugin["name"] as? String
                ?: throw IllegalStateException("Plugin name missing for plugin at: ${pluginDirectory.absolutePath}")

            // Include the plugin project and set its projectDir to the plugin's android directory.
            // Use settings.include and then set projectDir defensively.
            settings.include(":$pluginName")

            // Set projectDir defensively: prefer findProject then fallback to settings.project(...)
            val descriptor = settings.findProject(":$pluginName")
            if (descriptor != null) {
                descriptor.projectDir = pluginDirectory
            } else {
                // If the descriptor is not yet available, obtain it via settings.project and set projectDir.
                // settings.project(...) will create the project descriptor if necessary.
                settings.project(":$pluginName").projectDir = pluginDirectory
            }
        }
    }
}

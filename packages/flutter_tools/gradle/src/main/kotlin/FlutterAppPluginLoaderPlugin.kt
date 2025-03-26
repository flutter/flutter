// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import org.gradle.api.Plugin
import org.gradle.api.initialization.Settings
import org.jetbrains.kotlin.gradle.plugin.extraProperties
import java.io.File
import java.nio.file.Paths
import java.util.Properties

const val FLUTTER_SDK_PATH = "flutterSdkPath"

class FlutterAppPluginLoaderPlugin : Plugin<Settings> {
    override fun apply(settings: Settings) {
        val flutterProjectRoot: File = settings.settingsDir.parentFile

        if (!settings.extraProperties.has(FLUTTER_SDK_PATH)) {
            val properties = Properties()
            val localPropertiesFile = File(settings.rootProject.projectDir, "local.properties")
            localPropertiesFile.inputStream().use { properties.load(it) }
            settings.extraProperties.set(FLUTTER_SDK_PATH, properties.getProperty("flutter.sdk"))
            assert(
                settings.extraProperties.get(FLUTTER_SDK_PATH) != null
            ) { "flutter.sdk not set in local.properties" }
        }

        settings.apply {
            from(
                Paths.get(
                    settings.extraProperties.get(FLUTTER_SDK_PATH) as String,
                    "packages",
                    "flutter_tools",
                    "gradle",
                    "src",
                    "main",
                    "scripts",
                    "native_plugin_loader.gradle.kts"
                )
            )
            to()
        }

        // TODO(gmackall): We should prioritize removing this awful reflection.
        val nativePluginLoader = settings.extraProperties.get("nativePluginLoader")!!
        val pluginList: List<*>? =
            (
                nativePluginLoader::class
                    .members
                    .firstOrNull { it.name == "getPlugins" }
                    ?.call(nativePluginLoader, flutterProjectRoot) as? List<*>
            )

        NativePluginLoaderReflectionBridge
            .getPlugins(settings.extraProperties, flutterProjectRoot)
            .forEach { androidPlugin ->
                val pluginDirectory = File(androidPlugin["path"] as String, "android")
                check(
                    pluginDirectory.exists()
                ) { "Plugin directory does not exist: ${pluginDirectory.absolutePath}" } // Replaced assert with check
                val pluginName = androidPlugin["name"] as String
                settings.include(":$pluginName")
                settings.project(":$pluginName").projectDir = pluginDirectory
            }
    }
}

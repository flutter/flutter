package com.flutter.gradle

import org.gradle.api.Plugin
import org.gradle.api.initialization.Settings
import java.io.File

class FlutterAppPluginLoaderPlugin : Plugin<Settings> {
    override fun apply(settings: Settings) {
        val flutterProjectRoot = settings.settingsDir.parentFile

        val nativePluginLoader = NativePluginLoader()
        // settings.extraProperties.set("nativePluginLoader", nativePluginLoader)
        val pluginList = nativePluginLoader.getPlugins(flutterProjectRoot)

        pluginList.forEach { androidPlugin ->
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

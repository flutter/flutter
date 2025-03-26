package com.flutter.gradle

import org.gradle.api.plugins.ExtraPropertiesExtension
import java.io.File

object NativePluginLoaderReflectionBridge {
    private var nativePluginLoader: Any? = null

    @JvmStatic
    fun getPlugins(
        extraProperties: ExtraPropertiesExtension,
        flutterProjectRoot: File
    ): List<Map<String, Any>> {
        if (nativePluginLoader == null) {
            nativePluginLoader = extraProperties.get("nativePluginLoader")!!
        }

        @Suppress("UNCHECKED_CAST")
        val pluginList: List<Map<String, Any>> =
            nativePluginLoader!!::class
                .members
                .firstOrNull { it.name == "getPlugins" }
                ?.call(nativePluginLoader, flutterProjectRoot) as List<Map<String, Any>>

        return pluginList
    }

    /**
     * Parses <project-src>/.flutter-plugins-dependencies
     */
    @JvmStatic
    fun getDependenciesMetadata(
        extraProperties: ExtraPropertiesExtension,
        flutterProjectRoot: File
    ): Map<String, Any> {
        if (nativePluginLoader == null) {
            nativePluginLoader = extraProperties.get("nativePluginLoader")!!
        }
        @Suppress("UNCHECKED_CAST")
        val dependenciesMetadata: Map<String, Any> =
            nativePluginLoader!!::class
                .members
                .firstOrNull { it.name == "dependenciesMetadata" }
                ?.call(nativePluginLoader, flutterProjectRoot) as Map<String, Any>

        return dependenciesMetadata
    }
}

package com.flutter.gradle.plugins

import com.flutter.gradle.FlutterPluginUtils
import com.flutter.gradle.NativePluginLoaderReflectionBridge
import org.gradle.api.Project
import org.jetbrains.kotlin.gradle.plugin.extraProperties

class PluginHandler(
    val project: Project
) {
    private var pluginList: List<Map<String?, Any?>>? = null
    private var pluginDependencies: List<Map<String?, Any?>>? = null

    /**
     * Gets the list of plugins (as map) that support the Android platform.
     *
     * The map value contains either the plugins `name` (String),
     * its `path` (String), or its `dependencies` (List<String>).
     * See [NativePluginLoader#getPlugins] in packages/flutter_tools/gradle/src/main/scripts/native_plugin_loader.gradle.kts
     */
    internal fun getPluginList(): List<Map<String?, Any?>> {
        if (pluginList == null) {
            pluginList =
                NativePluginLoaderReflectionBridge.getPlugins(
                    project.extraProperties,
                    FlutterPluginUtils.getFlutterSourceDirectory(project)
                )
        }
        return pluginList!!
    }
}

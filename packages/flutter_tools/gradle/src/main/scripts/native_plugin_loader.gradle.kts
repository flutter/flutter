// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import groovy.json.JsonSlurper
import java.io.File

// When changing the names of either
// 1. this file or
// 2. the names of the methods on this class
// be sure to also modify the corresponding values in ../kotlin/NativePluginLoaderReflectionBridge.kt
class NativePluginLoader {
    companion object {
        // This string must match _kFlutterPluginsHasNativeBuildKey defined in
        // packages/flutter_tools/lib/src/flutter_plugins.dart.
        const val NATIVE_BUILD_KEY = "native_build"
        const val FLUTTER_PLUGINS_DEPENDENCIES_FILE = ".flutter-plugins-dependencies"
    }

    /**
     * Gets the list of plugins that support the Android platform.
     * The list contains map elements with the following content:
     * {
     *     "name": "plugin-a",
     *     "path": "/path/to/plugin-a",
     *     "dependencies": ["plugin-b", "plugin-c"],
     *     "native_build": true
     *     "dev_dependency": false
     * }
     *
     * Therefore the map value can either be a `String`, a `List<String>` or a `Boolean`.
     */
    fun getPlugins(flutterSourceDirectory: File): List<Map<String, Any>> {
        val nativePlugins = mutableListOf<Map<String, Any>>()
        val meta = getDependenciesMetadata(flutterSourceDirectory)
        if (meta == null) {
            return nativePlugins
        }

        val pluginsMap: Map<*, *> = (meta["plugins"] as? Map<*, *>) ?: error("Metadata 'plugins' is not a Map: $meta")
        val androidPluginsUntyped = pluginsMap["android"]
        if (androidPluginsUntyped == null) {
            return nativePlugins // Return empty list if android plugins are not found
        }
        val androidPlugins = androidPluginsUntyped as? List<*> ?: error("Metadata 'plugins.android' is not a List: $meta")

        // Includes the Flutter plugins that support the Android platform.
        androidPlugins.forEach { androidPluginUntyped ->
            val androidPlugin = androidPluginUntyped as? Map<*, *> ?: error("androidPlugin is not a Map: $androidPluginUntyped")

            // The property types can be found in _filterPluginsByPlatform defined in
            // packages/flutter_tools/lib/src/flutter_plugins.dart.
            check(androidPlugin["name"] is String) { "androidPlugin 'name' is not a String: $androidPlugin" }
            check(androidPlugin["path"] is String) { "androidPlugin 'path' is not a String: $androidPlugin" }
            check(androidPlugin["dependencies"] is List<*>) { "androidPlugin 'dependencies' is not a List: $androidPlugin" }
            check(androidPlugin["dev_dependency"] is Boolean) { "androidPlugin 'dev_dependency' is not a Boolean: $androidPlugin" }

            // Skip plugins that have no native build (such as a Dart-only implementation
            // of a federated plugin).
            val needsBuild = androidPlugin[NATIVE_BUILD_KEY] as? Boolean ?: true
            if (needsBuild) {
                // Suppress the unchecked cast warning as we define the structure of the JSON in
                // the tool and we have already mostly validated the structure.
                @Suppress("UNCHECKED_CAST")
                nativePlugins.add(androidPlugin as Map<String, Any>)
            }
        }
        return nativePlugins.toList() // Return immutable list
    }

    private var parsedFlutterPluginsDependencies: Map<String, Any>? = null

    /**
     * Parses <project-src>/.flutter-plugins-dependencies
     */
    fun getDependenciesMetadata(flutterSourceDirectory: File): Map<String, Any>? {
        // Consider a `.flutter-plugins-dependencies` file with the following content:
        // {
        //     "plugins": {
        //       "android": [
        //         {
        //           "name": "plugin-a",
        //           "path": "/path/to/plugin-a",
        //           "dependencies": ["plugin-b", "plugin-c"],
        //           "native_build": true
        //           "dev_dependency": false
        //         },
        //         {
        //           "name": "plugin-b",
        //           "path": "/path/to/plugin-b",
        //           "dependencies": ["plugin-c"],
        //           "native_build": true
        //           "dev_dependency": false
        //         },
        //         {
        //           "name": "plugin-c",
        //           "path": "/path/to/plugin-c",
        //           "dependencies": [],
        //           "native_build": true
        //           "dev_dependency": false
        //         },
        //         {
        //           "name": "plugin-d",
        //           "path": "/path/to/plugin-d",
        //           "dependencies": [],
        //           "native_build": true
        //           "dev_dependency": true
        //         },
        //       ],
        //     },
        //     "dependencyGraph": [
        //       {
        //         "name": "plugin-a",
        //         "dependencies": ["plugin-b","plugin-c"]
        //       },
        //       {
        //         "name": "plugin-b",
        //         "dependencies": ["plugin-c"]
        //       },
        //       {
        //         "name": "plugin-c",
        //         "dependencies": []
        //       },
        //       {
        //         "name": "plugin-d",
        //         "dependencies": []
        //       }
        //     ]
        // }
        // This means, `plugin-a` depends on `plugin-b` and `plugin-c`.
        // `plugin-b` depends on `plugin-c`.
        // `plugin-c` doesn't depend on anything.
        // `plugin-d` also doesn't depend on anything, but it is a dev
        // dependency to the Flutter project, so it is marked as such.
        if (parsedFlutterPluginsDependencies != null) {
            return parsedFlutterPluginsDependencies
        }
        val pluginsDependencyFile = File(flutterSourceDirectory, FLUTTER_PLUGINS_DEPENDENCIES_FILE)
        if (pluginsDependencyFile.exists()) {
            val slurper = JsonSlurper()
            val readText = slurper.parseText(pluginsDependencyFile.readText())

            // Suppress the unchecked cast warning as we define the structure of the JSON in the tool.
            @Suppress("UNCHECKED_CAST")
            val parsedText =
                readText as? Map<String, Any>
                    ?: error("Parsed JSON is not a Map<String, Any>: $readText")
            parsedFlutterPluginsDependencies = parsedText
            return parsedText
        }
        return null
    }
}

extra["nativePluginLoader"] = NativePluginLoader()

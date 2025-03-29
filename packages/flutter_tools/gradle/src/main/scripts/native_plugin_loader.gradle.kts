// blah

import groovy.json.JsonSlurper
import java.io.File

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

        check(meta["plugins"] is Map<*, *>) { "Metadata 'plugins' is not a Map: $meta" }
        val androidPluginsUntyped = (meta["plugins"] as Map<*, *>?)?.get("android")
        if (androidPluginsUntyped == null) {
            return nativePlugins // Return empty list if android plugins are not found
        }
        check(androidPluginsUntyped is List<*>) { "Metadata 'plugins.android' is not a List: $meta" }
        val androidPlugins = androidPluginsUntyped as List<*>

        // Includes the Flutter plugins that support the Android platform.
        androidPlugins.forEach { androidPluginUntyped ->
            check(androidPluginUntyped is Map<*, *>) { "androidPlugin is not a Map: $androidPluginUntyped" }
            val androidPlugin = androidPluginUntyped as Map<*, *>

            // The property types can be found in _filterPluginsByPlatform defined in
            // packages/flutter_tools/lib/src/flutter_plugins.dart.
            check(androidPlugin["name"] is String) { "androidPlugin 'name' is not a String: $androidPlugin" }
            check(androidPlugin["path"] is String) { "androidPlugin 'path' is not a String: $androidPlugin" }
            check(androidPlugin["dependencies"] is List<*>) { "androidPlugin 'dependencies' is not a List: $androidPlugin" }
            check(androidPlugin["dev_dependency"] is Boolean) { "androidPlugin 'dev_dependency' is not a Boolean: $androidPlugin" }

            // Skip plugins that have no native build (such as a Dart-only implementation
            // of a federated plugin).
            val needsBuild =
                if (androidPlugin.containsKey(NATIVE_BUILD_KEY)) {
                    androidPlugin[NATIVE_BUILD_KEY] as? Boolean ?: true // Default to true if not a boolean
                } else {
                    true
                }
            if (needsBuild) {
                nativePlugins.add(androidPlugin as Map<String, Any>) // Safe cast when adding, assuming type is now validated
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
        // { ... (example content as in the original Groovy code) ... }
        // This means, `plugin-a` depends on `plugin-b` and `plugin-c`.
        // ... (rest of the comment as in the original Groovy code) ...
        if (parsedFlutterPluginsDependencies != null) {
            return parsedFlutterPluginsDependencies
        }
        val pluginsDependencyFile = File(flutterSourceDirectory, FLUTTER_PLUGINS_DEPENDENCIES_FILE)
        if (pluginsDependencyFile.exists()) {
            val slurper = JsonSlurper()
            val objectUntyped = slurper.parseText(pluginsDependencyFile.readText())
            check(objectUntyped is Map<*, *>) { "Parsed JSON is not a Map: $objectUntyped" }
            val objectTyped = objectUntyped as Map<String, Any> // Safe cast after check
            parsedFlutterPluginsDependencies = objectTyped
            return objectTyped
        }
        return null
    }
}

extra["nativePluginLoader"] = NativePluginLoader()

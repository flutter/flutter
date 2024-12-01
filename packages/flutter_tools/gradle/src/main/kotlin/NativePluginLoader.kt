import java.io.File
import groovy.json.JsonSlurper

class NativePluginLoader {

    // This string must match _kFlutterPluginsHasNativeBuildKey defined in
    // packages/flutter_tools/lib/src/flutter_plugins.dart.
    companion object {
        const val nativeBuildKey = "native_build"
        const val flutterPluginsDependenciesFile = ".flutter-plugins-dependencies"
    }

    /**
     * Gets the list of plugins that support the Android platform.
     * The list contains map elements with the following content:
     * {
     *     "name": "plugin-a",
     *     "path": "/path/to/plugin-a",
     *     "dependencies": ["plugin-b", "plugin-c"],
     *     "native_build": true
     * }
     *
     * Therefore the map value can either be a `String`, a `List<String>` or a `boolean`.
     */
    fun getPlugins(flutterSourceDirectory: File): List<Map<String, Any>> {
        val nativePlugins = mutableListOf<Map<String, Any>>()
        val meta = getDependenciesMetadata(flutterSourceDirectory)
        if (meta == null) {
            return nativePlugins
        }

        val plugins = meta["plugins"] as? Map<String, Any>
        val androidPlugins = plugins?.get("android") as? List<Map<String, Any>> ?: return nativePlugins

        // Includes the Flutter plugins that support the Android platform.
        for (androidPlugin in androidPlugins) {
            // The property types can be found in _filterPluginsByPlatform defined in
            // packages/flutter_tools/lib/src/flutter_plugins.dart.
            val name = androidPlugin["name"] as? String
            val path = androidPlugin["path"] as? String
            val dependencies = androidPlugin["dependencies"] as? List<String>

            if (name != null && path != null && dependencies != null) {
                // Skip plugins that have no native build (such as a Dart-only implementation
                // of a federated plugin).
                val needsBuild = androidPlugin.getOrDefault(nativeBuildKey, true) as Boolean
                if (needsBuild) {
                    nativePlugins.add(androidPlugin)
                }
            }
        }
        return nativePlugins
    }

    private var parsedFlutterPluginsDependencies: Map<String, Any>? = null

    /**
     * Parses <project-src>/.flutter-plugins-dependencies
     */
    fun getDependenciesMetadata(flutterSourceDirectory: File): Map<String, Any>? {
        if (parsedFlutterPluginsDependencies != null) {
            return parsedFlutterPluginsDependencies
        }

        val pluginsDependencyFile = File(flutterSourceDirectory, flutterPluginsDependenciesFile)
        if (pluginsDependencyFile.exists()) {
            val jsonSlurper = JsonSlurper()
            val objectParsed = jsonSlurper.parseText(pluginsDependencyFile.readText())
            if (objectParsed is Map<*, *>) {
                parsedFlutterPluginsDependencies = objectParsed as Map<String, Any>
                return objectParsed
            }
        }
        return null
    }
}

// Usage example (similar to Groovy's `ext`):
val nativePluginLoader = NativePluginLoader()

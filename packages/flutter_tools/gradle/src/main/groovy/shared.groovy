import groovy.json.JsonSlurper

class NativePluginLoader {
    NativePluginLoader() {}

    // This string must match _kFlutterPluginsHasNativeBuildKey defined in
    // packages/flutter_tools/lib/src/flutter_plugins.dart.
    static final String nativeBuildKey = 'native_build'
    static final String flutterPluginsDependenciesFile = '.flutter-plugins-dependencies'

    void forEachPlugin(File flutterSourceDirectory, Closure<Object> callback) {
        def meta = getDependenciesMetadata(flutterSourceDirectory)
        if (meta == null) {
            return
        }

        assert meta.plugins instanceof Map
        assert meta.plugins.android instanceof List
        // Includes the Flutter plugins that support the Android platform.
        meta.plugins.android.each { androidPlugin ->
            assert androidPlugin.name instanceof String
            assert androidPlugin.path instanceof String
            // Skip plugins that have no native build (such as a Dart-only implementation
            // of a federated plugin).
            def needsBuild = androidPlugin.containsKey(nativeBuildKey) ? androidPlugin[nativeBuildKey] : true
            if (!needsBuild) {
                return
            }
            callback(androidPlugin)
        }
    }


    private Map parsedFlutterPluginsDependencies

    /**
     * Parses <project-src>/.flutter-plugins-dependencies
     */
    private Map getDependenciesMetadata(File flutterSourceDirectory) {
        if (parsedFlutterPluginsDependencies) {
            return parsedFlutterPluginsDependencies
        }
        File pluginsDependencyFile = new File(flutterSourceDirectory, flutterPluginsDependenciesFile)
        if (pluginsDependencyFile.exists()) {
            def object = new JsonSlurper().parseText(pluginsDependencyFile.text)
            assert object instanceof Map
            parsedFlutterPluginsDependencies = object
            return object
        }
        return null
    }
}

ext {
    nativePluginLoader = new NativePluginLoader()
}

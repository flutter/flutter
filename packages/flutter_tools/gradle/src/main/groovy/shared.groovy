import groovy.json.JsonSlurper

class NativePluginLoader {
    NativePluginLoader() {}

    // This string must match _kFlutterPluginsHasNativeBuildKey defined in
    // packages/flutter_tools/lib/src/flutter_plugins.dart.
    static final String nativeBuildKey = 'native_build'
    static final String flutterPluginsDependenciesFile = '.flutter-plugins-dependencies'

    void forEachPlugin(File flutterSourceDirectory, Closure<Map<String, Object>> callback) {
        def meta = getDependenciesMetadata(flutterSourceDirectory)
        if (meta == null) {
            return
        }

        assert meta.plugins instanceof Map<String, Object>
        assert meta.plugins.android instanceof List<Map<String, Object>>
        // Includes the Flutter plugins that support the Android platform.
        meta.plugins.android.each { androidPlugin ->
            // The properties are written to the file here:
            // https://github.com/flutter/flutter/blob/e33d4b86270e3c012ba13d68d6e90f2eabc4912b/packages/flutter_tools/lib/src/flutter_plugins.dart#L116
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


    private Map<String, Object> parsedFlutterPluginsDependencies

    /**
     * Parses <project-src>/.flutter-plugins-dependencies
     */
    Map<String, Object> getDependenciesMetadata(File flutterSourceDirectory) {
        if (parsedFlutterPluginsDependencies) {
            return parsedFlutterPluginsDependencies
        }
        File pluginsDependencyFile = new File(flutterSourceDirectory, flutterPluginsDependenciesFile)
        if (pluginsDependencyFile.exists()) {
            def object = new JsonSlurper().parseText(pluginsDependencyFile.text)
            assert object instanceof Map<String, Object>
            parsedFlutterPluginsDependencies = object
            return object
        }
        return null
    }
}

ext {
    nativePluginLoader = new NativePluginLoader()
}

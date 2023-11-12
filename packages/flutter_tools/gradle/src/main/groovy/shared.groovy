import groovy.json.JsonSlurper

class NativePluginLoader {
    NativePluginLoader() {}

    // This string must match _kFlutterPluginsHasNativeBuildKey defined in
    // packages/flutter_tools/lib/src/flutter_plugins.dart.
    static final String nativeBuildKey = 'native_build'
    static final String flutterPluginsDependenciesFile = '.flutter-plugins-dependencies'

    List<Map<String, Object>> getPlugins(File flutterSourceDirectory) {
        List<Map<String, Object>> nativePlugins = []
        def meta = getDependenciesMetadata(flutterSourceDirectory)
        if (meta == null) {
            return nativePlugins
        }

        assert meta.plugins instanceof Map<String, Object>
        def androidPlugins = meta.plugins.android
        assert androidPlugins instanceof List<Map<String, Object>>
        // Includes the Flutter plugins that support the Android platform.
        androidPlugins.each { androidPlugin ->
            // The property types can be found in _filterPluginsByPlatform defined in
            // packages/flutter_tools/lib/src/flutter_plugins.dart.
            assert androidPlugin.name instanceof String
            assert androidPlugin.path instanceof String
            // Skip plugins that have no native build (such as a Dart-only implementation
            // of a federated plugin).
            def needsBuild = androidPlugin.containsKey(nativeBuildKey) ? androidPlugin[nativeBuildKey] : true
            if (needsBuild) {
                nativePlugins.add(androidPlugin)
            }
        }
        return nativePlugins
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

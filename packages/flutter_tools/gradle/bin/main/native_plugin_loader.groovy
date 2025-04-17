// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import groovy.json.JsonSlurper

class NativePluginLoader {

    // This string must match _kFlutterPluginsHasNativeBuildKey defined in
    // packages/flutter_tools/lib/src/flutter_plugins.dart.
    static final String nativeBuildKey = "native_build"
    static final String flutterPluginsDependenciesFile = ".flutter-plugins-dependencies"

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
    List<Map<String, Object>> getPlugins(File flutterSourceDirectory) {
        List<Map<String, Object>> nativePlugins = []
        def meta = getDependenciesMetadata(flutterSourceDirectory)
        if (meta == null) {
            return nativePlugins
        }

        assert(meta.plugins instanceof Map<String, Object>)
        def androidPlugins = meta.plugins.android
        assert(androidPlugins instanceof List<Map>)
        // Includes the Flutter plugins that support the Android platform.
        androidPlugins.each { Map<String, Object> androidPlugin ->
            // The property types can be found in _filterPluginsByPlatform defined in
            // packages/flutter_tools/lib/src/flutter_plugins.dart.
            assert(androidPlugin.name instanceof String)
            assert(androidPlugin.path instanceof String)
            assert(androidPlugin.dependencies instanceof List<String>)
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
        // Consider a `.flutter-plugins-dependencies` file with the following content:
        // {
        //     "plugins": {
        //       "android": [
        //         {
        //           "name": "plugin-a",
        //           "path": "/path/to/plugin-a",
        //           "dependencies": ["plugin-b", "plugin-c"],
        //           "native_build": true
        //         },
        //         {
        //           "name": "plugin-b",
        //           "path": "/path/to/plugin-b",
        //           "dependencies": ["plugin-c"],
        //           "native_build": true
        //         },
        //         {
        //           "name": "plugin-c",
        //           "path": "/path/to/plugin-c",
        //           "dependencies": [],
        //           "native_build": true
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
        //       }
        //     ]
        // }
        // This means, `plugin-a` depends on `plugin-b` and `plugin-c`.
        // `plugin-b` depends on `plugin-c`.
        // `plugin-c` doesn't depend on anything.
        if (parsedFlutterPluginsDependencies) {
            return parsedFlutterPluginsDependencies
        }
        File pluginsDependencyFile = new File(flutterSourceDirectory, flutterPluginsDependenciesFile)
        if (pluginsDependencyFile.exists()) {
            def object = new JsonSlurper().parseText(pluginsDependencyFile.text)
            assert(object instanceof Map<String, Object>)
            parsedFlutterPluginsDependencies = object
            return object
        }
        return null
    }
}

// TODO(135392): Remove and use declarative form when migrated
ext {
    nativePluginLoader = new NativePluginLoader()
}

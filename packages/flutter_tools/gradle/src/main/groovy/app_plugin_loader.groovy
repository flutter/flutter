import groovy.json.JsonSlurper
import org.gradle.api.Plugin
import org.gradle.api.initialization.Settings

apply plugin: FlutterAppPluginLoaderPlugin

class FlutterAppPluginLoaderPlugin implements Plugin<Settings> {
    // This string must match _kFlutterPluginsHasNativeBuildKey defined in
    // packages/flutter_tools/lib/src/flutter_plugins.dart.
    private final String nativeBuildKey = 'native_build'

    @Override
    void apply(Settings settings) {
        def flutterProjectRoot = settings.settingsDir.parentFile

        // If this logic is changed, also change the logic in module_plugin_loader.gradle.
        def pluginsFile = new File(flutterProjectRoot, '.flutter-plugins-dependencies')
        if (!pluginsFile.exists()) {
            return
        }
<<<<<<< HEAD
=======

        // Load shared gradle functions
        settings.apply from: Paths.get(settings.ext.flutterSdkPath, "packages", "flutter_tools", "gradle", "src", "main", "groovy", "native_plugin_loader.groovy")
>>>>>>> 8495dee1fd4aacbe9de707e7581203232f591b2f

        def object = new JsonSlurper().parseText(pluginsFile.text)
        assert object instanceof Map
        assert object.plugins instanceof Map
        assert object.plugins.android instanceof List
        // Includes the Flutter plugins that support the Android platform.
        object.plugins.android.each { androidPlugin ->
            assert androidPlugin.name instanceof String
            assert androidPlugin.path instanceof String
            // Skip plugins that have no native build (such as a Dart-only implementation
            // of a federated plugin).
            def needsBuild = androidPlugin.containsKey(nativeBuildKey) ? androidPlugin[nativeBuildKey] : true
            if (!needsBuild) {
                return
            }
            def pluginDirectory = new File(androidPlugin.path, 'android')
            assert pluginDirectory.exists()
            settings.include(":${androidPlugin.name}")
            settings.project(":${androidPlugin.name}").projectDir = pluginDirectory
        }
    }
}

import groovy.json.JsonSlurper
import org.gradle.api.Plugin
import org.gradle.api.initialization.Settings

apply plugin: FlutterAppPluginLoaderPlugin

class FlutterAppPluginLoaderPlugin implements Plugin<Settings> {
    @Override
    void apply(Settings settings) {
        def flutterProjectRoot = settings.settingsDir.parentFile

        // If this logic is changed, also change the logic in module_plugin_loader.gradle.
        def pluginsFile = new File(flutterProjectRoot, '.flutter-plugins-dependencies')
        if (!pluginsFile.exists()) {
            return
        }

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
            def needsBuild = androidPlugin.containsKey('native_build') ? androidPlugin['native_build'] : true
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

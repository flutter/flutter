import org.gradle.api.Plugin
import org.gradle.api.initialization.Settings

apply plugin: FlutterAppPluginLoaderPlugin

class FlutterAppPluginLoaderPlugin implements Plugin<Settings> {
    @Override
    void apply(Settings settings) {
        def flutterProjectRoot = settings.settingsDir.parentFile
        NativePluginLoader.forEachPlugin(flutterProjectRoot, { androidPlugin ->
            def pluginDirectory = new File(androidPlugin.path, 'android')
            assert pluginDirectory.exists()
            settings.include(":${androidPlugin.name}")
            settings.project(":${androidPlugin.name}").projectDir = pluginDirectory
        })
    }
}

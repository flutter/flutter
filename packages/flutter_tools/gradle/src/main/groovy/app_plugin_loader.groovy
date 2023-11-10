import org.gradle.api.Plugin
import org.gradle.api.initialization.Settings
import NativePluginLoader

apply plugin: FlutterAppPluginLoaderPlugin

class FlutterAppPluginLoaderPlugin implements Plugin<Settings> {
    @Override
    void apply(Settings settings) {
        def flutterProjectRoot = settings.settingsDir.parentFile
        NativePluginLoader.forEachNativePlugin(flutterProjectRoot, { androidPlugin ->
            def pluginDirectory = new File(androidPlugin.path, 'android')
            assert pluginDirectory.exists()
            settings.include(":${androidPlugin.name}")
            settings.project(":${androidPlugin.name}").projectDir = pluginDirectory
        })
    }
}

import org.gradle.api.Plugin
import org.gradle.api.initialization.Settings

def pathToThisDirectory = buildscript.sourceFile.parentFile
apply from: "$pathToThisDirectory/shared.groovy"
apply plugin: FlutterAppPluginLoaderPlugin

class FlutterAppPluginLoaderPlugin implements Plugin<Settings> {
    @Override
    void apply(Settings settings) {
        def flutterProjectRoot = settings.settingsDir.parentFile
        settings.ext.nativePluginLoader.forEachPlugin(flutterProjectRoot, { androidPlugin ->
            def pluginDirectory = new File(androidPlugin.path, 'android')
            assert pluginDirectory.exists()
            settings.include(":${androidPlugin.name}")
            settings.project(":${androidPlugin.name}").projectDir = pluginDirectory
        })
    }
}

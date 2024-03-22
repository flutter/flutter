import org.gradle.api.Plugin
import org.gradle.api.initialization.Settings

import java.nio.file.Paths

apply plugin: FlutterAppPluginLoaderPlugin

class FlutterAppPluginLoaderPlugin implements Plugin<Settings> {
    @Override
    void apply(Settings settings) {
        def flutterProjectRoot = settings.settingsDir.parentFile

        if(!settings.ext.hasProperty('flutterSdkPath')) {
            def properties = new Properties()
            def localPropertiesFile = new File(settings.rootProject.projectDir, "local.properties")
            localPropertiesFile.withInputStream { properties.load(it) }
            settings.ext.flutterSdkPath = properties.getProperty("flutter.sdk")
            assert settings.ext.flutterSdkPath != null, "flutter.sdk not set in local.properties"
        }
        
        // Load shared gradle functions
        settings.apply from: Paths.get(settings.ext.flutterSdkPath, "packages", "flutter_tools", "gradle", "src", "main", "groovy", "native_plugin_loader.groovy")

        List<Map<String, Object>> nativePlugins = settings.ext.nativePluginLoader.getPlugins(flutterProjectRoot)
        nativePlugins.each { androidPlugin ->
            def pluginDirectory = new File(androidPlugin.path as String, 'android')
            assert pluginDirectory.exists()
            settings.include(":${androidPlugin.name}")
            settings.project(":${androidPlugin.name}").projectDir = pluginDirectory
        }
    }
}

import org.gradle.api.Plugin
import org.gradle.api.initialization.Settings
import java.io.File
import java.nio.file.Paths
import java.util.Properties

class FlutterAppPluginLoaderPlugin : Plugin<Settings> {
    override fun apply(settings: Settings) {
        val flutterProjectRoot = settings.settingsDir.parentFile

        if (!settings.extensions.extraProperties.has("flutterSdkPath")) {
            val properties = Properties()
            val localPropertiesFile = File(settings.rootProject.projectDir, "local.properties")
            localPropertiesFile.inputStream().use { properties.load(it) }
            val flutterSdkPath: String =
                properties.getProperty("flutter.sdk")
                    ?: throw IllegalStateException("flutter.sdk not set in local.properties")
            settings.extensions.extraProperties["flutterSdkPath"] = flutterSdkPath
        }

        val flutterSdkPath = settings.extensions.extraProperties["flutterSdkPath"] as String

        // Load shared gradle functions
        settings.apply {
            it
                .from(
                    Paths.get(
                        flutterSdkPath,
                        "packages",
                        "flutter_tools",
                        "gradle",
                        "src",
                        "main",
                        "groovy",
                        "native_plugin_loader.groovy",
                    ),
                )
        }

        val nativePluginLoader = settings.extensions.extraProperties["nativePluginLoader"]
        val nativePlugins = nativePluginLoader?.getPlugins(flutterProjectRoot) as List<Map<String, Any>>
        nativePlugins.forEach { androidPlugin: Map<String, Any> ->
            val pluginDirectory = File(androidPlugin["path"] as String, "android")
            check(pluginDirectory.exists()) { "Plugin directory does not exist: $pluginDirectory" }
            val projectName = ":${androidPlugin["name"]}"
            settings.include(projectName)
            settings.project(projectName).projectDir = pluginDirectory
        }
    }
}

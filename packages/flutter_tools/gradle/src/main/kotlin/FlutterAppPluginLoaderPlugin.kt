import org.gradle.api.Plugin
import org.gradle.api.initialization.Settings
import java.io.File
import java.nio.file.Paths
import java.util.Properties

class FlutterAppPluginLoaderPlugin : Plugin<Settings> {
    override fun apply(settings: Settings) {
        val flutterProjectRoot = settings.settingsDir.parentFile
            ?: throw IllegalStateException("settingsDir.parentFile is null. Ensure the settings directory is properly configured.")

        if (!settings.extra.has("flutterSdkPath")) {
            val properties = Properties()
            val localPropertiesFile = File(settings.rootDir, "local.properties")
            if (localPropertiesFile.exists()) {
                localPropertiesFile.inputStream().use { properties.load(it) }
            } else {
                throw IllegalStateException("local.properties file not found in the project root.")
            }

            val flutterSdkPath: String = properties.getProperty("flutter.sdk")
                ?: throw IllegalStateException("flutter.sdk is not set in local.properties. Add flutter.sdk to local.properties.")
            settings.extra["flutterSdkPath"] = flutterSdkPath
        }

        val flutterSdkPath = settings.extra["flutterSdkPath"] as? String
            ?: throw IllegalStateException("flutterSdkPath could not be resolved.")

        // Load shared Gradle functions
        val nativePluginLoaderPath = Paths.get(
            flutterSdkPath,
            "packages",
            "flutter_tools",
            "gradle",
            "src",
            "main",
            "groovy",
            "native_plugin_loader.groovy"
        ).toFile()

        if (!nativePluginLoaderPath.exists()) {
            throw IllegalStateException("Native plugin loader file not found: $nativePluginLoaderPath")
        }

        settings.apply {
            it.from(nativePluginLoaderPath)
        }

        val nativePluginLoader = settings.extra["nativePluginLoader"]
    ?: throw IllegalStateException("nativePluginLoader is not set. Ensure the native plugin loader is correctly applied.")

// Use reflection to call getPlugins
val method = nativePluginLoader.javaClass.getMethod("getPlugins", File::class.java)
val nativePlugins = method.invoke(nativePluginLoader, flutterProjectRoot) as? List<Map<String, Any>>
    ?: throw IllegalStateException("Failed to load native plugins. Ensure the nativePluginLoader is configured correctly.")

nativePlugins.forEach { androidPlugin: Map<String, Any> ->
    val pluginPath = androidPlugin["path"] as? String
        ?: throw IllegalStateException("Plugin path is missing for a native plugin.")
    val pluginDirectory = File(pluginPath, "android")
    check(pluginDirectory.exists()) { "Plugin directory does not exist: $pluginDirectory" }

    val projectName = ":${androidPlugin["name"]}"
    settings.include(projectName)
    settings.project(projectName).projectDir = pluginDirectory
}

    }
}

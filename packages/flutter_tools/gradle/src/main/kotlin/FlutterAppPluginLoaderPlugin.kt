import org.gradle.api.Plugin
import org.gradle.api.initialization.Settings
import java.io.File
import java.util.Properties
import javax.json.Json
import javax.json.JsonObject

class FlutterAppPluginLoaderPlugin : Plugin<Settings> {

    override fun apply(settings: Settings) {
        val flutterProjectRoot = settings.settingsDir.parentFile

        if (!settings.extensions.extraProperties.has("flutterSdkPath")) {
            val properties = Properties()
            val localPropertiesFile = File(settings.rootDir, "local.properties")
            localPropertiesFile.inputStream().use { properties.load(it) }
            val flutterSdkPath: String =
                properties.getProperty("flutter.sdk")
                    ?: throw IllegalStateException("flutter.sdk not set in local.properties")
            settings.extensions.extraProperties["flutterSdkPath"] = flutterSdkPath
        }

        val flutterSdkPath = settings.extensions.extraProperties["flutterSdkPath"] as String

        // Load shared gradle functions
        settings.apply {
            it.from(
                File(
                    flutterSdkPath,
                    "packages/flutter_tools/gradle/src/main/groovy/native_plugin_loader.groovy"
                )
            )
        }

        val nativePluginLoader = NativePluginLoader()
        val nativePlugins = nativePluginLoader.getPlugins(flutterProjectRoot)
        nativePlugins.forEach { androidPlugin ->
            val pluginPath = androidPlugin["path"] as String
            val pluginDirectory = File(pluginPath, "android")
            check(pluginDirectory.exists()) { "Plugin directory does not exist: $pluginDirectory" }
            val projectName = ":${androidPlugin["name"]}"
            settings.include(projectName)
            settings.project(projectName).projectDir = pluginDirectory
        }
    }

    class NativePluginLoader {

        private val nativeBuildKey = "native_build"
        private val flutterPluginsDependenciesFile = ".flutter-plugins-dependencies"
        private var parsedFlutterPluginsDependencies: JsonObject? = null

        fun getPlugins(flutterSourceDirectory: File): List<Map<String, Any>> {
            val nativePlugins = mutableListOf<Map<String, Any>>()
            val meta = getDependenciesMetadata(flutterSourceDirectory) ?: return nativePlugins

            val plugins = meta.getJsonObject("plugins")
            val androidPlugins = plugins.getJsonArray("android")

            androidPlugins.forEach { jsonElement ->
                val androidPlugin = jsonElement as JsonObject
                val needsBuild = androidPlugin.getBoolean(nativeBuildKey, true)

                if (needsBuild) {
                    val pluginMap = mapOf(
                        "name" to androidPlugin.getString("name"),
                        "path" to androidPlugin.getString("path"),
                        "dependencies" to androidPlugin.getJsonArray("dependencies")
                            .map { it.toString() },
                        nativeBuildKey to needsBuild
                    )
                    nativePlugins.add(pluginMap)
                }
            }
            return nativePlugins
        }

        private fun getDependenciesMetadata(flutterSourceDirectory: File): JsonObject? {
            if (parsedFlutterPluginsDependencies != null) {
                return parsedFlutterPluginsDependencies
            }

            val pluginsDependencyFile = File(flutterSourceDirectory, flutterPluginsDependenciesFile)
            if (pluginsDependencyFile.exists()) {
                val jsonReader = Json.createReader(pluginsDependencyFile.inputStream())
                val jsonObject = jsonReader.readObject()
                parsedFlutterPluginsDependencies = jsonObject
                return jsonObject
            }

            return null
        }
    }
}

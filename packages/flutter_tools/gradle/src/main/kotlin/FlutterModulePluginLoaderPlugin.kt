package com.flutter.gradle

import org.gradle.api.Plugin
import org.gradle.api.initialization.Settings
import java.io.File

class FlutterModulePluginLoaderPlugin : Plugin<Settings> {
    override fun apply(settings: Settings) {
        println("hi gray in FlutterModulePluginLoaderPlugin")
        val flutterProjectRoot = settings.settingsDir.parentFile

        val nativePluginLoader = NativePluginLoader()
        // settings.extraProperties.set("nativePluginLoader", nativePluginLoader)
        val pluginList = nativePluginLoader.getPlugins(flutterProjectRoot)

        pluginList.forEach { androidPlugin ->
            val pluginDirectory = File(androidPlugin["path"] as String, "android")
            check(
                pluginDirectory.exists()
            ) { "Plugin directory does not exist: ${pluginDirectory.absolutePath}" } // Replaced assert with check
            val pluginName = androidPlugin["name"] as String
            settings.include(":$pluginName")
            settings.project(":$pluginName").projectDir = pluginDirectory
        }
        println("hi gray")
        loadModulePluginsLogic(settings, flutterProjectRoot)
    }

    fun loadModulePluginsLogic(
        settings: Settings,
        flutterProjectRoot: File
    ) {
        val pathToThisDirectory: File? = settings.buildscript.sourceFile?.parentFile
        val nativePluginLoader: NativePluginLoader = NativePluginLoader()
        //        val moduleProjectRoot: File =
        //            settings
        //                .project("$flutterProjectRoot")
        //                .projectDir.parentFile.parentFile
        val nativePlugins: List<Map<String, Any>> =
            nativePluginLoader.getPlugins(flutterProjectRoot)
        nativePlugins.forEach { androidPlugin ->
            val pluginDirectory = File(androidPlugin["path"] as String, "android")
            check(pluginDirectory.exists()) { "Plugin directory does not exist: ${pluginDirectory.absolutePath}" }
            val pluginName = androidPlugin["name"] as String
            settings.include(":$pluginName")
            settings.project(":$pluginName").projectDir = pluginDirectory
        }

        settings.gradle.projectsLoaded {
            rootProject.beforeEvaluate {
                subprojects {
                    if (nativePlugins.filter { plugin -> plugin["name"] == name }.isNotEmpty()) {
                        // todo gmackall this path is wrong
                        val androidPluginBuildOutputDir =
                            File(flutterProjectRoot.path + File.separator + "plugins_build_output" + File.separator + name)
                        if (!androidPluginBuildOutputDir.exists()) {
                            androidPluginBuildOutputDir.mkdirs()
                        }
                        layout.buildDirectory.fileValue(androidPluginBuildOutputDir)
                    }
                }
//                val _mainModuleName = binding.variables["mainModuleName"]
//                if (_mainModuleName != null && _mainModuleName.isNotEmpty()) {
//                    ext.mainModuleName = _mainModuleName
//                }
            }
            rootProject.afterEvaluate {
                subprojects {
                    if (name != "flutter") {
                        evaluationDependsOn(":flutter")
                    }
                }
            }
        }
    }
}

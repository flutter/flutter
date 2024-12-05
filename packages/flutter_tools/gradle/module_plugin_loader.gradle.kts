import java.nio.file.Paths
import org.gradle.api.Project
import org.gradle.api.tasks.ProjectExecutionException
import java.io.File

val pathToThisDirectory = buildscript.sourceFile.parentFile
apply(from = Paths.get(pathToThisDirectory.absolutePath, "src", "main", "groovy", "native_plugin_loader.groovy"))

val moduleProjectRoot = project(":flutter").projectDir.parentFile.parentFile

// Accessing the nativePluginLoader from the 'ext' block
val nativePluginLoader = project.extra["nativePluginLoader"] as NativePluginLoader
val nativePlugins = nativePluginLoader.getPlugins(moduleProjectRoot)

nativePlugins.forEach { androidPlugin ->
    val pluginDirectory = File(androidPlugin["path"] as String, "android")
    check(pluginDirectory.exists()) { "Plugin directory does not exist: $pluginDirectory" }
    include(":${androidPlugin["name"]}")
    project(":${androidPlugin["name"]}").projectDir = pluginDirectory
}

val flutterModulePath = project(":flutter").projectDir.parentFile.absolutePath
gradle.projectsLoaded {
        gradleInstance -> gradleInstance.rootProject.beforeEvaluate {
        project -> project.subprojects { subproject ->
    if (nativePlugins.any { it["name"] == subproject.name }) {
        val androidPluginBuildOutputDir = File(flutterModulePath + File.separator + "plugins_build_output" + File.separator + subproject.name)
        if (!androidPluginBuildOutputDir.exists()) {
            androidPluginBuildOutputDir.mkdirs()
        }
        subproject.layout.buildDirectory.fileValue(androidPluginBuildOutputDir)
    }
}
    val mainModuleName = binding.variables["mainModuleName"]
    if (mainModuleName != null && mainModuleName.toString().isNotEmpty()) {
        project.ext["mainModuleName"] = mainModuleName
    }
}
    gradleInstance.rootProject.afterEvaluate { project ->
        project.subprojects { subproject ->
            if (subproject.name != "flutter") {
                subproject.evaluationDependsOn(":flutter")
            }
        }
    }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import java.nio.file.Paths
import org.gradle.api.Project
import org.gradle.api.initialization.dsl.ScriptHandler

val pathToThisDirectory: File = buildscript.sourceFile!!.parentFile
apply(from = Paths.get(pathToThisDirectory.absolutePath, "src", "main", "groovy", "native_plugin_loader.groovy").toFile())

val moduleProjectRoot = project(":flutter").projectDir.parentFile.parentFile

@Suppress("UNCHECKED_CAST")
val nativePlugins: List<Map<String, Any?>> = nativePluginLoader.getPlugins(moduleProjectRoot) as List<Map<String, Any?>>()

nativePlugins.forEach { androidPlugin ->
    val pluginDirectory = File(androidPlugin["path"] as String, "android")
    check(pluginDirectory.exists()) { "Plugin directory does not exist: ${pluginDirectory.absolutePath}" }
    include(":${androidPlugin["name"]}")
    project(":${androidPlugin["name"]}").projectDir = pluginDirectory
}

val flutterModulePath = project(":flutter").projectDir.parentFile.absolutePath

gradle.projectsLoaded { gradleInstance ->
    gradleInstance.rootProject.beforeEvaluate { project ->
        project.subprojects { subproject ->
            if (nativePlugins.any { it["name"] == subproject.name }) {
                val androidPluginBuildOutputDir = File(flutterModulePath + File.separator +
                        "plugins_build_output" + File.separator + subproject.name)
                if (!androidPluginBuildOutputDir.exists()) {
                    androidPluginBuildOutputDir.mkdirs()
                }
                subproject.layout.buildDirectory.fileValue(androidPluginBuildOutputDir)
            }
        }

        val mainModuleName: String? = findProperty("mainModuleName") as? String
        if (!mainModuleName.isNullOrEmpty()) {
            project.extensions.extraProperties["mainModuleName"] = mainModuleName
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

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is included from `<module>/.android/include_flutter.kts`,
// so it can be versioned with the Flutter SDK.

import java.nio.file.Paths

val pathToThisDirectory = buildscript.sourceFile!!.parentFile
apply(from = Paths.get(pathToThisDirectory.absolutePath, "src", "main", "kotlin", "NativePluginLoader.kt").toFile())

val moduleProjectRoot = project(":flutter").projectDir.parentFile!!.parentFile!!

val nativePlugins: List<Map<String, Any>> = nativePluginLoader.getPlugins(moduleProjectRoot)
nativePlugins.forEach { androidPlugin ->
    val pluginDirectory = File(androidPlugin["path"] as String, "android")
    check(pluginDirectory.exists()) { "Plugin directory does not exist: $pluginDirectory" }
    include(":${androidPlugin["name"]}")
    project(":${androidPlugin["name"]}").projectDir = pluginDirectory
}

val flutterModulePath = project(":flutter").projectDir.parentFile!!.absolutePath
gradle.projectsLoaded { g ->
    g.rootProject.beforeEvaluate { p ->
        p.subprojects { subproject ->
            if (nativePlugins.any { it["name"] == subproject.name }) {
                val androidPluginBuildOutputDir = File(
                    flutterModulePath + File.separator +
                            "plugins_build_output" + File.separator + subproject.name
                )
                if (!androidPluginBuildOutputDir.exists()) {
                    androidPluginBuildOutputDir.mkdirs()
                }
                subproject.layout.buildDirectory.fileValue(androidPluginBuildOutputDir)
            }
        }
        val mainModuleName = p.findProperty("mainModuleName") as String?
        if (!mainModuleName.isNullOrEmpty()) {
            p.extensions.extraProperties["mainModuleName"] = mainModuleName
        }
    }
    g.rootProject.afterEvaluate { p ->
        p.subprojects { sp ->
            if (sp.name != "flutter") {
                sp.evaluationDependsOn(":flutter")
            }
        }
    }
}

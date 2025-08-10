// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import com.flutter.gradle.FlutterPluginConstants
import org.gradle.api.Project
import org.gradle.api.file.CopySpec
import org.gradle.api.file.FileCollection
import java.io.File

/**
 * Stateless object to contain the logic used in [FlutterTask]. Any required state should be stored
 * on [FlutterTask] instead, while any logic needed by [FlutterTask] should be added here.
 */
object FlutterTaskHelper {
    const val FLUTTER_ASSETS_INCLUDE_DIRECTORY = "flutter_assets/**"

    internal fun getOutputDirectory(flutterTask: FlutterTask): File? = flutterTask.intermediateDir

    internal fun getAssetsDirectory(flutterTask: FlutterTask): String = "${flutterTask.outputDirectory}/flutter_assets"

    internal fun getAssets(
        project: Project,
        flutterTask: FlutterTask
    ): CopySpec =
        project.copySpec {
            from("${flutterTask.intermediateDir}")
            include(FLUTTER_ASSETS_INCLUDE_DIRECTORY) // the working dir and its files
        }

    internal fun getSnapshots(
        project: Project,
        flutterTask: FlutterTask
    ): CopySpec =
        project.copySpec {
            from("${flutterTask.intermediateDir}")
            if (flutterTask.buildMode == "release" || flutterTask.buildMode == "profile") {
                flutterTask.targetPlatformValues!!.forEach { targetArch ->
                    include("${FlutterPluginConstants.PLATFORM_ARCH_MAP[targetArch]}/app.so")
                }
            }
        }

    private fun readDependencies(
        project: Project,
        dependenciesFile: File,
        inputs: Boolean
    ): FileCollection {
        if (dependenciesFile.exists()) {
            // Dependencies file has Makefile syntax:
            //   <target> <files>: <source> <files> <separated> <by> <non-escaped space>
            val depText = dependenciesFile.readText()
            // So we split list of files by non-escaped(by backslash) space,
            val parts = depText.split(": ")
            val fileString = parts[if (inputs) 1 else 0]
            val matcher = Regex("""(\\ |\S)+""").findAll(fileString)
            // then we replace all escaped spaces with regular spaces
            val depList =
                matcher.map { it.value.replace("\\\\ ", " ") }.toList()
            return project.files(depList)
        }
        return project.files()
    }

    internal fun getSourceFiles(
        project: Project,
        flutterTask: FlutterTask
    ): FileCollection {
        var sources: FileCollection = project.files()
        flutterTask.getDependenciesFiles().forEach { dependenciesFile ->
            sources += readDependencies(project, dependenciesFile, true)
        }
        return sources + project.files("pubspec.yaml")
    }

    internal fun getOutputFiles(
        project: Project,
        flutterTask: FlutterTask
    ): FileCollection {
        var outputs: FileCollection = project.files()
        flutterTask.getDependenciesFiles().forEach { dependenciesFile ->
            outputs += readDependencies(project, dependenciesFile, false)
        }
        return outputs
    }

    internal fun build(flutterTask: FlutterTask) {
        flutterTask.buildBundle()
    }
}

package com.flutter.gradle

import org.gradle.api.file.CopySpec
import org.gradle.api.file.FileCollection
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.Internal
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.OutputFiles
import org.gradle.api.tasks.TaskAction
import java.io.File

abstract class FlutterTask : BaseFlutterTask() {
    @OutputDirectory
    fun getOutputDirectory(): File? = intermediateDir

    @Internal
    fun getAssetsDirectory(): String = "${getOutputDirectory()}/flutter_assets"

    @Internal
    fun getAssets(): CopySpec =
        project.copySpec {
            from("$intermediateDir")
            include("flutter_assets/**") // the working dir and its files
        }

    @Internal
    fun getSnapshots(): CopySpec =
        project.copySpec {
            from("$intermediateDir")
            if (buildMode == "release" || buildMode == "profile") {
                targetPlatformValues!!.forEach { _ ->
                    include("TODO/app.so")
                }
            }
        }

    private fun readDependencies(
        dependenciesFile: File,
        inputs: Boolean
    ): FileCollection {
        if (dependenciesFile.exists()) {
            // Dependencies file has Makefile syntax:
            //   <target> <files>: <source> <files> <separated> <by> <non-escaped space>
            val depText = dependenciesFile.readText() // Kotlin way to read file text
            // So we split list of files by non-escaped(by backslash) space,
            val parts = depText.split(": ")
            val fileString = parts[if (inputs) 1 else 0]
            val matcher = Regex("""(\\ |\S)+""").findAll(fileString) // Kotlin Regex
            // then we replace all escaped spaces with regular spaces
            val depList = matcher.map { it.value.replace("\\\\ ", " ") }.toList() // Kotlin map and toList
            return project.files(depList)
        }
        return project.files()
    }

    @InputFiles
    fun getSourceFiles(): FileCollection {
        var sources: FileCollection = project.files()
        getDependenciesFiles().forEach { dependenciesFile ->
            sources += readDependencies(dependenciesFile, true)
        }
        return sources + project.files("pubspec.yaml")
    }

    @OutputFiles
    fun getOutputFiles(): FileCollection {
        var outputs: FileCollection = project.files()
        getDependenciesFiles().forEach { dependenciesFile ->
            outputs += readDependencies(dependenciesFile, false)
        }
        return outputs
    }

    @TaskAction
    fun build() {
        buildBundle()
    }
}

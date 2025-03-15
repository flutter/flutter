package com.flutter.gradle

import org.gradle.api.Project
import org.gradle.api.file.FileCollection
import java.io.File

object FlutterTaskHelper {
    private fun readDependencies(
        project: Project,
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

//    fun getSourceFiles(project: Project): FileCollection {
//        var sources: FileCollection = project.files()
//        BaseFlutterTask.getDependenciesFiles().forEach { dependenciesFile ->
//            sources += readDependencies(dependenciesFile, true)
//        }
//        return sources + project.files("pubspec.yaml")
//    }
}

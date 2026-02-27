package com.flutter.gradle.tasks

import com.flutter.gradle.VersionFetcher
import org.gradle.api.DefaultTask
import org.gradle.api.tasks.TaskAction

abstract class PrintKgpTask : DefaultTask() {
    init {
        description = "Print the current kgp version used by the project."
    }

    @TaskAction
    fun run() {
        println("Kgp version: ${VersionFetcher.getKGPVersion(project)}")
    }
}

package com.flutter.gradle.tasks

import org.gradle.api.DefaultTask
import org.gradle.api.provider.Property
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.TaskAction

/**
 * Task to print the current Kotlin Gradle Plugin version used by the project.
 */
abstract class PrintKgpTask : DefaultTask() {
    /**
     * KGP version captured at configuration time. The task action only reads
     * this property so it does not need to call [org.gradle.api.Task.getProject]
     * during execution. See:
     * https://docs.gradle.org/current/userguide/upgrading_version_8.html#task_project
     */
    @get:Input
    abstract val kgpVersion: Property<String>

    init {
        description = "Print the current kgp version used by the project."
    }

    @TaskAction
    fun run() {
        println("KGP Version: ${kgpVersion.get()}")
    }
}

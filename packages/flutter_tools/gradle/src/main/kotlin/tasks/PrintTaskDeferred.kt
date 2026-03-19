package com.flutter.gradle.tasks

import org.gradle.api.DefaultTask
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.TaskAction

abstract class PrintTaskDeferred<T> : DefaultTask() {
    @get:Input
    abstract var closureInput: T

    @get:Input
    abstract var messageClosure: (input: T) -> String

    @TaskAction
    fun run() {
        println(messageClosure(closureInput))
    }
}

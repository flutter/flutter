package com.flutter.gradle.tasks

import org.gradle.api.DefaultTask
import org.gradle.api.provider.Property
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.TaskAction

abstract class PrintTask : DefaultTask() {
    @get:Input
    abstract val message: Property<String>

    @TaskAction
    fun run() {
        println(message.get())
    }
}

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

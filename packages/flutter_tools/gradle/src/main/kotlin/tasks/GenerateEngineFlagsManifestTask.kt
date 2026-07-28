package com.flutter.gradle.tasks

import groovy.json.JsonSlurper
import org.gradle.api.DefaultTask
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.TaskAction
import java.util.Base64
import java.nio.charset.StandardCharsets

abstract class GenerateEngineFlagsManifestTask : DefaultTask() {
    @get:Input
    abstract val engineShellArgsJson: Property<String>

    @get:OutputFile
    abstract val manifestOutputFile: RegularFileProperty

    @TaskAction
    fun generateManifest() {
        val base64Encoded = engineShellArgsJson.get()
        val decodedJsonStr = String(Base64.getDecoder().decode(base64Encoded), StandardCharsets.UTF_8)
        
        val jsonSlurper = JsonSlurper()
        val jsonObject = jsonSlurper.parseText(decodedJsonStr) as Map<*, *>

        val stringBuilder = StringBuilder()
        stringBuilder.append("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n")
        stringBuilder.append("<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\">\n")
        stringBuilder.append("    <application>\n")

        for ((key, value) in jsonObject) {
            stringBuilder.append("        <meta-data android:name=\"$key\" android:value=\"$value\" />\n")
        }

        stringBuilder.append("    </application>\n")
        stringBuilder.append("</manifest>")

        val outputFile = manifestOutputFile.get().asFile
        outputFile.parentFile.mkdirs()
        outputFile.writeText(stringBuilder.toString())
    }
}

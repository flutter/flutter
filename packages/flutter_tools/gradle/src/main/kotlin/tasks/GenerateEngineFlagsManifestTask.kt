package com.flutter.gradle.tasks

import groovy.json.JsonSlurper
import org.gradle.api.DefaultTask
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.TaskAction
import java.nio.charset.StandardCharsets
import java.util.Base64

abstract class GenerateEngineFlagsManifestTask : DefaultTask() {
    @get:Input
    abstract val engineShellArgsJson: Property<String>

    @get:OutputFile
    abstract val manifestOutputFile: RegularFileProperty

    @TaskAction
    fun generateManifest() {
        val base64Encoded = engineShellArgsJson.get()
        val decodedJsonStr = String(Base64.getDecoder().decode(base64Encoded), StandardCharsets.UTF_8)
        val escapedValue = escapeXml(decodedJsonStr)
        val metaDataTags = "<meta-data android:name=\"io.flutter.app.androidEngineShellArgs\" android:value=\"$escapedValue\" />"

        val manifestContent =
            """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android">
                <application>
                    $metaDataTags
                </application>
            </manifest>
            """.trimIndent()

        val outputFile = manifestOutputFile.get().asFile
        outputFile.parentFile.mkdirs()
        outputFile.writeText(manifestContent)
    }

    private fun escapeXml(str: String): String =
        str
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&apos;")
}

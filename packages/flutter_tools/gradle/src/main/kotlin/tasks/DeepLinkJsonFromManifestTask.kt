package com.flutter.gradle.tasks

import org.gradle.api.DefaultTask
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputFile
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.TaskAction
import kotlin.io.writeText

abstract class DeepLinkJsonFromManifestTask : DefaultTask() {
    // Input property to receive the manifest file
    @get:InputFile
    abstract val manifestFile: RegularFileProperty

    // Example: A property to hold a custom value to add to the manifest
    @get:Input
    abstract val customManifestValue: Property<String>

    // Does not need to transform manifest at all but there does not appear to be another dsl
    // supported way to depend on the merged manifest.
    @get:OutputFile
    abstract val updatedManifest: RegularFileProperty

    @get:OutputFile
    abstract val deepLinkJson: RegularFileProperty

    @TaskAction
    fun processManifest() {
        val manifest = manifestFile.get().asFile
        logger.lifecycle("Processing manifest: ${manifest.absolutePath}")

        // Example: Read and print existing content
        manifest.readLines().forEach { line ->
            logger.lifecycle("Manifest line: $line")
        }

        // Example: Modify the manifest (e.g., add a custom attribute)
        // This would involve XML parsing and manipulation,
        // which is beyond a simple example, but illustrates the concept.
        // For actual modification, you'd use an XML library.
        val modifiedContent =
            """
            <manifest ...>
                <application ...>
                    <meta-data android:name="com.example.CUSTOM_VALUE" android:value="${customManifestValue.get()}"/>
                </application>
            </manifest>
            """.trimIndent()
        updatedManifest.asFile.get().writeText(manifest.readText())
        deepLinkJson.asFile.get().writeText(modifiedContent)

        // For this example, we're just logging, but in a real scenario,
        // you'd write the modified content back to the manifestFile or a new output file.
        // manifest.writeText(modifiedContent)
        logger.lifecycle("Manifest processing complete (simulated modification).")
    }
}

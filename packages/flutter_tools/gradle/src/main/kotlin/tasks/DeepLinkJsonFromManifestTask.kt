package com.flutter.gradle.tasks

import com.flutter.gradle.FlutterPluginUtils
import groovy.util.Node
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

    // In the past for this task namespace was the ApplicationId.
    @get:Input
    abstract val namespace: Property<String>

    // Does not need to transform manifest at all but there does not appear to be another dsl
    // supported way to depend on the merged manifest.
    @get:OutputFile
    abstract val updatedManifest: RegularFileProperty

    @get:OutputFile
    abstract val deepLinkJson: RegularFileProperty

    @TaskAction
    fun processManifest() {
        val manifestFile = manifestFile.get().asFile
        logger.lifecycle("DeepLinkJsonFromManifestTask start.")
        updatedManifest.asFile.get().writeText(manifestFile.readText())
        val manifestNode: Node =
            groovy.xml
                .XmlParser(false, false)
                .parse(manifestFile)

        val appLinkSettings = FlutterPluginUtils.createAppLinkSettings(namespace.get(), manifestNode)
        deepLinkJson.asFile.get().writeText(appLinkSettings.toJson().toString())

        logger.lifecycle("DeepLinkJsonFromManifestTask complete.")
    }
}

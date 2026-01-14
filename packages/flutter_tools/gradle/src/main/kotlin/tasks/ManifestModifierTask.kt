// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import org.gradle.api.DefaultTask
import groovy.util.Node
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputFile
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.TaskAction

abstract class ManifestModifierTask : DefaultTask() {
    // Input property to receive the manifest file
    @get:InputFile
    abstract val manifestFile: RegularFileProperty

    // Input Android engine shell arguments as String
    @get:Input
    abstract val androidEngineShellArgsStr: Property<String>

    // Modified manifest output by this task
    @get:OutputFile
    abstract val updatedManifestFile: RegularFileProperty

    @TaskAction
    fun modifyManifest() {
        println("CAMILLE: androidEngineShellArgsStr")
        println(androidEngineShellArgsStr.get())

        val manifest: Node =
            groovy.xml
                .XmlParser(false, false)
                .parse(manifestFile.get().asFile)
        val applicationNode: Node? =
            manifest.children().find { node ->
                node is Node && node.name() == "application"
            } as Node?

        // We are attempting to modify the wrong manifest file. Do not attempt to modify.
        if (applicationNode == null) {
            return
        }

        applicationNode.appendNode("meta-data", mapOf(
            "android:name" to "androidEngineShellArgs",
            "android:value" to androidEngineShellArgsStr.get()
        ))

        updatedManifestFile.get().asFile.bufferedWriter().use { writer ->
            groovy.xml.XmlUtil.serialize(manifest, writer)
        }

        /////////////// IMPLEMENTATION WITHOUT XMLPARSER BELOW: ///////////////
        // val originalManifestText = manifestFile.get().asFile.readText()
        // val updatedManifestText = originalManifestText.replace(
        //     "</application>",
        //     "    <meta-data android:name=\"androidEngineShellArgs\" android:value=\"${androidEngineShellArgsStr.get()}\" />\n    </application>"
        // )
        // updatedManifestFile.get().asFile.writeText(updatedManifestText)
    }
}
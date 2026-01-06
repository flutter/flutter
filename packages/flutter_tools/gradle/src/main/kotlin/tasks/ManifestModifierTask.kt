// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import org.gradle.api.DefaultTask
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
        // TODO(camsim99): try out xml parser instead for safety
        val originalManifestText = manifestFile.get().asFile.readText()
        // val androidEngineShellArgs = androidEngineShellArgsStr.split(',')
        val updatedManifestText = originalManifestText.replace(
            "</application>",
            "    <meta-data android:name=\"androidEngineShellArgs\" android:value=\"${androidEngineShellArgsStr.get()}\" />\n    </application>"
        )
        // println("CAMILLE: ManifestModifierTask print out:")
        // println(updatedManifestText)
        updatedManifestFile.get().asFile.writeText(updatedManifestText)
    }
}
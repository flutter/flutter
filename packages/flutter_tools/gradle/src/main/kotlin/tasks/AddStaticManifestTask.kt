// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import org.gradle.api.DefaultTask
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.TaskAction

abstract class AddStaticManifestTask : DefaultTask() {
    @get:Input
    abstract val shellArgs: Property<String>

    @get:OutputFile
    abstract val manifestOutputFile: RegularFileProperty

    @TaskAction
    fun generate() {
        val outputFile = manifestOutputFile.get().asFile
        val content = """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android">
                <application>
                    <meta-data
                        android:name="androidEngineShellArgs"
                        android:value="${shellArgs.get()}" />
                </application>
            </manifest>
        """.trimIndent()
        
        outputFile.writeText(content)
    }
}

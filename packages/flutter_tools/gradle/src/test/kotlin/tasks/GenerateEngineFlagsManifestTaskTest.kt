// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import org.gradle.testfixtures.ProjectBuilder
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.io.TempDir
import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class GenerateEngineFlagsManifestTaskTest {
    @TempDir
    lateinit var testProjectDir: File

    private lateinit var task: GenerateEngineFlagsManifestTask

    @BeforeEach
    fun setup() {
        val project =
            ProjectBuilder
                .builder()
                .withProjectDir(testProjectDir)
                .build()

        task = project.tasks.create("generateManifest", GenerateEngineFlagsManifestTask::class.java)
    }

    @Test
    fun generateHandlesOneArgCorrectly() {
        val shellArg = "--verbose-logging"
        val manifestOutputFile = File(testProjectDir, "AndroidManifest.xml")
        val expectedContent =
            """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android">
                <application>
                    <meta-data
                        android:name="androidEngineShellArgs"
                        android:value="$shellArg" />
                </application>
            </manifest>
            """.trimIndent()

        task.shellArgs.set(shellArg)
        task.manifestOutputFile.set(manifestOutputFile)

        task.generate()

        assertTrue(manifestOutputFile.exists(), "Output file should be created")
        assertEquals(expectedContent, manifestOutputFile.readText())
    }

    @Test
    fun generateHandlesMultipleArgsCorrectly() {
        val shellArgs = "--enable-dart-profiling,--trace-to-file=path/to/some/file"
        val manifestOutputFile = File(testProjectDir, "AndroidManifest.xml")
        val expectedContent =
            """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android">
                <application>
                    <meta-data
                        android:name="androidEngineShellArgs"
                        android:value="$shellArgs" />
                </application>
            </manifest>
            """.trimIndent()

        task.shellArgs.set(shellArgs)
        task.manifestOutputFile.set(manifestOutputFile)

        task.generate()

        assertTrue(manifestOutputFile.exists(), "Output file should be created")
        assertEquals(expectedContent, manifestOutputFile.readText())
    }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import org.gradle.testfixtures.ProjectBuilder
import java.io.File
import java.util.Base64
import kotlin.test.Test
import kotlin.test.assertEquals

class GenerateEngineFlagsManifestTaskTest {
    private fun setupTask(): Pair<GenerateEngineFlagsManifestTask, File> {
        val project = ProjectBuilder.builder().build()
        val task =
            project.tasks
                .register(
                    "generateEngineFlagsManifestTest",
                    GenerateEngineFlagsManifestTask::class.java
                ).get()
        val outputFile = File.createTempFile("AndroidManifest", ".xml")
        outputFile.deleteOnExit()
        return Pair(task, outputFile)
    }

    private fun encodeJsonMap(json: String): String = Base64.getEncoder().encodeToString(json.toByteArray(Charsets.UTF_8))

    @Test
    fun generateHandlesNoArgsCorrectly() {
        val (task, outputFile) = setupTask()
        val jsonStr = "[]"
        task.engineShellArgsJson.set(encodeJsonMap(jsonStr))
        task.manifestOutputFile.set(outputFile)

        task.generateManifest()

        val expectedContent =
            """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android">
                <application>
                    <meta-data android:name="io.flutter.app.androidEngineShellArgs" android:value="[]" />
                </application>
            </manifest>
            """.trimIndent()

        assertEquals(expectedContent, outputFile.readText())
    }

    @Test
    fun generateHandlesOneArgCorrectly() {
        val (task, outputFile) = setupTask()
        val jsonStr = """["--enable-impeller"]"""
        task.engineShellArgsJson.set(encodeJsonMap(jsonStr))
        task.manifestOutputFile.set(outputFile)

        task.generateManifest()

        val expectedContent =
            """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android">
                <application>
                    <meta-data android:name="io.flutter.app.androidEngineShellArgs" android:value="[&quot;--enable-impeller&quot;]" />
                </application>
            </manifest>
            """.trimIndent()

        assertEquals(expectedContent, outputFile.readText())
    }

    @Test
    fun generateHandlesMultipleArgsCorrectly() {
        val (task, outputFile) = setupTask()
        val jsonStr = """["--enable-impeller=true","--trace-systrace","--old-gen-heap-size=100"]"""
        task.engineShellArgsJson.set(encodeJsonMap(jsonStr))
        task.manifestOutputFile.set(outputFile)

        task.generateManifest()

        val expectedContent =
            """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android">
                <application>
                    <meta-data android:name="io.flutter.app.androidEngineShellArgs" android:value="[&quot;--enable-impeller=true&quot;,&quot;--trace-systrace&quot;,&quot;--old-gen-heap-size=100&quot;]" />
                </application>
            </manifest>
            """.trimIndent()

        assertEquals(expectedContent, outputFile.readText())
    }

    @Test
    fun generateHandlesArgsWithBackSlashes() {
        val (task, outputFile) = setupTask()
        val jsonStr = """["--trace-to-file=\"path/to/a file\""]"""
        task.engineShellArgsJson.set(encodeJsonMap(jsonStr))
        task.manifestOutputFile.set(outputFile)

        task.generateManifest()

        val expectedContent =
            """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android">
                <application>
                    <meta-data android:name="io.flutter.app.androidEngineShellArgs" android:value="[&quot;--trace-to-file=\&quot;path/to/a file\&quot;&quot;]" />
                </application>
            </manifest>
            """.trimIndent()

        assertEquals(expectedContent, outputFile.readText())
    }

    @Test
    fun generateHandlesArgsWithAmpersandCorrectly() {
        val (task, outputFile) = setupTask()
        val jsonStr = """["--some-arg=a&b"]"""
        task.engineShellArgsJson.set(encodeJsonMap(jsonStr))
        task.manifestOutputFile.set(outputFile)

        task.generateManifest()

        val expectedContent =
            """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android">
                <application>
                    <meta-data android:name="io.flutter.app.androidEngineShellArgs" android:value="[&quot;--some-arg=a&amp;b&quot;]" />
                </application>
            </manifest>
            """.trimIndent()

        assertEquals(expectedContent, outputFile.readText())
    }

    @Test
    fun generateHandlesArgsWithAngleBracketsCorrectly() {
        val (task, outputFile) = setupTask()
        val jsonStr = """["--some-arg=<a>"]"""
        task.engineShellArgsJson.set(encodeJsonMap(jsonStr))
        task.manifestOutputFile.set(outputFile)

        task.generateManifest()

        val expectedContent =
            """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android">
                <application>
                    <meta-data android:name="io.flutter.app.androidEngineShellArgs" android:value="[&quot;--some-arg=&lt;a&gt;&quot;]" />
                </application>
            </manifest>
            """.trimIndent()

        assertEquals(expectedContent, outputFile.readText())
    }

    @Test
    fun generateHandlesArgsWithSingleQuotesCorrectly() {
        val (task, outputFile) = setupTask()
        val jsonStr = """["--some-arg='a'"]"""
        task.engineShellArgsJson.set(encodeJsonMap(jsonStr))
        task.manifestOutputFile.set(outputFile)

        task.generateManifest()

        val expectedContent =
            """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android">
                <application>
                    <meta-data android:name="io.flutter.app.androidEngineShellArgs" android:value="[&quot;--some-arg=&apos;a&apos;&quot;]" />
                </application>
            </manifest>
            """.trimIndent()

        assertEquals(expectedContent, outputFile.readText())
    }
}

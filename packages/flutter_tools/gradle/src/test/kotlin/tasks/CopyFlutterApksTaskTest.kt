// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import com.android.build.api.variant.BuiltArtifact
import com.android.build.api.variant.BuiltArtifacts
import com.android.build.api.variant.BuiltArtifactsLoader
import com.flutter.gradle.testing.mockAbiFilters
import io.mockk.every
import io.mockk.mockk
import org.gradle.api.GradleException
import org.gradle.api.Project
import org.gradle.api.file.Directory
import org.gradle.testfixtures.ProjectBuilder
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.junit.jupiter.api.io.TempDir
import java.io.File
import java.nio.file.Path
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertFalse

class CopyFlutterApksTaskTest {
    @Test
    fun `apkFileName matches the names the Flutter tool looks for`() {
        assertEquals("app-release.apk", CopyFlutterApksTask.apkFileName(CopyFlutterApksTask.NO_ABI, null, "release"))
        assertEquals("app-debug.apk", CopyFlutterApksTask.apkFileName(CopyFlutterApksTask.NO_ABI, "", "debug"))
        assertEquals(
            "app-arm64-v8a-release.apk",
            CopyFlutterApksTask.apkFileName("arm64-v8a", null, "release")
        )
        // The flavor is lower-cased, matching the Flutter tool's lowerCasedFlavor.
        assertEquals(
            "app-x86_64-freestaging-profile.apk",
            CopyFlutterApksTask.apkFileName("x86_64", "freeStaging", "profile")
        )
    }

    @Test
    fun `copies split APKs under per-ABI names and declares exactly those files as outputs`(
        @TempDir tempDir: Path
    ) {
        val project = projectIn(tempDir)
        val apkDir = tempDir.resolve("apk").toFile()
        val armApk = writeApk(apkDir, "app-free-armeabi-v7a-release.apk")
        val arm64Apk = writeApk(apkDir, "app-free-arm64-v8a-release.apk")
        val destinationDir = tempDir.resolve("flutter-apk").toFile()

        val task =
            registerTask(
                project,
                apkDir = apkDir,
                destinationDir = destinationDir,
                outputAbis = listOf("armeabi-v7a", "arm64-v8a"),
                flavorName = "Free",
                buildMode = "release",
                loader = loaderFor(builtApk(armApk, "armeabi-v7a"), builtApk(arm64Apk, "arm64-v8a"))
            )

        task.copyApks()

        val armCopy = destinationDir.resolve("app-armeabi-v7a-free-release.apk")
        val arm64Copy = destinationDir.resolve("app-arm64-v8a-free-release.apk")
        assertEquals(setOf(armCopy, arm64Copy), destinationDir.listFiles()!!.toSet())
        assertEquals("app-free-armeabi-v7a-release.apk", armCopy.readText())
        assertEquals("app-free-arm64-v8a-release.apk", arm64Copy.readText())
        // Reading task.outputs also checks that Gradle resolves the provider.
        assertEquals(setOf(armCopy, arm64Copy), task.outputs.files.files)
    }

    @Test
    fun `copies the single APK of a build without ABI splits under the non-ABI name`(
        @TempDir tempDir: Path
    ) {
        val project = projectIn(tempDir)
        val apkDir = tempDir.resolve("apk").toFile()
        val apk = writeApk(apkDir, "custom-output-name.apk")
        val destinationDir = tempDir.resolve("flutter-apk").toFile()

        val task =
            registerTask(
                project,
                apkDir = apkDir,
                destinationDir = destinationDir,
                outputAbis = listOf(CopyFlutterApksTask.NO_ABI),
                flavorName = null,
                buildMode = "debug",
                loader = loaderFor(builtApk(apk, abi = null))
            )

        task.copyApks()

        assertEquals(setOf(destinationDir.resolve("app-debug.apk")), destinationDir.listFiles()!!.toSet())
        assertEquals(setOf(destinationDir.resolve("app-debug.apk")), task.outputs.files.files)
    }

    @Test
    fun `fails instead of writing an undeclared output when AGP built an unexpected ABI`(
        @TempDir tempDir: Path
    ) {
        val project = projectIn(tempDir)
        val apkDir = tempDir.resolve("apk").toFile()
        val apk = writeApk(apkDir, "app-x86_64-release.apk")
        val destinationDir = tempDir.resolve("flutter-apk").toFile()

        val task =
            registerTask(
                project,
                apkDir = apkDir,
                destinationDir = destinationDir,
                outputAbis = listOf("arm64-v8a"),
                flavorName = null,
                buildMode = "release",
                loader = loaderFor(builtApk(apk, "x86_64"))
            )

        val exception = assertThrows<GradleException> { task.copyApks() }
        assertContains(exception.message!!, "for ABI 'x86_64'")
        assertContains(exception.message!!, "transforms SingleArtifact.APK")
        assertFalse(exception.message!!.contains("github.com/flutter/flutter/issues"))
        assertFalse(destinationDir.resolve("app-x86_64-release.apk").exists())
    }

    @Test
    fun `fails with an actionable message when the APK metadata cannot be read`(
        @TempDir tempDir: Path
    ) {
        val project = projectIn(tempDir)
        val apkDir = tempDir.resolve("apk").toFile().apply { mkdirs() }
        val unreadableMetadataLoader = mockk<BuiltArtifactsLoader>()
        every { unreadableMetadataLoader.load(any<Directory>()) } returns null
        val task =
            registerTask(
                project,
                apkDir = apkDir,
                destinationDir = tempDir.resolve("flutter-apk").toFile(),
                outputAbis = listOf(CopyFlutterApksTask.NO_ABI),
                flavorName = null,
                buildMode = "release",
                loader = unreadableMetadataLoader
            )

        val exception = assertThrows<GradleException> { task.copyApks() }
        assertContains(exception.message!!, "could not read the APK metadata")
        assertContains(exception.message!!, "transforms SingleArtifact.APK")
        assertFalse(exception.message!!.contains("github.com/flutter/flutter/issues"))
    }

    private fun projectIn(tempDir: Path): Project = ProjectBuilder.builder().withProjectDir(tempDir.resolve("project").toFile()).build()

    private fun writeApk(
        apkDir: File,
        name: String
    ): File {
        apkDir.mkdirs()
        // The content is the source file name, so tests can check which file landed where.
        return apkDir.resolve(name).apply { writeText(name) }
    }

    /** A built APK as AGP's metadata describes it: its path and its ABI filter, if any. */
    private fun builtApk(
        apk: File,
        abi: String?
    ): BuiltArtifact {
        val artifact = mockk<BuiltArtifact>()
        every { artifact.outputFile } returns apk.absolutePath
        every { artifact.filters } returns mockAbiFilters(abi)
        return artifact
    }

    /** A loader whose metadata lists [builtArtifacts]. */
    private fun loaderFor(vararg builtArtifacts: BuiltArtifact): BuiltArtifactsLoader {
        val artifacts = mockk<BuiltArtifacts>()
        every { artifacts.elements } returns builtArtifacts.toList()
        val loader = mockk<BuiltArtifactsLoader>()
        every { loader.load(any<Directory>()) } returns artifacts
        return loader
    }

    private fun registerTask(
        project: Project,
        apkDir: File,
        destinationDir: File,
        outputAbis: List<String>,
        flavorName: String?,
        buildMode: String,
        loader: BuiltArtifactsLoader
    ): CopyFlutterApksTask =
        project.tasks.register("copyFlutterApksTest", CopyFlutterApksTask::class.java).get().also { task ->
            task.apkDirectory.set(apkDir)
            task.builtArtifactsLoader.set(loader)
            task.outputAbis.set(outputAbis)
            task.flavorName.set(flavorName)
            task.buildMode.set(buildMode)
            task.destinationDir.set(destinationDir)
        }
}

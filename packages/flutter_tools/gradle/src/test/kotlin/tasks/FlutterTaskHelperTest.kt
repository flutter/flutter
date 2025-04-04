// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import com.flutter.gradle.FlutterPluginConstants
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.gradle.api.Action
import org.gradle.api.Project
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.CopySpec
import org.gradle.api.file.FileCollection
import org.junit.jupiter.api.io.TempDir
import java.io.File
import java.nio.file.Path
import kotlin.test.Test

class FlutterTaskHelperTest {
    @Test
    fun `getAssetsDirectory returns correct path`() {
        val flutterTask = mockk<FlutterTask>()
        val mockFile = mockk<File>()
        val flutterTaskOutputDirectory = "/path/to/assets"
        val expectedPath = "$flutterTaskOutputDirectory/flutter_assets"

        every { flutterTask.outputDirectory } returns mockFile
        every { mockFile.toString() } returns flutterTaskOutputDirectory
        val result = FlutterTaskHelper.getAssetsDirectory(flutterTask)
        assert(result == expectedPath)
    }

    @Test
    fun `getAssets returns correct CopySpec`() {
        val project = mockk<Project>()
        val flutterTask = mockk<FlutterTask>()
        val mockFile = mockk<File>()
        val mockCopySpec = mockk<CopySpec>()
        val copySpecActionSlot = slot<Action<in CopySpec>>()
        val fakeFromPath = "/path/to/intermediate"

        every { flutterTask.intermediateDir } returns mockFile
        every { mockFile.toString() } returns fakeFromPath
        every { project.copySpec(capture(copySpecActionSlot)) } returns mockk()

        FlutterTaskHelper.getAssets(project, flutterTask)
        every { mockCopySpec.from(fakeFromPath) } returns mockCopySpec
        every { mockCopySpec.include(FlutterTaskHelper.FLUTTER_ASSETS_INCLUDE_DIRECTORY) } returns mockCopySpec
        copySpecActionSlot.captured.execute(mockCopySpec)
        verify { mockCopySpec.from(fakeFromPath) }
        verify { mockCopySpec.include(FlutterTaskHelper.FLUTTER_ASSETS_INCLUDE_DIRECTORY) }
    }

    @Test
    fun `getSnapshots returns correct CopySpec for release build`() {
        val project = mockk<Project>()
        val flutterTask = mockk<FlutterTask>()
        val mockCopySpec = mockk<CopySpec>()
        val copySpecActionSlot = slot<Action<in CopySpec>>()
        val fakeIntermediateDirectory = mockk<File>()
        val fakeIntermediateDirectoryPath = "/path/to/intermediate"

        every { flutterTask.intermediateDir } returns fakeIntermediateDirectory
        every { flutterTask.buildMode } returns "release"
        every { flutterTask.targetPlatformValues } returns listOf("arm64-v8a", "x64")
        every { fakeIntermediateDirectory.toString() } returns fakeIntermediateDirectoryPath
        every { project.copySpec(capture(copySpecActionSlot)) } returns mockk()

        FlutterTaskHelper.getSnapshots(project, flutterTask)
        every { mockCopySpec.from(fakeIntermediateDirectoryPath) } returns mockCopySpec
        every { mockCopySpec.include(any<String>()) } returns mockCopySpec
        copySpecActionSlot.captured.execute(mockCopySpec)

        verify { mockCopySpec.from(fakeIntermediateDirectoryPath) }
        verify { mockCopySpec.include("${FlutterPluginConstants.PLATFORM_ARCH_MAP["arm64-v8a"]}/app.so") }
        verify { mockCopySpec.include("${FlutterPluginConstants.PLATFORM_ARCH_MAP["x64"]}/app.so") }
    }

    @Test
    fun `getSnapshots returns correct CopySpec for debug build`() {
        val project = mockk<Project>()
        val flutterTask = mockk<FlutterTask>()
        val mockCopySpec = mockk<CopySpec>()
        val copySpecActionSlot = slot<Action<in CopySpec>>()
        val fakeIntermediateDirectory = mockk<File>()
        val fakeIntermediateDirectoryPath = "/path/to/intermediate"

        every { flutterTask.intermediateDir } returns fakeIntermediateDirectory
        every { flutterTask.buildMode } returns "debug"
        every { flutterTask.targetPlatformValues } returns listOf("arm64-v8a", "x64")
        every { fakeIntermediateDirectory.toString() } returns fakeIntermediateDirectoryPath
        every { project.copySpec(capture(copySpecActionSlot)) } returns mockk()

        FlutterTaskHelper.getSnapshots(project, flutterTask)
        every { mockCopySpec.from(fakeIntermediateDirectoryPath) } returns mockCopySpec
        every { mockCopySpec.include(any<String>()) } returns mockCopySpec
        copySpecActionSlot.captured.execute(mockCopySpec)

        verify { mockCopySpec.from(fakeIntermediateDirectoryPath) }
        verify(exactly = 0) { mockCopySpec.include(any<String>()) }
    }

    @Test
    fun `getSourceFiles returns files when dependenciesFile exists`(
        @TempDir tempDir: Path
    ) {
        val mockProjectFileCollection = mockk<ConfigurableFileCollection>(relaxed = true)
        val mockDependenciesFileCollection = mockk<FileCollection>()
        val project = mockk<Project>()
        val mockFlutterTask = mockk<FlutterTask>()

        every { project.files() } returns mockProjectFileCollection
        every { project.files(any()) } returns mockProjectFileCollection

        every { mockFlutterTask.intermediateDir } returns tempDir.toFile()
        every { mockFlutterTask.getDependenciesFiles() } returns mockDependenciesFileCollection
        val dependenciesFile =
            tempDir
                .resolve("${mockFlutterTask.intermediateDir}/flutter_build.d")
                .toFile()
        dependenciesFile.writeText(
            " ${tempDir.toFile().path}/pre/delimiter/one ${tempDir.toFile().path}/pre/delimiter/two: ${tempDir.toFile().path}/post/delimiter/one ${tempDir.toFile().path}/post/delimiter/two"
        )
        every { mockDependenciesFileCollection.iterator() } returns (mutableListOf(dependenciesFile).iterator())

        FlutterTaskHelper.getSourceFiles(project, mockFlutterTask)

        verify {
            project.files(
                listOf(
                    "${tempDir.toFile().path}/post/delimiter/one",
                    "${tempDir.toFile().path}/post/delimiter/two"
                )
            )
        }

        verify { project.files("pubspec.yaml") }
    }

    @Test
    fun `getOutputFiles returns files when dependenciesFile exists`(
        @TempDir tempDir: Path
    ) {
        val mockProjectFileCollection = mockk<ConfigurableFileCollection>(relaxed = true)
        val mockDependenciesFileCollection = mockk<FileCollection>()
        val project = mockk<Project>()
        val mockFlutterTask = mockk<FlutterTask>()

        every { project.files() } returns mockProjectFileCollection
        every { project.files(any()) } returns mockProjectFileCollection

        every { mockFlutterTask.intermediateDir } returns tempDir.toFile()
        every { mockFlutterTask.getDependenciesFiles() } returns mockDependenciesFileCollection
        val dependenciesFile =
            tempDir
                .resolve("${mockFlutterTask.intermediateDir}/flutter_build.d")
                .toFile()
        dependenciesFile.writeText(
            " ${tempDir.toFile().path}/pre/delimiter/one ${tempDir.toFile().path}/pre/delimiter/two: ${tempDir.toFile().path}/post/delimiter/one ${tempDir.toFile().path}/post/delimiter/two"
        )
        every { mockDependenciesFileCollection.iterator() } returns (mutableListOf(dependenciesFile).iterator())

        FlutterTaskHelper.getOutputFiles(project, mockFlutterTask)

        verify {
            project.files(
                listOf(
                    "${tempDir.toFile().path}/pre/delimiter/one",
                    "${tempDir.toFile().path}/pre/delimiter/two"
                )
            )
        }

        verify(exactly = 0) { project.files("pubspec.yaml") }
    }
}

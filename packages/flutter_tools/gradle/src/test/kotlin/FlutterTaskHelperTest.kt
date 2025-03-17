package com.flutter.gradle

import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.gradle.api.Action
import org.gradle.api.Project
import org.gradle.api.file.CopySpec
import java.io.File
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
    fun `readDependencies returns files when dependenciesFile exists`() {
    }
}

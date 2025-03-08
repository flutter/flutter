package com.flutter.gradle

import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.gradle.api.Project
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.process.ExecSpec
import org.gradle.process.ProcessForkOptions
import org.junit.jupiter.api.assertDoesNotThrow
import java.io.File
import java.nio.file.Paths
import kotlin.test.Test

class BaseFlutterTaskTest {
    private val sourceDirTest = File("/path/to/working_directory")
    private val flutterRootTest = File("/path/to/flutter")
    private val flutterRootAbsolutePathTest = "/path/to/flutter"
    private val flutterExecutableTest = File("/path/to/flutter/bin/flutter")
    private val flutterExecutableAbsolutPathTest = "/path/to/flutter/bin/flutter"
    private val localEngineTest = "android_debug_arm64"
    private val localEngineHostTest = "host_debug"
    private val localEngineSrcPathTest = "/path/to/flutter/engine/src"
    private val intermediateDirFileTest = File("/path/to/build/app/intermediates/flutter/release")
    private val performanceMeasurementFileTest = "/path/to/build/performance_file"
    private val dartDefinesTest = "ENVIRONMENT=development"
    private val flavorTest = "dev"
    private val frontendServerStarterPathTest = "/path/to/starter/script_file"
    private val extraFrontEndOptionsTest = "--enable-asserts"
    private val extraGenSnapshotOptionsTest = "--debugger"
    private val splitDebugInfoTest = "/path/to/build/debug_info_directory"
    private val codeSizeDirectoryTest = "/path/to/build/code_size_directory"
    private val minSDKVersionTest = 21
    private val bundleSkSLPathTest = "/path/to/custom/shaders"
    private val flutterTargetFilePath = "/path/to/flutter/examples/splash/lib/main.dart"
    private val flutterTargetPath = "/path/to/main.dart"
    private val targetPlatformValuesListREAL = listOf("android", "linux")
    private val targetPlatformValuesJoinedListREAL = "android linux"

    @Test
    fun `getDependencyFiles returns a FileCollection`() {
        val baseFlutterTask = mockk<BaseFlutterTask>()
        val project = mockk<Project>()
        val configFileCollection = mockk<ConfigurableFileCollection>()
        every { baseFlutterTask.sourceDir } returns sourceDirTest

        val helper = BaseFlutterTaskHelper(baseFlutterTask)

        every { baseFlutterTask.project } returns project
        every { baseFlutterTask.intermediateDir } returns intermediateDirFileTest

        val projectIntermediary = baseFlutterTask.project
        val interDirFile = baseFlutterTask.intermediateDir

        every { projectIntermediary.files() } returns configFileCollection
        every { projectIntermediary.files("$interDirFile/flutter_build.d") } returns configFileCollection
        every { configFileCollection.plus(configFileCollection) } returns configFileCollection

        helper.getDependenciesFiles()
        verify { projectIntermediary.files() }
        verify { projectIntermediary.files("$intermediateDirFileTest/flutter_build.d") }
    }

    @Test
    fun `buildBundle builds a Flutter application bundle for Android`() {
        val buildModeString = "debug"

        // Create necessary mocks.
        val baseFlutterTask = mockk<BaseFlutterTask>()
        val mockExecSpec = mockk<ExecSpec>()
        val mockProcessForkOptions = mockk<ProcessForkOptions>()

        // Check preconditions
        every { baseFlutterTask.sourceDir } returns sourceDirTest
        every { baseFlutterTask.sourceDir!!.isDirectory } returns true

        every { baseFlutterTask.intermediateDir } returns intermediateDirFileTest
        every { baseFlutterTask.intermediateDir.mkdirs() } returns false

        val helper = BaseFlutterTaskHelper(baseFlutterTask)
        assertDoesNotThrow { helper.checkPreConditions() }
    }
}

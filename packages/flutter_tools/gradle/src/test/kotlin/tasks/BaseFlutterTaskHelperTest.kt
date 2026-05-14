// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import com.flutter.gradle.DependencyVersionChecker
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.gradle.api.Action
import org.gradle.api.GradleException
import org.gradle.api.Project
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.logging.LoggingManager
import org.gradle.kotlin.dsl.support.serviceOf
import org.gradle.process.ExecOperations
import org.gradle.process.ExecSpec
import org.gradle.process.ProcessForkOptions
import org.junit.jupiter.api.assertDoesNotThrow
import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class BaseFlutterTaskHelperTest {
    object BaseFlutterTaskPropertiesTest {
        internal const val LOCAL_ENGINE_TEST = "android_debug_arm64"
        internal const val LOCAL_ENGINE_HOST_TEST = "host_debug"
        internal const val DART_DEFINES_TEST = "ENVIRONMENT=development"
        internal const val FLAVOR_TEST = "dev"
        internal const val EXTRA_FRONTEND_OPTIONS_TEST = "--enable-asserts"
        internal const val EXTRA_GEN_SNAPSHOT_OPTIONS_TEST = "--debugger"
        internal const val TARGET_PLATFORM_VALUES_JOINED_LIST = "android linux"
        val MIN_SDK_VERSION_TEST = DependencyVersionChecker.warnMinSdkVersion

        // Using File.separator to ensure all paths use platform-specific separators
        internal val FLUTTER_ROOT_ABSOLUTE_PATH_TEST = "/path/to/flutter".replace("/", File.separator)
        internal val FLUTTER_EXECUTABLE_ABSOLUTE_PATH_TEST = "/path/to/flutter/bin/flutter".replace("/", File.separator)
        internal val LOCAL_ENGINE_SRC_PATH_TEST = "/path/to/flutter/engine/src".replace("/", File.separator)
        internal val PERFORMANCE_MEASUREMENT_FILE_TEST = "/path/to/build/performance_file".replace("/", File.separator)
        internal val FRONTEND_SERVER_STARTER_PATH_TEST = "/path/to/starter/script_file".replace("/", File.separator)
        internal val SPLIT_DEBUG_INFO_TEST = "/path/to/build/debug_info_directory".replace("/", File.separator)
        internal val CODE_SIZE_DIRECTORY_TEST = "/path/to/build/code_size_directory".replace("/", File.separator)

        internal val BUNDLE_SK_SL_PATH_TEST = "/path/to/custom/shaders".replace("/", File.separator)
        internal val FLUTTER_TARGET_FILE_PATH = "/path/to/flutter/examples/splash/lib/main.dart".replace("/", File.separator)
        internal val FLUTTER_TARGET_PATH = "/path/to/main.dart".replace("/", File.separator)

        internal val sourceDirTest = File("/path/to/working_directory".replace("/", File.separator))
        internal val flutterRootTest = File("/path/to/flutter".replace("/", File.separator))
        internal val flutterExecutableTest = File("/path/to/flutter/bin/flutter".replace("/", File.separator))
        internal val intermediateDirFileTest = File("/path/to/build/app/intermediates/flutter/release".replace("/", File.separator))
        internal val targetPlatformValuesList = listOf("android", "linux")
    }

    @Test
    fun `checkPreConditions throws a GradleException when sourceDir is null`() {
        val baseFlutterTask = mockk<BaseFlutterTask>()
        every { baseFlutterTask.sourceDir } returns null

        val gradleException =
            assertFailsWith<GradleException> { BaseFlutterTaskHelper.checkPreConditions(baseFlutterTask) }
        assert(
            gradleException.message ==
                BaseFlutterTaskHelper.getGradleErrorMessage(baseFlutterTask)
        )
    }

    @Test
    fun `checkPreConditions throws a GradleException when sourceDir is not a directory`() {
        val baseFlutterTask = mockk<BaseFlutterTask>()
        every { baseFlutterTask.sourceDir } returns BaseFlutterTaskPropertiesTest.sourceDirTest
        every { baseFlutterTask.sourceDir!!.isDirectory } returns false

        val gradleException =
            assertFailsWith<GradleException> { BaseFlutterTaskHelper.checkPreConditions(baseFlutterTask) }
        assert(
            gradleException.message ==
                BaseFlutterTaskHelper.getGradleErrorMessage(baseFlutterTask)
        )
    }

    // TODO(jesswon): Add a test for intermediateDir is not valid during cleanup for handling NPEs.
    @Test
    fun `checkPreConditions does not throw a GradleException and intermediateDir is valid`() {
        val baseFlutterTask = mockk<BaseFlutterTask>()

        every { baseFlutterTask.sourceDir } returns BaseFlutterTaskPropertiesTest.sourceDirTest
        every { baseFlutterTask.sourceDir!!.isDirectory } returns true

        every { baseFlutterTask.intermediateDir } returns BaseFlutterTaskPropertiesTest.intermediateDirFileTest
        // There is already an intermediate directory, so there is no need to create it.
        every { baseFlutterTask.intermediateDir!!.mkdirs() } returns false

        assertDoesNotThrow { BaseFlutterTaskHelper.checkPreConditions(baseFlutterTask) }
    }

    @Test
    fun `generateRuleNames returns correct rule names when buildMode is debug`() {
        val buildModeString = "debug"

        val baseFlutterTask = mockk<BaseFlutterTask>()
        // When baseFlutterTask.sourceDir is null, an exception is thrown. We mock its return value
        // before creating a BaseFlutterTaskHelper object.
        every { baseFlutterTask.sourceDir } returns BaseFlutterTaskPropertiesTest.sourceDirTest
        every { baseFlutterTask.buildMode } returns buildModeString

        val ruleNamesList = BaseFlutterTaskHelper.generateRuleNames(baseFlutterTask)

        assertEquals(ruleNamesList, listOf("debug_android_application"))
    }

    @Test
    fun `generateRuleNames returns correct rule names when buildMode is not debug and deferredComponents is true`() {
        val buildModeString = "release"

        val baseFlutterTask = mockk<BaseFlutterTask>()
        // When baseFlutterTask.sourceDir is null, an exception is thrown. We mock its return value
        // before creating a BaseFlutterTaskHelper object.
        every { baseFlutterTask.sourceDir } returns BaseFlutterTaskPropertiesTest.sourceDirTest
        every { baseFlutterTask.buildMode } returns buildModeString
        every { baseFlutterTask.deferredComponents } returns true
        every { baseFlutterTask.targetPlatformValues } returns BaseFlutterTaskPropertiesTest.targetPlatformValuesList

        val ruleNamesList = BaseFlutterTaskHelper.generateRuleNames(baseFlutterTask)

        assertEquals(
            ruleNamesList,
            listOf(
                "android_aot_deferred_components_bundle_release_android",
                "android_aot_deferred_components_bundle_release_linux"
            )
        )
    }

    @Test
    fun `generateRuleNames returns correct rule names when buildMode is not debug and deferredComponents is false`() {
        val buildModeString = "release"

        val baseFlutterTask = mockk<BaseFlutterTask>()
        // When baseFlutterTask.sourceDir is null, an exception is thrown. We mock its return value
        // before creating a BaseFlutterTaskHelper object.
        every { baseFlutterTask.sourceDir } returns BaseFlutterTaskPropertiesTest.sourceDirTest
        every { baseFlutterTask.buildMode } returns buildModeString
        every { baseFlutterTask.deferredComponents } returns false
        every { baseFlutterTask.targetPlatformValues } returns BaseFlutterTaskPropertiesTest.targetPlatformValuesList

        val ruleNamesList = BaseFlutterTaskHelper.generateRuleNames(baseFlutterTask)

        assertEquals(
            ruleNamesList,
            listOf(
                "android_aot_bundle_release_android",
                "android_aot_bundle_release_linux"
            )
        )
    }

    @Test
    fun `createSpecActionFromTask creates the correct build configurations when properties are non-null`() {
        val buildModeString = "debug"

        // Create necessary mocks.
        val baseFlutterTask = mockk<BaseFlutterTask>()
        val mockExecSpec = mockk<ExecSpec>()
        val mockProcessForkOptions = mockk<ProcessForkOptions>()

        // When baseFlutterTask.sourceDir is null, an exception is thrown. We mock its return value
        // before creating a BaseFlutterTaskHelper object.
        every { baseFlutterTask.sourceDir } returns BaseFlutterTaskPropertiesTest.sourceDirTest
        val execSpecActionFromTask = BaseFlutterTaskHelper.createExecSpecActionFromTask(baseFlutterTask)

        // Mock return values of properties.
        every { baseFlutterTask.flutterExecutable } returns BaseFlutterTaskPropertiesTest.flutterExecutableTest
        every {
            baseFlutterTask.flutterExecutable!!.absolutePath
        } returns BaseFlutterTaskPropertiesTest.FLUTTER_EXECUTABLE_ABSOLUTE_PATH_TEST

        every { baseFlutterTask.targetPath } returns BaseFlutterTaskPropertiesTest.FLUTTER_TARGET_FILE_PATH

        every { baseFlutterTask.localEngine } returns BaseFlutterTaskPropertiesTest.LOCAL_ENGINE_TEST
        every { baseFlutterTask.localEngineSrcPath } returns BaseFlutterTaskPropertiesTest.LOCAL_ENGINE_SRC_PATH_TEST

        every { baseFlutterTask.localEngineHost } returns BaseFlutterTaskPropertiesTest.LOCAL_ENGINE_HOST_TEST
        every { baseFlutterTask.verbose } returns true
        every { baseFlutterTask.intermediateDir } returns BaseFlutterTaskPropertiesTest.intermediateDirFileTest
        every { baseFlutterTask.performanceMeasurementFile } returns BaseFlutterTaskPropertiesTest.PERFORMANCE_MEASUREMENT_FILE_TEST

        every { baseFlutterTask.buildMode } returns buildModeString
        every { baseFlutterTask.flutterRoot } returns BaseFlutterTaskPropertiesTest.flutterRootTest
        every { baseFlutterTask.flutterRoot!!.absolutePath } returns BaseFlutterTaskPropertiesTest.FLUTTER_ROOT_ABSOLUTE_PATH_TEST

        every { baseFlutterTask.trackWidgetCreation } returns true
        every { baseFlutterTask.splitDebugInfo } returns BaseFlutterTaskPropertiesTest.SPLIT_DEBUG_INFO_TEST
        every { baseFlutterTask.treeShakeIcons } returns true

        every { baseFlutterTask.dartObfuscation } returns true
        every { baseFlutterTask.dartDefines } returns BaseFlutterTaskPropertiesTest.DART_DEFINES_TEST
        every { baseFlutterTask.bundleSkSLPath } returns BaseFlutterTaskPropertiesTest.BUNDLE_SK_SL_PATH_TEST

        every { baseFlutterTask.codeSizeDirectory } returns BaseFlutterTaskPropertiesTest.CODE_SIZE_DIRECTORY_TEST
        every { baseFlutterTask.flavor } returns BaseFlutterTaskPropertiesTest.FLAVOR_TEST
        every { baseFlutterTask.extraGenSnapshotOptions } returns BaseFlutterTaskPropertiesTest.EXTRA_GEN_SNAPSHOT_OPTIONS_TEST

        every { baseFlutterTask.frontendServerStarterPath } returns BaseFlutterTaskPropertiesTest.FRONTEND_SERVER_STARTER_PATH_TEST
        every { baseFlutterTask.extraFrontEndOptions } returns BaseFlutterTaskPropertiesTest.EXTRA_FRONTEND_OPTIONS_TEST

        every { baseFlutterTask.targetPlatformValues } returns BaseFlutterTaskPropertiesTest.targetPlatformValuesList

        every { baseFlutterTask.minSdkVersion } returns BaseFlutterTaskPropertiesTest.MIN_SDK_VERSION_TEST

        // Mock the method calls. We collapse all the args mock calls into four calls.
        every { mockExecSpec.executable(any<String>()) } returns mockExecSpec
        every { mockExecSpec.workingDir(any()) } returns mockProcessForkOptions
        every { mockExecSpec.args(any<String>(), any()) } returns mockExecSpec
        every { mockExecSpec.args(any<String>(), any()) } returns mockExecSpec
        every { mockExecSpec.args(any<String>()) } returns mockExecSpec
        every { mockExecSpec.args(any<List<String>>()) } returns mockExecSpec

        // Generate rule names for verification and can only be generated after buildMode is mocked.
        val ruleNamesList: List<String> = BaseFlutterTaskHelper.generateRuleNames(baseFlutterTask)

        // The exec function will be deprecated in gradle 8.11 and will be removed in gradle 9.0
        // https://docs.gradle.org/current/kotlin-dsl/gradle/org.gradle.kotlin.dsl/-kotlin-script/exec.html?query=abstract%20fun%20exec(configuration:%20Action%3CExecSpec%3E):%20ExecResult
        // The actions are executed.
        execSpecActionFromTask.execute(mockExecSpec)

        // After execution, we verify the functions are actually being
        // called with the expected argument passed in.
        verify { mockExecSpec.executable(BaseFlutterTaskPropertiesTest.FLUTTER_EXECUTABLE_ABSOLUTE_PATH_TEST) }
        verify { mockExecSpec.workingDir(BaseFlutterTaskPropertiesTest.sourceDirTest) }
        verify { mockExecSpec.args("--local-engine", BaseFlutterTaskPropertiesTest.LOCAL_ENGINE_TEST) }
        verify { mockExecSpec.args("--local-engine-src-path", BaseFlutterTaskPropertiesTest.LOCAL_ENGINE_SRC_PATH_TEST) }
        verify { mockExecSpec.args("--local-engine-host", BaseFlutterTaskPropertiesTest.LOCAL_ENGINE_HOST_TEST) }
        verify { mockExecSpec.args("--verbose") }
        verify { mockExecSpec.args("assemble") }
        verify { mockExecSpec.args("--no-version-check") }
        verify { mockExecSpec.args("--depfile", "${BaseFlutterTaskPropertiesTest.intermediateDirFileTest}/flutter_build.d") }
        verify { mockExecSpec.args("--output", "${BaseFlutterTaskPropertiesTest.intermediateDirFileTest}") }
        verify { mockExecSpec.args("--performance-measurement-file=${BaseFlutterTaskPropertiesTest.PERFORMANCE_MEASUREMENT_FILE_TEST}") }
        verify { mockExecSpec.args("-dTargetFile=${BaseFlutterTaskPropertiesTest.FLUTTER_TARGET_FILE_PATH}") }
        verify { mockExecSpec.args("-dTargetPlatform=android") }
        verify { mockExecSpec.args("-dBuildMode=$buildModeString") }
        verify { mockExecSpec.args("-dTrackWidgetCreation=${true}") }
        verify { mockExecSpec.args("-dSplitDebugInfo=${BaseFlutterTaskPropertiesTest.SPLIT_DEBUG_INFO_TEST}") }
        verify { mockExecSpec.args("-dTreeShakeIcons=true") }
        verify { mockExecSpec.args("-dDartObfuscation=true") }
        verify { mockExecSpec.args("--DartDefines=${BaseFlutterTaskPropertiesTest.DART_DEFINES_TEST}") }
        verify { mockExecSpec.args("-dBundleSkSLPath=${BaseFlutterTaskPropertiesTest.BUNDLE_SK_SL_PATH_TEST}") }
        verify { mockExecSpec.args("-dCodeSizeDirectory=${BaseFlutterTaskPropertiesTest.CODE_SIZE_DIRECTORY_TEST}") }
        verify { mockExecSpec.args("-dFlavor=${BaseFlutterTaskPropertiesTest.FLAVOR_TEST}") }
        verify { mockExecSpec.args("--ExtraGenSnapshotOptions=${BaseFlutterTaskPropertiesTest.EXTRA_GEN_SNAPSHOT_OPTIONS_TEST}") }
        verify { mockExecSpec.args("-dFrontendServerStarterPath=${BaseFlutterTaskPropertiesTest.FRONTEND_SERVER_STARTER_PATH_TEST}") }
        verify { mockExecSpec.args("--ExtraFrontEndOptions=${BaseFlutterTaskPropertiesTest.EXTRA_FRONTEND_OPTIONS_TEST}") }
        verify { mockExecSpec.args("-dAndroidArchs=${BaseFlutterTaskPropertiesTest.TARGET_PLATFORM_VALUES_JOINED_LIST}") }
        verify { mockExecSpec.args("-dMinSdkVersion=${BaseFlutterTaskPropertiesTest.MIN_SDK_VERSION_TEST}") }
        verify { mockExecSpec.args(ruleNamesList) }
    }

    @Test
    fun `createSpecActionFromTask creates the correct build configurations when properties are null`() {
        val buildModeString = "debug"

        // Create necessary mocks.
        val baseFlutterTask = mockk<BaseFlutterTask>()
        val mockExecSpec = mockk<ExecSpec>()
        val mockProcessForkOptions = mockk<ProcessForkOptions>()

        // When baseFlutterTask.sourceDir is null, an exception is thrown. We mock its return value
        // before creating a BaseFlutterTaskHelper object.
        every { baseFlutterTask.sourceDir } returns BaseFlutterTaskPropertiesTest.sourceDirTest
        val execSpecActionFromTask = BaseFlutterTaskHelper.createExecSpecActionFromTask(baseFlutterTask)

        // Mock return values of properties.
        every { baseFlutterTask.flutterExecutable } returns BaseFlutterTaskPropertiesTest.flutterExecutableTest
        every {
            baseFlutterTask.flutterExecutable!!.absolutePath
        } returns BaseFlutterTaskPropertiesTest.FLUTTER_EXECUTABLE_ABSOLUTE_PATH_TEST

        every { baseFlutterTask.targetPath } returns BaseFlutterTaskPropertiesTest.FLUTTER_TARGET_FILE_PATH

        every { baseFlutterTask.localEngine } returns null
        every { baseFlutterTask.localEngineSrcPath } returns null

        every { baseFlutterTask.localEngineHost } returns null
        every { baseFlutterTask.verbose } returns true
        every { baseFlutterTask.intermediateDir } returns BaseFlutterTaskPropertiesTest.intermediateDirFileTest
        every { baseFlutterTask.performanceMeasurementFile } returns null

        every { baseFlutterTask.buildMode } returns buildModeString
        every { baseFlutterTask.flutterRoot } returns BaseFlutterTaskPropertiesTest.flutterRootTest
        every { baseFlutterTask.flutterRoot!!.absolutePath } returns BaseFlutterTaskPropertiesTest.FLUTTER_ROOT_ABSOLUTE_PATH_TEST

        every { baseFlutterTask.trackWidgetCreation } returns null
        every { baseFlutterTask.splitDebugInfo } returns null
        every { baseFlutterTask.treeShakeIcons } returns null

        every { baseFlutterTask.dartObfuscation } returns null
        every { baseFlutterTask.dartDefines } returns null
        every { baseFlutterTask.bundleSkSLPath } returns null

        every { baseFlutterTask.codeSizeDirectory } returns null
        every { baseFlutterTask.flavor } returns null
        every { baseFlutterTask.extraGenSnapshotOptions } returns null

        every { baseFlutterTask.frontendServerStarterPath } returns null
        every { baseFlutterTask.extraFrontEndOptions } returns null

        every { baseFlutterTask.targetPlatformValues } returns BaseFlutterTaskPropertiesTest.targetPlatformValuesList

        every { baseFlutterTask.minSdkVersion } returns BaseFlutterTaskPropertiesTest.MIN_SDK_VERSION_TEST

        // Mock the method calls. We collapse all the args mock calls into four calls.
        every { mockExecSpec.executable(any<String>()) } returns mockExecSpec
        every { mockExecSpec.workingDir(any()) } returns mockProcessForkOptions
        every { mockExecSpec.args(any<String>(), any()) } returns mockExecSpec
        every { mockExecSpec.args(any<String>(), any()) } returns mockExecSpec
        every { mockExecSpec.args(any<String>()) } returns mockExecSpec
        every { mockExecSpec.args(any<List<String>>()) } returns mockExecSpec

        // Generate rule names for verification and can only be generated after buildMode is mocked.
        val ruleNamesList: List<String> = BaseFlutterTaskHelper.generateRuleNames(baseFlutterTask)

        // The exec function will be deprecated in gradle 8.11 and will be removed in gradle 9.0
        // https://docs.gradle.org/current/kotlin-dsl/gradle/org.gradle.kotlin.dsl/-kotlin-script/exec.html?query=abstract%20fun%20exec(configuration:%20Action%3CExecSpec%3E):%20ExecResult
        // The actions are executed.
        execSpecActionFromTask.execute(mockExecSpec)

        // After execution, we verify the functions are actually being
        // called with the expected argument passed in.
        verify { mockExecSpec.executable(BaseFlutterTaskPropertiesTest.FLUTTER_EXECUTABLE_ABSOLUTE_PATH_TEST) }
        verify { mockExecSpec.workingDir(BaseFlutterTaskPropertiesTest.sourceDirTest) }
        verify { mockExecSpec.args("--verbose") }
        verify { mockExecSpec.args("assemble") }
        verify { mockExecSpec.args("--no-version-check") }
        verify { mockExecSpec.args("--depfile", "${BaseFlutterTaskPropertiesTest.intermediateDirFileTest}/flutter_build.d") }
        verify { mockExecSpec.args("--output", "${BaseFlutterTaskPropertiesTest.intermediateDirFileTest}") }
        verify { mockExecSpec.args("-dTargetFile=${BaseFlutterTaskPropertiesTest.FLUTTER_TARGET_FILE_PATH}") }
        verify { mockExecSpec.args("-dTargetPlatform=android") }
        verify { mockExecSpec.args("-dBuildMode=$buildModeString") }
        verify { mockExecSpec.args("-dAndroidArchs=${BaseFlutterTaskPropertiesTest.TARGET_PLATFORM_VALUES_JOINED_LIST}") }
        verify { mockExecSpec.args("-dMinSdkVersion=${BaseFlutterTaskPropertiesTest.MIN_SDK_VERSION_TEST}") }
        verify { mockExecSpec.args(ruleNamesList) }
    }

    @Test
    fun `buildBundle calls the correct methods`() {
        val baseFlutterTask = mockk<BaseFlutterTask>()
        val mockLoggingManager = mockk<LoggingManager>()
        val mockFile = mockk<File>()
        // Mocking the serviceOf() extension below requires us to specify this internal type
        // unfortunately.
        val mockProject = mockk<org.gradle.api.internal.project.ProjectInternal>()

        // When baseFlutterTask.sourceDir is null, an exception is thrown. We mock its return value
        // before creating a BaseFlutterTaskHelper object.
        every { baseFlutterTask.sourceDir } returns mockFile
        every { mockFile.isDirectory } returns true
        every { baseFlutterTask.intermediateDir } returns BaseFlutterTaskPropertiesTest.intermediateDirFileTest
        every { baseFlutterTask.logging } returns mockLoggingManager
        every { mockLoggingManager.captureStandardError(any()) } returns mockLoggingManager
        every { baseFlutterTask.project } returns mockProject
        val mockExecOperations = mockk<ExecOperations>()
        every {
            mockProject.serviceOf<ExecOperations>()
        } returns mockExecOperations
        every { mockExecOperations.exec(any<Action<ExecSpec>>()) } returns mockk()

        BaseFlutterTaskHelper.buildBundle(baseFlutterTask)
    }

    @Test
    fun `getDependencyFiles returns a FileCollection of dependency file(s)`() {
        val baseFlutterTask = mockk<BaseFlutterTask>()
        val project = mockk<Project>()
        val configFileCollection = mockk<ConfigurableFileCollection>()
        every { baseFlutterTask.sourceDir } returns BaseFlutterTaskPropertiesTest.sourceDirTest

        every { baseFlutterTask.project } returns project
        every { baseFlutterTask.intermediateDir } returns BaseFlutterTaskPropertiesTest.intermediateDirFileTest

        val projectIntermediary = baseFlutterTask.project
        val interDirFile = baseFlutterTask.intermediateDir

        every { projectIntermediary.files() } returns configFileCollection
        every { projectIntermediary.files("$interDirFile/flutter_build.d") } returns configFileCollection
        every { configFileCollection.plus(configFileCollection) } returns configFileCollection

        BaseFlutterTaskHelper.getDependenciesFiles(baseFlutterTask)
        verify { projectIntermediary.files() }
        verify { projectIntermediary.files("${BaseFlutterTaskPropertiesTest.intermediateDirFileTest}/flutter_build.d") }
    }
}

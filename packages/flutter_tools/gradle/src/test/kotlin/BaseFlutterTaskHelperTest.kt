package com.flutter.gradle

import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.gradle.api.GradleException
import org.gradle.process.ExecSpec
import org.gradle.process.ProcessForkOptions
import org.junit.jupiter.api.assertDoesNotThrow
import java.io.File
import java.nio.file.Paths
import kotlin.test.Test
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

class BaseFlutterTaskHelperTest {
    object BaseFlutterTaskPropertiesTest {
        internal const val FLUTTER_ROOT_ABSOLUTE_PATH_TEST = "/path/to/flutter"
        internal const val FLUTTER_EXECUTABLE_ABSOLUTE_PATH_TEST = "/path/to/flutter/bin/flutter"
        internal const val LOCAL_ENGINE_TEST = "android_debug_arm64"
        internal const val LOCAL_ENGINE_HOST_TEST = "host_debug"
        internal const val LOCAL_ENGINE_SRC_PATH_TEST = "/path/to/flutter/engine/src"
        internal const val PERFORMANCE_MEASUREMENT_FILE_TEST = "/path/to/build/performance_file"
        internal const val DART_DEFINES_TEST = "ENVIRONMENT=development"
        internal const val FLAVOR_TEST = "dev"
        internal const val FRONTEND_SERVER_STARTER_PATH_TEST = "/path/to/starter/script_file"
        internal const val EXTRA_FRONTEND_OPTIONS_TEST = "--enable-asserts"
        internal const val EXTRA_GEN_SNAPSHOT_OPTIONS_TEST = "--debugger"
        internal const val SPLIT_DEBUG_INFO_TEST = "/path/to/build/debug_info_directory"
        internal const val CODE_SIZE_DIRECTORY_TEST = "/path/to/build/code_size_directory"
        internal const val MIN_SDK_VERSION_TEST = 21
        internal const val BUNDLE_SK_SL_PATH_TEST = "/path/to/custom/shaders"
        internal const val FLUTTER_TARGET_FILE_PATH = "/path/to/flutter/examples/splash/lib/main.dart"
        internal const val FLUTTER_TARGET_PATH = "/path/to/main.dart"
        internal const val TARGET_PLATFORM_VALUES_JOINED_LIST = "android linux"

        internal val sourceDirTest = File("/path/to/working_directory")
        internal val flutterRootTest = File("/path/to/flutter")
        internal val flutterExecutableTest = File("/path/to/flutter/bin/flutter")
        internal val intermediateDirFileTest = File("/path/to/build/app/intermediates/flutter/release")
        internal val targetPlatformValuesList = listOf("android", "linux")
    }

    @Test
    fun `checkPreConditions throws a GradleException when sourceDir is null`() {
        val baseFlutterTask = mockk<BaseFlutterTask>()
        every { baseFlutterTask.sourceDir } returns null

        val helper = BaseFlutterTaskHelper(baseFlutterTask)

        val gradleException =
            assertFailsWith<GradleException> { helper.checkPreConditions() }
        assert(
            gradleException.message ==
                helper.gradleErrorMessage,
        )
    }

    @Test
    fun `checkPreConditions throws a GradleException when sourceDir is not a directory`() {
        val baseFlutterTask = mockk<BaseFlutterTask>()
        every { baseFlutterTask.sourceDir } returns BaseFlutterTaskPropertiesTest.sourceDirTest
        every { baseFlutterTask.sourceDir!!.isDirectory } returns false

        val helper = BaseFlutterTaskHelper(baseFlutterTask)

        val gradleException =
            assertFailsWith<GradleException> { helper.checkPreConditions() }
        assert(
            gradleException.message ==
                helper.gradleErrorMessage,
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
        every { baseFlutterTask.intermediateDir.mkdirs() } returns false

        val helper = BaseFlutterTaskHelper(baseFlutterTask)
        assertDoesNotThrow { helper.checkPreConditions() }
    }

    @Test
    fun `generateRuleNames returns correct rule names when buildMode is debug`() {
        val buildModeString = "debug"

        val baseFlutterTask = mockk<BaseFlutterTask>()
        // When baseFlutterTask.sourceDir is null, an exception is thrown. We mock its return value
        // before creating a BaseFlutterTaskHelper object.
        every { baseFlutterTask.sourceDir } returns BaseFlutterTaskPropertiesTest.sourceDirTest
        every { baseFlutterTask.buildMode } returns buildModeString

        val helper = BaseFlutterTaskHelper(baseFlutterTask)
        val ruleNamesList = helper.generateRuleNames(baseFlutterTask)

        assertTrue { ruleNamesList.contentEquals(arrayOf("debug_android_application")) }
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

        val helper = BaseFlutterTaskHelper(baseFlutterTask)
        val ruleNamesList = helper.generateRuleNames(baseFlutterTask)

        assertTrue {
            ruleNamesList.contentEquals(
                arrayOf(
                    "android_aot_deferred_components_bundle_release_android",
                    "android_aot_deferred_components_bundle_release_linux",
                ),
            )
        }
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

        val helper = BaseFlutterTaskHelper(baseFlutterTask)
        val ruleNamesList = helper.generateRuleNames(baseFlutterTask)

        assertTrue {
            ruleNamesList.contentEquals(
                arrayOf(
                    "android_aot_bundle_release_android",
                    "android_aot_bundle_release_linux",
                ),
            )
        }
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
        val helper = BaseFlutterTaskHelper(baseFlutterTask)
        val execSpecActionFromTask = helper.createExecSpecActionFromTask()

        // Mock return values of properties.
        every { baseFlutterTask.flutterExecutable } returns BaseFlutterTaskPropertiesTest.flutterExecutableTest
        every {
            baseFlutterTask.flutterExecutable!!.absolutePath
        } returns BaseFlutterTaskPropertiesTest.FLUTTER_EXECUTABLE_ABSOLUTE_PATH_TEST

        every { baseFlutterTask.localEngine } returns BaseFlutterTaskPropertiesTest.LOCAL_ENGINE_TEST
        every { baseFlutterTask.localEngineSrcPath } returns BaseFlutterTaskPropertiesTest.LOCAL_ENGINE_SRC_PATH_TEST

        every { baseFlutterTask.localEngineHost } returns BaseFlutterTaskPropertiesTest.LOCAL_ENGINE_HOST_TEST
        every { baseFlutterTask.verbose } returns true
        every { baseFlutterTask.intermediateDir } returns BaseFlutterTaskPropertiesTest.intermediateDirFileTest
        every { baseFlutterTask.performanceMeasurementFile } returns BaseFlutterTaskPropertiesTest.PERFORMANCE_MEASUREMENT_FILE_TEST

        every { baseFlutterTask.fastStart } returns true
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

        // Mock the actual method calls. We don't make real calls because we cannot create a real
        // ExecSpec object.
        val taskAbsolutePath = baseFlutterTask.flutterExecutable!!.absolutePath
        every { mockExecSpec.executable(taskAbsolutePath) } returns mockProcessForkOptions

        val sourceDirFile = baseFlutterTask.sourceDir
        every { mockExecSpec.workingDir(sourceDirFile) } returns mockProcessForkOptions

        val localEngine = baseFlutterTask.localEngine
        every { mockExecSpec.args("--local-engine", localEngine) } returns mockExecSpec

        val localEngineSrcPath = baseFlutterTask.localEngineSrcPath
        every { mockExecSpec.args("--local-engine-src-path", localEngineSrcPath) } returns mockExecSpec

        val localEngineHost = baseFlutterTask.localEngineHost
        every { mockExecSpec.args("--local-engine-host", localEngineHost) } returns mockExecSpec
        every { mockExecSpec.args("--verbose") } returns mockExecSpec
        every { mockExecSpec.args("assemble") } returns mockExecSpec
        every { mockExecSpec.args("--no-version-check") } returns mockExecSpec

        val intermediateDir = baseFlutterTask.intermediateDir.toString()
        val depfilePath = "$intermediateDir/flutter_build.d"
        every { mockExecSpec.args("--depfile", depfilePath) } returns mockExecSpec
        every { mockExecSpec.args("--output", intermediateDir) } returns mockExecSpec

        val performanceMeasurementFile = baseFlutterTask.performanceMeasurementFile
        every { mockExecSpec.args("--performance-measurement-file=$performanceMeasurementFile") } returns mockExecSpec
        val taskRootAbsolutePath = baseFlutterTask.flutterRoot!!.absolutePath
        val targetFilePath = Paths.get(taskRootAbsolutePath, "examples", "splash", "lib", "main.dart")
        every { mockExecSpec.args("-dTargetFile=$targetFilePath") } returns mockExecSpec

        every { mockExecSpec.args("-dTargetPlatform=android") } returns mockExecSpec

        val buildModeTaskString = baseFlutterTask.buildMode
        every { mockExecSpec.args("-dBuildMode=$buildModeTaskString") } returns mockExecSpec

        val trackWidgetCreationBool = baseFlutterTask.trackWidgetCreation
        every { mockExecSpec.args("-dTrackWidgetCreation=$trackWidgetCreationBool") } returns mockExecSpec

        val splitDebugInfo = baseFlutterTask.splitDebugInfo
        every { mockExecSpec.args("-dSplitDebugInfo=$splitDebugInfo") } returns mockExecSpec
        every { mockExecSpec.args("-dTreeShakeIcons=true") } returns mockExecSpec

        every { mockExecSpec.args("-dDartObfuscation=true") } returns mockExecSpec
        val dartDefines = baseFlutterTask.dartDefines
        every { mockExecSpec.args("--DartDefines=$dartDefines") } returns mockExecSpec
        val bundleSkSLPath = baseFlutterTask.bundleSkSLPath
        every { mockExecSpec.args("-dBundleSkSLPath=$bundleSkSLPath") } returns mockExecSpec

        val codeSizeDirectory = baseFlutterTask.codeSizeDirectory
        every { mockExecSpec.args("-dCodeSizeDirectory=$codeSizeDirectory") } returns mockExecSpec
        val flavor = baseFlutterTask.flavor
        every { mockExecSpec.args("-dFlavor=$flavor") } returns mockExecSpec
        val extraGenSnapshotOptions = baseFlutterTask.extraGenSnapshotOptions
        every { mockExecSpec.args("--ExtraGenSnapshotOptions=$extraGenSnapshotOptions") } returns mockExecSpec

        val frontServerStarterPath = baseFlutterTask.frontendServerStarterPath
        every { mockExecSpec.args("-dFrontendServerStarterPath=$frontServerStarterPath") } returns mockExecSpec
        val extraFrontEndOptions = baseFlutterTask.extraFrontEndOptions
        every { mockExecSpec.args("--ExtraFrontEndOptions=$extraFrontEndOptions") } returns mockExecSpec

        val joinTestList = BaseFlutterTaskPropertiesTest.targetPlatformValuesList.joinToString(" ")
        every { mockExecSpec.args("-dAndroidArchs=$joinTestList") } returns mockExecSpec

        val minSdkVersionInt = baseFlutterTask.minSdkVersion.toString()
        every { mockExecSpec.args("-dMinSdkVersion=$minSdkVersionInt") } returns mockExecSpec

        val ruleNamesArray: Array<String> = helper.generateRuleNames(baseFlutterTask)
        every { mockExecSpec.args(ruleNamesArray) } returns mockExecSpec

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
        verify { mockExecSpec.args(ruleNamesArray) }
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
        val helper = BaseFlutterTaskHelper(baseFlutterTask)
        val execSpecActionFromTask = helper.createExecSpecActionFromTask()

        // Mock return values of properties.
        every { baseFlutterTask.flutterExecutable } returns BaseFlutterTaskPropertiesTest.flutterExecutableTest
        every {
            baseFlutterTask.flutterExecutable!!.absolutePath
        } returns BaseFlutterTaskPropertiesTest.FLUTTER_EXECUTABLE_ABSOLUTE_PATH_TEST

        every { baseFlutterTask.localEngine } returns null
        every { baseFlutterTask.localEngineSrcPath } returns null

        every { baseFlutterTask.localEngineHost } returns null
        every { baseFlutterTask.verbose } returns true
        every { baseFlutterTask.intermediateDir } returns BaseFlutterTaskPropertiesTest.intermediateDirFileTest
        every { baseFlutterTask.performanceMeasurementFile } returns null

        every { baseFlutterTask.fastStart } returns true
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

        // Mock the actual method calls. We don't make real calls because we cannot create a real
        // ExecSpec object.
        val taskAbsolutePath = baseFlutterTask.flutterExecutable!!.absolutePath
        every { mockExecSpec.executable(taskAbsolutePath) } returns mockProcessForkOptions

        val sourceDirFile = baseFlutterTask.sourceDir
        every { mockExecSpec.workingDir(sourceDirFile) } returns mockProcessForkOptions

        every { mockExecSpec.args("--verbose") } returns mockExecSpec
        every { mockExecSpec.args("assemble") } returns mockExecSpec
        every { mockExecSpec.args("--no-version-check") } returns mockExecSpec

        val intermediateDir = baseFlutterTask.intermediateDir.toString()
        val depfilePath = "$intermediateDir/flutter_build.d"
        every { mockExecSpec.args("--depfile", depfilePath) } returns mockExecSpec
        every { mockExecSpec.args("--output", intermediateDir) } returns mockExecSpec

        val taskRootAbsolutePath = baseFlutterTask.flutterRoot!!.absolutePath
        val targetFilePath = Paths.get(taskRootAbsolutePath, "examples", "splash", "lib", "main.dart")
        every { mockExecSpec.args("-dTargetFile=$targetFilePath") } returns mockExecSpec
        every { mockExecSpec.args("-dTargetPlatform=android") } returns mockExecSpec

        val buildModeTaskString = baseFlutterTask.buildMode
        every { mockExecSpec.args("-dBuildMode=$buildModeTaskString") } returns mockExecSpec

        val joinTestList = BaseFlutterTaskPropertiesTest.targetPlatformValuesList.joinToString(" ")
        every { mockExecSpec.args("-dAndroidArchs=$joinTestList") } returns mockExecSpec

        val minSdkVersionInt = baseFlutterTask.minSdkVersion.toString()
        every { mockExecSpec.args("-dMinSdkVersion=$minSdkVersionInt") } returns mockExecSpec

        val ruleNameList: Array<String> = helper.generateRuleNames(baseFlutterTask)
        every { mockExecSpec.args(ruleNameList) } returns mockExecSpec

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
        assertTrue { ruleNameList.contentEquals(arrayOf("debug_android_application")) }
        verify { mockExecSpec.args(ruleNameList) }
    }

    @Test
    fun `createSpecActionFromTask creates the correct build configurations when verbose is false and fastStart is false`() {
        val buildModeString = "debug"

        // Create necessary mocks.
        val baseFlutterTask = mockk<BaseFlutterTask>()
        val mockExecSpec = mockk<ExecSpec>()
        val mockProcessForkOptions = mockk<ProcessForkOptions>()

        // When baseFlutterTask.sourceDir is null, an exception is thrown. We mock its return value
        // before creating a BaseFlutterTaskHelper object.
        every { baseFlutterTask.sourceDir } returns BaseFlutterTaskPropertiesTest.sourceDirTest
        val helper = BaseFlutterTaskHelper(baseFlutterTask)
        val execSpecActionFromTask = helper.createExecSpecActionFromTask()

        // Mock return values of properties.
        every { baseFlutterTask.flutterExecutable } returns BaseFlutterTaskPropertiesTest.flutterExecutableTest
        every {
            baseFlutterTask.flutterExecutable!!.absolutePath
        } returns BaseFlutterTaskPropertiesTest.FLUTTER_EXECUTABLE_ABSOLUTE_PATH_TEST

        every { baseFlutterTask.localEngine } returns BaseFlutterTaskPropertiesTest.LOCAL_ENGINE_TEST
        every { baseFlutterTask.localEngineSrcPath } returns BaseFlutterTaskPropertiesTest.LOCAL_ENGINE_SRC_PATH_TEST

        every { baseFlutterTask.localEngineHost } returns BaseFlutterTaskPropertiesTest.LOCAL_ENGINE_HOST_TEST
        every { baseFlutterTask.verbose } returns false
        every { baseFlutterTask.intermediateDir } returns BaseFlutterTaskPropertiesTest.intermediateDirFileTest
        every { baseFlutterTask.performanceMeasurementFile } returns BaseFlutterTaskPropertiesTest.PERFORMANCE_MEASUREMENT_FILE_TEST

        every { baseFlutterTask.fastStart } returns false
        every { baseFlutterTask.buildMode } returns buildModeString
        every { baseFlutterTask.targetPath } returns BaseFlutterTaskPropertiesTest.FLUTTER_TARGET_PATH

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

        // Mock the actual method calls. We don't make real calls because we cannot create a real
        // ExecSpec object.
        val taskAbsolutePath = baseFlutterTask.flutterExecutable!!.absolutePath
        every { mockExecSpec.executable(taskAbsolutePath) } returns mockProcessForkOptions

        val sourceDirFile = baseFlutterTask.sourceDir
        every { mockExecSpec.workingDir(sourceDirFile) } returns mockProcessForkOptions

        val localEngine = baseFlutterTask.localEngine
        every { mockExecSpec.args("--local-engine", localEngine) } returns mockExecSpec

        val localEngineSrcPath = baseFlutterTask.localEngineSrcPath
        every { mockExecSpec.args("--local-engine-src-path", localEngineSrcPath) } returns mockExecSpec

        val localEngineHost = baseFlutterTask.localEngineHost
        every { mockExecSpec.args("--local-engine-host", localEngineHost) } returns mockExecSpec
        every { mockExecSpec.args("--quiet") } returns mockExecSpec
        every { mockExecSpec.args("assemble") } returns mockExecSpec
        every { mockExecSpec.args("--no-version-check") } returns mockExecSpec

        val intermediateDir = baseFlutterTask.intermediateDir.toString()
        val depfilePath = "$intermediateDir/flutter_build.d"
        every { mockExecSpec.args("--depfile", depfilePath) } returns mockExecSpec
        every { mockExecSpec.args("--output", intermediateDir) } returns mockExecSpec

        val performanceMeasurementFile = baseFlutterTask.performanceMeasurementFile
        every { mockExecSpec.args("--performance-measurement-file=$performanceMeasurementFile") } returns mockExecSpec

        val targetFilePath = baseFlutterTask.targetPath
        every { mockExecSpec.args("-dTargetFile=$targetFilePath") } returns mockExecSpec

        every { mockExecSpec.args("-dTargetPlatform=android") } returns mockExecSpec

        val buildModeTaskString = baseFlutterTask.buildMode
        every { mockExecSpec.args("-dBuildMode=$buildModeTaskString") } returns mockExecSpec

        val trackWidgetCreationBool = baseFlutterTask.trackWidgetCreation
        every { mockExecSpec.args("-dTrackWidgetCreation=$trackWidgetCreationBool") } returns mockExecSpec

        val splitDebugInfo = baseFlutterTask.splitDebugInfo
        every { mockExecSpec.args("-dSplitDebugInfo=$splitDebugInfo") } returns mockExecSpec
        every { mockExecSpec.args("-dTreeShakeIcons=true") } returns mockExecSpec

        every { mockExecSpec.args("-dDartObfuscation=true") } returns mockExecSpec
        val dartDefines = baseFlutterTask.dartDefines
        every { mockExecSpec.args("--DartDefines=$dartDefines") } returns mockExecSpec
        val bundleSkSLPath = baseFlutterTask.bundleSkSLPath
        every { mockExecSpec.args("-dBundleSkSLPath=$bundleSkSLPath") } returns mockExecSpec

        val codeSizeDirectory = baseFlutterTask.codeSizeDirectory
        every { mockExecSpec.args("-dCodeSizeDirectory=$codeSizeDirectory") } returns mockExecSpec
        val flavor = baseFlutterTask.flavor
        every { mockExecSpec.args("-dFlavor=$flavor") } returns mockExecSpec
        val extraGenSnapshotOptions = baseFlutterTask.extraGenSnapshotOptions
        every { mockExecSpec.args("--ExtraGenSnapshotOptions=$extraGenSnapshotOptions") } returns mockExecSpec

        val frontServerStarterPath = baseFlutterTask.frontendServerStarterPath
        every { mockExecSpec.args("-dFrontendServerStarterPath=$frontServerStarterPath") } returns mockExecSpec
        val extraFrontEndOptions = baseFlutterTask.extraFrontEndOptions
        every { mockExecSpec.args("--ExtraFrontEndOptions=$extraFrontEndOptions") } returns mockExecSpec

        val joinTestList = BaseFlutterTaskPropertiesTest.targetPlatformValuesList.joinToString(" ")
        every { mockExecSpec.args("-dAndroidArchs=$joinTestList") } returns mockExecSpec

        val minSdkVersionInt = baseFlutterTask.minSdkVersion.toString()
        every { mockExecSpec.args("-dMinSdkVersion=$minSdkVersionInt") } returns mockExecSpec

        val ruleNamesArray: Array<String> = helper.generateRuleNames(baseFlutterTask)
        every { mockExecSpec.args(ruleNamesArray) } returns mockExecSpec

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
        verify { mockExecSpec.args("--quiet") }
        verify { mockExecSpec.args("assemble") }
        verify { mockExecSpec.args("--no-version-check") }
        verify { mockExecSpec.args("--depfile", "${BaseFlutterTaskPropertiesTest.intermediateDirFileTest}/flutter_build.d") }
        verify { mockExecSpec.args("--output", "${BaseFlutterTaskPropertiesTest.intermediateDirFileTest}") }
        verify { mockExecSpec.args("--performance-measurement-file=${BaseFlutterTaskPropertiesTest.PERFORMANCE_MEASUREMENT_FILE_TEST}") }
        verify { mockExecSpec.args("-dTargetFile=${BaseFlutterTaskPropertiesTest.FLUTTER_TARGET_PATH}") }
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
        verify { mockExecSpec.args(ruleNamesArray) }
    }

    @Test
    fun `createSpecActionFromTask creates the correct build configurations when fastStart is true and buildMode is not debug`() {
        val buildModeString = "release"

        // Create necessary mocks.
        val baseFlutterTask = mockk<BaseFlutterTask>()
        val mockExecSpec = mockk<ExecSpec>()
        val mockProcessForkOptions = mockk<ProcessForkOptions>()

        // When baseFlutterTask.sourceDir is null, an exception is thrown. We mock its return value
        // before creating a BaseFlutterTaskHelper object.
        every { baseFlutterTask.sourceDir } returns BaseFlutterTaskPropertiesTest.sourceDirTest
        val helper = BaseFlutterTaskHelper(baseFlutterTask)
        val execSpecActionFromTask = helper.createExecSpecActionFromTask()

        // Mock return values of properties.
        every { baseFlutterTask.flutterExecutable } returns BaseFlutterTaskPropertiesTest.flutterExecutableTest
        every {
            baseFlutterTask.flutterExecutable!!.absolutePath
        } returns BaseFlutterTaskPropertiesTest.FLUTTER_EXECUTABLE_ABSOLUTE_PATH_TEST

        every { baseFlutterTask.localEngine } returns BaseFlutterTaskPropertiesTest.LOCAL_ENGINE_TEST
        every { baseFlutterTask.localEngineSrcPath } returns BaseFlutterTaskPropertiesTest.LOCAL_ENGINE_SRC_PATH_TEST

        every { baseFlutterTask.localEngineHost } returns BaseFlutterTaskPropertiesTest.LOCAL_ENGINE_HOST_TEST
        every { baseFlutterTask.verbose } returns true
        every { baseFlutterTask.intermediateDir } returns BaseFlutterTaskPropertiesTest.intermediateDirFileTest
        every { baseFlutterTask.performanceMeasurementFile } returns BaseFlutterTaskPropertiesTest.PERFORMANCE_MEASUREMENT_FILE_TEST

        every { baseFlutterTask.fastStart } returns true
        every { baseFlutterTask.buildMode } returns buildModeString
        every { baseFlutterTask.targetPath } returns BaseFlutterTaskPropertiesTest.FLUTTER_TARGET_PATH

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

        every { baseFlutterTask.deferredComponents } returns true
        every { baseFlutterTask.targetPlatformValues } returns BaseFlutterTaskPropertiesTest.targetPlatformValuesList

        every { baseFlutterTask.minSdkVersion } returns BaseFlutterTaskPropertiesTest.MIN_SDK_VERSION_TEST

        // Mock the actual method calls. We don't make real calls because we cannot create a real
        // ExecSpec object.
        val taskAbsolutePath = baseFlutterTask.flutterExecutable!!.absolutePath
        every { mockExecSpec.executable(taskAbsolutePath) } returns mockProcessForkOptions

        val sourceDirFile = baseFlutterTask.sourceDir
        every { mockExecSpec.workingDir(sourceDirFile) } returns mockProcessForkOptions

        val localEngine = baseFlutterTask.localEngine
        every { mockExecSpec.args("--local-engine", localEngine) } returns mockExecSpec

        val localEngineSrcPath = baseFlutterTask.localEngineSrcPath
        every { mockExecSpec.args("--local-engine-src-path", localEngineSrcPath) } returns mockExecSpec

        val localEngineHost = baseFlutterTask.localEngineHost
        every { mockExecSpec.args("--local-engine-host", localEngineHost) } returns mockExecSpec
        every { mockExecSpec.args("--verbose") } returns mockExecSpec
        every { mockExecSpec.args("assemble") } returns mockExecSpec
        every { mockExecSpec.args("--no-version-check") } returns mockExecSpec

        val intermediateDir = baseFlutterTask.intermediateDir.toString()
        val depfilePath = "$intermediateDir/flutter_build.d"
        every { mockExecSpec.args("--depfile", depfilePath) } returns mockExecSpec
        every { mockExecSpec.args("--output", intermediateDir) } returns mockExecSpec

        val performanceMeasurementFile = baseFlutterTask.performanceMeasurementFile
        every { mockExecSpec.args("--performance-measurement-file=$performanceMeasurementFile") } returns mockExecSpec

        val targetFilePath = baseFlutterTask.targetPath
        every { mockExecSpec.args("-dTargetFile=$targetFilePath") } returns mockExecSpec

        every { mockExecSpec.args("-dTargetPlatform=android") } returns mockExecSpec

        val buildModeTaskString = baseFlutterTask.buildMode
        every { mockExecSpec.args("-dBuildMode=$buildModeTaskString") } returns mockExecSpec

        val trackWidgetCreationBool = baseFlutterTask.trackWidgetCreation
        every { mockExecSpec.args("-dTrackWidgetCreation=$trackWidgetCreationBool") } returns mockExecSpec

        val splitDebugInfo = baseFlutterTask.splitDebugInfo
        every { mockExecSpec.args("-dSplitDebugInfo=$splitDebugInfo") } returns mockExecSpec
        every { mockExecSpec.args("-dTreeShakeIcons=true") } returns mockExecSpec

        every { mockExecSpec.args("-dDartObfuscation=true") } returns mockExecSpec
        val dartDefines = baseFlutterTask.dartDefines
        every { mockExecSpec.args("--DartDefines=$dartDefines") } returns mockExecSpec
        val bundleSkSLPath = baseFlutterTask.bundleSkSLPath
        every { mockExecSpec.args("-dBundleSkSLPath=$bundleSkSLPath") } returns mockExecSpec

        val codeSizeDirectory = baseFlutterTask.codeSizeDirectory
        every { mockExecSpec.args("-dCodeSizeDirectory=$codeSizeDirectory") } returns mockExecSpec
        val flavor = baseFlutterTask.flavor
        every { mockExecSpec.args("-dFlavor=$flavor") } returns mockExecSpec
        val extraGenSnapshotOptions = baseFlutterTask.extraGenSnapshotOptions
        every { mockExecSpec.args("--ExtraGenSnapshotOptions=$extraGenSnapshotOptions") } returns mockExecSpec

        val frontServerStarterPath = baseFlutterTask.frontendServerStarterPath
        every { mockExecSpec.args("-dFrontendServerStarterPath=$frontServerStarterPath") } returns mockExecSpec
        val extraFrontEndOptions = baseFlutterTask.extraFrontEndOptions
        every { mockExecSpec.args("--ExtraFrontEndOptions=$extraFrontEndOptions") } returns mockExecSpec

        val joinTestList = BaseFlutterTaskPropertiesTest.targetPlatformValuesList.joinToString(" ")
        every { mockExecSpec.args("-dAndroidArchs=$joinTestList") } returns mockExecSpec

        val minSdkVersionInt = baseFlutterTask.minSdkVersion.toString()
        every { mockExecSpec.args("-dMinSdkVersion=$minSdkVersionInt") } returns mockExecSpec

        val ruleNamesArray: Array<String> = helper.generateRuleNames(baseFlutterTask)
        every { mockExecSpec.args(ruleNamesArray) } returns mockExecSpec

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
        verify { mockExecSpec.args("-dTargetFile=${BaseFlutterTaskPropertiesTest.FLUTTER_TARGET_PATH}") }
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
        verify { mockExecSpec.args(ruleNamesArray) }
    }
}

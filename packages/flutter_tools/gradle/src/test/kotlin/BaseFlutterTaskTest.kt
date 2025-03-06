package com.flutter.gradle

import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.gradle.api.GradleException
import org.gradle.api.Project
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.process.ExecSpec
import org.gradle.process.ProcessForkOptions
import java.io.File
import java.nio.file.Paths
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

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
    fun `verify createSpecActionFromTask creates and executes with non-null properties`() {
        val buildModeString = "debug"

        // Create necessary mocks.
        val baseFlutterTask = mockk<BaseFlutterTask>()
        val mockExecSpec = mockk<ExecSpec>()
        val mockProcessForkOptions = mockk<ProcessForkOptions>()

        // When baseFlutterTask.sourceDir is null, an exception is thrown. We mock its return value
        // before creating a BaseFlutterTaskHelper object.
        every { baseFlutterTask.sourceDir } returns sourceDirTest
        val helper = BaseFlutterTaskHelper(baseFlutterTask)
        val execSpecActionFromTask = helper.createExecSpecActionFromTask()

        // Mock return values of properties.
        every { baseFlutterTask.flutterExecutable } returns flutterExecutableTest
        every { baseFlutterTask.flutterExecutable!!.absolutePath } returns flutterExecutableAbsolutPathTest

        every { baseFlutterTask.localEngine } returns localEngineTest
        every { baseFlutterTask.localEngineSrcPath } returns localEngineSrcPathTest

        every { baseFlutterTask.localEngineHost } returns localEngineHostTest
        every { baseFlutterTask.verbose } returns true
        every { baseFlutterTask.intermediateDir } returns intermediateDirFileTest
        every { baseFlutterTask.performanceMeasurementFile } returns performanceMeasurementFileTest

        every { baseFlutterTask.fastStart } returns true
        every { baseFlutterTask.buildMode } returns buildModeString
        every { baseFlutterTask.flutterRoot } returns flutterRootTest
        every { baseFlutterTask.flutterRoot!!.absolutePath } returns flutterRootAbsolutePathTest

        every { baseFlutterTask.trackWidgetCreation } returns true
        every { baseFlutterTask.splitDebugInfo } returns splitDebugInfoTest
        every { baseFlutterTask.treeShakeIcons } returns true

        every { baseFlutterTask.dartObfuscation } returns true
        every { baseFlutterTask.dartDefines } returns dartDefinesTest
        every { baseFlutterTask.bundleSkSLPath } returns bundleSkSLPathTest

        every { baseFlutterTask.codeSizeDirectory } returns codeSizeDirectoryTest
        every { baseFlutterTask.flavor } returns flavorTest
        every { baseFlutterTask.extraGenSnapshotOptions } returns extraGenSnapshotOptionsTest

        every { baseFlutterTask.frontendServerStarterPath } returns frontendServerStarterPathTest
        every { baseFlutterTask.extraFrontEndOptions } returns extraFrontEndOptionsTest

        every { baseFlutterTask.targetPlatformValues } returns targetPlatformValuesListREAL

        every { baseFlutterTask.minSdkVersion } returns minSDKVersionTest

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

        val joinTestList = targetPlatformValuesListREAL.joinToString(" ")
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
        // called.
        verify { mockExecSpec.executable(flutterExecutableAbsolutPathTest) }
        verify { mockExecSpec.workingDir(sourceDirTest) }
        verify { mockExecSpec.args("--local-engine", localEngineTest) }
        verify { mockExecSpec.args("--local-engine-src-path", localEngineSrcPathTest) }
        verify { mockExecSpec.args("--local-engine-host", localEngineHostTest) }
        verify { mockExecSpec.args("--verbose") }
        verify { mockExecSpec.args("assemble") }
        verify { mockExecSpec.args("--no-version-check") }
        verify { mockExecSpec.args("--depfile", "$intermediateDirFileTest/flutter_build.d") }
        verify { mockExecSpec.args("--output", "$intermediateDirFileTest") }
        verify { mockExecSpec.args("--performance-measurement-file=$performanceMeasurementFileTest") }
        verify { mockExecSpec.args("-dTargetFile=$flutterTargetFilePath") }
        verify { mockExecSpec.args("-dTargetPlatform=android") }
        verify { mockExecSpec.args("-dBuildMode=$buildModeString") }
        verify { mockExecSpec.args("-dTrackWidgetCreation=${true}") }
        verify { mockExecSpec.args("-dSplitDebugInfo=$splitDebugInfoTest") }
        verify { mockExecSpec.args("-dTreeShakeIcons=true") }
        verify { mockExecSpec.args("-dDartObfuscation=true") }
        verify { mockExecSpec.args("--DartDefines=$dartDefinesTest") }
        verify { mockExecSpec.args("-dBundleSkSLPath=$bundleSkSLPathTest") }
        verify { mockExecSpec.args("-dCodeSizeDirectory=$codeSizeDirectoryTest") }
        verify { mockExecSpec.args("-dFlavor=$flavorTest") }
        verify { mockExecSpec.args("--ExtraGenSnapshotOptions=$extraGenSnapshotOptionsTest") }
        verify { mockExecSpec.args("-dFrontendServerStarterPath=$frontendServerStarterPathTest") }
        verify { mockExecSpec.args("--ExtraFrontEndOptions=$extraFrontEndOptionsTest") }
        verify { mockExecSpec.args("-dAndroidArchs=$targetPlatformValuesJoinedListREAL") }
        verify { mockExecSpec.args("-dMinSdkVersion=$minSDKVersionTest") }
        verify { mockExecSpec.args(ruleNameList) }
        assertTrue { ruleNameList.contentEquals(arrayOf("debug_android_application")) }
    }

    @Test
    fun `verify execSpecActionFromTask creates and executes with null properties`() {
        val buildModeString = "debug"

        // Create necessary mocks.
        val baseFlutterTask = mockk<BaseFlutterTask>()
        val mockExecSpec = mockk<ExecSpec>()
        val mockProcessForkOptions = mockk<ProcessForkOptions>()

        // When baseFlutterTask.sourceDir is null, an exception is thrown. We mock its return value
        // before creating a BaseFlutterTaskHelper object.
        every { baseFlutterTask.sourceDir } returns sourceDirTest
        val helper = BaseFlutterTaskHelper(baseFlutterTask)
        val execSpecActionFromTask = helper.createExecSpecActionFromTask()

        // Mock return values of properties.
        every { baseFlutterTask.flutterExecutable } returns flutterExecutableTest
        every { baseFlutterTask.flutterExecutable!!.absolutePath } returns flutterExecutableAbsolutPathTest

        every { baseFlutterTask.localEngine } returns null
        every { baseFlutterTask.localEngineSrcPath } returns null

        every { baseFlutterTask.localEngineHost } returns null
        every { baseFlutterTask.verbose } returns true
        every { baseFlutterTask.intermediateDir } returns intermediateDirFileTest
        every { baseFlutterTask.performanceMeasurementFile } returns null

        every { baseFlutterTask.fastStart } returns true
        every { baseFlutterTask.buildMode } returns buildModeString
        every { baseFlutterTask.flutterRoot } returns flutterRootTest
        every { baseFlutterTask.flutterRoot!!.absolutePath } returns flutterRootAbsolutePathTest

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

        every { baseFlutterTask.targetPlatformValues } returns targetPlatformValuesListREAL

        every { baseFlutterTask.minSdkVersion } returns minSDKVersionTest

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

        val joinTestList = targetPlatformValuesListREAL.joinToString(" ")
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
        // called.
        verify { mockExecSpec.executable(flutterExecutableAbsolutPathTest) }
        verify { mockExecSpec.workingDir(sourceDirTest) }
        verify { mockExecSpec.args("--verbose") }
        verify { mockExecSpec.args("assemble") }
        verify { mockExecSpec.args("--no-version-check") }
        verify { mockExecSpec.args("--depfile", "$intermediateDirFileTest/flutter_build.d") }
        verify { mockExecSpec.args("--output", "$intermediateDirFileTest") }
        verify { mockExecSpec.args("-dTargetFile=$flutterTargetFilePath") }
        verify { mockExecSpec.args("-dTargetPlatform=android") }
        verify { mockExecSpec.args("-dBuildMode=$buildModeString") }
        verify { mockExecSpec.args("-dAndroidArchs=$targetPlatformValuesJoinedListREAL") }
        verify { mockExecSpec.args("-dMinSdkVersion=$minSDKVersionTest") }
        assertTrue { ruleNameList.contentEquals(arrayOf("debug_android_application")) }
        verify { mockExecSpec.args(ruleNameList) }
    }

    @Test
    fun `verify execSpecActionFromTask creates and executes with null properties and goes into different branches`() {
        val buildModeString = "release"
        val ruleNameListForDeferredComponentsTestList =
            arrayOf("android_aot_deferred_components_bundle_release_android", "android_aot_deferred_components_bundle_release_linux")

        // Create necessary mocks.
        val baseFlutterTask = mockk<BaseFlutterTask>()
        val mockExecSpec = mockk<ExecSpec>()
        val mockProcessForkOptions = mockk<ProcessForkOptions>()

        // When baseFlutterTask.sourceDir is null, an exception is thrown. We mock its return value
        // before creating a BaseFlutterTaskHelper object.
        every { baseFlutterTask.sourceDir } returns sourceDirTest
        val helper = BaseFlutterTaskHelper(baseFlutterTask)
        val execSpecActionFromTask = helper.createExecSpecActionFromTask()

        // Mock return values of properties.
        every { baseFlutterTask.flutterExecutable } returns flutterExecutableTest
        every { baseFlutterTask.flutterExecutable!!.absolutePath } returns flutterExecutableAbsolutPathTest

        every { baseFlutterTask.localEngine } returns null
        every { baseFlutterTask.localEngineSrcPath } returns null

        every { baseFlutterTask.localEngineHost } returns null
        every { baseFlutterTask.verbose } returns false
        every { baseFlutterTask.intermediateDir } returns intermediateDirFileTest
        every { baseFlutterTask.performanceMeasurementFile } returns null

        every { baseFlutterTask.fastStart } returns false
        every { baseFlutterTask.buildMode } returns buildModeString
        every { baseFlutterTask.targetPath } returns flutterTargetPath

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

        every { baseFlutterTask.targetPlatformValues } returns targetPlatformValuesListREAL

        every { baseFlutterTask.minSdkVersion } returns minSDKVersionTest

        every { baseFlutterTask.deferredComponents } returns true

        // Mock the actual method calls. We don't make real calls because we cannot create a real
        // ExecSpec object.
        val taskExecutableAbsolutePath = baseFlutterTask.flutterExecutable!!.absolutePath
        every { mockExecSpec.executable(taskExecutableAbsolutePath) } returns mockProcessForkOptions

        val sourceDirFile = baseFlutterTask.sourceDir
        every { mockExecSpec.workingDir(sourceDirFile) } returns mockProcessForkOptions

        every { mockExecSpec.args("--quiet") } returns mockExecSpec
        every { mockExecSpec.args("assemble") } returns mockExecSpec
        every { mockExecSpec.args("--no-version-check") } returns mockExecSpec

        val intermediateDir = baseFlutterTask.intermediateDir.toString()
        val depfilePath = "$intermediateDir/flutter_build.d"
        every { mockExecSpec.args("--depfile", depfilePath) } returns mockExecSpec
        every { mockExecSpec.args("--output", intermediateDir) } returns mockExecSpec

        val targetFilePath = baseFlutterTask.targetPath
        every { mockExecSpec.args("-dTargetFile=$targetFilePath") } returns mockExecSpec
        every { mockExecSpec.args("-dTargetPlatform=android") } returns mockExecSpec

        val buildModeTaskString = baseFlutterTask.buildMode
        every { mockExecSpec.args("-dBuildMode=$buildModeTaskString") } returns mockExecSpec

        val joinTestList = targetPlatformValuesListREAL.joinToString(" ")
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
        // called.
        verify { mockExecSpec.executable(flutterExecutableAbsolutPathTest) }
        verify { mockExecSpec.workingDir(sourceDirTest) }
        verify { mockExecSpec.args("--quiet") }
        verify { mockExecSpec.args("assemble") }
        verify { mockExecSpec.args("--no-version-check") }
        verify { mockExecSpec.args("--depfile", "$intermediateDirFileTest/flutter_build.d") }
        verify { mockExecSpec.args("--output", "$intermediateDirFileTest") }
        verify { mockExecSpec.args("-dTargetFile=$flutterTargetPath") }
        verify { mockExecSpec.args("-dTargetPlatform=android") }
        verify { mockExecSpec.args("-dBuildMode=$buildModeString") }
        verify { mockExecSpec.args("-dAndroidArchs=$targetPlatformValuesJoinedListREAL") }
        verify { mockExecSpec.args("-dMinSdkVersion=$minSDKVersionTest") }
        assertTrue { ruleNameList.contentEquals(ruleNameListForDeferredComponentsTestList) }
        verify { mockExecSpec.args(ruleNameList) }
    }

    @Test
    fun `verify execSpecActionFromTask creates and executes with null properties and goes into other different branches`() {
        val ruleNameListForTestList = arrayOf("android_aot_bundle_release_android", "android_aot_bundle_release_linux")
        val buildModeString = "release"

        // Create necessary mocks.
        val baseFlutterTask = mockk<BaseFlutterTask>()
        val mockExecSpec = mockk<ExecSpec>()
        val mockProcessForkOptions = mockk<ProcessForkOptions>()

        // When baseFlutterTask.sourceDir is null, an exception is thrown. We mock its return value
        // before creating a BaseFlutterTaskHelper object.
        every { baseFlutterTask.sourceDir } returns sourceDirTest
        val helper = BaseFlutterTaskHelper(baseFlutterTask)
        val execSpecActionFromTask = helper.createExecSpecActionFromTask()

        // Mock return values of properties.
        every { baseFlutterTask.flutterExecutable } returns flutterExecutableTest
        every { baseFlutterTask.flutterExecutable!!.absolutePath } returns flutterExecutableAbsolutPathTest

        every { baseFlutterTask.localEngine } returns null
        every { baseFlutterTask.localEngineSrcPath } returns null

        every { baseFlutterTask.localEngineHost } returns null
        every { baseFlutterTask.verbose } returns false
        every { baseFlutterTask.intermediateDir } returns intermediateDirFileTest
        every { baseFlutterTask.performanceMeasurementFile } returns null

        every { baseFlutterTask.fastStart } returns false
        every { baseFlutterTask.buildMode } returns buildModeString
        every { baseFlutterTask.targetPath } returns flutterTargetPath

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

        every { baseFlutterTask.targetPlatformValues } returns targetPlatformValuesListREAL

        every { baseFlutterTask.minSdkVersion } returns minSDKVersionTest

        every { baseFlutterTask.deferredComponents } returns false

        // Mock the actual method calls. We don't make real calls because we cannot create a real
        // ExecSpec object.
        val taskExecutableAbsolutePath = baseFlutterTask.flutterExecutable!!.absolutePath
        every { mockExecSpec.executable(taskExecutableAbsolutePath) } returns mockProcessForkOptions

        val sourceDirFile = baseFlutterTask.sourceDir
        every { mockExecSpec.workingDir(sourceDirFile) } returns mockProcessForkOptions

        every { mockExecSpec.args("--quiet") } returns mockExecSpec
        every { mockExecSpec.args("assemble") } returns mockExecSpec
        every { mockExecSpec.args("--no-version-check") } returns mockExecSpec

        val intermediateDir = baseFlutterTask.intermediateDir.toString()
        val depfilePath = "$intermediateDir/flutter_build.d"
        every { mockExecSpec.args("--depfile", depfilePath) } returns mockExecSpec
        every { mockExecSpec.args("--output", intermediateDir) } returns mockExecSpec

        val targetFilePath = baseFlutterTask.targetPath
        every { mockExecSpec.args("-dTargetFile=$targetFilePath") } returns mockExecSpec
        every { mockExecSpec.args("-dTargetPlatform=android") } returns mockExecSpec

        val buildModeTaskString = baseFlutterTask.buildMode
        every { mockExecSpec.args("-dBuildMode=$buildModeTaskString") } returns mockExecSpec

        val joinTestList = targetPlatformValuesListREAL.joinToString(" ")
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
        // called.
        verify { mockExecSpec.executable(flutterExecutableAbsolutPathTest) }
        verify { mockExecSpec.workingDir(sourceDirTest) }
        verify { mockExecSpec.args("--quiet") }
        verify { mockExecSpec.args("assemble") }
        verify { mockExecSpec.args("--no-version-check") }
        verify { mockExecSpec.args("--depfile", "$intermediateDirFileTest/flutter_build.d") }
        verify { mockExecSpec.args("--output", "$intermediateDirFileTest") }
        verify { mockExecSpec.args("-dTargetFile=$flutterTargetPath") }
        verify { mockExecSpec.args("-dTargetPlatform=android") }
        verify { mockExecSpec.args("-dBuildMode=$buildModeString") }
        verify { mockExecSpec.args("-dAndroidArchs=$targetPlatformValuesJoinedListREAL") }
        verify { mockExecSpec.args("-dMinSdkVersion=$minSDKVersionTest") }
        assertTrue { ruleNameList.contentEquals(ruleNameListForTestList) }
        verify { mockExecSpec.args(ruleNameList) }
    }
}

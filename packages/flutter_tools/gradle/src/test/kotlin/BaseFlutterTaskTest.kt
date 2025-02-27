package com.flutter.gradle

import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.gradle.api.GradleException
import org.gradle.api.Project
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.FileCollection
import org.gradle.process.ExecSpec
import org.gradle.process.ProcessForkOptions
import java.io.File
import java.nio.file.Paths
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class BaseFlutterTaskTest {
    @Test
    fun `getDependencyFiles returns a FileCollection`() {
        val baseFlutterTask = mockk<BaseFlutterTask>()
        val file = File("")
        val intermediateDirFile = File("User/flutter")
//        val depFileTest: File = File("User/flutter/flutter_build.d")
        val project = mockk<Project>()
        val configFileCollection = mockk<ConfigurableFileCollection>()
//        val actualConfigurableFileCollection: ConfigurableFileCollection = project.files("User/flutter/flutter_build.d")
        every { baseFlutterTask.sourceDir } returns file

        val helper = BaseFlutterTaskHelper(baseFlutterTask)

        every { baseFlutterTask.project } returns project
        every { baseFlutterTask.intermediateDir } returns intermediateDirFile

        val projectIntermediary = baseFlutterTask.project
        val interDirFile = baseFlutterTask.intermediateDir

        every { projectIntermediary.files() } returns configFileCollection
        every { projectIntermediary.files("${interDirFile}/flutter_build.d") } returns configFileCollection
        every { configFileCollection.plus(configFileCollection)} returns configFileCollection

        val depFiles: FileCollection = helper.getDependenciesFiles()
        verify { projectIntermediary.files() }
        verify { projectIntermediary.files("${intermediateDirFile}/flutter_build.d") }
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
                    helper.gradleErrorMessage
        )
    }

    @Test
    fun `checkPreConditions throws a GradleException when sourceDir is not a directory`() {
        val baseFlutterTask = mockk<BaseFlutterTask>()
        val file = mockk<File>()
        every { baseFlutterTask.sourceDir } returns file
        every { baseFlutterTask.sourceDir!!.isDirectory } returns false

        val helper = BaseFlutterTaskHelper(baseFlutterTask)

        val gradleException =
            assertFailsWith<GradleException> { helper.checkPreConditions() }
        assert(
            gradleException.message ==
                    helper.gradleErrorMessage
        )
    }

    @Test
    fun `verify execSpecActionFromTask creates and executes with non-null properties`() {
        val flutterExecutablePath = "path/to/flutter/executable"
        val flutterRootAbsolutePath = "path/to/flutter"
        val flutterTargetFilePath = "path/to/flutter/examples/splash/lib/main.dart"
        val file = mockk<File>()
        val testString = "testString"
        val testingFile = File("foo")
        val testBool = true
        val testList = listOf("foo", "bar")
        val testJoinedList = "foo bar"
        val testMinSDKVersion = 21
        val buildModeDebugString = "debug"

        // Create necessary mocks.
        val baseFlutterTask = mockk<BaseFlutterTask>()
        val mockExecSpec = mockk<ExecSpec>()
        val mockProcessForkOptions = mockk<ProcessForkOptions>()

        // When baseFlutterTask.sourceDir is null, an exception is thrown. We mock its return value
        // before creating a BaseFlutterTaskHelper object.
        every { baseFlutterTask.sourceDir } returns testingFile
        val helper = BaseFlutterTaskHelper(baseFlutterTask)
        val execSpecActionFromTask = helper.createExecSpecActionFromTask()

        // Mock return values of properties.
        every { baseFlutterTask.flutterExecutable } returns file
        every { baseFlutterTask.flutterExecutable.absolutePath } returns flutterExecutablePath

        every { baseFlutterTask.localEngine } returns testString
        every { baseFlutterTask.localEngineSrcPath } returns testString

        every { baseFlutterTask.localEngineHost } returns testString
        every { baseFlutterTask.verbose } returns true
        every { baseFlutterTask.intermediateDir } returns testingFile
        every { baseFlutterTask.performanceMeasurementFile } returns testString

        every { baseFlutterTask.fastStart } returns true
        every { baseFlutterTask.buildMode } returns buildModeDebugString
        every { baseFlutterTask.flutterRoot } returns file
        every { baseFlutterTask.flutterRoot.absolutePath } returns flutterRootAbsolutePath

        every { baseFlutterTask.trackWidgetCreation } returns testBool
        every { baseFlutterTask.splitDebugInfo } returns testString
        every { baseFlutterTask.treeShakeIcons } returns testBool

        every { baseFlutterTask.dartObfuscation } returns testBool
        every { baseFlutterTask.dartDefines } returns testString
        every { baseFlutterTask.bundleSkSLPath } returns testString

        every { baseFlutterTask.codeSizeDirectory } returns testString
        every { baseFlutterTask.flavor } returns testString
        every { baseFlutterTask.extraGenSnapshotOptions } returns testString

        every { baseFlutterTask.frontendServerStarterPath } returns testString
        every { baseFlutterTask.extraFrontEndOptions } returns testString

        every { baseFlutterTask.targetPlatformValues } returns testList

        every { baseFlutterTask.minSdkVersion } returns testMinSDKVersion

        // Mock the actual method calls. We don't make real calls because we cannot create a real
        // ExecSpec object.
        val taskAbsolutePath = baseFlutterTask.flutterExecutable.absolutePath
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
        every { mockExecSpec.args("--output", intermediateDir ) } returns mockExecSpec

        val performanceMeasurementFile = baseFlutterTask.performanceMeasurementFile
        every { mockExecSpec.args("--performance-measurement-file=${performanceMeasurementFile}") } returns mockExecSpec
        val taskRootAbsolutePath = baseFlutterTask.flutterRoot.absolutePath
        val targetFilePath = Paths.get(taskRootAbsolutePath, "examples", "splash", "lib", "main.dart")
        every { mockExecSpec.args("-dTargetFile=${targetFilePath}") } returns mockExecSpec

        every { mockExecSpec.args("-dTargetPlatform=android") } returns mockExecSpec

        val buildModeTaskString = baseFlutterTask.buildMode
        every { mockExecSpec.args("-dBuildMode=${buildModeTaskString}") } returns mockExecSpec

        val trackWidgetCreationBool = baseFlutterTask.trackWidgetCreation
        every { mockExecSpec.args("-dTrackWidgetCreation=${trackWidgetCreationBool}") } returns mockExecSpec

        val splitDebugInfo = baseFlutterTask.splitDebugInfo
        every { mockExecSpec.args("-dSplitDebugInfo=${splitDebugInfo}") } returns mockExecSpec
        every { mockExecSpec.args("-dTreeShakeIcons=true") } returns mockExecSpec

        every { mockExecSpec.args("-dDartObfuscation=true") } returns mockExecSpec
        val dartDefines = baseFlutterTask.dartDefines
        every { mockExecSpec.args("--DartDefines=${dartDefines}") } returns mockExecSpec
        val bundleSkSLPath = baseFlutterTask.bundleSkSLPath
        every { mockExecSpec.args("-dBundleSkSLPath=${bundleSkSLPath}") } returns mockExecSpec

        val codeSizeDirectory = baseFlutterTask.codeSizeDirectory
        every { mockExecSpec.args("-dCodeSizeDirectory=${codeSizeDirectory}") } returns mockExecSpec
        val flavor = baseFlutterTask.flavor
        every { mockExecSpec.args("-dFlavor=${flavor}") } returns mockExecSpec
        val extraGenSnapshotOptions = baseFlutterTask.extraGenSnapshotOptions
        every { mockExecSpec.args("--ExtraGenSnapshotOptions=${extraGenSnapshotOptions}") } returns mockExecSpec

        val frontServerStarterPath = baseFlutterTask.frontendServerStarterPath
        every { mockExecSpec.args("-dFrontendServerStarterPath=${frontServerStarterPath}") } returns mockExecSpec
        val extraFrontEndOptions = baseFlutterTask.extraFrontEndOptions
        every { mockExecSpec.args("--ExtraFrontEndOptions=${extraFrontEndOptions}") } returns mockExecSpec

        val joinTestList = testList.joinToString(" ")
        every { mockExecSpec.args("-dAndroidArchs=${joinTestList}") } returns mockExecSpec

        val minSdkVersionInt = baseFlutterTask.minSdkVersion.toString()
        every { mockExecSpec.args("-dMinSdkVersion=${minSdkVersionInt}") } returns mockExecSpec

        val ruleNameList: List<String> = helper.generateRuleNames(baseFlutterTask)
        every { mockExecSpec.args(ruleNameList) } returns mockExecSpec

        // The exec function will be deprecated in gradle 8.11 and will be removed in gradle 9.0
        // https://docs.gradle.org/current/kotlin-dsl/gradle/org.gradle.kotlin.dsl/-kotlin-script/exec.html?query=abstract%20fun%20exec(configuration:%20Action%3CExecSpec%3E):%20ExecResult
        // The actions are executed.
        execSpecActionFromTask.execute(mockExecSpec)

        // After execution, we verify the functions are actually being
        // called.
        verify { mockExecSpec.executable(flutterExecutablePath) }
        verify { mockExecSpec.workingDir(testingFile) }
        verify { mockExecSpec.args("--local-engine", testString) }
        verify { mockExecSpec.args("--local-engine-src-path", testString) }
        verify { mockExecSpec.args("--local-engine-host", testString) }
        verify { mockExecSpec.args("--verbose") }
        verify { mockExecSpec.args("assemble") }
        verify { mockExecSpec.args("--no-version-check") }
        verify { mockExecSpec.args("--depfile", "${testingFile}/flutter_build.d") }
        verify { mockExecSpec.args("--output", "$testingFile") }
        verify { mockExecSpec.args("--performance-measurement-file=${testString}") }
        verify { mockExecSpec.args("-dTargetFile=${flutterTargetFilePath}") }
        verify { mockExecSpec.args("-dTargetPlatform=android") }
        verify { mockExecSpec.args("-dBuildMode=${buildModeDebugString}") }
        verify { mockExecSpec.args("-dTrackWidgetCreation=${testBool}") }
        verify { mockExecSpec.args("-dSplitDebugInfo=${testString}") }
        verify { mockExecSpec.args("-dTreeShakeIcons=true") }
        verify { mockExecSpec.args("-dDartObfuscation=true") }
        verify { mockExecSpec.args("--DartDefines=${testString}") }
        verify { mockExecSpec.args("-dBundleSkSLPath=${testString}") }
        verify { mockExecSpec.args("-dCodeSizeDirectory=${testString}") }
        verify { mockExecSpec.args("-dFlavor=${testString}") }
        verify { mockExecSpec.args("--ExtraGenSnapshotOptions=${testString}") }
        verify { mockExecSpec.args("-dFrontendServerStarterPath=${testString}") }
        verify { mockExecSpec.args("--ExtraFrontEndOptions=${testString}") }
        verify { mockExecSpec.args("-dAndroidArchs=${testJoinedList}") }
        verify { mockExecSpec.args("-dMinSdkVersion=${testMinSDKVersion}") }
        assertEquals(ruleNameList, listOf("debug_android_application"))
        verify { mockExecSpec.args(ruleNameList) }
    }

    @Test
    fun `verify execSpecActionFromTask creates and executes with null properties`() {
        val flutterExecutablePath = "path/to/flutter/executable"
        val flutterRootAbsolutePath = "path/to/flutter"
        val flutterTargetFilePath = "path/to/flutter/examples/splash/lib/main.dart"
        val file = mockk<File>()
//        val testString = "testString"
        val testingFile = File("foo")
        val testList = listOf("foo", "bar")
        val testJoinedList = "foo bar"
        val testMinSDKVersion = 21
        val buildModeDebugString = "debug"

        // Create necessary mocks.
        val baseFlutterTask = mockk<BaseFlutterTask>()
        val mockExecSpec = mockk<ExecSpec>()
        val mockProcessForkOptions = mockk<ProcessForkOptions>()

        // When baseFlutterTask.sourceDir is null, an exception is thrown. We mock its return value
        // before creating a BaseFlutterTaskHelper object.
        every { baseFlutterTask.sourceDir } returns testingFile
        val helper = BaseFlutterTaskHelper(baseFlutterTask)
        val execSpecActionFromTask = helper.createExecSpecActionFromTask()

        // Mock return values of properties.
        every { baseFlutterTask.flutterExecutable } returns file
        every { baseFlutterTask.flutterExecutable.absolutePath } returns flutterExecutablePath

        every { baseFlutterTask.localEngine } returns null
        every { baseFlutterTask.localEngineSrcPath } returns null

        every { baseFlutterTask.localEngineHost } returns null
        every { baseFlutterTask.verbose } returns true
        every { baseFlutterTask.intermediateDir } returns testingFile
        every { baseFlutterTask.performanceMeasurementFile } returns null

        every { baseFlutterTask.fastStart } returns true
        every { baseFlutterTask.buildMode } returns buildModeDebugString
        every { baseFlutterTask.flutterRoot } returns file
        every { baseFlutterTask.flutterRoot.absolutePath } returns flutterRootAbsolutePath

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

        every { baseFlutterTask.targetPlatformValues } returns testList

        every { baseFlutterTask.minSdkVersion } returns testMinSDKVersion

        // Mock the actual method calls. We don't make real calls because we cannot create a real
        // ExecSpec object.
        val taskAbsolutePath = baseFlutterTask.flutterExecutable.absolutePath
        every { mockExecSpec.executable(taskAbsolutePath) } returns mockProcessForkOptions

        val sourceDirFile = baseFlutterTask.sourceDir
        every { mockExecSpec.workingDir(sourceDirFile) } returns mockProcessForkOptions

        every { mockExecSpec.args("--verbose") } returns mockExecSpec
        every { mockExecSpec.args("assemble") } returns mockExecSpec
        every { mockExecSpec.args("--no-version-check") } returns mockExecSpec

        val intermediateDir = baseFlutterTask.intermediateDir.toString()
        val depfilePath = "$intermediateDir/flutter_build.d"
        every { mockExecSpec.args("--depfile", depfilePath) } returns mockExecSpec
        every { mockExecSpec.args("--output", intermediateDir ) } returns mockExecSpec

        val taskRootAbsolutePath = baseFlutterTask.flutterRoot.absolutePath
        val targetFilePath = Paths.get(taskRootAbsolutePath, "examples", "splash", "lib", "main.dart")
        every { mockExecSpec.args("-dTargetFile=${targetFilePath}") } returns mockExecSpec
        every { mockExecSpec.args("-dTargetPlatform=android") } returns mockExecSpec

        val buildModeTaskString = baseFlutterTask.buildMode
        every { mockExecSpec.args("-dBuildMode=${buildModeTaskString}") } returns mockExecSpec

        val joinTestList = testList.joinToString(" ")
        every { mockExecSpec.args("-dAndroidArchs=${joinTestList}") } returns mockExecSpec

        val minSdkVersionInt = baseFlutterTask.minSdkVersion.toString()
        every { mockExecSpec.args("-dMinSdkVersion=${minSdkVersionInt}") } returns mockExecSpec

        val ruleNameList: List<String> = helper.generateRuleNames(baseFlutterTask)
        every { mockExecSpec.args(ruleNameList) } returns mockExecSpec

        // The exec function will be deprecated in gradle 8.11 and will be removed in gradle 9.0
        // https://docs.gradle.org/current/kotlin-dsl/gradle/org.gradle.kotlin.dsl/-kotlin-script/exec.html?query=abstract%20fun%20exec(configuration:%20Action%3CExecSpec%3E):%20ExecResult
        // The actions are executed.
        execSpecActionFromTask.execute(mockExecSpec)

        // After execution, we verify the functions are actually being
        // called.
        verify { mockExecSpec.executable(flutterExecutablePath) }
        verify { mockExecSpec.workingDir(testingFile) }
        verify { mockExecSpec.args("--verbose") }
        verify { mockExecSpec.args("assemble") }
        verify { mockExecSpec.args("--no-version-check") }
        verify { mockExecSpec.args("--depfile", "${testingFile}/flutter_build.d") }
        verify { mockExecSpec.args("--output", "$testingFile") }
        verify { mockExecSpec.args("-dTargetFile=${flutterTargetFilePath}") }
        verify { mockExecSpec.args("-dTargetPlatform=android") }
        verify { mockExecSpec.args("-dBuildMode=${buildModeDebugString}") }
        verify { mockExecSpec.args("-dAndroidArchs=${testJoinedList}") }
        verify { mockExecSpec.args("-dMinSdkVersion=${testMinSDKVersion}") }
        assertEquals(ruleNameList, listOf("debug_android_application"))
        verify { mockExecSpec.args(ruleNameList) }
    }

    @Test
    fun `verify execSpecActionFromTask creates and executes with null properties and goes into different branches`() {
        val flutterExecutableAbsolutePath = "path/to/flutter/executable"
        val file = mockk<File>()
        val testString = "testString"
        val testingFile = File("foo")
        val testList = listOf("foo", "bar")
        val testJoinedList = "foo bar"
        val testMinSDKVersion = 21
        val buildModeReleaseString = "release"
        val targetPlatformValuesList = listOf("foo", "bar")
        val ruleNameListForDeferredComponentsTestList = listOf("android_aot_deferred_components_bundle_release_foo", "android_aot_deferred_components_bundle_release_bar")

        // Create necessary mocks.
        val baseFlutterTask = mockk<BaseFlutterTask>()
        val mockExecSpec = mockk<ExecSpec>()
        val mockProcessForkOptions = mockk<ProcessForkOptions>()

        // When baseFlutterTask.sourceDir is null, an exception is thrown. We mock its return value
        // before creating a BaseFlutterTaskHelper object.
        every { baseFlutterTask.sourceDir } returns testingFile
        val helper = BaseFlutterTaskHelper(baseFlutterTask)
        val execSpecActionFromTask = helper.createExecSpecActionFromTask()

        // Mock return values of properties.
        every { baseFlutterTask.flutterExecutable } returns file
        every { baseFlutterTask.flutterExecutable.absolutePath } returns flutterExecutableAbsolutePath

        every { baseFlutterTask.localEngine } returns null
        every { baseFlutterTask.localEngineSrcPath } returns null

        every { baseFlutterTask.localEngineHost } returns null
        every { baseFlutterTask.verbose } returns false
        every { baseFlutterTask.intermediateDir } returns testingFile
        every { baseFlutterTask.performanceMeasurementFile } returns null

        every { baseFlutterTask.fastStart } returns false
        every { baseFlutterTask.buildMode } returns buildModeReleaseString
        every { baseFlutterTask.targetPath } returns testString

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

        every { baseFlutterTask.targetPlatformValues } returns testList

        every { baseFlutterTask.minSdkVersion } returns testMinSDKVersion

        every { baseFlutterTask.deferredComponents } returns true
        every { baseFlutterTask.targetPlatformValues } returns targetPlatformValuesList

        // Mock the actual method calls. We don't make real calls because we cannot create a real
        // ExecSpec object.
        val taskExecutableAbsolutePath = baseFlutterTask.flutterExecutable.absolutePath
        every { mockExecSpec.executable(taskExecutableAbsolutePath) } returns mockProcessForkOptions

        val sourceDirFile = baseFlutterTask.sourceDir
        every { mockExecSpec.workingDir(sourceDirFile) } returns mockProcessForkOptions

        every { mockExecSpec.args("--quiet") } returns mockExecSpec
        every { mockExecSpec.args("assemble") } returns mockExecSpec
        every { mockExecSpec.args("--no-version-check") } returns mockExecSpec

        val intermediateDir = baseFlutterTask.intermediateDir.toString()
        val depfilePath = "$intermediateDir/flutter_build.d"
        every { mockExecSpec.args("--depfile", depfilePath) } returns mockExecSpec
        every { mockExecSpec.args("--output", intermediateDir ) } returns mockExecSpec

        val targetFilePath = baseFlutterTask.targetPath
        every { mockExecSpec.args("-dTargetFile=${targetFilePath}") } returns mockExecSpec
        every { mockExecSpec.args("-dTargetPlatform=android") } returns mockExecSpec

        val buildModeTaskString = baseFlutterTask.buildMode
        every { mockExecSpec.args("-dBuildMode=${buildModeTaskString}") } returns mockExecSpec

        val joinTestList = testList.joinToString(" ")
        every { mockExecSpec.args("-dAndroidArchs=${joinTestList}") } returns mockExecSpec

        val minSdkVersionInt = baseFlutterTask.minSdkVersion.toString()
        every { mockExecSpec.args("-dMinSdkVersion=${minSdkVersionInt}") } returns mockExecSpec

        val ruleNameList: List<String> = helper.generateRuleNames(baseFlutterTask)
        every { mockExecSpec.args(ruleNameList) } returns mockExecSpec

        // The exec function will be deprecated in gradle 8.11 and will be removed in gradle 9.0
        // https://docs.gradle.org/current/kotlin-dsl/gradle/org.gradle.kotlin.dsl/-kotlin-script/exec.html?query=abstract%20fun%20exec(configuration:%20Action%3CExecSpec%3E):%20ExecResult
        // The actions are executed.
        execSpecActionFromTask.execute(mockExecSpec)

        // After execution, we verify the functions are actually being
        // called.
        verify { mockExecSpec.executable(flutterExecutableAbsolutePath) }
        verify { mockExecSpec.workingDir(testingFile) }
        verify { mockExecSpec.args("--quiet") }
        verify { mockExecSpec.args("assemble") }
        verify { mockExecSpec.args("--no-version-check") }
        verify { mockExecSpec.args("--depfile", "${testingFile}/flutter_build.d") }
        verify { mockExecSpec.args("--output", "$testingFile") }
        verify { mockExecSpec.args("-dTargetFile=${testString}") }
        verify { mockExecSpec.args("-dTargetPlatform=android") }
        verify { mockExecSpec.args("-dBuildMode=${buildModeReleaseString}") }
        verify { mockExecSpec.args("-dAndroidArchs=${testJoinedList}") }
        verify { mockExecSpec.args("-dMinSdkVersion=${testMinSDKVersion}") }
        assertEquals(ruleNameList, ruleNameListForDeferredComponentsTestList)
        verify { mockExecSpec.args(ruleNameList) }
    }

    @Test
    fun `verify execSpecActionFromTask creates and executes with null properties and goes into other different branches`() {
        val flutterExecutableAbsolutePath = "path/to/flutter/executable"
        val file = mockk<File>()
        val testString = "testString"
        val testingFile = File("foo")
        val testList = listOf("foo", "bar")
        val testJoinedList = "foo bar"
        val testMinSDKVersion = 21
        val buildModeReleaseString = "release"
        val targetPlatformValuesList = listOf("foo", "bar")
        val ruleNameListForTestList = listOf("android_aot_bundle_release_foo", "android_aot_bundle_release_bar")

        // Create necessary mocks.
        val baseFlutterTask = mockk<BaseFlutterTask>()
        val mockExecSpec = mockk<ExecSpec>()
        val mockProcessForkOptions = mockk<ProcessForkOptions>()

        // When baseFlutterTask.sourceDir is null, an exception is thrown. We mock its return value
        // before creating a BaseFlutterTaskHelper object.
        every { baseFlutterTask.sourceDir } returns testingFile
        val helper = BaseFlutterTaskHelper(baseFlutterTask)
        val execSpecActionFromTask = helper.createExecSpecActionFromTask()

        // Mock return values of properties.
        every { baseFlutterTask.flutterExecutable } returns file
        every { baseFlutterTask.flutterExecutable.absolutePath } returns flutterExecutableAbsolutePath

        every { baseFlutterTask.localEngine } returns null
        every { baseFlutterTask.localEngineSrcPath } returns null

        every { baseFlutterTask.localEngineHost } returns null
        every { baseFlutterTask.verbose } returns false
        every { baseFlutterTask.intermediateDir } returns testingFile
        every { baseFlutterTask.performanceMeasurementFile } returns null

        every { baseFlutterTask.fastStart } returns false
        every { baseFlutterTask.buildMode } returns buildModeReleaseString
        every { baseFlutterTask.targetPath } returns testString

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

        every { baseFlutterTask.targetPlatformValues } returns testList

        every { baseFlutterTask.minSdkVersion } returns testMinSDKVersion

        every { baseFlutterTask.deferredComponents } returns false
        every { baseFlutterTask.targetPlatformValues } returns targetPlatformValuesList

        // Mock the actual method calls. We don't make real calls because we cannot create a real
        // ExecSpec object.
        val taskExecutableAbsolutePath = baseFlutterTask.flutterExecutable.absolutePath
        every { mockExecSpec.executable(taskExecutableAbsolutePath) } returns mockProcessForkOptions

        val sourceDirFile = baseFlutterTask.sourceDir
        every { mockExecSpec.workingDir(sourceDirFile) } returns mockProcessForkOptions

        every { mockExecSpec.args("--quiet") } returns mockExecSpec
        every { mockExecSpec.args("assemble") } returns mockExecSpec
        every { mockExecSpec.args("--no-version-check") } returns mockExecSpec

        val intermediateDir = baseFlutterTask.intermediateDir.toString()
        val depfilePath = "$intermediateDir/flutter_build.d"
        every { mockExecSpec.args("--depfile", depfilePath) } returns mockExecSpec
        every { mockExecSpec.args("--output", intermediateDir ) } returns mockExecSpec

        val targetFilePath = baseFlutterTask.targetPath
        every { mockExecSpec.args("-dTargetFile=${targetFilePath}") } returns mockExecSpec
        every { mockExecSpec.args("-dTargetPlatform=android") } returns mockExecSpec

        val buildModeTaskString = baseFlutterTask.buildMode
        every { mockExecSpec.args("-dBuildMode=${buildModeTaskString}") } returns mockExecSpec

        val joinTestList = testList.joinToString(" ")
        every { mockExecSpec.args("-dAndroidArchs=${joinTestList}") } returns mockExecSpec

        val minSdkVersionInt = baseFlutterTask.minSdkVersion.toString()
        every { mockExecSpec.args("-dMinSdkVersion=${minSdkVersionInt}") } returns mockExecSpec

        val ruleNameList: List<String> = helper.generateRuleNames(baseFlutterTask)
        every { mockExecSpec.args(ruleNameList) } returns mockExecSpec

        // The exec function will be deprecated in gradle 8.11 and will be removed in gradle 9.0
        // https://docs.gradle.org/current/kotlin-dsl/gradle/org.gradle.kotlin.dsl/-kotlin-script/exec.html?query=abstract%20fun%20exec(configuration:%20Action%3CExecSpec%3E):%20ExecResult
        // The actions are executed.
        execSpecActionFromTask.execute(mockExecSpec)

        // After execution, we verify the functions are actually being
        // called.
        verify { mockExecSpec.executable(flutterExecutableAbsolutePath) }
        verify { mockExecSpec.workingDir(testingFile) }
        verify { mockExecSpec.args("--quiet") }
        verify { mockExecSpec.args("assemble") }
        verify { mockExecSpec.args("--no-version-check") }
        verify { mockExecSpec.args("--depfile", "${testingFile}/flutter_build.d") }
        verify { mockExecSpec.args("--output", "$testingFile") }
        verify { mockExecSpec.args("-dTargetFile=${testString}") }
        verify { mockExecSpec.args("-dTargetPlatform=android") }
        verify { mockExecSpec.args("-dBuildMode=${buildModeReleaseString}") }
        verify { mockExecSpec.args("-dAndroidArchs=${testJoinedList}") }
        verify { mockExecSpec.args("-dMinSdkVersion=${testMinSDKVersion}") }
        assertEquals(ruleNameList, ruleNameListForTestList)
        verify { mockExecSpec.args(ruleNameList) }
    }
}

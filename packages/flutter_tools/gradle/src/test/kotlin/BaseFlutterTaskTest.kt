package com.flutter.gradle

import com.flutter.gradle.BaseFlutterTaskHelperTest.BaseFlutterTaskPropertiesTest
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.gradle.api.Project
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.process.ExecSpec
import org.gradle.process.ProcessForkOptions
import org.junit.jupiter.api.assertDoesNotThrow
import kotlin.test.Test

class BaseFlutterTaskTest {
    @Test
    fun `getDependencyFiles returns a FileCollection of dependency file(s)`() {
        val baseFlutterTask = mockk<BaseFlutterTask>()
        val project = mockk<Project>()
        val configFileCollection = mockk<ConfigurableFileCollection>()
        every { baseFlutterTask.sourceDir } returns BaseFlutterTaskPropertiesTest.sourceDirTest

        val helper = BaseFlutterTaskHelper(baseFlutterTask)

        every { baseFlutterTask.project } returns project
        every { baseFlutterTask.intermediateDir } returns BaseFlutterTaskPropertiesTest.intermediateDirFileTest

        val projectIntermediary = baseFlutterTask.project
        val interDirFile = baseFlutterTask.intermediateDir

        every { projectIntermediary.files() } returns configFileCollection
        every { projectIntermediary.files("$interDirFile/flutter_build.d") } returns configFileCollection
        every { configFileCollection.plus(configFileCollection) } returns configFileCollection

        helper.getDependenciesFiles()
        verify { projectIntermediary.files() }
        verify { projectIntermediary.files("${BaseFlutterTaskPropertiesTest.intermediateDirFileTest}/flutter_build.d") }
    }

    @Test
    fun `buildBundle builds a Flutter application bundle for Android`() {
        val buildModeString = "debug"

        // Create necessary mocks.
        val baseFlutterTask = mockk<BaseFlutterTask>()
        val mockExecSpec = mockk<ExecSpec>()
        val mockProcessForkOptions = mockk<ProcessForkOptions>()

        // Check preconditions
        every { baseFlutterTask.sourceDir } returns BaseFlutterTaskPropertiesTest.sourceDirTest
        every { baseFlutterTask.sourceDir!!.isDirectory } returns true

        every { baseFlutterTask.intermediateDir } returns BaseFlutterTaskPropertiesTest.intermediateDirFileTest
        every { baseFlutterTask.intermediateDir!!.mkdirs() } returns false

        val helper = BaseFlutterTaskHelper(baseFlutterTask)
        assertDoesNotThrow { helper.checkPreConditions() }

        // Create action to be executed.
        val execSpecActionFromTask = helper.createExecSpecActionFromTask()

        // Mock return values of properties.
        every { baseFlutterTask.flutterExecutable } returns BaseFlutterTaskPropertiesTest.flutterExecutableTest
        every {
            baseFlutterTask.flutterExecutable!!.absolutePath
        } returns BaseFlutterTaskPropertiesTest.FLUTTER_EXECUTABLE_ABSOLUTE_PATH_TEST
        every { baseFlutterTask.sourceDir } returns BaseFlutterTaskPropertiesTest.sourceDirTest

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

        // Mock the method calls. We collapse all the args mock calls into four calls.
        every { mockExecSpec.executable(any<String>()) } returns mockExecSpec
        every { mockExecSpec.workingDir(any()) } returns mockProcessForkOptions
        every { mockExecSpec.args(any<String>(), any()) } returns mockExecSpec
        every { mockExecSpec.args(any<String>(), any()) } returns mockExecSpec
        every { mockExecSpec.args(any<String>()) } returns mockExecSpec
        every { mockExecSpec.args(any<List<String>>()) } returns mockExecSpec

        // Generate rule names for verification and can only be generated after buildMode is mocked.
        val ruleNamesList: List<String> = helper.generateRuleNames(baseFlutterTask)

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
}

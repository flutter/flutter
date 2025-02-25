package com.flutter.gradle

import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.gradle.api.GradleException
import org.gradle.kotlin.dsl.internal.sharedruntime.codegen.pluginEntriesFrom
import org.gradle.process.ExecSpec
import org.gradle.process.ProcessForkOptions
import java.io.File
import java.nio.file.Path
import java.nio.file.Paths
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class BaseFlutterTaskTest {
    @Test
    fun `buildBundle throws a GradleException when sourceDir is null`() {
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
    fun `buildBundle throws a GradleException when sourceDir is not a directory`() {
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
    fun `we testing`() {
        val baseFlutterTask = mockk<BaseFlutterTask>()
        val flutterExecutablePath = ""
        val file = mockk<File>()
        val testString = ""
        val testingFile = File("bob")
        val testBool = true
        val testList = listOf("bob", "fred")
        val testJoinedList = "bob fred"
        val testMinSDKVersion = 21
        val buildModeDebugString = "debug"

        every { baseFlutterTask.sourceDir } returns file
        val helper = BaseFlutterTaskHelper(baseFlutterTask)

        val execSpecActionFromTask = helper.createExecSpecActionFromTask()
        val mockExecSpec = mockk<ExecSpec>()
        val mockProcessForkOptions = mockk<ProcessForkOptions>()

        // mock return values of properties
        every { baseFlutterTask.flutterExecutable } returns file
        every { baseFlutterTask.flutterExecutable?.absolutePath } returns flutterExecutablePath
        every { mockExecSpec.executable(baseFlutterTask.flutterExecutable?.absolutePath) } returns mockProcessForkOptions

        every { mockExecSpec.workingDir(baseFlutterTask.sourceDir) } returns mockProcessForkOptions

        every { baseFlutterTask.localEngine } returns testString
        every { mockExecSpec.args("--local-engine", baseFlutterTask.localEngine) } returns mockExecSpec
        every { baseFlutterTask.localEngineSrcPath } returns testString
        every { mockExecSpec.args("--local-engine-src-path", baseFlutterTask.localEngineSrcPath) } returns mockExecSpec

        every { baseFlutterTask.localEngineHost } returns testString
        every { mockExecSpec.args("--local-engine-host", baseFlutterTask.localEngineHost) } returns mockExecSpec

        every { baseFlutterTask.verbose } returns true
        every { mockExecSpec.args("--verbose") } returns mockExecSpec

        every { mockExecSpec.args("assemble") } returns mockExecSpec

        every { mockExecSpec.args("--no-version-check") } returns mockExecSpec

        every { baseFlutterTask.intermediateDir } returns testingFile
        val intermediateDir = baseFlutterTask.intermediateDir.toString()
        val depfilePath = "$intermediateDir/flutter_build.d"
        every { mockExecSpec.args("--depfile", depfilePath) } returns mockExecSpec
        every { mockExecSpec.args("--output", intermediateDir ) } returns mockExecSpec

        every { baseFlutterTask.performanceMeasurementFile } returns testString
        every { mockExecSpec.args("--performance-measurement-file=${baseFlutterTask.performanceMeasurementFile}") } returns mockExecSpec

        every { mockExecSpec.args("-dTargetPlatform=android") } returns mockExecSpec

        every { baseFlutterTask.buildMode } returns buildModeDebugString
        val buildModeTaskString = baseFlutterTask.buildMode
        every { mockExecSpec.args("-dBuildMode=${buildModeTaskString}") } returns mockExecSpec

        every { baseFlutterTask.trackWidgetCreation } returns testBool
        val trackWidgetCreationBool = baseFlutterTask.trackWidgetCreation
        every { mockExecSpec.args("-dTrackWidgetCreation=${trackWidgetCreationBool}") } returns mockExecSpec

        every { baseFlutterTask.splitDebugInfo } returns testString
        every { mockExecSpec.args("-dSplitDebugInfo=${baseFlutterTask.splitDebugInfo}") } returns mockExecSpec

        every { baseFlutterTask.treeShakeIcons } returns testBool
        every { mockExecSpec.args("-dTreeShakeIcons=true") } returns mockExecSpec

        every { baseFlutterTask.dartObfuscation } returns testBool
        every { mockExecSpec.args("-dDartObfuscation=true") } returns mockExecSpec

        every { baseFlutterTask.dartDefines } returns testString
        every { mockExecSpec.args("--DartDefines=${baseFlutterTask.dartDefines}") } returns mockExecSpec

        every { baseFlutterTask.bundleSkSLPath } returns testString
        every { mockExecSpec.args("-dBundleSkSLPath=${baseFlutterTask.bundleSkSLPath}") } returns mockExecSpec

        every { baseFlutterTask.codeSizeDirectory } returns testString
        every { mockExecSpec.args("-dCodeSizeDirectory=${baseFlutterTask.codeSizeDirectory}") } returns mockExecSpec

        every { baseFlutterTask.flavor } returns testString
        every { mockExecSpec.args("-dFlavor=${baseFlutterTask.flavor}") } returns mockExecSpec

        every { baseFlutterTask.extraGenSnapshotOptions } returns testString
        every { mockExecSpec.args("--ExtraGenSnapshotOptions=${baseFlutterTask.extraGenSnapshotOptions}") } returns mockExecSpec

        every { baseFlutterTask.frontendServerStarterPath } returns testString
        every { mockExecSpec.args("-dFrontendServerStarterPath=${baseFlutterTask.frontendServerStarterPath}") } returns mockExecSpec

        every { baseFlutterTask.extraFrontEndOptions } returns testString
        every { mockExecSpec.args("--ExtraFrontEndOptions=${baseFlutterTask.extraFrontEndOptions}") } returns mockExecSpec

        every { baseFlutterTask.fastStart } returns false
        every { baseFlutterTask.targetPath } returns testString
        every { mockExecSpec.args("-dTargetFile=${baseFlutterTask.targetPath}") } returns mockExecSpec

        every { baseFlutterTask.minSdkVersion } returns testMinSDKVersion
        val minSdkVersionInt = baseFlutterTask.minSdkVersion.toString()
        every { mockExecSpec.args("-dMinSdkVersion=${minSdkVersionInt}") } returns mockExecSpec

        every { baseFlutterTask.buildMode } returns buildModeDebugString
        val ruleNameList: List<String> = helper.generateRuleNames(baseFlutterTask)
        every { mockExecSpec.args(ruleNameList) } returns mockExecSpec

        execSpecActionFromTask.execute(mockExecSpec)

        verify { mockExecSpec.executable(baseFlutterTask.flutterExecutable?.absolutePath) }
        verify { mockExecSpec.workingDir(baseFlutterTask.sourceDir) }
        verify { mockExecSpec.args("--local-engine", testString) }
        verify { mockExecSpec.args("--local-engine-src-path", testString) }
        verify { mockExecSpec.args("--local-engine-host", testString) }
        verify { mockExecSpec.args("--verbose") }
        verify { mockExecSpec.args("assemble") }
        verify { mockExecSpec.args("--no-version-check") }
        verify { mockExecSpec.args("--depfile", "${testingFile}/flutter_build.d") }
        verify { mockExecSpec.args("--output", "$testingFile") }
        verify { mockExecSpec.args("--performance-measurement-file=${testString}") }
        verify { mockExecSpec.args("-dTargetFile=${testString}") }
        // TODO(jesswon): call args("-dTargetFile=${Paths.get(baseFlutterTask.flutterRoot.absolutePath ?: "bob", "examples", "splash", "lib", "main.dart")}")
        verify { mockExecSpec.args("-dTargetPlatform=android") }
        verify { mockExecSpec.args("-dBuildMode=${buildModeDebugString}") }
        verify { mockExecSpec.args("-dTrackWidgetCreation=${testBool}") }
        verify { mockExecSpec.args("-dSplitDebugInfo=${testString}") }
        verify { mockExecSpec.args("-dTreeShakeIcons=true") }
        verify { mockExecSpec.args("-dDartObfuscation=true") }
        verify { mockExecSpec.args("--DartDefines=${testString}") }
        verify { mockExecSpec.args("-dBundleSkSLPath=${testString}") }
        verify { mockExecSpec.args("-dCodeSizeDirectory=${testString}") }
        verify { mockExecSpec.args("--ExtraGenSnapshotOptions=${testString}") }
        verify { mockExecSpec.args("-dFrontendServerStarterPath=${testString}") }

        verify { mockExecSpec.args("--ExtraFrontEndOptions=${testString}") }
//        verify { mockExecSpec.args("-dAndroidArchs=${testList}") }
        verify { mockExecSpec.args("-dMinSdkVersion=${testMinSDKVersion}") }

        assertEquals(ruleNameList, listOf("debug_android_application"))
        verify { mockExecSpec.args(ruleNameList) }

    }

}

package com.flutter.gradle

import io.mockk.CapturingSlot
import kotlin.test.assertEquals
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.gradle.api.Action
import org.gradle.api.GradleException
import org.gradle.api.Project
import org.gradle.process.ExecResult
import org.gradle.process.ExecSpec
import java.io.File
import kotlin.test.Test
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
    fun `buildBundle creates execSpecActionFromTask with non-null properties`() {
        val baseFlutterTask = mockk<BaseFlutterTask>()
        val flutterExecutablePath = "flutterExecutablePath"
        val file = mockk<File>()
        val testString = ""
        val debugInfoString = "debug"

        every { baseFlutterTask.flutterExecutable } returns file
        every { baseFlutterTask.flutterExecutable?.absolutePath } returns flutterExecutablePath
        every { baseFlutterTask.sourceDir } returns file

        every { baseFlutterTask.localEngine } returns testString
        every { baseFlutterTask.localEngineHost } returns testString
        every { baseFlutterTask.verbose } returns true
        every { baseFlutterTask.performanceMeasurementFile } returns testString

        // goes into the else condition
        every { baseFlutterTask.fastStart } returns true
        every { baseFlutterTask.buildMode } returns debugInfoString

        every { baseFlutterTask.trackWidgetCreation } returns true
        every { baseFlutterTask.splitDebugInfo } returns testString


        every { baseFlutterTask.treeShakeIcons } returns false
        every { baseFlutterTask.dartObfuscation } returns false

        every { baseFlutterTask.dartDefines } returns testString
        every { baseFlutterTask.bundleSkSLPath } returns testString
        every { baseFlutterTask.codeSizeDirectory } returns testString
        every { baseFlutterTask.flavor } returns testString
        every { baseFlutterTask.extraGenSnapshotOptions } returns testString
        every { baseFlutterTask.frontendServerStarterPath } returns testString
        every { baseFlutterTask.extraFrontEndOptions } returns testString
        every { baseFlutterTask.deferredComponents } returns true

        val helper = BaseFlutterTaskHelper(baseFlutterTask)

        // want to capture args (custom captor)
        // or get a REAL execSpec
        val mockProject = mockk<Project>()
        val execResult = mockk<ExecResult>()
        val slot = slot<Action<ExecSpec>>()

        val execSpecActionFromTask = helper.createExecSpecActionFromTask()

        // my capture attempt
        // can't verify mockProject.exec(capture(slot)) was ever called)
        every { mockProject.exec(execSpecActionFromTask) } returns execResult
        mockProject.exec(execSpecActionFromTask)
        verify { mockProject.exec(capture(slot)) }
        // assertEquals("test argument", slot.captured )

        // The exec function will be deprecated in gradle 8.11 and will be removed in gradle 9.0
        // https://docs.gradle.org/current/kotlin-dsl/gradle/org.gradle.kotlin.dsl/-kotlin-script/exec.html?query=abstract%20fun%20exec(configuration:%20Action%3CExecSpec%3E):%20ExecResult
        mockProject.exec(execSpecActionFromTask)

        assert(helper.flutterExecutablePath == "foo")
        assert(helper.workingDirectoryFile == file)

        val resList = listOf("bob")

        assert(helper.getAllArguments == resList)


    }

    // pass action exec spec into a mockk..call project.exec spec and use captor
    // to capture the input

}

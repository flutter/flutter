package com.flutter.gradle.plugins

import com.android.build.gradle.BaseExtension
import com.flutter.gradle.FlutterPluginUtilsTest.Companion.cameraDependency
import com.flutter.gradle.FlutterPluginUtilsTest.Companion.flutterPluginAndroidLifecycleDependency
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.gradle.api.Action
import org.gradle.api.Project
import org.gradle.api.artifacts.dsl.DependencyHandler
import org.junit.jupiter.api.assertThrows
import org.junit.jupiter.api.io.TempDir
import java.io.File
import java.nio.file.Path
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class PluginHandlerTest {
    // pluginSupportsAndroidPlatform
    @Test
    fun `pluginSupportsAndroidPlatform returns true when android directory exists with gradle build file`(
        @TempDir tempDir: Path
    ) {
        val projectDir = tempDir.resolve("my-plugin")
        projectDir.toFile().mkdirs()

        val androidDir = tempDir.resolve("android")
        androidDir.toFile().mkdirs()
        File(androidDir.toFile(), "build.gradle").createNewFile()

        val mockProject =
            mockk<Project> {
                every { this@mockk.projectDir } returns projectDir.toFile()
            }
        val pluginHandlerUnderTest = PluginHandler(mockProject)

        assertTrue {
            pluginHandlerUnderTest.pluginSupportsAndroidPlatform()
        } // Replace YourClass with the actual class containing the method
    }

    @Test
    fun `pluginSupportsAndroidPlatform returns false when gradle build file does not exist`(
        @TempDir tempDir: Path
    ) {
        val projectDir = tempDir.resolve("my-plugin")
        projectDir.toFile().mkdirs()

        val mockProject =
            mockk<Project> {
                every { this@mockk.projectDir } returns projectDir.toFile()
            }
        val pluginHandlerUnderTest = PluginHandler(mockProject)

        assertFalse {
            pluginHandlerUnderTest.pluginSupportsAndroidPlatform()
        }
    }

    // configurePluginDependencies
    @Test
    fun `configurePluginDependencies throws IllegalArgumentException when plugin has no name`() {
        val project = mockk<Project>()
        val pluginWithoutName: MutableMap<String?, Any?> = cameraDependency.toMutableMap()
        pluginWithoutName.remove("name")

        val pluginHandlerUnderTest = PluginHandler(project)
        assertThrows<IllegalArgumentException> {
            pluginHandlerUnderTest.configurePluginDependencies(
                pluginObject = pluginWithoutName
            )
        }
    }

    @Test
    fun `configurePluginDependencies throws IllegalArgumentException when plugin has null dependencies`() {
        val project = mockk<Project>()
        val pluginProject = mockk<Project>()
        val mockBuildType = mockk<com.android.build.gradle.internal.dsl.BuildType>()
        val pluginWithNullDependencies: MutableMap<String?, Any?> = cameraDependency.toMutableMap()
        pluginWithNullDependencies["dependencies"] = null
        every { project.rootProject.findProject(":${pluginWithNullDependencies["name"]}") } returns pluginProject
        every {
            project.extensions
                .findByType(BaseExtension::class.java)!!
                .buildTypes
                .iterator()
        } returns
            mutableListOf(
                mockBuildType
            ).iterator()
        every { mockBuildType.name } returns "debug"
        every { mockBuildType.isDebuggable } returns true

        val pluginHandlerUnderTest = PluginHandler(project)
        assertThrows<IllegalArgumentException> {
            pluginHandlerUnderTest.configurePluginDependencies(
                pluginObject = pluginWithNullDependencies
            )
        }
    }

    @Test
    fun `configurePluginDependencies adds plugin dependencies`() {
        val project = mockk<Project>()
        val pluginProject = mockk<Project>()
        val pluginDependencyProject = mockk<Project>()
        val mockBuildType = mockk<com.android.build.gradle.internal.dsl.BuildType>()
        val pluginWithDependencies: MutableMap<String?, Any?> = cameraDependency.toMutableMap()
        pluginWithDependencies["dependencies"] =
            listOf(flutterPluginAndroidLifecycleDependency["name"])
        every { project.rootProject.findProject(":${pluginWithDependencies["name"]}") } returns pluginProject
        every { project.rootProject.findProject(":${flutterPluginAndroidLifecycleDependency["name"]}") } returns pluginDependencyProject
        every {
            project.extensions
                .findByType(BaseExtension::class.java)!!
                .buildTypes
                .iterator()
        } returns
            mutableListOf(
                mockBuildType
            ).iterator()
        every { mockBuildType.name } returns "debug"
        every { mockBuildType.isDebuggable } returns true
        val captureActionSlot = slot<Action<Project>>()
        every { pluginProject.afterEvaluate(any<Action<Project>>()) } returns Unit
        val mockDependencyHandler = mockk<DependencyHandler>()
        every { pluginProject.dependencies } returns mockDependencyHandler
        every { mockDependencyHandler.add(any(), any()) } returns mockk()

        val pluginHandlerUnderTest = PluginHandler(project)
        pluginHandlerUnderTest.configurePluginDependencies(
            pluginObject = pluginWithDependencies
        )

        verify { pluginProject.afterEvaluate(capture(captureActionSlot)) }
        captureActionSlot.captured.execute(pluginDependencyProject)
        verify { mockDependencyHandler.add("implementation", pluginDependencyProject) }
    }
}

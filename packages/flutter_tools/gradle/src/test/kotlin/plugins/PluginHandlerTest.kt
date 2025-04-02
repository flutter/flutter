package com.flutter.gradle.plugins

import com.android.build.gradle.BaseExtension
import com.flutter.gradle.FlutterExtension
import com.flutter.gradle.FlutterPluginUtilsTest.Companion.cameraDependency
import com.flutter.gradle.FlutterPluginUtilsTest.Companion.exampleEngineVersion
import com.flutter.gradle.FlutterPluginUtilsTest.Companion.flutterPluginAndroidLifecycleDependency
import io.mockk.called
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.gradle.api.Action
import org.gradle.api.NamedDomainObjectContainer
import org.gradle.api.Project
import org.gradle.api.artifacts.dsl.DependencyHandler
import org.gradle.api.logging.Logger
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

        assertTrue {
            PluginHandler.pluginSupportsAndroidPlatform(mockProject)
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

        assertFalse {
            PluginHandler.pluginSupportsAndroidPlatform(mockProject)
        }
    }

    // configurePluginDependencies
    @Test
    fun `configurePluginDependencies throws IllegalArgumentException when plugin has no name`() {
        val project = mockk<Project>()
        val pluginWithoutName: MutableMap<String?, Any?> = cameraDependency.toMutableMap()
        pluginWithoutName.remove("name")

        assertThrows<IllegalArgumentException> {
            PluginHandler.configurePluginDependencies(
                project = project,
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

        assertThrows<IllegalArgumentException> {
            PluginHandler.configurePluginDependencies(
                project = project,
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

        PluginHandler.configurePluginDependencies(
            project = project,
            pluginObject = pluginWithDependencies
        )

        verify { pluginProject.afterEvaluate(capture(captureActionSlot)) }
        captureActionSlot.captured.execute(pluginDependencyProject)
        verify { mockDependencyHandler.add("implementation", pluginDependencyProject) }
    }

    // configurePluginProject
    @Test
    fun `configurePluginProject throws IllegalArgumentException when plugin has no name`() {
        val project = mockk<Project>()
        val pluginWithoutName: MutableMap<String?, Any?> = cameraDependency.toMutableMap()
        pluginWithoutName.remove("name")

        assertThrows<IllegalArgumentException> {
            PluginHandler.configurePluginProject(
                project = project,
                pluginObject = pluginWithoutName,
                engineVersion = exampleEngineVersion
            )
        }
    }

    @Test
    fun `configurePluginProject adds plugin project`() {
        val project = mockk<Project>()
        val pluginProject = mockk<Project>()
        val mockBuildType = mockk<com.android.build.gradle.internal.dsl.BuildType>()
        val mockLogger = mockk<Logger>()
        every { project.logger } returns mockLogger
        every { pluginProject.hasProperty("local-engine-repo") } returns false
        every { pluginProject.hasProperty("android") } returns true
        every { mockBuildType.name } returns "debug"
        every { mockBuildType.isDebuggable } returns true
        every { project.rootProject.findProject(":${cameraDependency["name"]}") } returns pluginProject
        every { pluginProject.extensions.create(any(), any<Class<Any>>()) } returns mockk()
        val captureActionSlot = slot<Action<Project>>()
        val capturePluginActionSlot = slot<Action<Project>>()
        every { project.afterEvaluate(any<Action<Project>>()) } returns Unit
        every { pluginProject.afterEvaluate(any<Action<Project>>()) } returns Unit

        val mockProjectBuildTypes =
            mockk<NamedDomainObjectContainer<com.android.build.gradle.internal.dsl.BuildType>>()
        val mockPluginProjectBuildTypes =
            mockk<NamedDomainObjectContainer<com.android.build.gradle.internal.dsl.BuildType>>()
        every { project.extensions.findByType(BaseExtension::class.java)!!.buildTypes } returns mockProjectBuildTypes
        every { pluginProject.extensions.findByType(BaseExtension::class.java)!!.buildTypes } returns mockPluginProjectBuildTypes
        every { mockPluginProjectBuildTypes.addAll(any()) } returns true
        every { pluginProject.configurations.named(any<String>()) } returns mockk()
        every { pluginProject.dependencies.add(any(), any()) } returns mockk()

        every {
            project.extensions
                .findByType(BaseExtension::class.java)!!
                .buildTypes
                .iterator()
        } returns
            mutableListOf(
                mockBuildType
            ).iterator() andThen
            mutableListOf( // can't return the same iterator as it is stateful
                mockBuildType
            ).iterator()
        every { project.dependencies.add(any(), any()) } returns mockk()
        every { project.extensions.findByType(BaseExtension::class.java)!!.compileSdkVersion } returns "android-35"
        every { pluginProject.extensions.findByType(BaseExtension::class.java)!!.compileSdkVersion } returns "android-35"

        PluginHandler.configurePluginProject(
            project = project,
            pluginObject = cameraDependency,
            engineVersion = exampleEngineVersion
        )

        verify { project.afterEvaluate(capture(captureActionSlot)) }
        verify { pluginProject.afterEvaluate(capture(capturePluginActionSlot)) }
        captureActionSlot.captured.execute(project)
        capturePluginActionSlot.captured.execute(pluginProject)
        verify { pluginProject.extensions.create("flutter", FlutterExtension::class.java) }
        verify {
            pluginProject.dependencies.add(
                "debugApi",
                "io.flutter:flutter_embedding_debug:$exampleEngineVersion"
            )
        }
        verify { project.dependencies.add("debugApi", pluginProject) }
        verify { mockLogger wasNot called }
        verify { mockPluginProjectBuildTypes.addAll(project.extensions.findByType(BaseExtension::class.java)!!.buildTypes) }
    }
}

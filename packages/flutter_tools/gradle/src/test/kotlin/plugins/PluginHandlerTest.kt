// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.plugins

import com.android.build.gradle.BaseExtension
import com.flutter.gradle.FlutterExtension
import com.flutter.gradle.FlutterPluginUtils
import com.flutter.gradle.FlutterPluginUtilsTest.Companion.EXAMPLE_ENGINE_VERSION
import com.flutter.gradle.FlutterPluginUtilsTest.Companion.cameraDependency
import com.flutter.gradle.FlutterPluginUtilsTest.Companion.flutterPluginAndroidLifecycleDependency
import com.flutter.gradle.FlutterPluginUtilsTest.Companion.pluginListWithDevDependency
import com.flutter.gradle.FlutterPluginUtilsTest.Companion.pluginListWithoutDevDependency
import com.flutter.gradle.NativePluginLoaderReflectionBridge
import com.flutter.gradle.testing.setUpMockAndroidExtension
import io.mockk.called
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkObject
import io.mockk.slot
import io.mockk.verify
import org.gradle.api.Action
import org.gradle.api.NamedDomainObjectContainer
import org.gradle.api.Project
import org.gradle.api.logging.Logger
import org.jetbrains.kotlin.gradle.plugin.extraProperties
import org.junit.jupiter.api.assertThrows
import org.junit.jupiter.api.io.TempDir
import java.io.File
import java.nio.file.Path
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import com.android.build.gradle.internal.dsl.BuildType as InternalDslBuildType

class PluginHandlerTest {
    // getPluginListWithoutDevDependencies
    @Test
    fun `getPluginListWithoutDevDependencies removes dev dependencies from list`() {
        val project = mockk<Project>()
        val pluginHandler = PluginHandler(project)
        mockkObject(NativePluginLoaderReflectionBridge)
        // mock return of NativePluginLoaderReflectionBridge.getPlugins
        every {
            NativePluginLoaderReflectionBridge.getPlugins(
                any(),
                any()
            )
        } returns pluginListWithDevDependency
        // mock method calls that are invoked by the args to NativePluginLoaderReflectionBridge
        every { project.extraProperties } returns mockk()
        every { project.extensions.findByType(FlutterExtension::class.java) } returns FlutterExtension()
        every { project.file(any()) } returns mockk()

        val result = pluginHandler.getPluginListWithoutDevDependencies()
        assertEquals(pluginListWithoutDevDependency, result)
    }

    @Test
    fun `getPluginListWithoutDevDependencies does not modify list without dev dependencies`() {
        val project = mockk<Project>()
        val pluginHandler = PluginHandler(project)
        mockkObject(NativePluginLoaderReflectionBridge)
        // mock return of NativePluginLoaderReflectionBridge.getPlugins
        every {
            NativePluginLoaderReflectionBridge.getPlugins(
                any(),
                any()
            )
        } returns pluginListWithoutDevDependency
        // mock method calls that are invoked by the args to NativePluginLoaderReflectionBridge
        every { project.extraProperties } returns mockk()
        every { project.extensions.findByType(FlutterExtension::class.java) } returns FlutterExtension()
        every { project.file(any()) } returns mockk()

        val result = pluginHandler.getPluginListWithoutDevDependencies()
        assertEquals(pluginListWithoutDevDependency, result)
    }

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
        }
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

    @Test
    fun `configurePlugins throws IllegalArgumentException when plugin has no name`(
        @TempDir tempDir: Path
    ) {
        val project = mockk<Project>()

        val projectDir = tempDir.resolve("my-plugin")
        projectDir.toFile().mkdirs()
        every { project.projectDir } returns projectDir.toFile()
        val settingsGradle = File(projectDir.parent.toFile(), "settings.gradle")
        settingsGradle.createNewFile()
        val mockLogger = mockk<Logger>()
        every { project.logger } returns mockLogger

        val pluginWithoutName: MutableMap<String?, Any?> = cameraDependency.toMutableMap()
        pluginWithoutName.remove("name")

        mockkObject(NativePluginLoaderReflectionBridge)
        every { NativePluginLoaderReflectionBridge.getPlugins(any(), any()) } returns
            listOf(
                pluginWithoutName
            )
        every { project.extraProperties } returns mockk()
        every { project.extensions.findByType(FlutterExtension::class.java) } returns FlutterExtension()
        every { project.file(any()) } returns mockk()

        val pluginHandler = PluginHandler(project)
        assertThrows<IllegalArgumentException> {
            pluginHandler.configurePlugins(
                engineVersionValue = EXAMPLE_ENGINE_VERSION
            )
        }
    }

    @Test
    fun `configurePlugins adds plugin project and configures its dependencies`(
        @TempDir tempDir: Path
    ) {
        val project = mockk<Project>()
        val pluginProject = mockk<Project>()
        val pluginDependencyProject = mockk<Project>()
        val mockBuildType = mockk<InternalDslBuildType>()
        val mockLogger = mockk<Logger>()

        val (_, mockPluginProjectBuildTypes) =
            setupBasicMocks(
                project,
                pluginProject,
                mockBuildType,
                tempDir,
                mockLogger = mockLogger,
                pluginDependencyProject = pluginDependencyProject
            )

        val captureActionSlot = slot<Action<Project>>()
        val capturePluginActionSlot = mutableListOf<Action<Project>>()

        val pluginWithDependencies: MutableMap<String?, Any?> = cameraDependency.toMutableMap()
        pluginWithDependencies["dependencies"] =
            listOf(flutterPluginAndroidLifecycleDependency["name"])
        every { NativePluginLoaderReflectionBridge.getPlugins(any(), any()) } returns
            listOf(
                pluginWithDependencies
            )

        val pluginHandler = PluginHandler(project)
        pluginHandler.configurePlugins(
            engineVersionValue = EXAMPLE_ENGINE_VERSION
        )

        verify { project.afterEvaluate(capture(captureActionSlot)) }
        verify { pluginProject.afterEvaluate(capture(capturePluginActionSlot)) }
        captureActionSlot.captured.execute(project)
        capturePluginActionSlot[0].execute(pluginProject)
        capturePluginActionSlot[1].execute(pluginProject)
        verify { pluginProject.extensions.create("flutter", FlutterExtension::class.java) }
        verify {
            pluginProject.dependencies.add(
                "debugApi",
                "io.flutter:flutter_embedding_debug:$EXAMPLE_ENGINE_VERSION"
            )
        }
        verify { project.dependencies.add("debugApi", pluginProject) }
        verify { mockLogger wasNot called }
        verify(exactly = 0) { mockPluginProjectBuildTypes.addAll(any()) }

        verify { pluginProject.dependencies.add("implementation", pluginDependencyProject) }
    }

    @Test
    fun `configurePlugins throws IllegalArgumentException when plugin has null dependencies`(
        @TempDir tempDir: Path
    ) {
        val project = mockk<Project>()
        val pluginProject = mockk<Project>()
        val mockBuildType = mockk<InternalDslBuildType>()

        setupBasicMocks(project, pluginProject, mockBuildType, tempDir)

        val pluginWithNullDependencies: MutableMap<String?, Any?> = cameraDependency.toMutableMap()
        pluginWithNullDependencies["dependencies"] = null

        every { NativePluginLoaderReflectionBridge.getPlugins(any(), any()) } returns
            listOf(
                pluginWithNullDependencies
            )

        val pluginHandler = PluginHandler(project)
        assertThrows<IllegalArgumentException> {
            pluginHandler.configurePlugins(
                engineVersionValue = EXAMPLE_ENGINE_VERSION
            )
        }
    }

    @Test
    fun `configurePlugins uses addAll for app plugins`(
        @TempDir tempDir: Path
    ) {
        val project = mockk<Project>()
        val pluginProject = mockk<Project>()
        val mockBuildType = mockk<InternalDslBuildType>()

        val (_, mockPluginProjectBuildTypes) =
            setupBasicMocks(
                project,
                pluginProject,
                mockBuildType,
                tempDir
            )
        every { NativePluginLoaderReflectionBridge.getPlugins(any(), any()) } returns listOf(cameraDependency)

        mockkObject(FlutterPluginUtils)
        every { FlutterPluginUtils.isBuiltAsApp(pluginProject) } returns true

        every { FlutterPluginUtils.getLegacyAndroidExtension(project) } returns project.extensions.findByType(BaseExtension::class.java)!!
        every { FlutterPluginUtils.getLegacyAndroidExtension(pluginProject) } returns
            pluginProject.extensions.findByType(BaseExtension::class.java)!!

        val pluginHandler = PluginHandler(project)
        pluginHandler.configurePlugins(
            engineVersionValue = EXAMPLE_ENGINE_VERSION
        )

        verify(exactly = 0) {
            mockPluginProjectBuildTypes.create(
                any<String>(),
                any<Action<InternalDslBuildType>>()
            )
        }
    }

    @Test
    fun `configurePlugins creates individual build types for library plugins`(
        @TempDir tempDir: Path
    ) {
        val project = mockk<Project>()
        val pluginProject = mockk<Project>()
        val mockBuildType = mockk<InternalDslBuildType>()

        val (mockProjectBuildTypes, mockPluginProjectBuildTypes) =
            setupBasicMocks(
                project,
                pluginProject,
                mockBuildType,
                tempDir
            )
        every { NativePluginLoaderReflectionBridge.getPlugins(any(), any()) } returns listOf(cameraDependency)

        mockkObject(FlutterPluginUtils)
        every { FlutterPluginUtils.isBuiltAsApp(pluginProject) } returns false

        val mockCreatedBuildType = mockk<InternalDslBuildType>(relaxed = true)
        every { mockPluginProjectBuildTypes.findByName("debug") } returns null
        every {
            mockPluginProjectBuildTypes.create(
                "debug",
                any<Action<InternalDslBuildType>>()
            )
        } returns mockCreatedBuildType

        val testBuildType = mockk<InternalDslBuildType>()
        every { testBuildType.name } returns "debug"
        every { testBuildType.isDebuggable } returns true
        every { testBuildType.isMinifyEnabled } returns false
        every { mockProjectBuildTypes.iterator() } returns mutableListOf(testBuildType).iterator()

        every { FlutterPluginUtils.getLegacyAndroidExtension(project) } returns project.extensions.findByType(BaseExtension::class.java)!!
        every { FlutterPluginUtils.getLegacyAndroidExtension(pluginProject) } returns
            pluginProject.extensions.findByType(BaseExtension::class.java)!!

        val pluginHandler = PluginHandler(project)
        pluginHandler.configurePlugins(
            engineVersionValue = EXAMPLE_ENGINE_VERSION
        )

        verify(exactly = 0) { mockPluginProjectBuildTypes.addAll(any()) }
    }

    private fun setupBasicMocks(
        project: Project,
        pluginProject: Project,
        mockBuildType: InternalDslBuildType,
        tempDir: Path,
        mockLogger: Logger = mockk(relaxed = true),
        projectCompileSdk: Int = 35,
        pluginCompileSdk: Int = 35,
        pluginDependencyProject: Project? = null
    ): Pair<NamedDomainObjectContainer<InternalDslBuildType>, NamedDomainObjectContainer<InternalDslBuildType>> {
        val projectDir = tempDir.resolve("my-plugin")
        projectDir.toFile().mkdirs()
        every { project.projectDir } returns projectDir.toFile()
        val settingsGradle = File(projectDir.parent.toFile(), "settings.gradle")
        settingsGradle.createNewFile()
        every { project.logger } returns mockLogger

        mockkObject(NativePluginLoaderReflectionBridge)
        every { project.extraProperties } returns mockk()
        every { project.extensions.findByType(FlutterExtension::class.java) } returns FlutterExtension()
        every { project.file(any()) } returns mockk()

        every { pluginProject.hasProperty("local-engine-repo") } returns false
        every { pluginProject.hasProperty("android") } returns true
        val mockPluginContainer = mockk<org.gradle.api.plugins.PluginContainer>()
        every { pluginProject.plugins } returns mockPluginContainer
        every { mockPluginContainer.hasPlugin("com.android.application") } returns false
        every { mockBuildType.name } returns "debug"
        every { mockBuildType.isDebuggable } returns true
        every { project.rootProject.findProject(":${cameraDependency["name"]}") } returns pluginProject
        if (pluginDependencyProject != null) {
            every { project.rootProject.findProject(":${flutterPluginAndroidLifecycleDependency["name"]}") } returns pluginDependencyProject
        }
        every { pluginProject.extensions.create(any(), any<Class<Any>>()) } returns mockk()
        every { project.afterEvaluate(any<Action<Project>>()) } returns Unit
        every { pluginProject.afterEvaluate(any<Action<Project>>()) } returns Unit

        val mockProjectBuildTypes = mockk<NamedDomainObjectContainer<InternalDslBuildType>>()
        val mockPluginProjectBuildTypes = mockk<NamedDomainObjectContainer<InternalDslBuildType>>()
        every { project.extensions.findByType(BaseExtension::class.java)!!.buildTypes } returns mockProjectBuildTypes
        every { pluginProject.extensions.findByType(BaseExtension::class.java)!!.buildTypes } returns mockPluginProjectBuildTypes
        every { mockPluginProjectBuildTypes.addAll(any()) } returns true
        every { pluginProject.configurations.named(any<String>()) } returns mockk()
        every { pluginProject.dependencies.add(any(), any()) } returns mockk()
        every { mockProjectBuildTypes.iterator() } answers {
            mutableListOf<InternalDslBuildType>().iterator()
        }
        every { project.dependencies.add(any(), any()) } returns mockk()

        setUpMockAndroidExtension(project, compileSdk = projectCompileSdk, buildTypes = listOf(mockBuildType))
        setUpMockAndroidExtension(pluginProject, compileSdk = pluginCompileSdk)

        return Pair(mockProjectBuildTypes, mockPluginProjectBuildTypes)
    }

    @Test
    fun `configurePlugins logs warning when plugin compileSdk is higher than project compileSdk`(
        @TempDir tempDir: Path
    ) {
        val project = mockk<Project>()
        val pluginProject = mockk<Project>()
        val mockBuildType = mockk<InternalDslBuildType>()
        val mockLogger = mockk<Logger>(relaxed = true)

        setupBasicMocks(
            project,
            pluginProject,
            mockBuildType,
            tempDir,
            mockLogger = mockLogger,
            projectCompileSdk = 34,
            pluginCompileSdk = 35
        )
        every { NativePluginLoaderReflectionBridge.getPlugins(any(), any()) } returns listOf(cameraDependency)

        val capturePluginActionSlot = mutableListOf<Action<Project>>()

        val pluginHandler = PluginHandler(project)
        pluginHandler.configurePlugins(
            engineVersionValue = EXAMPLE_ENGINE_VERSION
        )

        verify { pluginProject.afterEvaluate(capture(capturePluginActionSlot)) }
        capturePluginActionSlot[0].execute(pluginProject)

        verify {
            mockLogger.quiet(
                match { message ->
                    message.contains("The plugin camera_android_camerax requires Android SDK version 35 or higher")
                }
            )
        }
    }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.plugins

import com.android.build.api.dsl.ApplicationBuildType
import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.dsl.LibraryBuildType
import com.android.build.api.dsl.LibraryExtension
import com.flutter.gradle.FlutterExtension
import com.flutter.gradle.FlutterPluginUtils
import com.flutter.gradle.FlutterPluginUtilsTest.Companion.EXAMPLE_ENGINE_VERSION
import com.flutter.gradle.FlutterPluginUtilsTest.Companion.cameraDependency
import com.flutter.gradle.FlutterPluginUtilsTest.Companion.flutterPluginAndroidLifecycleDependency
import com.flutter.gradle.FlutterPluginUtilsTest.Companion.pluginListWithDevDependency
import com.flutter.gradle.FlutterPluginUtilsTest.Companion.pluginListWithoutDevDependency
import com.flutter.gradle.NativePluginLoaderReflectionBridge
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

class PluginHandlerTest {
    /**
     * Mocks the new-DSL android extension read through [FlutterPluginUtils.getAndroidExtension]
     * (compileSdk for the mismatch warning, buildTypes for the dependency-wiring loops and the
     * build-type copy block).
     */
    private fun mockAndroidExtension(
        project: Project,
        compileSdk: Int = 35,
        buildTypes: List<ApplicationBuildType> = emptyList()
    ): NamedDomainObjectContainer<ApplicationBuildType> {
        val androidExtension = mockk<ApplicationExtension>()
        every { project.extensions.findByName("android") } returns androidExtension
        every { androidExtension.compileSdk } returns compileSdk
        every { androidExtension.compileSdkPreview } returns null
        val container = mockk<NamedDomainObjectContainer<ApplicationBuildType>>()
        // A fresh iterator per call: the container is iterated by multiple loops.
        every { container.iterator() } answers { buildTypes.toMutableList().iterator() }
        // By default every name already exists on the container, so the build-type copy block
        // does not create copies. Tests exercising the copy override findByName per name.
        every { container.findByName(any<String>()) } returns mockk<ApplicationBuildType>(relaxed = true)
        every { androidExtension.buildTypes } returns container
        return container
    }

    /**
     * Like [mockAndroidExtension], but for a library (plugin) project whose build types are
     * [LibraryBuildType]s without app-specific properties.
     */
    private fun mockLibraryAndroidExtension(
        project: Project,
        compileSdk: Int = 35
    ): NamedDomainObjectContainer<LibraryBuildType> {
        val androidExtension = mockk<LibraryExtension>()
        every { project.extensions.findByName("android") } returns androidExtension
        every { androidExtension.compileSdk } returns compileSdk
        every { androidExtension.compileSdkPreview } returns null
        val container = mockk<NamedDomainObjectContainer<LibraryBuildType>>()
        every { container.iterator() } answers { mutableListOf<LibraryBuildType>().iterator() }
        every { androidExtension.buildTypes } returns container
        return container
    }

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

    // getPluginList skipped as it is a wrapper around a single reflection call

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

    @Test
    fun `configurePlugins throws IllegalArgumentException when plugin has no name`(
        @TempDir tempDir: Path
    ) {
        val project = mockk<Project>()

        // configuration for configureLegacyPluginEachProjects
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
        // mock return of NativePluginLoaderReflectionBridge.getPlugins
        every { NativePluginLoaderReflectionBridge.getPlugins(any(), any()) } returns
            listOf(
                pluginWithoutName
            )
        // mock method calls that are invoked by the args to NativePluginLoaderReflectionBridge
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

        // configuration for configureLegacyPluginEachProjects
        val projectDir = tempDir.resolve("my-plugin")
        projectDir.toFile().mkdirs()
        every { project.projectDir } returns projectDir.toFile()
        val settingsGradle = File(projectDir.parent.toFile(), "settings.gradle")
        settingsGradle.createNewFile()
        val mockLogger = mockk<Logger>()
        every { project.logger } returns mockLogger

        val pluginProject = mockk<Project>()
        val pluginDependencyProject = mockk<Project>()
        val mockBuildType = mockk<ApplicationBuildType>()
        every { pluginProject.hasProperty("local-engine-repo") } returns false
        every { pluginProject.hasProperty("android") } returns true
        val mockPluginContainer = mockk<org.gradle.api.plugins.PluginContainer>()
        every { pluginProject.plugins } returns mockPluginContainer
        every { mockPluginContainer.hasPlugin("com.android.application") } returns false
        every { mockBuildType.name } returns "debug"
        every { mockBuildType.isDebuggable } returns true
        every { project.rootProject.findProject(":${cameraDependency["name"]}") } returns pluginProject
        every { project.rootProject.findProject(":${flutterPluginAndroidLifecycleDependency["name"]}") } returns pluginDependencyProject
        every { pluginProject.extensions.create(any(), any<Class<Any>>()) } returns mockk()
        val captureActionSlot = slot<Action<Project>>()
        val capturePluginActionSlot = mutableListOf<Action<Project>>()
        every { project.afterEvaluate(any<Action<Project>>()) } returns Unit
        every { pluginProject.afterEvaluate(any<Action<Project>>()) } returns Unit

        every { pluginProject.configurations.named(any<String>()) } returns mockk()
        every { pluginProject.dependencies.add(any(), any()) } returns mockk()
        every { project.dependencies.add(any(), any()) } returns mockk()
        mockAndroidExtension(project, buildTypes = listOf(mockBuildType))
        val pluginProjectBuildTypes = mockAndroidExtension(pluginProject)

        val pluginHandler = PluginHandler(project)
        mockkObject(NativePluginLoaderReflectionBridge)
        // mock return of NativePluginLoaderReflectionBridge.getPlugins
        val pluginWithDependencies: MutableMap<String?, Any?> = cameraDependency.toMutableMap()
        pluginWithDependencies["dependencies"] =
            listOf(flutterPluginAndroidLifecycleDependency["name"])
        every { NativePluginLoaderReflectionBridge.getPlugins(any(), any()) } returns
            listOf(
                pluginWithDependencies
            )
        // mock method calls that are invoked by the args to NativePluginLoaderReflectionBridge
        every { project.extraProperties } returns mockk()
        every { project.extensions.findByType(FlutterExtension::class.java) } returns FlutterExtension()
        every { project.file(any()) } returns mockk()

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
        // The "debug" build type already exists on the plugin project, so no copy is created.
        verify(exactly = 0) {
            pluginProjectBuildTypes.create(any<String>(), any<Action<ApplicationBuildType>>())
        }

        verify { pluginProject.dependencies.add("implementation", pluginDependencyProject) }
    }

    @Test
    fun `configurePlugins throws IllegalArgumentException when plugin has null dependencies`(
        @TempDir tempDir: Path
    ) {
        val project = mockk<Project>()

        // configuration for configureLegacyPluginEachProjects
        val projectDir = tempDir.resolve("my-plugin")
        projectDir.toFile().mkdirs()
        every { project.projectDir } returns projectDir.toFile()
        val settingsGradle = File(projectDir.parent.toFile(), "settings.gradle")
        settingsGradle.createNewFile()
        val mockLogger = mockk<Logger>()
        every { project.logger } returns mockLogger

        val pluginProject = mockk<Project>()
        val mockBuildType = mockk<ApplicationBuildType>()
        every { pluginProject.hasProperty("local-engine-repo") } returns false
        every { pluginProject.hasProperty("android") } returns true
        every { mockBuildType.name } returns "debug"
        every { mockBuildType.isDebuggable } returns true
        val pluginWithNullDependencies: MutableMap<String?, Any?> = cameraDependency.toMutableMap()
        pluginWithNullDependencies["dependencies"] = null
        every { project.rootProject.findProject(":${pluginWithNullDependencies["name"]}") } returns pluginProject
        every { pluginProject.extensions.create(any(), any<Class<Any>>()) } returns mockk()
        every { project.afterEvaluate(any<Action<Project>>()) } returns Unit
        every { pluginProject.afterEvaluate(any<Action<Project>>()) } returns Unit

        every { pluginProject.configurations.named(any<String>()) } returns mockk()
        every { pluginProject.dependencies.add(any(), any()) } returns mockk()
        every { project.dependencies.add(any(), any()) } returns mockk()
        mockAndroidExtension(project, buildTypes = listOf(mockBuildType))
        mockAndroidExtension(pluginProject)

        val pluginHandler = PluginHandler(project)
        mockkObject(NativePluginLoaderReflectionBridge)
        // mock return of NativePluginLoaderReflectionBridge.getPlugins
        every { NativePluginLoaderReflectionBridge.getPlugins(any(), any()) } returns
            listOf(
                pluginWithNullDependencies
            )
        // mock method calls that are invoked by the args to NativePluginLoaderReflectionBridge
        every { project.extraProperties } returns mockk()
        every { project.extensions.findByType(FlutterExtension::class.java) } returns FlutterExtension()
        every { project.file(any()) } returns mockk()

        assertThrows<IllegalArgumentException> {
            pluginHandler.configurePlugins(
                engineVersionValue = EXAMPLE_ENGINE_VERSION
            )
        }
    }

    @Test
    fun `configurePlugins copies missing app build types onto library plugin projects using initWith`(
        @TempDir tempDir: Path
    ) {
        val project = mockk<Project>()
        val pluginProject = mockk<Project>()
        val appBuildType = mockk<ApplicationBuildType>()
        every { appBuildType.name } returns "staging"
        every { appBuildType.isDebuggable } returns true

        setupBasicMocks(project, pluginProject, appBuildType, tempDir)
        setupPluginMocks(project)
        // The plugin project is an Android library: its build types are LibraryBuildTypes,
        // which cannot receive app-specific properties such as isDebuggable.
        val pluginProjectBuildTypes = mockLibraryAndroidExtension(pluginProject)
        every { pluginProjectBuildTypes.findByName("staging") } returns null
        val createdBuildType = mockk<LibraryBuildType>(relaxed = true)
        val createActionSlot = slot<Action<LibraryBuildType>>()
        every {
            pluginProjectBuildTypes.create("staging", capture(createActionSlot))
        } returns createdBuildType

        val pluginHandler = PluginHandler(project)
        pluginHandler.configurePlugins(engineVersionValue = EXAMPLE_ENGINE_VERSION)

        val capturePluginActionSlot = mutableListOf<Action<Project>>()
        verify { pluginProject.afterEvaluate(capture(capturePluginActionSlot)) }
        capturePluginActionSlot[0].execute(pluginProject)

        createActionSlot.captured.execute(createdBuildType)
        verify { createdBuildType.initWith(appBuildType) }
        // The custom debuggable build type maps to the debug engine artifacts.
        verify {
            pluginProject.dependencies.add(
                "stagingApi",
                "io.flutter:flutter_embedding_debug:$EXAMPLE_ENGINE_VERSION"
            )
        }
    }

    @Test
    fun `configurePlugins copies app-specific properties when the plugin project is an app`(
        @TempDir tempDir: Path
    ) {
        val project = mockk<Project>()
        val pluginProject = mockk<Project>()
        val appBuildType = mockk<ApplicationBuildType>()
        every { appBuildType.name } returns "staging"
        every { appBuildType.isDebuggable } returns true

        setupBasicMocks(project, pluginProject, appBuildType, tempDir)
        setupPluginMocks(project)
        // The plugin project is itself built as an app, so its build types are
        // ApplicationBuildTypes and app-specific properties are copied.
        val pluginProjectBuildTypes = mockAndroidExtension(pluginProject)
        every { pluginProjectBuildTypes.findByName("staging") } returns null
        val createdBuildType = mockk<ApplicationBuildType>(relaxed = true)
        val createActionSlot = slot<Action<ApplicationBuildType>>()
        every {
            pluginProjectBuildTypes.create("staging", capture(createActionSlot))
        } returns createdBuildType

        val pluginHandler = PluginHandler(project)
        pluginHandler.configurePlugins(engineVersionValue = EXAMPLE_ENGINE_VERSION)

        val capturePluginActionSlot = mutableListOf<Action<Project>>()
        verify { pluginProject.afterEvaluate(capture(capturePluginActionSlot)) }
        capturePluginActionSlot[0].execute(pluginProject)

        createActionSlot.captured.execute(createdBuildType)
        verify { createdBuildType.initWith(appBuildType) }
        verify { createdBuildType.isDebuggable = true }
    }

    private fun setupBasicMocks(
        project: Project,
        pluginProject: Project,
        mockBuildType: ApplicationBuildType,
        tempDir: Path
    ) {
        // Configuration for project directory
        val projectDir = tempDir.resolve("my-plugin")
        projectDir.toFile().mkdirs()
        every { project.projectDir } returns projectDir.toFile()
        val settingsGradle = File(projectDir.parent.toFile(), "settings.gradle")
        settingsGradle.createNewFile()
        val mockLogger = mockk<Logger>()
        every { project.logger } returns mockLogger

        // Plugin project setup. Callers stub mockBuildType's name and isDebuggable.
        every { pluginProject.hasProperty("local-engine-repo") } returns false
        every { pluginProject.hasProperty("android") } returns true
        val mockPluginContainer = mockk<org.gradle.api.plugins.PluginContainer>()
        every { pluginProject.plugins } returns mockPluginContainer
        every { mockPluginContainer.hasPlugin("com.android.application") } returns false
        every { project.rootProject.findProject(":${cameraDependency["name"]}") } returns pluginProject
        every { pluginProject.extensions.create(any(), any<Class<Any>>()) } returns mockk()
        every { project.afterEvaluate(any<Action<Project>>()) } returns Unit
        every { pluginProject.afterEvaluate(any<Action<Project>>()) } returns Unit

        // Dependencies and configurations
        every { pluginProject.configurations.named(any<String>()) } returns mockk()
        every { pluginProject.dependencies.add(any(), any()) } returns mockk()
        every { project.dependencies.add(any(), any()) } returns mockk()
        mockAndroidExtension(project, buildTypes = listOf(mockBuildType))
        mockAndroidExtension(pluginProject)
    }

    private fun setupPluginMocks(project: Project) {
        mockkObject(NativePluginLoaderReflectionBridge)
        every { NativePluginLoaderReflectionBridge.getPlugins(any(), any()) } returns listOf(cameraDependency)
        every { project.extraProperties } returns mockk()
        every { project.extensions.findByType(FlutterExtension::class.java) } returns FlutterExtension()
        every { project.file(any()) } returns mockk()
    }
}

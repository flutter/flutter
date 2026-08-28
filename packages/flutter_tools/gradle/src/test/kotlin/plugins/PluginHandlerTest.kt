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
        every {
            NativePluginLoaderReflectionBridge.getPlugins(
                any(),
                any()
            )
        } returns pluginListWithDevDependency
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
        every {
            NativePluginLoaderReflectionBridge.getPlugins(
                any(),
                any()
            )
        } returns pluginListWithoutDevDependency
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
        val mockLogger = mockk<Logger>()
        every { project.logger } returns mockLogger

        setupMockProjectDir(project, tempDir)

        val pluginWithoutName: MutableMap<String?, Any?> = cameraDependency.toMutableMap()
        pluginWithoutName.remove("name")
        setupMockPluginLoader(project, listOf(pluginWithoutName))

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
        val mockBuildType =
            mockk<InternalDslBuildType> {
                every { name } returns "debug"
                every { isDebuggable } returns true
            }
        val mockLogger = mockk<Logger>()
        every { project.logger } returns mockLogger

        setupMockProjectDir(project, tempDir)
        setupMockPluginProject(
            project,
            pluginProject,
            dependencyProject = pluginDependencyProject
        )

        val pluginProjectBuildTypes = mockk<NamedDomainObjectContainer<InternalDslBuildType>>(relaxed = true)
        val projectBuildTypes = mockk<NamedDomainObjectContainer<InternalDslBuildType>>(relaxed = true)
        setupBaseExtensionBuildTypeContainers(project, pluginProject, projectBuildTypes, pluginProjectBuildTypes)

        setUpMockAndroidExtension(project, compileSdk = 35, buildTypes = listOf(mockBuildType))
        setUpMockAndroidExtension(pluginProject, compileSdk = 35)

        val captureActionSlot = slot<Action<Project>>()
        val capturePluginActionSlot = mutableListOf<Action<Project>>()

        val pluginWithDependencies: MutableMap<String?, Any?> = cameraDependency.toMutableMap()
        pluginWithDependencies["dependencies"] =
            listOf(flutterPluginAndroidLifecycleDependency["name"])
        setupMockPluginLoader(project, listOf(pluginWithDependencies))

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
        verify(exactly = 0) { pluginProjectBuildTypes.addAll(any()) }
        verify { pluginProject.dependencies.add("implementation", pluginDependencyProject) }
    }

    @Test
    fun `configurePlugins throws IllegalArgumentException when plugin has null dependencies`(
        @TempDir tempDir: Path
    ) {
        val project = mockk<Project>()
        val pluginProject = mockk<Project>()
        val mockBuildType =
            mockk<InternalDslBuildType> {
                every { name } returns "debug"
                every { isDebuggable } returns true
            }
        every { project.logger } returns mockk(relaxed = true)

        setupMockProjectDir(project, tempDir)
        setupMockPluginProject(project, pluginProject)
        setupBaseExtensionBuildTypeContainers(
            project,
            pluginProject,
            mockk(relaxed = true),
            mockk(relaxed = true)
        )
        setUpMockAndroidExtension(project, compileSdk = 35, buildTypes = listOf(mockBuildType))
        setUpMockAndroidExtension(pluginProject, compileSdk = 35)

        val pluginWithNullDependencies: MutableMap<String?, Any?> = cameraDependency.toMutableMap()
        pluginWithNullDependencies["dependencies"] = null
        setupMockPluginLoader(project, listOf(pluginWithNullDependencies))

        val pluginHandler = PluginHandler(project)
        assertThrows<IllegalArgumentException> {
            pluginHandler.configurePlugins(
                engineVersionValue = EXAMPLE_ENGINE_VERSION
            )
        }
    }

    @Test
    fun `configurePlugins mirrors build types using initWith for app plugins`(
        @TempDir tempDir: Path
    ) {
        val project = mockk<Project>()
        val pluginProject = mockk<Project>()
        val mockBuildType =
            mockk<InternalDslBuildType> {
                every { name } returns "debug"
                every { isDebuggable } returns true
            }
        every { project.logger } returns mockk(relaxed = true)

        setupMockProjectDir(project, tempDir)
        setupMockPluginProject(project, pluginProject, isAppPlugin = true)

        val pluginProjectBuildTypes = mockk<NamedDomainObjectContainer<InternalDslBuildType>>(relaxed = true)
        val projectBuildTypes = mockk<NamedDomainObjectContainer<InternalDslBuildType>>(relaxed = true)
        every { projectBuildTypes.iterator() } returns mutableListOf(mockBuildType).iterator()
        setupBaseExtensionBuildTypeContainers(project, pluginProject, projectBuildTypes, pluginProjectBuildTypes)

        setUpMockAndroidExtension(project, compileSdk = 35, buildTypes = listOf(mockBuildType))
        setUpMockAndroidExtension(pluginProject, compileSdk = 35)
        setupMockPluginLoader(project, listOf(cameraDependency))

        mockkObject(FlutterPluginUtils)
        every { FlutterPluginUtils.isBuiltAsApp(pluginProject) } returns true
        every { FlutterPluginUtils.getLegacyAndroidExtension(project) } returns
            project.extensions.findByType(BaseExtension::class.java)!!
        every { FlutterPluginUtils.getLegacyAndroidExtension(pluginProject) } returns
            pluginProject.extensions.findByType(BaseExtension::class.java)!!

        val capturePluginActionSlot = mutableListOf<Action<Project>>()

        val createdBuildType = mockk<InternalDslBuildType>(relaxed = true)
        every { pluginProjectBuildTypes.findByName("debug") } returns null
        every {
            pluginProjectBuildTypes.create(
                "debug",
                any<Action<InternalDslBuildType>>()
            )
        } answers {
            val action = secondArg<Action<InternalDslBuildType>>()
            action.execute(createdBuildType)
            createdBuildType
        }

        val pluginHandler = PluginHandler(project)
        pluginHandler.configurePlugins(
            engineVersionValue = EXAMPLE_ENGINE_VERSION
        )

        verify { pluginProject.afterEvaluate(capture(capturePluginActionSlot)) }
        capturePluginActionSlot.forEach { it.execute(pluginProject) }

        // App plugins mirror project build types using initWith.
        verify {
            pluginProjectBuildTypes.create(
                "debug",
                any<Action<InternalDslBuildType>>()
            )
        }
        verify { createdBuildType.initWith(mockBuildType) }
    }

    @Test
    fun `configurePlugins creates individual build types for library plugins`(
        @TempDir tempDir: Path
    ) {
        val project = mockk<Project>()
        val pluginProject = mockk<Project>()
        val mockBuildType =
            mockk<InternalDslBuildType> {
                every { name } returns "debug"
                every { isDebuggable } returns true
            }
        every { project.logger } returns mockk(relaxed = true)

        setupMockProjectDir(project, tempDir)
        setupMockPluginProject(project, pluginProject, isAppPlugin = false)

        val pluginProjectBuildTypes = mockk<NamedDomainObjectContainer<InternalDslBuildType>>(relaxed = true)
        val projectBuildTypes = mockk<NamedDomainObjectContainer<InternalDslBuildType>>()
        val testBuildType =
            mockk<InternalDslBuildType> {
                every { name } returns "debug"
                every { isDebuggable } returns true
                every { isMinifyEnabled } returns false
            }
        every { projectBuildTypes.iterator() } returns mutableListOf(testBuildType).iterator()

        setupBaseExtensionBuildTypeContainers(project, pluginProject, projectBuildTypes, pluginProjectBuildTypes)

        setUpMockAndroidExtension(project, compileSdk = 35, buildTypes = listOf(mockBuildType))
        setUpMockAndroidExtension(pluginProject, compileSdk = 35)
        setupMockPluginLoader(project, listOf(cameraDependency))

        mockkObject(FlutterPluginUtils)
        every { FlutterPluginUtils.isBuiltAsApp(pluginProject) } returns false

        val mockCreatedBuildType = mockk<InternalDslBuildType>(relaxed = true)
        every { pluginProjectBuildTypes.findByName("debug") } returns null
        every {
            pluginProjectBuildTypes.create(
                "debug",
                any<Action<InternalDslBuildType>>()
            )
        } returns mockCreatedBuildType

        every { FlutterPluginUtils.getLegacyAndroidExtension(project) } returns
            project.extensions.findByType(BaseExtension::class.java)!!
        every { FlutterPluginUtils.getLegacyAndroidExtension(pluginProject) } returns
            pluginProject.extensions.findByType(BaseExtension::class.java)!!

        val capturePluginActionSlot = mutableListOf<Action<Project>>()

        val pluginHandler = PluginHandler(project)
        pluginHandler.configurePlugins(
            engineVersionValue = EXAMPLE_ENGINE_VERSION
        )

        verify { pluginProject.afterEvaluate(capture(capturePluginActionSlot)) }
        capturePluginActionSlot.forEach { it.execute(pluginProject) }

        // For library plugins, individual missing build types must be created explicitly rather than bulk-copied.
        verify {
            pluginProjectBuildTypes.create(
                "debug",
                any<Action<InternalDslBuildType>>()
            )
        }
        verify(exactly = 0) { pluginProjectBuildTypes.addAll(any()) }
    }

    @Test
    fun `configurePlugins logs warning when plugin compileSdk is higher than project compileSdk`(
        @TempDir tempDir: Path
    ) {
        val project = mockk<Project>()
        val pluginProject = mockk<Project>()
        val mockBuildType =
            mockk<InternalDslBuildType> {
                every { name } returns "debug"
                every { isDebuggable } returns true
            }
        val mockLogger = mockk<Logger>(relaxed = true)
        every { project.logger } returns mockLogger

        setupMockProjectDir(project, tempDir)
        setupMockPluginProject(project, pluginProject)
        setupBaseExtensionBuildTypeContainers(
            project,
            pluginProject,
            mockk(relaxed = true),
            mockk(relaxed = true)
        )
        setUpMockAndroidExtension(project, compileSdk = 34, buildTypes = listOf(mockBuildType))
        setUpMockAndroidExtension(pluginProject, compileSdk = 35)
        setupMockPluginLoader(project, listOf(cameraDependency))

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

    private fun setupMockProjectDir(
        project: Project,
        tempDir: Path,
        projectName: String = "my-plugin"
    ) {
        val projectDir = tempDir.resolve(projectName)
        projectDir.toFile().mkdirs()
        every { project.projectDir } returns projectDir.toFile()
        val settingsGradle = File(projectDir.parent.toFile(), "settings.gradle")
        settingsGradle.createNewFile()
    }

    private fun setupMockPluginLoader(
        project: Project,
        pluginList: List<Map<String?, Any?>>
    ) {
        mockkObject(NativePluginLoaderReflectionBridge)
        every { NativePluginLoaderReflectionBridge.getPlugins(any(), any()) } returns pluginList
        every { project.extraProperties } returns mockk()
        every { project.extensions.findByType(FlutterExtension::class.java) } returns FlutterExtension()
        every { project.file(any()) } returns mockk()
    }

    private fun setupMockPluginProject(
        project: Project,
        pluginProject: Project,
        pluginName: String = cameraDependency["name"] as String,
        isAppPlugin: Boolean = false,
        dependencyProject: Project? = null
    ) {
        every { pluginProject.hasProperty("local-engine-repo") } returns false
        every { pluginProject.hasProperty("android") } returns true
        val mockPluginContainer = mockk<org.gradle.api.plugins.PluginContainer>()
        every { pluginProject.plugins } returns mockPluginContainer
        every { mockPluginContainer.hasPlugin("com.android.application") } returns isAppPlugin
        every { project.rootProject.findProject(":$pluginName") } returns pluginProject
        if (dependencyProject != null) {
            every { project.rootProject.findProject(":${flutterPluginAndroidLifecycleDependency["name"]}") } returns dependencyProject
        }
        every { pluginProject.extensions.create(any(), any<Class<Any>>()) } returns mockk()
        every { project.afterEvaluate(any<Action<Project>>()) } returns Unit
        every { pluginProject.afterEvaluate(any<Action<Project>>()) } returns Unit
        every { pluginProject.configurations.named(any<String>()) } returns mockk()
        every { pluginProject.dependencies.add(any(), any()) } returns mockk()
        every { project.dependencies.add(any(), any()) } returns mockk()
    }

    private fun setupBaseExtensionBuildTypeContainers(
        project: Project,
        pluginProject: Project,
        projectBuildTypes: NamedDomainObjectContainer<InternalDslBuildType>,
        pluginBuildTypes: NamedDomainObjectContainer<InternalDslBuildType>
    ) {
        val projectBaseExt =
            mockk<BaseExtension>(relaxed = true) {
                every { buildTypes } returns projectBuildTypes
            }
        val pluginBaseExt =
            mockk<BaseExtension>(relaxed = true) {
                every { buildTypes } returns pluginBuildTypes
            }
        every { project.extensions.findByType(BaseExtension::class.java) } returns projectBaseExt
        every { pluginProject.extensions.findByType(BaseExtension::class.java) } returns pluginBaseExt
    }
}

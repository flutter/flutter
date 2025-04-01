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
import kotlin.test.Test

class PluginConfigurerTest {
    // configurePluginDependencies TODO
    @Test
    fun `configurePluginDependencies throws IllegalArgumentException when plugin has no name`() {
        val project = mockk<Project>()
        val pluginWithoutName: MutableMap<String?, Any?> = cameraDependency.toMutableMap()
        val pluginConfigurer = PluginConfigurer(project)
        pluginWithoutName.remove("name")
        assertThrows<IllegalArgumentException> {
            pluginConfigurer.configurePluginDependencies(
                pluginObject = pluginWithoutName
            )
        }
    }

    @Test
    fun `configurePluginDependencies throws IllegalArgumentException when plugin has null dependencies`() {
        val project = mockk<Project>()
        val pluginConfigurer = PluginConfigurer(project)
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
            pluginConfigurer.configurePluginDependencies(
                pluginObject = pluginWithNullDependencies
            )
        }
    }

    @Test
    fun `configurePluginDependencies adds plugin dependencies`() {
        val project = mockk<Project>()
        val pluginConfigurer = PluginConfigurer(project)
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

        pluginConfigurer.configurePluginDependencies(
            pluginObject = pluginWithDependencies
        )

        verify { pluginProject.afterEvaluate(capture(captureActionSlot)) }
        captureActionSlot.captured.execute(pluginDependencyProject)
        verify { mockDependencyHandler.add("implementation", pluginDependencyProject) }
    }
}

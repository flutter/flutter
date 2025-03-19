package com.flutter.gradle

import com.android.builder.model.BuildType
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.gradle.api.GradleException
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.api.UnknownTaskException
import org.gradle.api.logging.Logger
import org.junit.jupiter.api.assertThrows
import org.junit.jupiter.api.io.TempDir
import java.io.File
import java.nio.file.Path
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class FlutterPluginUtilsTest {
    // toCamelCase
    @Test
    fun `toCamelCase converts a list of strings to camel case`() {
        val result = FlutterPluginUtils.toCamelCase(listOf("hello", "world"))
        assertEquals("helloWorld", result)
    }

    @Test
    fun `toCamelCase handles empty list`() {
        val result = FlutterPluginUtils.toCamelCase(emptyList())
        assertEquals("", result)
    }

    @Test
    fun `toCamelCase handles single-element list`() {
        val result = FlutterPluginUtils.toCamelCase(listOf("hello"))
        assertEquals("hello", result)
    }

    // compareVersionStrings
    @Test
    fun `compareVersionStrings compares last element of version string correctly`() {
        val result = FlutterPluginUtils.compareVersionStrings("1.2.3", "1.2.4")
        assertEquals(-1, result)
    }

    @Test
    fun `compareVersionStrings compares middle element of version string correctly`() {
        val result = FlutterPluginUtils.compareVersionStrings("1.2.3", "1.1.4")
        assertEquals(1, result)
    }

    @Test
    fun `compareVersionStrings compares first element of version string correctly`() {
        val result = FlutterPluginUtils.compareVersionStrings("1.2.3", "2.2.4")
        assertEquals(-1, result)
    }

    @Test
    fun `compareVersionStrings considers rc candidates the same`() {
        val result = FlutterPluginUtils.compareVersionStrings("1.2.3-rc", "1.2.3")
        assertEquals(0, result)
    }

    // formatPlatformString
    @Test
    fun `formatPlatformString returns correct string`() {
        val result = FlutterPluginUtils.formatPlatformString("android-arm64")
        assertEquals("arm64_v8a", result)
    }

    // shouldShrinkResources
    @Test
    fun `shouldShrinkResources returns true by default`() {
        val project = mockk<Project>()
        every { project.hasProperty(any()) } returns false
        val result = FlutterPluginUtils.shouldShrinkResources(project)
        assertEquals(true, result)
    }

    @Test
    fun `shouldShrinkResources returns true when property is set to true`() {
        val project = mockk<Project>()
        every { project.hasProperty(FlutterPluginUtils.PROP_SHOULD_SHRINK_RESOURCES) } returns true
        every { project.property(FlutterPluginUtils.PROP_SHOULD_SHRINK_RESOURCES) } returns true
        val result = FlutterPluginUtils.shouldShrinkResources(project)
        assertEquals(true, result)
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
            FlutterPluginUtils.pluginSupportsAndroidPlatform(mockProject)
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
            FlutterPluginUtils.pluginSupportsAndroidPlatform(mockProject)
        } // Replace YourClass with the actual class containing the method
    }

    // settingsGradleFile
    @Test
    fun `settingsGradleFile returns groovy settings gradle file when it exists`(
        @TempDir tempDir: Path
    ) {
        val projectDir = tempDir.resolve("android").resolve("app")
        projectDir.toFile().mkdirs()

        val settingsGradle = File(projectDir.parent.toFile(), "settings.gradle")
        settingsGradle.createNewFile()

        val result = FlutterPluginUtils.getSettingsGradleFileFromProjectDir(projectDir.toFile(), mockk())
        assertEquals(settingsGradle, result)
    }

    @Test
    fun `settingsGradleFile returns groovy settings file and logs when both groovy and kotlin exist`(
        @TempDir tempDir: Path
    ) {
        val projectDir = tempDir.resolve("android").resolve("app")
        projectDir.toFile().mkdirs()

        val groovySettingsGradle = File(projectDir.parent.toFile(), "settings.gradle")
        groovySettingsGradle.createNewFile()
        val kotlinSettingsGradle = File(projectDir.parent.toFile(), "settings.gradle.kts")
        kotlinSettingsGradle.createNewFile()

        val mockLogger = mockk<Logger>()
        every { mockLogger.error(any()) } returns Unit

        val result = FlutterPluginUtils.getSettingsGradleFileFromProjectDir(projectDir.toFile(), mockLogger)
        assertEquals(groovySettingsGradle, result)
        verify { mockLogger.error(any()) }
    }

    // buildGradleFile
    @Test
    fun `buildGradleFile returns groovy build gradle file when it exists`(
        @TempDir tempDir: Path
    ) {
        val projectDir = tempDir.resolve("android").resolve("app")
        projectDir.toFile().mkdirs()

        val buildGradle = File(projectDir.parent.resolve("app").toFile(), "build.gradle")
        buildGradle.createNewFile()

        val result = FlutterPluginUtils.getBuildGradleFileFromProjectDir(projectDir.toFile(), mockk())
        assertEquals(buildGradle, result)
    }

    @Test
    fun `buildGradleFile returns groovy build file and logs when both groovy and kotlin exist`(
        @TempDir tempDir: Path
    ) {
        val projectDir = tempDir.resolve("android").resolve("app")
        projectDir.toFile().mkdirs()

        val groovyBuildGradle = File(projectDir.parent.resolve("app").toFile(), "build.gradle")
        groovyBuildGradle.createNewFile()
        val kotlinBuildGradle = File(projectDir.parent.resolve("app").toFile(), "build.gradle.kts")
        kotlinBuildGradle.createNewFile()

        val mockLogger = mockk<Logger>()
        every { mockLogger.error(any()) } returns Unit

        val result = FlutterPluginUtils.getBuildGradleFileFromProjectDir(projectDir.toFile(), mockLogger)
        assertEquals(groovyBuildGradle, result)
        verify { mockLogger.error(any()) }
    }

    // shouldProjectSplitPerAbi
    @Test
    fun `shouldProjectSplitPerAbi returns false by default`() {
        val project = mockk<Project>()
        every { project.findProperty(FlutterPluginUtils.PROP_SPLIT_PER_ABI) } returns null
        val result = FlutterPluginUtils.shouldProjectSplitPerAbi(project)
        assertEquals(false, result)
    }

    @Test
    fun `shouldProjectSplitPerAbi returns true when property is set to true`() {
        val project = mockk<Project>()
        every { project.findProperty(FlutterPluginUtils.PROP_SPLIT_PER_ABI) } returns "true"
        val result = FlutterPluginUtils.shouldProjectSplitPerAbi(project)
        assertEquals(true, result)
    }

    // shouldProjectUseLocalEngine skipped as it is a wrapper for a single getter

    // isProjectVerbose
    @Test
    fun `isProjectVerbose returns false by default`() {
        val project = mockk<Project>()
        every { project.findProperty(FlutterPluginUtils.PROP_IS_VERBOSE) } returns null
        val result = FlutterPluginUtils.isProjectVerbose(project)
        assertEquals(false, result)
    }

    // isProjectVerbose
    @Test
    fun `isProjectVerbose returns true when the property is set to true`() {
        val project = mockk<Project>()
        every { project.findProperty(FlutterPluginUtils.PROP_IS_VERBOSE) } returns true
        val result = FlutterPluginUtils.isProjectVerbose(project)
        assertEquals(true, result)
    }

    // isProjectFastStart
    @Test
    fun `isProjectFastStart returns false by default`() {
        val project = mockk<Project>()
        every { project.findProperty(FlutterPluginUtils.PROP_IS_FAST_START) } returns null
        val result = FlutterPluginUtils.isProjectFastStart(project)
        assertEquals(false, result)
    }

    @Test
    fun `isProjectFastStart returns true when the property is set to true`() {
        val project = mockk<Project>()
        every { project.findProperty(FlutterPluginUtils.PROP_IS_FAST_START) } returns true
        val result = FlutterPluginUtils.isProjectFastStart(project)
        assertEquals(true, result)
    }

    // shouldConfigureFlutterTask
    @Test
    fun `shouldConfigureFlutterTask returns true for assemble task`() {
        val project = mockk<Project>()
        val assembleTask = mockk<Task>()

        every { project.gradle.startParameter.taskNames } returns listOf("assemble")

        val result = FlutterPluginUtils.shouldConfigureFlutterTask(project, assembleTask)
        assertEquals(true, result)
    }

    @Test
    fun `shouldConfigureFlutterTask returns true when taskname and assembleTask end with Release`() {
        val project = mockk<Project>()
        val assembleTask = mockk<Task>()

        every { project.gradle.startParameter.taskNames } returns listOf("assembleRelease")
        every { assembleTask.name } returns "assembleSomethingElseRelease"

        val result = FlutterPluginUtils.shouldConfigureFlutterTask(project, assembleTask)
        assertEquals(true, result)
    }

    // getFlutterSourceDirectory
    @Test
    fun `getFlutterSourceDirectory returns the flutter source directory`() {
        val flutterExtension = FlutterExtension()
        val project = mockk<Project>()

        flutterExtension.source = "my/flutter/source/directory"
        every { project.extensions.findByType(FlutterExtension::class.java) } returns flutterExtension
        every { project.file(any()) } returns mockk()

        FlutterPluginUtils.getFlutterSourceDirectory(project)
        verify { project.file("my/flutter/source/directory") }
    }

    @Test
    fun `getFlutterSourceDirectory throws exception when flutter source directory is not set`() {
        val flutterExtension = FlutterExtension()
        val project = mockk<Project>()

        flutterExtension.source = null
        every { project.extensions.findByType(FlutterExtension::class.java) } returns flutterExtension

        assertThrows<GradleException> {
            FlutterPluginUtils.getFlutterSourceDirectory(project)
        }
    }

    // getFlutterTarget
    @Test
    fun `getFlutterTarget returns the target when the project property is set`() {
        val project = mockk<Project>()
        every { project.hasProperty(FlutterPluginUtils.PROP_TARGET) } returns true
        every { project.property(FlutterPluginUtils.PROP_TARGET) } returns "my/target"

        val result = FlutterPluginUtils.getFlutterTarget(project)
        assertEquals("my/target", result)
    }

    @Test
    fun `getFlutterTarget returns the target from the FlutterExtension when it is set and project property is not set`() {
        val flutterExtension = FlutterExtension()
        val project = mockk<Project>()
        flutterExtension.target = "my/target"
        every { project.hasProperty(FlutterPluginUtils.PROP_TARGET) } returns false
        every { project.extensions.findByType(FlutterExtension::class.java) } returns flutterExtension

        val result = FlutterPluginUtils.getFlutterTarget(project)
        assertEquals(flutterExtension.target, result)
    }

    @Test
    fun `getFlutterTarget returns the default target when it is not set`() {
        val project = mockk<Project>()
        every { project.hasProperty(FlutterPluginUtils.PROP_TARGET) } returns false
        every { project.extensions.findByType(FlutterExtension::class.java)!!.target } returns null

        val result = FlutterPluginUtils.getFlutterTarget(project)
        assertEquals("lib/main.dart", result)
    }

    // isBuiltAsApp skipped as it is a wrapper for a single getter

    // addApiDependencies
    @Test
    fun `addApiDependencies adds the dependency with the correct name when no UnknownTaskException`() {
        val project = mockk<Project>()
        val variantName = "debug"
        val dependency = mockk<Any>()

        every { project.configurations.named("api") } returns mockk()
        every { project.dependencies.add(any(), any()) } returns mockk()

        FlutterPluginUtils.addApiDependencies(project, variantName, dependency)

        verify { project.dependencies.add("debugApi", dependency) }
    }

    @Test
    fun `addApiDependencies adds the dependency with the correct name when UnknownTaskException`() {
        val project = mockk<Project>()
        val variantName = "debug"
        val dependency = mockk<Any>()

        every { project.configurations.named("api") } throws UnknownTaskException("message", mockk())
        every { project.dependencies.add(any(), any()) } returns mockk()

        FlutterPluginUtils.addApiDependencies(project, variantName, dependency)

        verify { project.dependencies.add("debugCompile", dependency) }
    }

    // buildModeFor
    @Test
    fun `buildModeFor returns profile if the BuildType has name profile`() {
        val buildType = mockk<BuildType>()
        every { buildType.name } returns "profile"

        val result = FlutterPluginUtils.buildModeFor(buildType)
        assertEquals("profile", result)
    }

    @Test
    fun `buildModeFor returns debug if the BuildType is debuggable`() {
        val buildType = mockk<BuildType>()
        every { buildType.name } returns "something random"
        every { buildType.isDebuggable } returns true

        val result = FlutterPluginUtils.buildModeFor(buildType)
        assertEquals("debug", result)
    }

    @Test
    fun `buildModeFor returns release if the BuildType is not debuggable and not named profile`() {
        val buildType = mockk<BuildType>()
        every { buildType.isDebuggable } returns false
        every { buildType.name } returns "something random"

        val result = FlutterPluginUtils.buildModeFor(buildType)
        assertEquals("release", result)
    }

    // supportsBuildMode
    @Test
    fun `supportsBuildMode returns true if project should not use local engine`() {
        val project = mockk<Project>()
        every { project.hasProperty(FlutterPluginUtils.PROP_LOCAL_ENGINE_REPO) } returns false
        val result = FlutterPluginUtils.supportsBuildMode(project, "debug")
        assertEquals(true, result)
    }

    @Test
    fun `supportsBuildMode returns false if project should use local engine and build mode does not match`() {
        val project = mockk<Project>()
        every { project.hasProperty(FlutterPluginUtils.PROP_LOCAL_ENGINE_REPO) } returns true
        every { project.hasProperty(FlutterPluginUtils.PROP_LOCAL_ENGINE_BUILD_MODE) } returns true
        every { project.property(FlutterPluginUtils.PROP_LOCAL_ENGINE_BUILD_MODE) } returns "debug"

        val result = FlutterPluginUtils.supportsBuildMode(project, "release")
        assertEquals(false, result)
    }
}

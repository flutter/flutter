// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.variant.AndroidComponentsExtension
import com.android.build.gradle.BaseExtension
import com.android.build.gradle.internal.dsl.CmakeOptions
import com.android.build.gradle.internal.dsl.DefaultConfig
import com.android.builder.model.BuildType
import com.flutter.gradle.FlutterPluginUtils.BUILT_IN_KOTLIN_DOCS
import com.flutter.gradle.FlutterPluginUtils.BUILT_IN_KOTLIN_DOCS_FOR_APPS
import com.flutter.gradle.FlutterPluginUtils.BUILT_IN_KOTLIN_DOCS_FOR_PLUGINS
import com.flutter.gradle.FlutterPluginUtils.BUILT_IN_KOTLIN_DOCS_TO_REPORT_UNMIGRATED_PLUGINS
import com.flutter.gradle.FlutterPluginUtils.detectApplyingKotlinGradlePlugin
import com.flutter.gradle.plugins.PluginHandler
import io.mockk.called
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkObject
import io.mockk.slot
import io.mockk.verify
import org.gradle.api.Action
import org.gradle.api.GradleException
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.api.UnknownTaskException
import org.gradle.api.file.Directory
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.invocation.Gradle
import org.gradle.api.logging.Logger
import org.gradle.api.plugins.PluginManager
import org.gradle.internal.impldep.junit.framework.TestCase.assertFalse
import org.gradle.internal.impldep.junit.framework.TestCase.assertTrue
import org.jetbrains.kotlin.gradle.plugin.extraProperties
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.assertThrows
import org.junit.jupiter.api.io.TempDir
import java.io.File
import java.nio.file.Path
import java.util.Properties
import kotlin.io.path.createDirectory
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertFalse

class FlutterPluginUtilsTest {
    companion object {
        const val EXAMPLE_ENGINE_VERSION = "1.0.0-e0676b47c7550ecdc0f0c4fa759201449b2c5f23"

        val devDependency: Map<String?, Any?> =
            mapOf(
                Pair("name", "grays_fun_dev_dependency"),
                Pair(
                    "path",
                    "/Users/someuser/.pub-cache/hosted/pub.dev/grays_fun_dev_dependency-1.1.1/"
                ),
                Pair("native_build", true),
                Pair("dependencies", emptyList<String>()),
                Pair("dev_dependency", true)
            )

        val cameraDependency: Map<String?, Any?> =
            mapOf(
                Pair("name", "camera_android_camerax"),
                Pair(
                    "path",
                    "/Users/someuser/.pub-cache/hosted/pub.dev/camera_android_camerax-0.6.14+1/"
                ),
                Pair("native_build", true),
                Pair("dependencies", emptyList<String>()),
                Pair("dev_dependency", false)
            )

        val flutterPluginAndroidLifecycleDependency: Map<String?, Any?> =
            mapOf(
                Pair("name", "flutter_plugin_android_lifecycle"),
                Pair(
                    "path",
                    "/Users/someuser/.pub-cache/hosted/pub.dev/flutter_plugin_android_lifecycle-2.0.27/"
                ),
                Pair("native_build", true),
                Pair("dependencies", emptyList<String>()),
                Pair("dev_dependency", false)
            )

        val pluginListWithoutDevDependency: List<Map<String?, Any?>> =
            listOf(
                cameraDependency,
                flutterPluginAndroidLifecycleDependency,
                mapOf(
                    Pair("name", "in_app_purchase_android"),
                    Pair(
                        "path",
                        "/Users/someuser/.pub-cache/hosted/pub.dev/in_app_purchase_android-0.4.0+1/"
                    ),
                    Pair("native_build", true),
                    Pair("dependencies", emptyList<String>()),
                    Pair("dev_dependency", false)
                )
            )

        val pluginListWithDevDependency: List<Map<String?, Any?>> =
            listOf(
                cameraDependency,
                flutterPluginAndroidLifecycleDependency,
                devDependency,
                mapOf(
                    Pair("name", "in_app_purchase_android"),
                    Pair(
                        "path",
                        "/Users/someuser/.pub-cache/hosted/pub.dev/in_app_purchase_android-0.4.0+1/"
                    ),
                    Pair("native_build", true),
                    Pair("dependencies", emptyList<String>()),
                    Pair("dev_dependency", false)
                )
            )
        val manifestText =
            """
                <manifest xmlns:android="http://schemas.android.com/apk/res/android">
                    <!-- Permissions do not break parsing -->
                    <uses-permission android:name="android.permission.INTERNET"/>

                    <application android:label="Flutter Task Helper Test" android:icon="@mipmap/ic_launcher">
                        <activity android:name="com.example.FlutterActivity1"
                                  android:exported="true"
                                  android:theme="@android:style/Theme.Black.NoTitleBar">
                            <intent-filter>
                                <action android:name="android.intent.action.MAIN"/>
                                <category android:name="android.intent.category.LAUNCHER"/>
                            </intent-filter>
                        </activity>
                        <activity android:name="com.example.FlutterActivity2"
                                  android:exported="false"
                                  android:theme="@android:style/Theme.Black.NoTitleBar">
                            <intent-filter>
                              <action android:name="android.intent.action.VIEW" />
                              <category android:name="android.intent.category.DEFAULT" />
                              <category android:name="android.intent.category.BROWSABLE" />
                              <data
                                android:scheme="poc"
                                android:host="deeplink.flutter.dev"
                                android:pathPrefix="some.prefix"
                                />
                            </intent-filter>
                            <meta-data android:name="flutter_deeplinking_enabled" android:value="true" />
                        </activity>
                        <meta-data
                            android:name="flutterEmbedding"
                            android:value="2" />

                    </application>
            </manifest>
            """.trimIndent()
    }

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

    // settingsGradleFile
    @Test
    fun `settingsGradleFile returns groovy settings gradle file when it exists`(
        @TempDir tempDir: Path
    ) {
        val projectDir = tempDir.resolve("android").resolve("app")
        projectDir.toFile().mkdirs()

        val settingsGradle = File(projectDir.parent.toFile(), "settings.gradle")
        settingsGradle.createNewFile()

        val result =
            FlutterPluginUtils.getSettingsGradleFileFromProjectDir(projectDir.toFile(), mockk())
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

        val result =
            FlutterPluginUtils.getSettingsGradleFileFromProjectDir(projectDir.toFile(), mockLogger)
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

        val result =
            FlutterPluginUtils.getBuildGradleFileFromProjectDir(projectDir.toFile(), mockk())
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

        val result =
            FlutterPluginUtils.getBuildGradleFileFromProjectDir(projectDir.toFile(), mockLogger)
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

        every { project.configurations.named("api") } throws
            UnknownTaskException(
                "message",
                mockk()
            )
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

    // getTargetPlatforms
    @Test
    fun `getTargetPlatforms the default if property is not set`() {
        val project = mockk<Project>()
        every { project.hasProperty(FlutterPluginUtils.PROP_TARGET_PLATFORM) } returns false
        val result = FlutterPluginUtils.getTargetPlatforms(project)
        assertEquals(listOf("android-arm", "android-arm64", "android-x64"), result)
    }

    @Test
    fun `getTargetPlatforms the value if property is set`() {
        val project = mockk<Project>()
        every { project.hasProperty(FlutterPluginUtils.PROP_TARGET_PLATFORM) } returns true
        every { project.property(FlutterPluginUtils.PROP_TARGET_PLATFORM) } returns "android-arm64,android-arm"
        val result = FlutterPluginUtils.getTargetPlatforms(project)
        assertEquals(listOf("android-arm64", "android-arm"), result)
    }

    @Test
    fun `getTargetPlatforms throws GradleException if property is set to invalid value`() {
        val project = mockk<Project>()
        every { project.hasProperty(FlutterPluginUtils.PROP_TARGET_PLATFORM) } returns true
        every { project.property(FlutterPluginUtils.PROP_TARGET_PLATFORM) } returns "android-invalid"
        val gradleException: GradleException =
            assertThrows<GradleException> {
                FlutterPluginUtils.getTargetPlatforms(project)
            }
        assertContains(gradleException.message!!, "android-invalid")
    }

    // readPropertiesIfExist
    @Test
    fun `readPropertiesIfExist returns empty Properties when file does not exist`(
        @TempDir tempDir: Path
    ) {
        val propertiesFile = tempDir.resolve("file_that_doesnt_exist.properties")
        val result = FlutterPluginUtils.readPropertiesIfExist(propertiesFile.toFile())
        assertEquals(Properties(), result)
    }

    @Test
    fun `readPropertiesIfExist returns Properties when file exists`(
        @TempDir tempDir: Path
    ) {
        val propertiesFile = tempDir.resolve("file_that_exists.properties").toFile()
        propertiesFile.writeText(
            """
            sdk.dir=/Users/someuser/Library/Android/sdk
            flutter.sdk=/Users/someuser/development/flutter/flutter
            flutter.buildMode=release
            flutter.versionName=1.0.0
            flutter.versionCode=1
            """.trimIndent()
        )

        val result = FlutterPluginUtils.readPropertiesIfExist(propertiesFile)
        assertEquals(5, result.size)
        assertEquals("/Users/someuser/Library/Android/sdk", result["sdk.dir"])
        assertEquals("/Users/someuser/development/flutter/flutter", result["flutter.sdk"])
        assertEquals("release", result["flutter.buildMode"])
        assertEquals("1.0.0", result["flutter.versionName"])
        assertEquals("1", result["flutter.versionCode"])
    }

    // getCompileSdkFromProject
    @Test
    fun `getCompileSdkFromProject returns the compileSdk from the project`() {
        val project = mockk<Project>()
        every { project.extensions.findByType(BaseExtension::class.java)!!.compileSdkVersion } returns "android-35"
        val result = FlutterPluginUtils.getCompileSdkFromProject(project)
        assertEquals("35", result)
    }

    // detectLowCompileSdkVersionOrNdkVersion
    @Test
    fun `detectLowCompileSdkVersionOrNdkVersion logs no warnings when no plugins have higher sdk or ndk`(
        @TempDir tempDir: Path
    ) {
        val projectDir = tempDir.resolve("app").toFile()

        val project = mockk<Project>()
        val mockLogger = mockk<Logger>()
        every { project.logger } returns mockLogger
        every { project.projectDir } returns projectDir
        val cameraPluginProject = mockk<Project>()
        val projectActionSlot = slot<Action<Project>>()
        val cameraPluginProjectActionSlot = slot<Action<Project>>()
        every { project.afterEvaluate(any<Action<Project>>()) } returns Unit
        every { project.extensions.findByType(BaseExtension::class.java)!!.compileSdkVersion } returns "android-35"
        every { project.extensions.findByType(BaseExtension::class.java)!!.ndkVersion } returns "26.3.11579264"
        every { project.rootProject.findProject(":${cameraDependency["name"]}") } returns cameraPluginProject
        every { cameraPluginProject.afterEvaluate(capture(cameraPluginProjectActionSlot)) } returns Unit
        every { cameraPluginProject.extensions.findByType(BaseExtension::class.java)!!.compileSdkVersion } returns "android-35"
        every { cameraPluginProject.extensions.findByType(BaseExtension::class.java)!!.ndkVersion } returns "26.3.11579264"

        FlutterPluginUtils.detectLowCompileSdkVersionOrNdkVersion(project, listOf(cameraDependency))

        verify { project.afterEvaluate(capture(projectActionSlot)) }
        projectActionSlot.captured.execute(project)
        verify { cameraPluginProject.afterEvaluate(capture(cameraPluginProjectActionSlot)) }
        cameraPluginProjectActionSlot.captured.execute(cameraPluginProject)

        verify { mockLogger wasNot called }
    }

    @Test
    fun `detectLowCompileSdkVersionOrNdkVersion logs warnings when plugins have higher sdk and ndk`(
        @TempDir tempDir: Path
    ) {
        val buildGradleFile =
            tempDir
                .resolve("app")
                .createDirectory()
                .resolve("build.gradle")
                .toFile()
        buildGradleFile.createNewFile()
        val projectDir = tempDir.resolve("app").toFile()

        val project = mockk<Project>()
        val mockLogger = mockk<Logger>()
        every { project.logger } returns mockLogger
        every { mockLogger.error(any()) } returns Unit
        every { project.projectDir } returns projectDir
        val cameraPluginProject = mockk<Project>()
        val flutterPluginAndroidLifecycleDependencyPluginProject = mockk<Project>()
        val projectActionSlot = slot<Action<Project>>()
        val cameraPluginProjectActionSlot = slot<Action<Project>>()
        val flutterPluginAndroidLifecycleDependencyPluginProjectActionSlot = slot<Action<Project>>()
        every { project.afterEvaluate(any<Action<Project>>()) } returns Unit
        every { project.extensions.findByType(BaseExtension::class.java)!!.compileSdkVersion } returns "android-33"
        every { project.extensions.findByType(BaseExtension::class.java)!!.ndkVersion } returns "24.3.11579264"
        every { project.rootProject.findProject(":${cameraDependency["name"]}") } returns cameraPluginProject
        every { project.rootProject.findProject(":${flutterPluginAndroidLifecycleDependency["name"]}") } returns
            flutterPluginAndroidLifecycleDependencyPluginProject
        every { cameraPluginProject.afterEvaluate(capture(cameraPluginProjectActionSlot)) } returns Unit
        every { cameraPluginProject.extensions.findByType(BaseExtension::class.java)!!.compileSdkVersion } returns "android-35"
        every { cameraPluginProject.extensions.findByType(BaseExtension::class.java)!!.ndkVersion } returns "26.3.11579264"
        every {
            flutterPluginAndroidLifecycleDependencyPluginProject.afterEvaluate(
                capture(
                    flutterPluginAndroidLifecycleDependencyPluginProjectActionSlot
                )
            )
        } returns Unit
        every {
            flutterPluginAndroidLifecycleDependencyPluginProject.extensions
                .findByType(
                    BaseExtension::class.java
                )!!
                .compileSdkVersion
        } returns "android-34"
        every {
            flutterPluginAndroidLifecycleDependencyPluginProject.extensions
                .findByType(
                    BaseExtension::class.java
                )!!
                .ndkVersion
        } returns "25.3.11579264"

        val dependencyList: List<Map<String?, Any?>> =
            listOf(cameraDependency, flutterPluginAndroidLifecycleDependency)
        FlutterPluginUtils.detectLowCompileSdkVersionOrNdkVersion(
            project,
            dependencyList
        )

        verify { project.afterEvaluate(capture(projectActionSlot)) }
        projectActionSlot.captured.execute(project)
        verify { cameraPluginProject.afterEvaluate(capture(cameraPluginProjectActionSlot)) }
        cameraPluginProjectActionSlot.captured.execute(cameraPluginProject)
        verify {
            flutterPluginAndroidLifecycleDependencyPluginProject.afterEvaluate(
                capture(
                    flutterPluginAndroidLifecycleDependencyPluginProjectActionSlot
                )
            )
        }
        flutterPluginAndroidLifecycleDependencyPluginProjectActionSlot.captured.execute(
            flutterPluginAndroidLifecycleDependencyPluginProject
        )

        verify {
            mockLogger.error(
                "Your project is configured to compile against Android SDK 33, but the " +
                    "following plugin(s) require to be compiled against a higher Android SDK version:"
            )
        }
        verify {
            mockLogger.error(
                "- ${cameraDependency["name"]} compiles against Android SDK 35"
            )
        }
        verify {
            mockLogger.error(
                "- ${flutterPluginAndroidLifecycleDependency["name"]} compiles against Android SDK 34"
            )
        }
        verify {
            mockLogger.error(
                """
                Fix this issue by compiling against the highest Android SDK version (they are backward compatible).
                Add the following to ${buildGradleFile.path}:

                    android {
                        compileSdk = 35
                        ...
                    }
                """.trimIndent()
            )
        }
        verify {
            mockLogger.error(
                "Your project is configured with Android NDK 24.3.11579264, but the following plugin(s) depend on a different Android NDK version:"
            )
        }
        verify {
            mockLogger.error(
                "- ${cameraDependency["name"]} requires Android NDK 26.3.11579264"
            )
        }
        verify {
            mockLogger.error(
                "- ${flutterPluginAndroidLifecycleDependency["name"]} requires Android NDK 25.3.11579264"
            )
        }
        verify {
            mockLogger.error(
                """
                Fix this issue by using the highest Android NDK version (they are backward compatible).
                Add the following to ${buildGradleFile.path}:

                    android {
                        ndkVersion = "26.3.11579264"
                        ...
                    }
                """.trimIndent()
            )
        }
    }

    @Test
    fun `detectLowCompileSdkVersionOrNdkVersion throws IllegalArgumentException when plugin has no name`() {
        val project = mockk<Project>()
        val projectActionSlot = slot<Action<Project>>()
        every { project.afterEvaluate(any<Action<Project>>()) } returns Unit
        every { project.extensions.findByType(BaseExtension::class.java)!!.compileSdkVersion } returns "android-35"
        every { project.extensions.findByType(BaseExtension::class.java)!!.ndkVersion } returns "26.3.11579264"

        val pluginWithoutName: MutableMap<String?, Any?> = cameraDependency.toMutableMap()
        pluginWithoutName.remove("name")

        FlutterPluginUtils.detectLowCompileSdkVersionOrNdkVersion(
            project,
            listOf(pluginWithoutName)
        )
        verify { project.afterEvaluate(capture(projectActionSlot)) }
        assertThrows<IllegalArgumentException> { projectActionSlot.captured.execute(project) }
    }

    enum class DslType { GROOVY, KOTLIN }

    @Nested
    inner class SupportBuiltInKotlinTests {
        @Nested
        inner class TestApplyingPluginsRegexTests {
            @Test
            fun `AGP app regex on single line apply`() {
                assertSingeLinePluginDetection(FlutterPluginUtils.appPluginRegexKotlin, "com.android.application", DslType.KOTLIN)
                assertSingeLinePluginDetection(FlutterPluginUtils.appPluginRegexGroovy, "com.android.application", DslType.GROOVY)
            }

            @Test
            fun `AGP lib regex on single line apply`() {
                assertSingeLinePluginDetection(FlutterPluginUtils.libPluginRegexKotlin, "com.android.library", DslType.KOTLIN)
                assertSingeLinePluginDetection(FlutterPluginUtils.libPluginRegexGroovy, "com.android.library", DslType.GROOVY)
            }

            @Test
            fun `KGP regex on single line apply`() {
                assertSingeLinePluginDetection(FlutterPluginUtils.kgpRegexKotlin, "kotlin-android", DslType.KOTLIN)
                assertSingeLinePluginDetection(FlutterPluginUtils.kgpRegexGroovy, "kotlin-android", DslType.GROOVY)
                assertSingeLinePluginDetection(FlutterPluginUtils.kgpRegexKotlin, "org.jetbrains.kotlin.android", DslType.KOTLIN)
                assertSingeLinePluginDetection(FlutterPluginUtils.kgpRegexGroovy, "org.jetbrains.kotlin.android", DslType.GROOVY)
            }

            @Test
            fun `Regexes are successful when multiple plugins are applied`() {
                val appProjectBuildGradlePluginsBlock =
                    """
                    plugins {
                        id("com.android.application")
                        id("kotlin-android")
                    }
                    """.trimIndent()
                assertTrue(
                    FlutterPluginUtils.appPluginRegexKotlin.containsMatchIn(appProjectBuildGradlePluginsBlock)
                )
                assertTrue(
                    FlutterPluginUtils.kgpRegexKotlin.containsMatchIn(appProjectBuildGradlePluginsBlock)
                )

                assertTrue(
                    FlutterPluginUtils.appPluginRegexGroovy.containsMatchIn(appProjectBuildGradlePluginsBlock)
                )
                assertTrue(
                    FlutterPluginUtils.kgpRegexGroovy.containsMatchIn(appProjectBuildGradlePluginsBlock)
                )

                val libProjectBuildGradlePluginsBlock =
                    """
                    plugins {
                        id("com.android.library")
                        id("org.jetbrains.kotlin.android")
                    }
                    """.trimIndent()
                assertTrue(
                    FlutterPluginUtils.libPluginRegexKotlin.containsMatchIn(libProjectBuildGradlePluginsBlock)
                )
                assertTrue(
                    FlutterPluginUtils.kgpRegexKotlin.containsMatchIn(libProjectBuildGradlePluginsBlock)
                )

                assertTrue(
                    FlutterPluginUtils.libPluginRegexGroovy.containsMatchIn(libProjectBuildGradlePluginsBlock)
                )
                assertTrue(
                    FlutterPluginUtils.kgpRegexGroovy.containsMatchIn(libProjectBuildGradlePluginsBlock)
                )

                val appProjectBuildGradlePluginsBlockNoParens =
                    """
                    plugins {
                        id 'com.android.application'
                        id 'kotlin-android'
                    }
                    """.trimIndent()
                assertTrue(
                    FlutterPluginUtils.appPluginRegexGroovy.containsMatchIn(appProjectBuildGradlePluginsBlockNoParens)
                )
                assertTrue(
                    FlutterPluginUtils.kgpRegexGroovy.containsMatchIn(appProjectBuildGradlePluginsBlockNoParens)
                )

                assertFalse(
                    FlutterPluginUtils.appPluginRegexKotlin.containsMatchIn(appProjectBuildGradlePluginsBlockNoParens)
                )
                assertFalse(
                    FlutterPluginUtils.kgpRegexKotlin.containsMatchIn(appProjectBuildGradlePluginsBlockNoParens)
                )

                val appProjectBuildGradlePluginsBlockMixed =
                    """
                    plugins {
                        id 'com.android.application'
                        alias 'kotlin-android'
                    }
                    """.trimIndent()
                assertTrue(
                    FlutterPluginUtils.appPluginRegexGroovy.containsMatchIn(appProjectBuildGradlePluginsBlockMixed)
                )
                assertTrue(
                    FlutterPluginUtils.kgpRegexGroovy.containsMatchIn(appProjectBuildGradlePluginsBlockMixed)
                )

                assertFalse(
                    FlutterPluginUtils.appPluginRegexKotlin.containsMatchIn(appProjectBuildGradlePluginsBlockMixed)
                )
                assertFalse(
                    FlutterPluginUtils.kgpRegexKotlin.containsMatchIn(appProjectBuildGradlePluginsBlockMixed)
                )
            }

            @Test
            fun `Regexes fail when multiple plugins are applied`() {
                val kotlinSameLine =
                    """
                    plugins {
                        id("com.android.application") id("kotlin-android")
                    }
                    """.trimIndent()

                assertFalse(
                    FlutterPluginUtils.appPluginRegexKotlin.containsMatchIn(kotlinSameLine),
                    "Should fail: multi-id on one line"
                )
                assertFalse(
                    FlutterPluginUtils.kgpRegexKotlin.containsMatchIn(kotlinSameLine),
                    "Should fail: multi-id on one line"
                )

                val groovySameLine =
                    """
                    plugins {
                        id 'com.android.application' id 'kotlin-android'
                    }
                    """.trimIndent()

                assertFalse(
                    FlutterPluginUtils.appPluginRegexGroovy.containsMatchIn(groovySameLine),
                    "Should fail: multi-id on one line"
                )
                assertFalse(
                    FlutterPluginUtils.kgpRegexGroovy.containsMatchIn(groovySameLine),
                    "Should fail: multi-id on one line"
                )

                val appProjectBuildGradlePluginsCommentOnePlugin =
                    """
                    plugins {
                       id 'com.android.application'
                       // alias 'kotlin-android'
                    }
                    """.trimIndent()
                assertTrue(
                    FlutterPluginUtils.appPluginRegexGroovy.containsMatchIn(appProjectBuildGradlePluginsCommentOnePlugin)
                )
                assertFalse(
                    FlutterPluginUtils.kgpRegexGroovy.containsMatchIn(appProjectBuildGradlePluginsCommentOnePlugin)
                )

                assertFalse(
                    FlutterPluginUtils.appPluginRegexKotlin.containsMatchIn(appProjectBuildGradlePluginsCommentOnePlugin)
                )
                assertFalse(
                    FlutterPluginUtils.kgpRegexKotlin.containsMatchIn(appProjectBuildGradlePluginsCommentOnePlugin)
                )

                val appProjectBuildGradlePluginsComment =
                    """
                    // plugins {
                    //    id 'com.android.application'
                    //    alias 'kotlin-android'
                    // }
                    """.trimIndent()
                assertFalse(
                    FlutterPluginUtils.appPluginRegexGroovy.containsMatchIn(appProjectBuildGradlePluginsComment)
                )
                assertFalse(
                    FlutterPluginUtils.kgpRegexGroovy.containsMatchIn(appProjectBuildGradlePluginsComment)
                )

                assertFalse(
                    FlutterPluginUtils.appPluginRegexKotlin.containsMatchIn(appProjectBuildGradlePluginsComment)
                )
                assertFalse(
                    FlutterPluginUtils.kgpRegexKotlin.containsMatchIn(appProjectBuildGradlePluginsComment)
                )
            }
        }

        fun assertSingeLinePluginDetection(
            regex: Regex,
            pluginId: String,
            dslType: DslType
        ) {
            if (dslType == DslType.GROOVY) {
                assertTrue(regex.containsMatchIn("apply plugin: '$pluginId'"))
                assertTrue(regex.containsMatchIn("apply plugin: \"$pluginId\""))
                assertTrue(regex.containsMatchIn("plugins { id '$pluginId' }"))
                assertTrue(regex.containsMatchIn("plugins { id \"$pluginId\" }"))
                assertTrue(regex.containsMatchIn("plugins {\n  id '$pluginId'\n}"))
                assertTrue(regex.containsMatchIn("plugins { alias '$pluginId' }"))

                assertFalse(regex.containsMatchIn("apply plugin\n:'$pluginId'"), "Newline before colon failure")
                assertFalse(regex.containsMatchIn("plugins { id\n'$pluginId' }"), "newline before opening quote")
            }
            if (dslType == DslType.KOTLIN) {
                assertTrue(regex.containsMatchIn("plugins {\n  id(\"$pluginId\")\n}"))
                assertTrue(regex.containsMatchIn("plugins { id(\n'$pluginId'\n) }"))

                assertFalse(regex.containsMatchIn("plugins { id '$pluginId' }"), "Kotlin DSL requires parentheses")
                assertFalse(regex.containsMatchIn("apply plugin: '$pluginId'"), "Kotlin DSL does not use apply plugin: for AGP/KGP")
            }

            assertTrue(regex.containsMatchIn("plugins { id('$pluginId') }"))
            assertTrue(regex.containsMatchIn("plugins { id(\"$pluginId\") }"))
            assertTrue(regex.containsMatchIn("plugins { alias('$pluginId') }"))
            assertTrue(regex.containsMatchIn("plugins { alias(\"$pluginId\") }"))

            assertFalse(regex.containsMatchIn("// id '$pluginId'"), "Failed to ignore single line comment")
            assertFalse(regex.containsMatchIn("// id('$pluginId')"), "Failed to ignore single line comment")

            // Check newline constraints
            assertFalse(regex.containsMatchIn("plugins\n{ id('$pluginId') }"), "Newline before opening bracket should fail")
            assertFalse(regex.containsMatchIn("plugins { id\n('$pluginId') }"), "Newline before opening parentheses should fail")
            // Check spacing inside quotes
            assertFalse(regex.containsMatchIn("id ' $pluginId '"), "Should fail when there are spaces in quotes")
        }

        @Nested
        inner class DetectApplyingKotlinGradlePluginTests {
            @Test
            fun `logs app warning when KGP is only applied in app`(
                @TempDir tempDir: Path
            ) {
                val appDir = tempDir.resolve("app").toFile().apply { mkdirs() }
                val appBuildGradleFile =
                    File(appDir, "build.gradle").apply {
                        createNewFile()
                        writeText(
                            """
                            plugins {
                                id("com.android.application")
                                id("kotlin-android")
                            }
                            """.trimIndent()
                        )
                    }

                val pluginDir = tempDir.resolve("plugin").toFile().apply { mkdirs() }
                val pluginBuildGradleFile =
                    File(pluginDir, "build.gradle").apply {
                        createNewFile()
                        writeText(
                            """
                            plugins {
                                id("com.android.library")
                            }
                            """.trimIndent()
                        )
                    }

                val rootProject = mockk<Project>()
                val mockGradle = mockk<Gradle>()
                val mockLogger = mockk<Logger>(relaxed = true)

                val appProjectPluginManager = mockk<PluginManager>(relaxed = true)
                val pluginProjectPluginManager = mockk<PluginManager>(relaxed = true)

                val appProject =
                    createMockSubproject(
                        tempDir = tempDir,
                        buildFile = appBuildGradleFile,
                        projectName = "app",
                        mockLogger = mockLogger,
                        rootProjectMock = rootProject,
                        gradleMock = mockGradle,
                        pluginManager = appProjectPluginManager
                    )

                val pluginProject =
                    createMockSubproject(
                        tempDir = tempDir,
                        buildFile = pluginBuildGradleFile,
                        projectName = "plugin",
                        mockLogger = mockLogger,
                        rootProjectMock = rootProject,
                        gradleMock = mockGradle,
                        pluginManager = pluginProjectPluginManager
                    )

                val subprojectsActionSlot = slot<Action<Project>>()
                val projectsEvaluatedActionSlot = slot<Action<Gradle>>()

                every { rootProject.subprojects(capture(subprojectsActionSlot)) } returns Unit
                every { mockGradle.projectsEvaluated(capture(projectsEvaluatedActionSlot)) } returns Unit

                detectApplyingKotlinGradlePlugin(appProject)

                verify { rootProject.subprojects(capture(subprojectsActionSlot)) }
                subprojectsActionSlot.captured.execute(appProject)
                subprojectsActionSlot.captured.execute(pluginProject)

                verify { mockGradle.projectsEvaluated(capture(projectsEvaluatedActionSlot)) }
                projectsEvaluatedActionSlot.captured.execute(mockGradle)

                verify {
                    mockLogger.error(
                        """
                        WARNING: Your Android app project: app located at: ${appBuildGradleFile.absolutePath}
                        applies the Kotlin Gradle Plugin, which will cause build failures in future versions of Flutter. 
                        Please migrate your app to Built-in Kotlin using this guide: $BUILT_IN_KOTLIN_DOCS_FOR_APPS
                        
                        """.trimIndent()
                    )
                }

                verify(exactly = 0) {
                    mockLogger.error(match { it.contains("Your app uses the following plugins") })
                }
                verify(exactly = 0) { appProjectPluginManager.apply("kotlin-android") }
                verify(exactly = 1) { pluginProjectPluginManager.apply("kotlin-android") }
            }

            @Test
            fun `logs plugin warning when KGP is only applied in one plugin`(
                @TempDir tempDir: Path
            ) {
                val appDir = tempDir.resolve("app").toFile().apply { mkdirs() }
                val appBuildGradleFile =
                    File(appDir, "build.gradle").apply {
                        createNewFile()
                        writeText(
                            """
                            plugins {
                                id("com.android.application")
                            }
                            """.trimIndent()
                        )
                    }

                val pluginDir = tempDir.resolve("plugin").toFile().apply { mkdirs() }
                val pluginBuildGradleFile =
                    File(pluginDir, "build.gradle").apply {
                        createNewFile()
                        writeText(
                            """
                            plugins {
                                id("com.android.library")
                                id("kotlin-android")
                            }
                            """.trimIndent()
                        )
                    }

                val rootProject = mockk<Project>()
                val mockGradle = mockk<Gradle>()
                val mockLogger = mockk<Logger>(relaxed = true)

                val appProjectPluginManager = mockk<PluginManager>(relaxed = true)
                val pluginProjectPluginManager = mockk<PluginManager>(relaxed = true)

                val appProject =
                    createMockSubproject(
                        tempDir = tempDir,
                        buildFile = appBuildGradleFile,
                        projectName = "app",
                        mockLogger = mockLogger,
                        rootProjectMock = rootProject,
                        gradleMock = mockGradle,
                        pluginManager = appProjectPluginManager
                    )

                val pluginProject =
                    createMockSubproject(
                        tempDir = tempDir,
                        buildFile = pluginBuildGradleFile,
                        projectName = "plugin",
                        mockLogger = mockLogger,
                        rootProjectMock = rootProject,
                        gradleMock = mockGradle,
                        pluginManager = pluginProjectPluginManager
                    )

                val subprojectsActionSlot = slot<Action<Project>>()
                val projectsEvaluatedActionSlot = slot<Action<Gradle>>()

                every { rootProject.subprojects(capture(subprojectsActionSlot)) } returns Unit
                every { mockGradle.projectsEvaluated(capture(projectsEvaluatedActionSlot)) } returns Unit

                detectApplyingKotlinGradlePlugin(appProject)

                verify { rootProject.subprojects(capture(subprojectsActionSlot)) }
                subprojectsActionSlot.captured.execute(appProject)
                subprojectsActionSlot.captured.execute(pluginProject)

                verify { mockGradle.projectsEvaluated(capture(projectsEvaluatedActionSlot)) }
                projectsEvaluatedActionSlot.captured.execute(mockGradle)

                verify {
                    mockLogger.error(
                        """
                        WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): plugin
                        Future versions of Flutter will fail to build if your app uses plugins that apply KGP.
                        
                        Please check the changelogs of these plugins and upgrade to a version that supports Built-in Kotlin.
                        If no such version exists, report the issue to the plugin. If necessary, here is a guide on filing 
                        an issue against a plugin: $BUILT_IN_KOTLIN_DOCS_TO_REPORT_UNMIGRATED_PLUGINS
                        
                        If you are a plugin author, please migrate your plugin to Built-in Kotlin using this guide: $BUILT_IN_KOTLIN_DOCS_FOR_PLUGINS
                        """.trimIndent()
                    )
                }

                verify(exactly = 0) {
                    mockLogger.error(match { it.contains("Your Android app project") })
                }
                verify(exactly = 1) { appProjectPluginManager.apply("kotlin-android") }
                verify(exactly = 0) { pluginProjectPluginManager.apply("kotlin-android") }
            }

            @Test
            fun `logs app and plugin warning when KGP is applied in both app and plugins`(
                @TempDir tempDir: Path
            ) {
                val appDir = tempDir.resolve("app").toFile().apply { mkdirs() }
                val appBuildGradleFile =
                    File(appDir, "build.gradle").apply {
                        createNewFile()
                        writeText(
                            """
                            plugins {
                                id("com.android.application")
                                id("kotlin-android")
                            }
                            """.trimIndent()
                        )
                    }

                val pluginDir = tempDir.resolve("plugin").toFile().apply { mkdirs() }
                val pluginBuildGradleFile =
                    File(pluginDir, "build.gradle").apply {
                        createNewFile()
                        writeText(
                            """
                            plugins {
                                id("com.android.library")
                                id("kotlin-android")
                            }
                            """.trimIndent()
                        )
                    }

                val rootProject = mockk<Project>()
                val mockGradle = mockk<Gradle>()
                val mockLogger = mockk<Logger>(relaxed = true)

                val appProjectPluginManager = mockk<PluginManager>(relaxed = true)
                val pluginProjectPluginManager = mockk<PluginManager>(relaxed = true)

                val appProject =
                    createMockSubproject(
                        tempDir = tempDir,
                        buildFile = appBuildGradleFile,
                        projectName = "app",
                        mockLogger = mockLogger,
                        rootProjectMock = rootProject,
                        gradleMock = mockGradle,
                        pluginManager = appProjectPluginManager
                    )

                val pluginProject =
                    createMockSubproject(
                        tempDir = tempDir,
                        buildFile = pluginBuildGradleFile,
                        projectName = "plugin",
                        mockLogger = mockLogger,
                        rootProjectMock = rootProject,
                        gradleMock = mockGradle,
                        pluginManager = pluginProjectPluginManager
                    )

                val subprojectsActionSlot = slot<Action<Project>>()
                val projectsEvaluatedActionSlot = slot<Action<Gradle>>()

                every { rootProject.subprojects(capture(subprojectsActionSlot)) } returns Unit
                every { mockGradle.projectsEvaluated(capture(projectsEvaluatedActionSlot)) } returns Unit

                detectApplyingKotlinGradlePlugin(appProject)

                verify { rootProject.subprojects(capture(subprojectsActionSlot)) }
                subprojectsActionSlot.captured.execute(appProject)
                subprojectsActionSlot.captured.execute(pluginProject)

                verify { mockGradle.projectsEvaluated(capture(projectsEvaluatedActionSlot)) }
                projectsEvaluatedActionSlot.captured.execute(mockGradle)

                verify {
                    mockLogger.error(
                        """
                        WARNING: Your Android app project: app located at: ${appBuildGradleFile.absolutePath}
                        applies the Kotlin Gradle Plugin, which will cause build failures in future versions of Flutter. 
                        Please migrate your app to Built-in Kotlin using this guide: $BUILT_IN_KOTLIN_DOCS_FOR_APPS
                        
                        """.trimIndent()
                    )
                }

                verify {
                    mockLogger.error(
                        """
                        WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): plugin
                        Future versions of Flutter will fail to build if your app uses plugins that apply KGP.
                        
                        Please check the changelogs of these plugins and upgrade to a version that supports Built-in Kotlin.
                        If no such version exists, report the issue to the plugin. If necessary, here is a guide on filing 
                        an issue against a plugin: $BUILT_IN_KOTLIN_DOCS_TO_REPORT_UNMIGRATED_PLUGINS
                        
                        If you are a plugin author, please migrate your plugin to Built-in Kotlin using this guide: $BUILT_IN_KOTLIN_DOCS_FOR_PLUGINS
                        """.trimIndent()
                    )
                }

                verify(exactly = 0) { appProjectPluginManager.apply("kotlin-android") }
                verify(exactly = 0) { pluginProjectPluginManager.apply("kotlin-android") }
            }

            @Test
            fun `logs app and plugin warning when legacy KGP configuration is applied in both app and plugins`(
                @TempDir tempDir: Path
            ) {
                val appDir = tempDir.resolve("app").toFile().apply { mkdirs() }
                val appBuildGradleFile =
                    File(appDir, "build.gradle").apply {
                        createNewFile()
                        writeText(
                            """
                            apply plugin: 'com.android.application'
                            apply plugin: 'kotlin-android'
                            """.trimIndent()
                        )
                    }

                val pluginDir = tempDir.resolve("plugin").toFile().apply { mkdirs() }
                val pluginBuildGradleFile =
                    File(pluginDir, "build.gradle").apply {
                        createNewFile()
                        writeText(
                            """
                            apply plugin: 'com.android.library'
                            apply plugin: 'kotlin-android'
                            """.trimIndent()
                        )
                    }

                val rootProject = mockk<Project>()
                val mockGradle = mockk<Gradle>()
                val mockLogger = mockk<Logger>(relaxed = true)

                val appProjectPluginManager = mockk<PluginManager>(relaxed = true)
                val pluginProjectOnePluginManager = mockk<PluginManager>(relaxed = true)
                val pluginProjectTwoPluginManager = mockk<PluginManager>(relaxed = true)

                val appProject =
                    createMockSubproject(
                        tempDir = tempDir,
                        buildFile = appBuildGradleFile,
                        projectName = "app",
                        mockLogger = mockLogger,
                        rootProjectMock = rootProject,
                        gradleMock = mockGradle,
                        pluginManager = appProjectPluginManager
                    )

                val pluginProjectOne =
                    createMockSubproject(
                        tempDir = tempDir,
                        buildFile = pluginBuildGradleFile,
                        projectName = "plugin1",
                        mockLogger = mockLogger,
                        rootProjectMock = rootProject,
                        gradleMock = mockGradle,
                        pluginManager = pluginProjectOnePluginManager
                    )

                val pluginProjectTwo =
                    createMockSubproject(
                        tempDir = tempDir,
                        buildFile = pluginBuildGradleFile,
                        projectName = "plugin2",
                        mockLogger = mockLogger,
                        rootProjectMock = rootProject,
                        gradleMock = mockGradle,
                        pluginManager = pluginProjectTwoPluginManager
                    )

                val subprojectsActionSlot = slot<Action<Project>>()
                val projectsEvaluatedActionSlot = slot<Action<Gradle>>()

                every { rootProject.subprojects(capture(subprojectsActionSlot)) } returns Unit
                every { mockGradle.projectsEvaluated(capture(projectsEvaluatedActionSlot)) } returns Unit

                detectApplyingKotlinGradlePlugin(appProject)

                verify { rootProject.subprojects(capture(subprojectsActionSlot)) }
                subprojectsActionSlot.captured.execute(appProject)
                subprojectsActionSlot.captured.execute(pluginProjectOne)
                subprojectsActionSlot.captured.execute(pluginProjectTwo)

                verify { mockGradle.projectsEvaluated(capture(projectsEvaluatedActionSlot)) }
                projectsEvaluatedActionSlot.captured.execute(mockGradle)

                verify {
                    mockLogger.error(
                        """
                        WARNING: Your Android app project: app located at: ${appBuildGradleFile.absolutePath}
                        applies the Kotlin Gradle Plugin, which will cause build failures in future versions of Flutter. 
                        Please migrate your app to Built-in Kotlin using this guide: $BUILT_IN_KOTLIN_DOCS_FOR_APPS
                        
                        """.trimIndent()
                    )
                }

                verify {
                    mockLogger.error(
                        """
                        WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): plugin1, plugin2
                        Future versions of Flutter will fail to build if your app uses plugins that apply KGP.
                        
                        Please check the changelogs of these plugins and upgrade to a version that supports Built-in Kotlin.
                        If no such version exists, report the issue to the plugin. If necessary, here is a guide on filing 
                        an issue against a plugin: $BUILT_IN_KOTLIN_DOCS_TO_REPORT_UNMIGRATED_PLUGINS
                        
                        If you are a plugin author, please migrate your plugin to Built-in Kotlin using this guide: $BUILT_IN_KOTLIN_DOCS_FOR_PLUGINS
                        """.trimIndent()
                    )
                }

                verify(exactly = 0) { appProjectPluginManager.apply("kotlin-android") }
                verify(exactly = 0) { pluginProjectOnePluginManager.apply("kotlin-android") }
                verify(exactly = 0) { pluginProjectTwoPluginManager.apply("kotlin-android") }
            }

            @Test
            fun `does not log when migrated to Built-in Kotlin`(
                @TempDir tempDir: Path
            ) {
                val appDir = tempDir.resolve("app").toFile().apply { mkdirs() }
                val appBuildGradleFile =
                    File(appDir, "build.gradle").apply {
                        createNewFile()
                        writeText(
                            """
                            apply plugin: 'com.android.application'
                            """.trimIndent()
                        )
                    }

                val pluginDir = tempDir.resolve("plugin").toFile().apply { mkdirs() }
                val pluginBuildGradleFile =
                    File(pluginDir, "build.gradle").apply {
                        createNewFile()
                        writeText(
                            """
                            apply plugin: 'com.android.library'
                            """.trimIndent()
                        )
                    }

                val rootProject = mockk<Project>()
                val mockGradle = mockk<Gradle>()
                val mockLogger = mockk<Logger>(relaxed = true)

                val appProjectPluginManager = mockk<PluginManager>(relaxed = true)
                val pluginProjectPluginManager = mockk<PluginManager>(relaxed = true)

                val appProject =
                    createMockSubproject(
                        tempDir = tempDir,
                        buildFile = appBuildGradleFile,
                        projectName = "app",
                        mockLogger = mockLogger,
                        rootProjectMock = rootProject,
                        gradleMock = mockGradle,
                        pluginManager = appProjectPluginManager
                    )

                val pluginProject =
                    createMockSubproject(
                        tempDir = tempDir,
                        buildFile = pluginBuildGradleFile,
                        projectName = "plugin",
                        mockLogger = mockLogger,
                        rootProjectMock = rootProject,
                        gradleMock = mockGradle,
                        pluginManager = pluginProjectPluginManager
                    )

                val subprojectsActionSlot = slot<Action<Project>>()
                val projectsEvaluatedActionSlot = slot<Action<Gradle>>()

                every { rootProject.subprojects(capture(subprojectsActionSlot)) } returns Unit
                every { mockGradle.projectsEvaluated(capture(projectsEvaluatedActionSlot)) } returns Unit

                detectApplyingKotlinGradlePlugin(appProject)

                verify { rootProject.subprojects(capture(subprojectsActionSlot)) }
                subprojectsActionSlot.captured.execute(appProject)
                subprojectsActionSlot.captured.execute(pluginProject)

                verify { mockGradle.projectsEvaluated(capture(projectsEvaluatedActionSlot)) }
                projectsEvaluatedActionSlot.captured.execute(mockGradle)

                verify(exactly = 0) {
                    mockLogger.error(any())
                }

                verify(exactly = 1) { appProjectPluginManager.apply("kotlin-android") }
                verify(exactly = 1) { pluginProjectPluginManager.apply("kotlin-android") }
            }

            @Test
            fun `logs when KGP is applied but fails to apply`(
                @TempDir tempDir: Path
            ) {
                val appDir = tempDir.resolve("app").toFile().apply { mkdirs() }
                val appBuildGradleFile =
                    File(appDir, "build.gradle").apply {
                        createNewFile()
                        writeText(
                            """
                            plugins {
                                id("com.android.application")
                            }
                            """.trimIndent()
                        )
                    }

                val pluginDir = tempDir.resolve("plugin").toFile().apply { mkdirs() }
                val pluginBuildGradleFile =
                    File(pluginDir, "build.gradle").apply {
                        createNewFile()
                        writeText(
                            """
                            plugins {
                                id("com.android.library")
                            }
                            """.trimIndent()
                        )
                    }

                val rootProject = mockk<Project>()
                val mockGradle = mockk<Gradle>()
                val mockLogger = mockk<Logger>(relaxed = true)

                val appProjectPluginManager = mockk<PluginManager>(relaxed = true)
                val pluginProjectPluginManager = mockk<PluginManager>(relaxed = true)

                val appProject =
                    createMockSubproject(
                        tempDir = tempDir,
                        buildFile = appBuildGradleFile,
                        projectName = "app",
                        mockLogger = mockLogger,
                        rootProjectMock = rootProject,
                        gradleMock = mockGradle,
                        pluginManager = appProjectPluginManager
                    )

                val pluginProject =
                    createMockSubproject(
                        tempDir = tempDir,
                        buildFile = pluginBuildGradleFile,
                        projectName = "plugin",
                        mockLogger = mockLogger,
                        rootProjectMock = rootProject,
                        gradleMock = mockGradle,
                        pluginManager = pluginProjectPluginManager
                    )

                val subprojectsActionSlot = slot<Action<Project>>()
                val projectsEvaluatedActionSlot = slot<Action<Gradle>>()

                every { rootProject.subprojects(capture(subprojectsActionSlot)) } returns Unit
                every { mockGradle.projectsEvaluated(capture(projectsEvaluatedActionSlot)) } returns Unit

                every { appProjectPluginManager.apply("kotlin-android") } throws Exception("KGP not on classpath")
                every { pluginProjectPluginManager.apply("kotlin-android") } throws Exception("KGP not on classpath")

                detectApplyingKotlinGradlePlugin(appProject)

                verify { rootProject.subprojects(capture(subprojectsActionSlot)) }
                subprojectsActionSlot.captured.execute(appProject)
                subprojectsActionSlot.captured.execute(pluginProject)

                verify { mockGradle.projectsEvaluated(capture(projectsEvaluatedActionSlot)) }
                projectsEvaluatedActionSlot.captured.execute(mockGradle)

                verify(exactly = 0) {
                    mockLogger.error(any())
                }

                verify {
                    mockLogger.quiet(
                        """
                        Applying the Kotlin Android Plugin (KGP) was unsuccessful. KGP was not found on the classpath.
                        If your project uses Kotlin, ensure KGP is declared in the root plugins block.
                        For more details check: $BUILT_IN_KOTLIN_DOCS
                        """.trimIndent()
                    )
                }
            }
        }

        private fun createMockSubproject(
            tempDir: Path,
            buildFile: File,
            projectName: String,
            mockLogger: Logger,
            rootProjectMock: Project? = null,
            gradleMock: Gradle? = null,
            pluginManager: PluginManager
        ): Project {
            val projectDir = tempDir.resolve(projectName).toFile().apply { mkdirs() }

            val project = mockk<Project>()
            every { project.name } returns projectName
            every { project.projectDir } returns projectDir
            every { project.buildFile } returns buildFile
            every { project.logger } returns mockLogger
            every { project.pluginManager } returns pluginManager

            if (rootProjectMock != null) every { project.rootProject } returns rootProjectMock
            if (gradleMock != null) every { project.gradle } returns gradleMock

            return project
        }
    }

    // forceNdkDownload
    @Test
    fun `forceNdkDownload skips projects which are already configuring a native build`(
        @TempDir tempDir: Path
    ) {
        val fakeCmakeFile = tempDir.resolve("CMakeLists.txt").toFile()
        fakeCmakeFile.createNewFile()
        val project = mockk<Project>()
        val mockCmakeOptions = mockk<CmakeOptions>()
        val mockDefaultConfig = mockk<DefaultConfig>()
        every { project.extensions.findByType(ApplicationExtension::class.java) } returns null
        every {
            project.extensions
                .findByType(BaseExtension::class.java)!!
                .externalNativeBuild.cmake
        } returns mockCmakeOptions
        every { project.extensions.findByType(BaseExtension::class.java)!!.defaultConfig } returns mockDefaultConfig

        every { mockCmakeOptions.path } returns fakeCmakeFile

        FlutterPluginUtils.forceNdkDownload(project, "ignored")

        verify(exactly = 1) {
            mockCmakeOptions.path
        }
        verify(exactly = 0) { mockCmakeOptions.setPath(any()) }
        verify { mockDefaultConfig wasNot called }
    }

    @Test
    fun `forceNdkDownload skips when project has a preprovisioned ndk property`() {
        val project = mockk<Project>()
        val mockCmakeOptions = mockk<CmakeOptions>()
        val mockDefaultConfig = mockk<DefaultConfig>()
        every {
            project.extensions
                .findByType(BaseExtension::class.java)!!
                .externalNativeBuild.cmake
        } returns mockCmakeOptions
        every { project.extensions.findByType(BaseExtension::class.java)!!.defaultConfig } returns mockDefaultConfig
        every { mockCmakeOptions.path } returns null
        every { project.findProperty(FlutterPluginUtils.PROP_PREPROVISIONED_NDK_VERSION) } returns "29.0.13846066"
        every { project.gradle.startParameter.taskNames } returns emptyList()
        every { project.extensions.findByType(ApplicationExtension::class.java) } returns mockk(relaxed = true)

        FlutterPluginUtils.forceNdkDownload(project, "/base/path")

        verify(exactly = 0) { mockCmakeOptions.path(any()) }
        verify { mockDefaultConfig wasNot called }
    }

    @Test
    fun `forceNdkDownload skips when invoking the ndk metadata task`() {
        val project = mockk<Project>()
        val mockCmakeOptions = mockk<CmakeOptions>()
        val mockDefaultConfig = mockk<DefaultConfig>()
        every {
            project.extensions
                .findByType(BaseExtension::class.java)!!
                .externalNativeBuild.cmake
        } returns mockCmakeOptions
        every { project.extensions.findByType(BaseExtension::class.java)!!.defaultConfig } returns mockDefaultConfig
        every { mockCmakeOptions.path } returns null
        every { project.findProperty(FlutterPluginUtils.PROP_PREPROVISIONED_NDK_VERSION) } returns null
        every { project.gradle.startParameter.taskNames } returns listOf(FlutterPluginUtils.TASK_PRINT_NDK_VERSION)
        every { project.extensions.findByType(ApplicationExtension::class.java) } returns mockk(relaxed = true)

        FlutterPluginUtils.forceNdkDownload(project, "/base/path")

        verify(exactly = 0) { mockCmakeOptions.path(any()) }
        verify { mockDefaultConfig wasNot called }
    }

    @Test
    fun `forceNdkDownload sets externalNativeBuild properties`() {
        val project = mockk<Project>()
        val mockCmakeOptions = mockk<CmakeOptions>()
        val mockDefaultConfig = mockk<DefaultConfig>()
        val mockDirectoryProperty = mockk<DirectoryProperty>()
        val mockDirectory = mockk<Directory>()
        every { project.extensions.findByType(ApplicationExtension::class.java) } returns null
        every {
            project.extensions
                .findByType(BaseExtension::class.java)!!
                .externalNativeBuild.cmake
        } returns mockCmakeOptions
        every { project.extensions.findByType(BaseExtension::class.java)!!.defaultConfig } returns mockDefaultConfig

        val basePath = "/base/path"
        val fakeBuildPath = "/randomapp/build/app/"
        every { mockCmakeOptions.path } returns null
        every { mockCmakeOptions.path(any()) } returns Unit
        every { mockCmakeOptions.buildStagingDirectory(any()) } returns Unit
        every { project.layout.buildDirectory } returns mockDirectoryProperty
        every { mockDirectoryProperty.dir(any<String>()) } returns mockDirectoryProperty
        every { mockDirectoryProperty.get() } returns mockDirectory
        every { mockDirectory.asFile.path } returns fakeBuildPath

        val mockBuildType = mockk<com.android.build.gradle.internal.dsl.BuildType>()
        every {
            project.extensions
                .findByType(BaseExtension::class.java)!!
                .buildTypes
                .iterator()
        } returns mutableListOf(mockBuildType).iterator()
        every { mockBuildType.name } returns "Debug"
        every { mockBuildType.externalNativeBuild.cmake.arguments(any(), any(), any()) } returns Unit

        FlutterPluginUtils.forceNdkDownload(project, basePath)

        verify(exactly = 1) {
            mockCmakeOptions.path
        }
        verify(exactly = 1) { mockCmakeOptions.path("$basePath/packages/flutter_tools/gradle/src/main/scripts/CMakeLists.txt") }
        verify(exactly = 1) { mockCmakeOptions.buildStagingDirectory(any()) }
        verify(exactly = 1) {
            mockBuildType.externalNativeBuild.cmake.arguments(
                "-Wno-dev",
                "--no-warn-unused-cli",
                "-DCMAKE_BUILD_TYPE=Debug"
            )
        }
    }

    @Test
    fun `addTaskForPrintNdkVersion adds task for printing ndk version`() {
        val project = mockk<Project>()
        val androidExtension = mockk<ApplicationExtension>()
        every { androidExtension.ndkVersion } returns "29.0.13846066"
        every { project.extensions.getByType(ApplicationExtension::class.java) } returns androidExtension
        every { project.tasks.register(any(), any<Action<Task>>()) } returns mockk()
        val captureSlot = slot<Action<Task>>()

        FlutterPluginUtils.addTaskForPrintNdkVersion(project)

        verify { project.tasks.register("printNdkVersion", capture(captureSlot)) }
        val mockTask = mockk<Task>()
        every { mockTask.description = any() } returns Unit
        every { mockTask.doLast(any<Action<Task>>()) } returns mockk()

        captureSlot.captured.execute(mockTask)

        verify {
            mockTask.description = "Prints out the configured ndkVersion for this Android project"
        }
    }

    // isFlutterAppProject skipped as it is a wrapper for a single getter that we would have to mock

    // addFlutterDependencies
    @Test
    fun `addFlutterDependencies returns early if buildMode is not supported`() {
        val project = mockk<Project>()
        every { project.extraProperties } returns mockk()
        every { project.extensions.findByType(FlutterExtension::class.java) } returns FlutterExtension()
        every { project.file(any()) } returns mockk()
        val pluginHandler = PluginHandler(project)
        mockkObject(NativePluginLoaderReflectionBridge)
        every { NativePluginLoaderReflectionBridge.getPlugins(any(), any()) } returns pluginListWithoutDevDependency
        val buildType: BuildType = mockk<BuildType>()
        every { buildType.name } returns "debug"
        every { buildType.isDebuggable } returns true
        every { project.hasProperty("local-engine-repo") } returns true
        every { project.hasProperty("local-engine-build-mode") } returns true
        every { project.property("local-engine-build-mode") } returns "release"
        every { project.logger.quiet(any()) } returns Unit

        FlutterPluginUtils.addFlutterDependencies(
            project = project,
            buildType = buildType,
            pluginHandler = pluginHandler,
            engineVersion = "1.0.0-e0676b47c7550ecdc0f0c4fa759201449b2c5f23"
        )

        verify(exactly = 1) {
            project.logger.quiet(
                "Project does not support Flutter build mode: debug, " +
                    "skipping adding Flutter dependencies"
            )
        }
    }

    @Test
    fun `addFlutterDependencies adds libflutter dependency but not embedding dependency when is a flutter app`() {
        val project = mockk<Project>()
        every { project.extraProperties } returns mockk()
        every { project.extensions.findByType(FlutterExtension::class.java) } returns FlutterExtension()
        every { project.file(any()) } returns mockk()
        val pluginHandler = PluginHandler(project)
        mockkObject(NativePluginLoaderReflectionBridge)
        every { NativePluginLoaderReflectionBridge.getPlugins(any(), any()) } returns pluginListWithoutDevDependency
        val buildType: BuildType = mockk<BuildType>()
        val engineVersion = EXAMPLE_ENGINE_VERSION
        every { buildType.name } returns "debug"
        every { buildType.isDebuggable } returns true
        every { project.hasProperty("local-engine-repo") } returns false
        every { project.extensions.findByType(ApplicationExtension::class.java) } returns mockk<ApplicationExtension>()
        every { project.hasProperty("target-platform") } returns false
        every { project.configurations.named("api") } returns mockk()
        every { project.dependencies.add(any(), any()) } returns mockk()

        FlutterPluginUtils.addFlutterDependencies(
            project = project,
            buildType = buildType,
            pluginHandler = pluginHandler,
            engineVersion = engineVersion
        )

        verify(exactly = 3) { project.dependencies.add(any(), any()) }
        verify {
            project.dependencies.add(
                "debugApi",
                "io.flutter:armeabi_v7a_debug:$engineVersion"
            )
        }
        verify { project.dependencies.add("debugApi", "io.flutter:arm64_v8a_debug:$engineVersion") }
        verify { project.dependencies.add("debugApi", "io.flutter:x86_64_debug:$engineVersion") }
    }

    @Test
    fun `addFlutterDependencies adds libflutter and embedding dep when only dep is dev dep in release mode`() {
        val project = mockk<Project>()
        val pluginListWithSingleDevDependency = listOf(devDependency)
        every { project.extraProperties } returns mockk()
        every { project.extensions.findByType(FlutterExtension::class.java) } returns FlutterExtension()
        every { project.file(any()) } returns mockk()
        val pluginHandler = PluginHandler(project)
        mockkObject(NativePluginLoaderReflectionBridge)
        every { NativePluginLoaderReflectionBridge.getPlugins(any(), any()) } returns pluginListWithSingleDevDependency
        val buildType: BuildType = mockk<BuildType>()
        val engineVersion = EXAMPLE_ENGINE_VERSION
        every { buildType.name } returns "release"
        every { buildType.isDebuggable } returns false
        every { project.hasProperty("local-engine-repo") } returns false
        every { project.extensions.findByType(ApplicationExtension::class.java) } returns mockk<ApplicationExtension>()
        every { project.hasProperty("target-platform") } returns false
        every { project.configurations.named("api") } returns mockk()
        every { project.dependencies.add(any(), any()) } returns mockk()

        FlutterPluginUtils.addFlutterDependencies(
            project = project,
            buildType = buildType,
            pluginHandler = pluginHandler,
            engineVersion = engineVersion
        )

        verify(exactly = 4) { project.dependencies.add(any(), any()) }
        verify {
            project.dependencies.add(
                "releaseApi",
                "io.flutter:flutter_embedding_release:$engineVersion"
            )
        }
        verify {
            project.dependencies.add(
                "releaseApi",
                "io.flutter:armeabi_v7a_release:$engineVersion"
            )
        }
        verify {
            project.dependencies.add(
                "releaseApi",
                "io.flutter:arm64_v8a_release:$engineVersion"
            )
        }
        verify {
            project.dependencies.add(
                "releaseApi",
                "io.flutter:x86_64_release:$engineVersion"
            )
        }
    }

    @Test
    fun `addFlutterDependencies adds libflutter dep but not embedding dep when only dep is dev dep in debug mode`() {
        val project = mockk<Project>()
        val pluginListWithSingleDevDependency = listOf(devDependency)
        every { project.extraProperties } returns mockk()
        every { project.extensions.findByType(FlutterExtension::class.java) } returns FlutterExtension()
        every { project.file(any()) } returns mockk()
        val pluginHandler = PluginHandler(project)
        mockkObject(NativePluginLoaderReflectionBridge)
        every { NativePluginLoaderReflectionBridge.getPlugins(any(), any()) } returns pluginListWithSingleDevDependency
        val buildType: BuildType = mockk<BuildType>()
        val engineVersion = EXAMPLE_ENGINE_VERSION
        every { buildType.name } returns "debug"
        every { buildType.isDebuggable } returns true
        every { project.hasProperty("local-engine-repo") } returns false
        every { project.extensions.findByType(ApplicationExtension::class.java) } returns mockk<ApplicationExtension>()
        every { project.hasProperty("target-platform") } returns false
        every { project.configurations.named("api") } returns mockk()
        every { project.dependencies.add(any(), any()) } returns mockk()

        FlutterPluginUtils.addFlutterDependencies(
            project = project,
            buildType = buildType,
            pluginHandler = pluginHandler,
            engineVersion = engineVersion
        )

        verify(exactly = 3) { project.dependencies.add(any(), any()) }
        verify {
            project.dependencies.add(
                "debugApi",
                "io.flutter:armeabi_v7a_debug:$engineVersion"
            )
        }
        verify {
            project.dependencies.add(
                "debugApi",
                "io.flutter:arm64_v8a_debug:$engineVersion"
            )
        }
        verify {
            project.dependencies.add(
                "debugApi",
                "io.flutter:x86_64_debug:$engineVersion"
            )
        }
    }

    // addTaskForJavaVersion
    @Test
    fun `addTaskForJavaVersion adds task for Java version`() {
        val project = mockk<Project>()
        every { project.tasks.register(any(), any<Action<Task>>()) } returns mockk()
        val captureSlot = slot<Action<Task>>()
        FlutterPluginUtils.addTaskForJavaVersion(project)
        verify { project.tasks.register("javaVersion", capture(captureSlot)) }

        val mockTask = mockk<Task>()
        every { mockTask.description = any() } returns Unit
        every { mockTask.doLast(any<Action<Task>>()) } returns mockk()
        captureSlot.captured.execute(mockTask)
        verify {
            mockTask.description = "Print the current java version used by gradle. see: " +
                "https://docs.gradle.org/current/javadoc/org/gradle/api/JavaVersion.html"
        }
    }

    // addTaskForKGPVersion
    @Test
    fun `addTaskForKGPVersion adds task for KGP version`() {
        val project = mockk<Project>()
        every { project.tasks.register(any(), any<Action<Task>>()) } returns mockk()
        val captureSlot = slot<Action<Task>>()
        FlutterPluginUtils.addTaskForKGPVersion(project)
        verify { project.tasks.register("kgpVersion", capture(captureSlot)) }

        val mockTask = mockk<Task>()
        every { mockTask.description = any() } returns Unit
        every { mockTask.doLast(any<Action<Task>>()) } returns mockk()
        captureSlot.captured.execute(mockTask)
        verify {
            mockTask.description = "Print the current kgp version used by the project."
        }
    }

    // addTaskForPrintBuildVariants
    @Test
    fun `addTaskForPrintBuildVariants adds task for printing build variants`() {
        val project = mockk<Project>()
        val androidComponents = mockk<AndroidComponentsExtension<*, *, *>>(relaxed = true)
        val listProperty = mockk<org.gradle.api.provider.ListProperty<String>>()
        every { project.extensions.getByType(AndroidComponentsExtension::class.java) } returns androidComponents
        every { project.objects.listProperty(String::class.java) } returns listProperty
        every { project.tasks.register(any(), any<Action<Task>>()) } returns mockk()
        val captureSlot = slot<Action<Task>>()

        FlutterPluginUtils.addTaskForPrintBuildVariants(project)

        verify { project.tasks.register("printBuildVariants", capture(captureSlot)) }
        val mockTask = mockk<Task>()
        every { mockTask.description = any() } returns Unit
        every { mockTask.doLast(any<Action<Task>>()) } returns mockk()

        captureSlot.captured.execute(mockTask)

        verify {
            mockTask.description = "Prints out all build variants for this Android project"
        }
    }
}

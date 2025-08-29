// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.gradle.AbstractAppExtension
import com.android.build.gradle.BaseExtension
import com.android.build.gradle.internal.dsl.CmakeOptions
import com.android.build.gradle.internal.dsl.DefaultConfig
import com.android.builder.model.BuildType
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
import org.gradle.api.logging.Logger
import org.jetbrains.kotlin.gradle.plugin.extraProperties
import org.junit.jupiter.api.assertThrows
import org.junit.jupiter.api.io.TempDir
import java.io.File
import java.nio.file.Path
import java.util.Properties
import kotlin.io.path.createDirectory
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertEquals

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
    fun `forceNdkDownload sets externalNativeBuild properties`() {
        val project = mockk<Project>()
        val mockCmakeOptions = mockk<CmakeOptions>()
        val mockDefaultConfig = mockk<DefaultConfig>()
        val mockDirectoryProperty = mockk<DirectoryProperty>()
        val mockDirectory = mockk<Directory>()
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
        every { project.extensions.findByType(AbstractAppExtension::class.java) } returns mockk<AbstractAppExtension>()
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
        every { project.extensions.findByType(AbstractAppExtension::class.java) } returns mockk<AbstractAppExtension>()
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
        every { project.extensions.findByType(AbstractAppExtension::class.java) } returns mockk<AbstractAppExtension>()
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
        every { project.extensions.getByType(AbstractAppExtension::class.java) } returns mockk()
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

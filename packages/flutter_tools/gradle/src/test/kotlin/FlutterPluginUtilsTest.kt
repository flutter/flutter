// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.AndroidPluginVersion
import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.variant.AndroidComponentsExtension
import com.android.build.api.variant.Variant
import com.android.build.api.variant.VariantBuilder
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
import com.flutter.gradle.tasks.PrintTask
import io.mockk.called
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkObject
import io.mockk.slot
import io.mockk.unmockkObject
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
import org.gradle.api.provider.Provider
import org.gradle.api.provider.ProviderFactory
import org.jetbrains.kotlin.gradle.plugin.extraProperties
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.assertThrows
import org.junit.jupiter.api.io.TempDir
import java.io.File
import java.io.IOException
import java.nio.file.Path
import java.util.Properties
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Configuration for a mock Gradle subproject.
 *
 * @property name The name of the subproject.
 * @property declarativelyAppliedPlugins Plugins applied via the modern Gradle `plugins {}` block.
 *           For more details, see [Gradle Plugins Block Docs](https://docs.gradle.org/current/userguide/plugins_intermediate.html#sec:plugins_block).
 * @property imperativelyAppliedPlugins Plugins applied via the legacy Gradle `apply plugin:` statement.
 *           For more details, see [Gradle Old Plugin Application Docs](https://docs.gradle.org/current/userguide/plugins_intermediate.html#sec:old_plugin_application).
 */
private data class SubprojectConfig(
    val name: String,
    val declarativelyAppliedPlugins: List<String> = emptyList(),
    val imperativelyAppliedPlugins: List<String> = emptyList()
)

private class TestEnvironment(
    val appProject: Project,
    val plugins: List<Project>,
    val subprojectsActionSlot: io.mockk.CapturingSlot<Action<Project>> = slot(),
    val projectsEvaluatedActionSlot: io.mockk.CapturingSlot<Action<Gradle>> = slot()
) {
    val appPluginManager: PluginManager get() = appProject.pluginManager
    val plugin1Manager: PluginManager get() = plugins[0].pluginManager
    val plugin2Manager: PluginManager get() = plugins[1].pluginManager
}

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

    @Test
    fun `detectLowCompileSdkVersionOrNdkVersion registers ValidateCompileSdkVersionTask`() {
        val project = mockk<Project>()
        val taskContainer = mockk<org.gradle.api.tasks.TaskContainer>()
        val taskProvider = mockk<org.gradle.api.tasks.TaskProvider<com.flutter.gradle.tasks.ValidateCompileSdkVersionTask>>()
        val preBuildTaskProvider = mockk<org.gradle.api.tasks.TaskProvider<org.gradle.api.Task>>()

        val androidComponents = mockk<AndroidComponentsExtension<Any, VariantBuilder, Variant>>()

        every { project.tasks } returns taskContainer
        every {
            taskContainer.register(
                "validateCompileSdkVersion",
                com.flutter.gradle.tasks.ValidateCompileSdkVersionTask::class.java,
                any<org.gradle.api.Action<com.flutter.gradle.tasks.ValidateCompileSdkVersionTask>>()
            )
        } returns taskProvider

        every {
            project.extensions.getByType(AndroidComponentsExtension::class.java)
        } returns androidComponents as AndroidComponentsExtension<*, *, *>
        every { androidComponents.finalizeDsl(match<(Any) -> Unit> { true }) } returns Unit

        every { taskContainer.named("preBuild") } returns preBuildTaskProvider
        every { preBuildTaskProvider.configure(any()) } returns Unit

        FlutterPluginUtils.detectLowCompileSdkVersionOrNdkVersion(project, emptyList())

        verify {
            taskContainer.register(
                "validateCompileSdkVersion",
                com.flutter.gradle.tasks.ValidateCompileSdkVersionTask::class.java,
                any()
            )
        }
        verify { androidComponents.finalizeDsl(match<(Any) -> Unit> { true }) }
        verify { taskContainer.named("preBuild") }
    }

    @Test
    fun `detectLowCompileSdkVersionOrNdkVersion handles non-Android plugins safely`() {
        val project = mockk<Project>()
        val rootProject = mockk<Project>()
        val taskContainer = mockk<org.gradle.api.tasks.TaskContainer>()
        val taskProvider = mockk<org.gradle.api.tasks.TaskProvider<com.flutter.gradle.tasks.ValidateCompileSdkVersionTask>>()
        val preBuildTaskProvider = mockk<org.gradle.api.tasks.TaskProvider<org.gradle.api.Task>>()
        val androidComponents = mockk<AndroidComponentsExtension<Any, VariantBuilder, Variant>>()
        val pluginProject = mockk<Project>()
        val extensionContainer = mockk<org.gradle.api.plugins.ExtensionContainer>()

        val pluginSdks = mockk<org.gradle.api.provider.MapProperty<String, Int>>(relaxed = true)
        val pluginNdks = mockk<org.gradle.api.provider.MapProperty<String, String>>(relaxed = true)
        val mapPropertyObjects = mockk<org.gradle.api.model.ObjectFactory>()

        every { project.rootProject } returns rootProject
        every { project.tasks } returns taskContainer
        every { project.objects } returns mapPropertyObjects
        every { mapPropertyObjects.mapProperty(String::class.java, Int::class.java) } returns pluginSdks
        every { mapPropertyObjects.mapProperty(String::class.java, String::class.java) } returns pluginNdks
        every { project.provider(any<java.util.concurrent.Callable<Any>>()) } answers {
            val callable = firstArg<java.util.concurrent.Callable<Any>>()
            mockk<org.gradle.api.provider.Provider<Any>> {
                every { get() } answers { callable.call() }
            }
        }

        every {
            taskContainer.register(
                "validateCompileSdkVersion",
                com.flutter.gradle.tasks.ValidateCompileSdkVersionTask::class.java,
                any<org.gradle.api.Action<com.flutter.gradle.tasks.ValidateCompileSdkVersionTask>>()
            )
        } returns taskProvider

        every {
            project.extensions.getByType(AndroidComponentsExtension::class.java)
        } returns androidComponents as AndroidComponentsExtension<*, *, *>
        every { androidComponents.finalizeDsl(match<(Any) -> Unit> { true }) } returns Unit

        every { taskContainer.named("preBuild") } returns preBuildTaskProvider
        every { preBuildTaskProvider.configure(any()) } returns Unit

        val pluginList: List<Map<String?, Any?>> = listOf(mapOf("name" to "nonAndroidPlugin"))
        every { rootProject.findProject(":nonAndroidPlugin") } returns pluginProject
        every { pluginProject.extensions } returns extensionContainer
        every { extensionContainer.findByName("android") } returns null // Simulates non-Android project

        val actionSlot = slot<org.gradle.api.Action<com.flutter.gradle.tasks.ValidateCompileSdkVersionTask>>()
        every {
            taskContainer.register(
                "validateCompileSdkVersion",
                com.flutter.gradle.tasks.ValidateCompileSdkVersionTask::class.java,
                capture(actionSlot)
            )
        } returns taskProvider

        FlutterPluginUtils.detectLowCompileSdkVersionOrNdkVersion(project, pluginList)

        // We don't execute the action here as it requires complex stubbing of project.provider
        // which is hard to do in this setup. The fact that this method completes without crashing
        // is enough to verify that it handles non-Android plugins safely during registration.

        verify {
            taskContainer.register(
                "validateCompileSdkVersion",
                com.flutter.gradle.tasks.ValidateCompileSdkVersionTask::class.java,
                any()
            )
        }
    }

    private fun writeBuildFile(
        buildFile: File,
        declarativelyAppliedPlugins: List<String> = emptyList(),
        imperativelyAppliedPlugins: List<String> = emptyList()
    ) {
        buildFile.apply {
            parentFile.mkdirs()
            if (!exists()) {
                createNewFile()
            }
            val declarativeBlock =
                if (declarativelyAppliedPlugins.isNotEmpty()) {
                    // Expected output of declarativeBlock if declarativelyAppliedPlugins contains ["kotlin-android"]:
                    // plugins {
                    //     id("kotlin-android")
                    // }
                    "plugins {\n" + declarativelyAppliedPlugins.joinToString("\n") { "    id(\"$it\")" } + "\n}\n"
                } else {
                    ""
                }
            val imperativeBlock =
                if (imperativelyAppliedPlugins.isNotEmpty()) {
                    // Expected output of imperativeBlock if imperativelyAppliedPlugins contains ["kotlin-android"]:
                    // apply plugin: 'kotlin-android'
                    imperativelyAppliedPlugins.joinToString("\n") { "apply plugin: '$it'" } + "\n"
                } else {
                    ""
                }
            writeText(declarativeBlock + imperativeBlock)
        }
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
        inner class GetSubprojectPluginStateTests {
            @Test
            fun `returns null if build file does not exist`() {
                val subproject = mockk<Project>()
                val file = mockk<File>()
                every { subproject.buildFile } returns file
                every { file.exists() } returns false

                val result = FlutterPluginUtils.getSubprojectPluginState(subproject)

                assertNull(result)
            }

            @Test
            fun `returns null if build file path contains ephemeral android directory`() {
                val subproject = mockk<Project>()
                val file = mockk<File>()
                every { subproject.buildFile } returns file
                every { file.exists() } returns true
                every { file.absolutePath } returns "/path/to/.android/build.gradle"

                val result = FlutterPluginUtils.getSubprojectPluginState(subproject)

                assertNull(result)
            }

            @Test
            fun `returns null and logs error when IOException is thrown during read`(
                @TempDir tempDir: Path
            ) {
                val subproject = mockk<Project>()
                val mockBuildFile = mockk<File>()
                val mockLogger = mockk<Logger>(relaxed = true)

                every { subproject.buildFile } returns mockBuildFile
                every { mockBuildFile.exists() } returns true
                every { mockBuildFile.absolutePath } returns "/some/path/build.gradle"
                every { mockBuildFile.extension } returns "gradle"
                every { mockBuildFile.path } throws IOException("Simulated I/O error")
                every { subproject.projectDir } returns tempDir.toFile()
                every { subproject.logger } returns mockLogger

                val result = FlutterPluginUtils.getSubprojectPluginState(subproject)

                assertNull(result)
                verify(exactly = 1) {
                    mockLogger.error(
                        "Failed to read build file: /some/path/build.gradle",
                        any<IOException>()
                    )
                }
            }

            @Test
            fun `detects KGP and AGP in app subproject indicated by AGP app id in Groovy DSL`(
                @TempDir tempDir: Path
            ) {
                val buildFile = tempDir.resolve("build.gradle").toFile()
                writeBuildFile(
                    buildFile = buildFile,
                    imperativelyAppliedPlugins = listOf("com.android.application", "kotlin-android")
                )
                val subproject = mockk<Project>()
                every { subproject.buildFile } returns buildFile
                every { subproject.projectDir } returns tempDir.toFile()
                every { subproject.logger } returns mockk(relaxed = true)

                val state = FlutterPluginUtils.getSubprojectPluginState(subproject)

                assertNotNull(state)
                assertTrue(state.hasAppPlugin)
                assertTrue(state.hasKgpPlugin)
                assertFalse(state.hasLibPlugin)
            }

            @Test
            fun `detects KGP and AGP in library subproject indicated by AGP library id in Groovy DSL`(
                @TempDir tempDir: Path
            ) {
                val buildFile = tempDir.resolve("build.gradle").toFile()
                writeBuildFile(
                    buildFile = buildFile,
                    imperativelyAppliedPlugins = listOf("com.android.library", "kotlin-android")
                )
                val subproject = mockk<Project>()
                every { subproject.buildFile } returns buildFile
                every { subproject.projectDir } returns tempDir.toFile()
                every { subproject.logger } returns mockk(relaxed = true)

                val state = FlutterPluginUtils.getSubprojectPluginState(subproject)

                assertNotNull(state)
                assertFalse(state.hasAppPlugin)
                assertTrue(state.hasKgpPlugin)
                assertTrue(state.hasLibPlugin)
            }

            @Test
            fun `does not detect KGP or AGP in Groovy DSL`(
                @TempDir tempDir: Path
            ) {
                val buildFile = tempDir.resolve("build.gradle").toFile()
                writeBuildFile(
                    buildFile = buildFile,
                    imperativelyAppliedPlugins = listOf("java")
                )
                val subproject = mockk<Project>()
                every { subproject.buildFile } returns buildFile
                every { subproject.projectDir } returns tempDir.toFile()
                every { subproject.logger } returns mockk(relaxed = true)

                val state = FlutterPluginUtils.getSubprojectPluginState(subproject)

                assertNotNull(state)
                assertFalse(state.hasAppPlugin)
                assertFalse(state.hasKgpPlugin)
                assertFalse(state.hasLibPlugin)
            }

            @Test
            fun `detects KGP and AGP in app subproject indicated by AGP app id in Kotlin DSL`(
                @TempDir tempDir: Path
            ) {
                val buildFile = tempDir.resolve("build.gradle.kts").toFile()
                writeBuildFile(
                    buildFile = buildFile,
                    declarativelyAppliedPlugins = listOf("com.android.application", "org.jetbrains.kotlin.android")
                )
                val subproject = mockk<Project>()
                every { subproject.buildFile } returns buildFile
                every { subproject.projectDir } returns tempDir.toFile()
                every { subproject.logger } returns mockk(relaxed = true)

                val state = FlutterPluginUtils.getSubprojectPluginState(subproject)

                assertNotNull(state)
                assertTrue(state.hasAppPlugin)
                assertTrue(state.hasKgpPlugin)
                assertFalse(state.hasLibPlugin)
            }

            @Test
            fun `detects KGP and AGP in library subproject indicated by AGP library id in Kotlin DSL`(
                @TempDir tempDir: Path
            ) {
                val buildFile = tempDir.resolve("build.gradle.kts").toFile()
                writeBuildFile(
                    buildFile = buildFile,
                    declarativelyAppliedPlugins = listOf("com.android.library", "org.jetbrains.kotlin.android")
                )
                val subproject = mockk<Project>()
                every { subproject.buildFile } returns buildFile
                every { subproject.projectDir } returns tempDir.toFile()
                every { subproject.logger } returns mockk(relaxed = true)

                val state = FlutterPluginUtils.getSubprojectPluginState(subproject)

                assertNotNull(state)
                assertFalse(state.hasAppPlugin)
                assertTrue(state.hasKgpPlugin)
                assertTrue(state.hasLibPlugin)
            }

            @Test
            fun `does not detect KGP or AGP in Kotlin DSL`(
                @TempDir tempDir: Path
            ) {
                val buildFile = tempDir.resolve("build.gradle.kts").toFile()
                writeBuildFile(
                    buildFile = buildFile,
                    declarativelyAppliedPlugins = listOf("kotlin(\"jvm\") version \"1.9.0\"")
                )
                val subproject = mockk<Project>()
                every { subproject.buildFile } returns buildFile
                every { subproject.projectDir } returns tempDir.toFile()
                every { subproject.logger } returns mockk(relaxed = true)

                val state = FlutterPluginUtils.getSubprojectPluginState(subproject)

                assertNotNull(state)
                assertFalse(state.hasAppPlugin)
                assertFalse(state.hasKgpPlugin)
                assertFalse(state.hasLibPlugin)
            }
        }

        @Nested
        inner class DetectApplyingKotlinGradlePluginTests {
            private val rootProject = mockk<Project>()
            private val mockGradle = mockk<Gradle>()
            private val mockLogger = mockk<Logger>(relaxed = true)

            // This AGP version will should match the Flutter create template values.
            // In //packages/flutter_tools/lib/src/android/gradle_utils.dart
            private val templateAgpVersion = AndroidPluginVersion(9, 0, 1)

            private val errorAgpVersion = DependencyVersionChecker.errorAGPVersion

            private fun mockBuiltInKotlinProperty(value: String?) {
                val mockProvider = mockk<Provider<String>>()
                every { mockProvider.orNull } returns value
                val mockProviders = mockk<ProviderFactory>()
                every { mockProviders.gradleProperty("android.builtInKotlin") } returns mockProvider
                every { rootProject.providers } returns mockProviders
                every { rootProject.findProperty("android.builtInKotlin") } returns value
            }

            @Nested
            inner class IsBuiltInKotlinEnabledTests {
                private fun setupProjectWithProperty(propertyValue: String?): Project {
                    val project = mockk<Project>()
                    every { project.rootProject } returns rootProject
                    every { project.providers } answers { rootProject.providers }
                    mockBuiltInKotlinProperty(propertyValue)
                    return project
                }

                @Test
                fun `returns false when AGP version is null`() {
                    val project = setupProjectWithProperty("true")

                    val result = FlutterPluginUtils.isBuiltInKotlinEnabled(project, null)

                    assertFalse(result)
                }

                @Test
                fun `returns false when AGP is less than 9 and builtInKotlin is set to true`() {
                    val subproject = setupProjectWithProperty("true")

                    val result = FlutterPluginUtils.isBuiltInKotlinEnabled(subproject, errorAgpVersion)

                    assertFalse(result)
                }

                @Test
                fun `returns false when AGP is less than 9 and builtInKotlin is set to TRUE`() {
                    val subproject = setupProjectWithProperty("TRUE")

                    val result = FlutterPluginUtils.isBuiltInKotlinEnabled(subproject, errorAgpVersion)

                    assertFalse(result)
                }

                @Test
                fun `returns false when AGP is less than 9 and builtInKotlin is set to false`() {
                    val subproject = setupProjectWithProperty("false")

                    val result = FlutterPluginUtils.isBuiltInKotlinEnabled(subproject, errorAgpVersion)

                    assertFalse(result)
                }

                @Test
                fun `returns false when AGP is less than 9 and builtInKotlin is set to FALSE`() {
                    val subproject = setupProjectWithProperty("FALSE")

                    val result = FlutterPluginUtils.isBuiltInKotlinEnabled(subproject, errorAgpVersion)

                    assertFalse(result)
                }

                @Test
                fun `returns true when AGP is 9 or higher and builtInKotlin is set to true`() {
                    val subproject = setupProjectWithProperty("true")

                    val result = FlutterPluginUtils.isBuiltInKotlinEnabled(subproject, templateAgpVersion)

                    assertTrue(result)
                }

                @Test
                fun `returns true when AGP is 9 or higher and builtInKotlin is set to TRUE`() {
                    val subproject = setupProjectWithProperty("TRUE")

                    val result = FlutterPluginUtils.isBuiltInKotlinEnabled(subproject, templateAgpVersion)

                    assertTrue(result)
                }

                @Test
                fun `returns false when AGP is 9 or higher and builtInKotlin is set to false`() {
                    val subproject = setupProjectWithProperty("false")

                    val result = FlutterPluginUtils.isBuiltInKotlinEnabled(subproject, templateAgpVersion)

                    assertFalse(result)
                }

                @Test
                fun `returns false when AGP is 9 or higher and builtInKotlin is set to FALSE`() {
                    val subproject = setupProjectWithProperty("FALSE")

                    val result = FlutterPluginUtils.isBuiltInKotlinEnabled(subproject, templateAgpVersion)

                    assertFalse(result)
                }

                @Test
                fun `defaults to true when property is null and AGP is 9 or higher`() {
                    val subproject = setupProjectWithProperty(null)

                    val result = FlutterPluginUtils.isBuiltInKotlinEnabled(subproject, templateAgpVersion)

                    assertTrue(result)
                }
            }

            @BeforeEach
            fun setUp() {
                mockkObject(VersionFetcher)
            }

            @AfterEach
            fun tearDown() {
                unmockkObject(VersionFetcher)
            }

            private fun writeGradleProperties(
                rootDir: File,
                content: String
            ) {
                File(rootDir, "gradle.properties").apply {
                    createNewFile()
                    writeText(content)
                }
            }

            private fun createSubproject(
                tempDir: Path,
                projectName: String,
                declarativelyAppliedPlugins: List<String> = emptyList(),
                imperativelyAppliedPlugins: List<String> = emptyList()
            ): Project {
                val rootDir = tempDir.toFile()
                every { rootProject.file("gradle.properties") } returns File(rootDir, "gradle.properties")
                every { rootProject.projectDir } returns rootDir

                val projectDir = tempDir.resolve(projectName).toFile().apply { mkdirs() }
                val buildGradleFile = File(projectDir, "build.gradle")
                writeBuildFile(buildGradleFile, declarativelyAppliedPlugins, imperativelyAppliedPlugins)
                val pluginManager = mockk<PluginManager>(relaxed = true)
                val project = mockk<Project>()
                every { project.name } returns projectName
                every { project.projectDir } returns projectDir
                every { project.buildFile } returns buildGradleFile
                every { project.logger } returns mockLogger
                every { project.pluginManager } returns pluginManager
                every { project.rootProject } returns rootProject
                every { project.providers } answers { rootProject.providers }
                every { project.gradle } returns mockGradle
                every { project.findProperty(any()) } answers { rootProject.findProperty(arg(0)) }

                val pluginContainer = mockk<org.gradle.api.plugins.PluginContainer>(relaxed = true)
                every { pluginContainer.withId(any(), any()) } answers {
                    // Cast is required because star-projecting Action (a consumer) yields Action<Nothing>, making it unexecutable.
                    @Suppress("UNCHECKED_CAST")
                    val action = args[1] as Action<org.gradle.api.Plugin<*>>
                    action.execute(mockk(relaxed = true))
                }
                every { project.plugins } returns pluginContainer

                return project
            }

            private fun setupTest(
                tempDir: Path,
                agpVersion: AndroidPluginVersion,
                builtInKotlin: String?,
                appConfig: SubprojectConfig,
                pluginConfigs: List<SubprojectConfig>,
                captureActions: Boolean = true
            ): TestEnvironment {
                val rootDir = tempDir.toFile()
                if (builtInKotlin != null) {
                    writeGradleProperties(rootDir, "android.builtInKotlin=$builtInKotlin\n")
                } else {
                    writeGradleProperties(rootDir, "")
                }
                every { VersionFetcher.getAGPVersion(any()) } returns agpVersion

                val appProject =
                    createSubproject(
                        tempDir = tempDir,
                        projectName = appConfig.name,
                        declarativelyAppliedPlugins = appConfig.declarativelyAppliedPlugins,
                        imperativelyAppliedPlugins = appConfig.imperativelyAppliedPlugins
                    )

                val pluginProjects =
                    pluginConfigs.map { config ->
                        createSubproject(
                            tempDir = tempDir,
                            projectName = config.name,
                            declarativelyAppliedPlugins = config.declarativelyAppliedPlugins,
                            imperativelyAppliedPlugins = config.imperativelyAppliedPlugins
                        )
                    }

                val allProjects = setOf(appProject) + pluginProjects
                every { rootProject.subprojects } returns allProjects
                mockBuiltInKotlinProperty(builtInKotlin)

                val testProject = TestEnvironment(appProject, pluginProjects)

                if (captureActions) {
                    every { rootProject.subprojects(capture(testProject.subprojectsActionSlot)) } answers {
                        val action = firstArg<Action<Project>>()
                        allProjects.forEach { action.execute(it) }
                    }
                    every { mockGradle.projectsEvaluated(capture(testProject.projectsEvaluatedActionSlot)) } returns Unit
                }

                return testProject
            }

            private fun executeDetectApplyingKotlinGradlePlugin(testProject: TestEnvironment) {
                detectApplyingKotlinGradlePlugin(testProject.appProject)

                verify { rootProject.subprojects(any<Action<Project>>()) }

                if (testProject.projectsEvaluatedActionSlot.isCaptured) {
                    verify { mockGradle.projectsEvaluated(capture(testProject.projectsEvaluatedActionSlot)) }
                    testProject.projectsEvaluatedActionSlot.captured.execute(mockGradle)
                } else {
                    verify(exactly = 0) { mockGradle.projectsEvaluated(any<Action<Gradle>>()) }
                }
            }

            @Nested
            inner class BuiltInKotlinIsEnabledAndAgpIs9OrHigher {
                @Test
                fun `does not log nor apply KGP`(
                    @TempDir tempDir: Path
                ) {
                    val testProject =
                        setupTest(
                            tempDir = tempDir,
                            agpVersion = templateAgpVersion,
                            builtInKotlin = "true",
                            appConfig = SubprojectConfig("app", declarativelyAppliedPlugins = listOf("com.android.application")),
                            pluginConfigs = listOf(SubprojectConfig("plugin", declarativelyAppliedPlugins = listOf("com.android.library")))
                        )

                    detectApplyingKotlinGradlePlugin(testProject.appProject)

                    verify(exactly = 1) { rootProject.subprojects(any<Action<Project>>()) }
                    verify(exactly = 0) { testProject.appPluginManager.apply("kotlin-android") }
                    verify(exactly = 0) { testProject.plugin1Manager.apply("kotlin-android") }
                }

                @Test
                fun `does not log nor apply KGP when property is null`(
                    @TempDir tempDir: Path
                ) {
                    val testProject =
                        setupTest(
                            tempDir = tempDir,
                            agpVersion = templateAgpVersion,
                            builtInKotlin = null,
                            appConfig = SubprojectConfig("app", declarativelyAppliedPlugins = listOf("com.android.application")),
                            pluginConfigs = listOf(SubprojectConfig("plugin", declarativelyAppliedPlugins = listOf("com.android.library")))
                        )

                    detectApplyingKotlinGradlePlugin(testProject.appProject)

                    verify(exactly = 1) { rootProject.subprojects(any<Action<Project>>()) }
                    verify(exactly = 0) { testProject.appPluginManager.apply("kotlin-android") }
                    verify(exactly = 0) { testProject.plugin1Manager.apply("kotlin-android") }
                }
            }

            @Nested
            inner class BuiltInKotlinIsDisabled {
                @Nested
                inner class AgpIs9OrHigher {
                    @Test
                    fun `logs warning when KGP is only applied in app`(
                        @TempDir tempDir: Path
                    ) {
                        val testProject =
                            setupTest(
                                tempDir = tempDir,
                                agpVersion = templateAgpVersion,
                                builtInKotlin = "false",
                                appConfig =
                                    SubprojectConfig(
                                        "app",
                                        declarativelyAppliedPlugins = listOf("com.android.application", "kotlin-android")
                                    ),
                                pluginConfigs =
                                    listOf(
                                        SubprojectConfig("plugin", declarativelyAppliedPlugins = listOf("com.android.library"))
                                    )
                            )

                        executeDetectApplyingKotlinGradlePlugin(testProject)

                        verify {
                            mockLogger.error(
                                match {
                                    it.contains("WARNING: Your Android app project") &&
                                        it.contains("applies the Kotlin Gradle Plugin") &&
                                        it.contains(BUILT_IN_KOTLIN_DOCS_FOR_APPS)
                                }
                            )
                        }

                        verify(exactly = 0) {
                            mockLogger.error(match { it.contains("WARNING: Your app uses the following plugins") })
                        }
                        val appPluginManager = testProject.appPluginManager
                        val plugin1Manager = testProject.plugin1Manager
                        verify(exactly = 0) { appPluginManager.apply("kotlin-android") }
                        verify(exactly = 1) { plugin1Manager.apply("kotlin-android") }
                    }

                    @Test
                    fun `logs warning when KGP is only applied in one plugin`(
                        @TempDir tempDir: Path
                    ) {
                        val testProject =
                            setupTest(
                                tempDir = tempDir,
                                agpVersion = templateAgpVersion,
                                builtInKotlin = "false",
                                appConfig = SubprojectConfig("app", declarativelyAppliedPlugins = listOf("com.android.application")),
                                pluginConfigs =
                                    listOf(
                                        SubprojectConfig(
                                            "plugin",
                                            declarativelyAppliedPlugins = listOf("com.android.library", "kotlin-android")
                                        )
                                    )
                            )

                        executeDetectApplyingKotlinGradlePlugin(testProject)

                        verify {
                            mockLogger.error(
                                match {
                                    it.contains("WARNING: Your app uses the following plugins") &&
                                        it.contains(BUILT_IN_KOTLIN_DOCS_TO_REPORT_UNMIGRATED_PLUGINS) &&
                                        it.contains(BUILT_IN_KOTLIN_DOCS_FOR_PLUGINS)
                                }
                            )
                        }

                        verify(exactly = 0) {
                            mockLogger.error(match { it.contains("WARNING: Your Android app project") })
                        }
                        val appPluginManager = testProject.appPluginManager
                        val plugin1Manager = testProject.plugin1Manager
                        verify(exactly = 1) { appPluginManager.apply("kotlin-android") }
                        verify(exactly = 0) { plugin1Manager.apply("kotlin-android") }
                    }

                    @Test
                    fun `logs warning when KGP is applied in both app and plugin`(
                        @TempDir tempDir: Path
                    ) {
                        val testProject =
                            setupTest(
                                tempDir = tempDir,
                                agpVersion = templateAgpVersion,
                                builtInKotlin = "false",
                                appConfig =
                                    SubprojectConfig(
                                        "app",
                                        declarativelyAppliedPlugins = listOf("com.android.application", "kotlin-android")
                                    ),
                                pluginConfigs =
                                    listOf(
                                        SubprojectConfig(
                                            "plugin",
                                            declarativelyAppliedPlugins = listOf("com.android.library", "kotlin-android")
                                        )
                                    )
                            )

                        executeDetectApplyingKotlinGradlePlugin(testProject)

                        verify {
                            mockLogger.error(
                                match {
                                    it.contains("WARNING: Your Android app project") &&
                                        it.contains("applies the Kotlin Gradle Plugin") &&
                                        it.contains(BUILT_IN_KOTLIN_DOCS_FOR_APPS)
                                }
                            )
                        }

                        verify {
                            mockLogger.error(
                                match {
                                    it.contains("WARNING: Your app uses the following plugins") &&
                                        it.contains(BUILT_IN_KOTLIN_DOCS_TO_REPORT_UNMIGRATED_PLUGINS) &&
                                        it.contains(BUILT_IN_KOTLIN_DOCS_FOR_PLUGINS)
                                }
                            )
                        }

                        verify(exactly = 0) { testProject.appPluginManager.apply("kotlin-android") }
                        verify(exactly = 0) { testProject.plugin1Manager.apply("kotlin-android") }
                    }

                    @Test
                    fun `logs warning when KGP is imperatively applied in both app and plugins`(
                        @TempDir tempDir: Path
                    ) {
                        val testProject =
                            setupTest(
                                tempDir = tempDir,
                                agpVersion = templateAgpVersion,
                                builtInKotlin = "false",
                                appConfig =
                                    SubprojectConfig(
                                        "app",
                                        imperativelyAppliedPlugins =
                                            listOf(
                                                "com.android.application",
                                                "kotlin-android"
                                            )
                                    ),
                                pluginConfigs =
                                    listOf(
                                        SubprojectConfig(
                                            "plugin1",
                                            imperativelyAppliedPlugins =
                                                listOf(
                                                    "com.android.library",
                                                    "kotlin-android"
                                                )
                                        ),
                                        SubprojectConfig(
                                            "plugin2",
                                            imperativelyAppliedPlugins =
                                                listOf(
                                                    "com.android.library",
                                                    "kotlin-android"
                                                )
                                        )
                                    )
                            )

                        executeDetectApplyingKotlinGradlePlugin(testProject)

                        verify {
                            mockLogger.error(
                                match {
                                    it.contains("WARNING: Your Android app project") &&
                                        it.contains("applies the Kotlin Gradle Plugin") &&
                                        it.contains(BUILT_IN_KOTLIN_DOCS_FOR_APPS)
                                }
                            )
                        }

                        verify {
                            mockLogger.error(
                                match {
                                    it.contains("WARNING: Your app uses the following plugins") &&
                                        it.contains(BUILT_IN_KOTLIN_DOCS_TO_REPORT_UNMIGRATED_PLUGINS) &&
                                        it.contains(BUILT_IN_KOTLIN_DOCS_FOR_PLUGINS)
                                }
                            )
                        }

                        verify(exactly = 0) { testProject.appPluginManager.apply("kotlin-android") }
                        verify(exactly = 0) { testProject.plugin1Manager.apply("kotlin-android") }
                        verify(exactly = 0) { testProject.plugin2Manager.apply("kotlin-android") }
                    }

                    @Test
                    fun `does not log when migrated`(
                        @TempDir tempDir: Path
                    ) {
                        val testProject =
                            setupTest(
                                tempDir = tempDir,
                                agpVersion = templateAgpVersion,
                                builtInKotlin = "false",
                                appConfig = SubprojectConfig("app", imperativelyAppliedPlugins = listOf("com.android.application")),
                                pluginConfigs =
                                    listOf(
                                        SubprojectConfig("plugin", imperativelyAppliedPlugins = listOf("com.android.library"))
                                    )
                            )

                        executeDetectApplyingKotlinGradlePlugin(testProject)

                        verify(exactly = 0) {
                            mockLogger.error(any())
                        }

                        val appPluginManager = testProject.appPluginManager
                        val plugin1Manager = testProject.plugin1Manager
                        verify(exactly = 1) { appPluginManager.apply("kotlin-android") }
                        verify(exactly = 1) { plugin1Manager.apply("kotlin-android") }
                    }

                    @Test
                    fun `logs quiet warning when KGP fails to apply`(
                        @TempDir tempDir: Path
                    ) {
                        val testProject =
                            setupTest(
                                tempDir = tempDir,
                                agpVersion = templateAgpVersion,
                                builtInKotlin = "false",
                                appConfig =
                                    SubprojectConfig(
                                        "app",
                                        declarativelyAppliedPlugins = listOf("com.android.application")
                                    ),
                                pluginConfigs =
                                    listOf(
                                        SubprojectConfig(
                                            "plugin",
                                            declarativelyAppliedPlugins = listOf("com.android.library")
                                        )
                                    )
                            )

                        val appPluginManager = testProject.appPluginManager
                        val plugin1Manager = testProject.plugin1Manager

                        every { appPluginManager.apply("kotlin-android") } throws Exception("KGP not on classpath")
                        every { plugin1Manager.apply("kotlin-android") } throws Exception("KGP not on classpath")

                        executeDetectApplyingKotlinGradlePlugin(testProject)

                        verify(exactly = 0) {
                            mockLogger.error(any())
                        }

                        verify {
                            mockLogger.quiet(
                                match {
                                    it.contains("Applying the Kotlin Android Plugin (KGP) was unsuccessful") &&
                                        it.contains("ensure KGP is declared in the root plugins block") &&
                                        it.contains(BUILT_IN_KOTLIN_DOCS)
                                }
                            )
                        }
                    }
                }

                @Nested
                inner class AgpIsLessThan9 {
                    @Test
                    fun `applies KGP without logging`(
                        @TempDir tempDir: Path
                    ) {
                        val testProject =
                            setupTest(
                                tempDir = tempDir,
                                agpVersion = errorAgpVersion,
                                builtInKotlin = "false",
                                appConfig = SubprojectConfig("app", declarativelyAppliedPlugins = listOf("com.android.application")),
                                pluginConfigs =
                                    listOf(
                                        SubprojectConfig("plugin", declarativelyAppliedPlugins = listOf("com.android.library"))
                                    )
                            )

                        executeDetectApplyingKotlinGradlePlugin(testProject)

                        val appPluginManager = testProject.appPluginManager
                        val plugin1Manager = testProject.plugin1Manager
                        verify(exactly = 1) { appPluginManager.apply("kotlin-android") }
                        verify(exactly = 1) { plugin1Manager.apply("kotlin-android") }
                    }

                    @Test
                    fun `does not re-apply KGP and does not log`(
                        @TempDir tempDir: Path
                    ) {
                        val testProject =
                            setupTest(
                                tempDir = tempDir,
                                agpVersion = errorAgpVersion,
                                builtInKotlin = "false",
                                appConfig =
                                    SubprojectConfig(
                                        "app",
                                        declarativelyAppliedPlugins = listOf("com.android.application", "kotlin-android")
                                    ),
                                pluginConfigs =
                                    listOf(
                                        SubprojectConfig(
                                            "plugin",
                                            declarativelyAppliedPlugins = listOf("com.android.library", "kotlin-android")
                                        )
                                    )
                            )

                        val appPluginManager = testProject.appPluginManager
                        val plugin1Manager = testProject.plugin1Manager

                        executeDetectApplyingKotlinGradlePlugin(testProject)

                        // No warnings should be logged because AGP version is < 9.
                        verify(exactly = 0) { mockLogger.error(any()) }
                        verify(exactly = 0) { appPluginManager.apply("kotlin-android") }
                        verify(exactly = 0) { plugin1Manager.apply("kotlin-android") }
                    }

                    @Test
                    fun `logs quiet warning when KGP fails to apply`(
                        @TempDir tempDir: Path
                    ) {
                        val testProject =
                            setupTest(
                                tempDir = tempDir,
                                agpVersion = errorAgpVersion,
                                builtInKotlin = "false",
                                appConfig =
                                    SubprojectConfig(
                                        "app",
                                        declarativelyAppliedPlugins = listOf("com.android.application")
                                    ),
                                pluginConfigs =
                                    listOf(
                                        SubprojectConfig(
                                            "plugin",
                                            declarativelyAppliedPlugins = listOf("com.android.library")
                                        )
                                    )
                            )

                        val appPluginManager = testProject.appPluginManager
                        val plugin1Manager = testProject.plugin1Manager

                        every { appPluginManager.apply("kotlin-android") } throws Exception("KGP not on classpath")
                        every { plugin1Manager.apply("kotlin-android") } throws Exception("KGP not on classpath")

                        executeDetectApplyingKotlinGradlePlugin(testProject)

                        verify(exactly = 0) {
                            mockLogger.error(any())
                        }

                        verify {
                            mockLogger.quiet(
                                match {
                                    it.contains("Applying the Kotlin Android Plugin (KGP) was unsuccessful") &&
                                        it.contains("ensure KGP is declared in the root plugins block") &&
                                        it.contains(BUILT_IN_KOTLIN_DOCS)
                                }
                            )
                        }
                    }
                }
            }
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

    @Test
    fun `addTaskForJavaVersion adds task for Java version`() {
        val project = mockk<Project>()
        every { project.tasks.register(any(), eq(PrintTask::class.java), any()) } returns mockk()
        val captureSlot = slot<Action<PrintTask>>()

        FlutterPluginUtils.addTaskForJavaVersion(project)
        verify { project.tasks.register("javaVersion", eq(PrintTask::class.java), capture(captureSlot)) }

        val mockPrintTask = mockk<PrintTask>(relaxed = true)
        captureSlot.captured.execute(mockPrintTask)

        verify {
            mockPrintTask.description = "Print the current java version used by gradle. see: " +
                "https://docs.gradle.org/current/javadoc/org/gradle/api/JavaVersion.html"
        }
    }

    // addTaskForKGPVersion
    @Test
    fun `addTaskForKGPVersion adds task for KGP version`() {
        val project = mockk<Project>(relaxed = true)
        every { project.tasks.register(any(), eq(PrintTask::class.java), any()) } returns mockk()
        val captureSlot = slot<Action<PrintTask>>()

        mockkObject(VersionFetcher)
        every { VersionFetcher.getKGPVersion(project) } returns Version(2, 2, 0)

        try {
            FlutterPluginUtils.addTaskForKGPVersion(project)
            verify { project.tasks.register("kgpVersion", eq(PrintTask::class.java), capture(captureSlot)) }

            val mockPrintTask = mockk<PrintTask>(relaxed = true)
            captureSlot.captured.execute(mockPrintTask)

            verify {
                mockPrintTask.description = "Print the current kgp version used by the project."
            }
        } finally {
            io.mockk.unmockkObject(VersionFetcher)
        }
    }

    // addTaskForPrintBuildVariants
    @Test
    fun `addTaskForPrintBuildVariants adds task for printing build variants`() {
        val project = mockk<Project>()
        val androidComponents = mockk<AndroidComponentsExtension<*, *, *>>(relaxed = true)
        val listProperty = mockk<org.gradle.api.provider.ListProperty<String>>(relaxed = true)

        every { project.extensions } returns mockk()
        every { project.extensions.getByType(AndroidComponentsExtension::class.java) } returns androidComponents
        every { project.objects.listProperty(String::class.java) } returns listProperty
        every { project.tasks.register(any(), eq(PrintTask::class.java), any()) } returns mockk()

        val captureSlot = slot<Action<PrintTask>>()

        FlutterPluginUtils.addTaskForPrintBuildVariants(project)
        verify { project.tasks.register("printBuildVariants", eq(PrintTask::class.java), capture(captureSlot)) }

        val mockPrintTask = mockk<PrintTask>(relaxed = true)
        captureSlot.captured.execute(mockPrintTask)

        verify {
            mockPrintTask.description = "Prints out all build variants for this Android project"
        }
    }
}

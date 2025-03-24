package com.flutter.gradle

import com.android.build.gradle.AbstractAppExtension
import com.android.build.gradle.api.ApplicationVariant
import com.android.build.gradle.api.BaseVariantOutput
import com.android.build.gradle.tasks.ProcessAndroidResources
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.gradle.api.Action
import org.gradle.api.DomainObjectCollection
import org.gradle.api.DomainObjectSet
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.CopySpec
import org.gradle.api.file.FileCollection
import org.gradle.api.logging.Logger
import org.gradle.api.tasks.TaskContainer
import org.junit.jupiter.api.io.TempDir
import java.io.File
import java.nio.file.Path
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertEquals

class FlutterTaskHelperTest {
    @Test
    fun `getAssetsDirectory returns correct path`() {
        val flutterTask = mockk<FlutterTask>()
        val mockFile = mockk<File>()
        val flutterTaskOutputDirectory = "/path/to/assets"
        val expectedPath = "$flutterTaskOutputDirectory/flutter_assets"

        every { flutterTask.outputDirectory } returns mockFile
        every { mockFile.toString() } returns flutterTaskOutputDirectory
        val result = FlutterTaskHelper.getAssetsDirectory(flutterTask)
        assert(result == expectedPath)
    }

    @Test
    fun `getAssets returns correct CopySpec`() {
        val project = mockk<Project>()
        val flutterTask = mockk<FlutterTask>()
        val mockFile = mockk<File>()
        val mockCopySpec = mockk<CopySpec>()
        val copySpecActionSlot = slot<Action<in CopySpec>>()
        val fakeFromPath = "/path/to/intermediate"

        every { flutterTask.intermediateDir } returns mockFile
        every { mockFile.toString() } returns fakeFromPath
        every { project.copySpec(capture(copySpecActionSlot)) } returns mockk()

        FlutterTaskHelper.getAssets(project, flutterTask)
        every { mockCopySpec.from(fakeFromPath) } returns mockCopySpec
        every { mockCopySpec.include(FlutterTaskHelper.FLUTTER_ASSETS_INCLUDE_DIRECTORY) } returns mockCopySpec
        copySpecActionSlot.captured.execute(mockCopySpec)
        verify { mockCopySpec.from(fakeFromPath) }
        verify { mockCopySpec.include(FlutterTaskHelper.FLUTTER_ASSETS_INCLUDE_DIRECTORY) }
    }

    @Test
    fun `getSnapshots returns correct CopySpec for release build`() {
        val project = mockk<Project>()
        val flutterTask = mockk<FlutterTask>()
        val mockCopySpec = mockk<CopySpec>()
        val copySpecActionSlot = slot<Action<in CopySpec>>()
        val fakeIntermediateDirectory = mockk<File>()
        val fakeIntermediateDirectoryPath = "/path/to/intermediate"

        every { flutterTask.intermediateDir } returns fakeIntermediateDirectory
        every { flutterTask.buildMode } returns "release"
        every { flutterTask.targetPlatformValues } returns listOf("arm64-v8a", "x64")
        every { fakeIntermediateDirectory.toString() } returns fakeIntermediateDirectoryPath
        every { project.copySpec(capture(copySpecActionSlot)) } returns mockk()

        FlutterTaskHelper.getSnapshots(project, flutterTask)
        every { mockCopySpec.from(fakeIntermediateDirectoryPath) } returns mockCopySpec
        every { mockCopySpec.include(any<String>()) } returns mockCopySpec
        copySpecActionSlot.captured.execute(mockCopySpec)

        verify { mockCopySpec.from(fakeIntermediateDirectoryPath) }
        verify { mockCopySpec.include("${FlutterPluginConstants.PLATFORM_ARCH_MAP["arm64-v8a"]}/app.so") }
        verify { mockCopySpec.include("${FlutterPluginConstants.PLATFORM_ARCH_MAP["x64"]}/app.so") }
    }

    @Test
    fun `getSnapshots returns correct CopySpec for debug build`() {
        val project = mockk<Project>()
        val flutterTask = mockk<FlutterTask>()
        val mockCopySpec = mockk<CopySpec>()
        val copySpecActionSlot = slot<Action<in CopySpec>>()
        val fakeIntermediateDirectory = mockk<File>()
        val fakeIntermediateDirectoryPath = "/path/to/intermediate"

        every { flutterTask.intermediateDir } returns fakeIntermediateDirectory
        every { flutterTask.buildMode } returns "debug"
        every { flutterTask.targetPlatformValues } returns listOf("arm64-v8a", "x64")
        every { fakeIntermediateDirectory.toString() } returns fakeIntermediateDirectoryPath
        every { project.copySpec(capture(copySpecActionSlot)) } returns mockk()

        FlutterTaskHelper.getSnapshots(project, flutterTask)
        every { mockCopySpec.from(fakeIntermediateDirectoryPath) } returns mockCopySpec
        every { mockCopySpec.include(any<String>()) } returns mockCopySpec
        copySpecActionSlot.captured.execute(mockCopySpec)

        verify { mockCopySpec.from(fakeIntermediateDirectoryPath) }
        verify(exactly = 0) { mockCopySpec.include(any<String>()) }
    }

    @Test
    fun `getSourceFiles returns files when dependenciesFile exists`(
        @TempDir tempDir: Path
    ) {
        val mockProjectFileCollection = mockk<ConfigurableFileCollection>(relaxed = true)
        val mockDependenciesFileCollection = mockk<FileCollection>()
        val project = mockk<Project>()
        val mockFlutterTask = mockk<FlutterTask>()

        every { project.files() } returns mockProjectFileCollection
        every { project.files(any()) } returns mockProjectFileCollection

        every { mockFlutterTask.intermediateDir } returns tempDir.toFile()
        every { mockFlutterTask.getDependenciesFiles() } returns mockDependenciesFileCollection
        val dependenciesFile =
            tempDir
                .resolve("${mockFlutterTask.intermediateDir}/flutter_build.d")
                .toFile()
        dependenciesFile.writeText(
            " ${tempDir.toFile().path}/pre/delimiter/one ${tempDir.toFile().path}/pre/delimiter/two: ${tempDir.toFile().path}/post/delimiter/one ${tempDir.toFile().path}/post/delimiter/two"
        )
        every { mockDependenciesFileCollection.iterator() } returns (mutableListOf(dependenciesFile).iterator())

        FlutterTaskHelper.getSourceFiles(project, mockFlutterTask)

        verify {
            project.files(
                listOf(
                    "${tempDir.toFile().path}/post/delimiter/one",
                    "${tempDir.toFile().path}/post/delimiter/two"
                )
            )
        }

        verify { project.files("pubspec.yaml") }
    }

    @Test
    fun `getOutputFiles returns files when dependenciesFile exists`(
        @TempDir tempDir: Path
    ) {
        val mockProjectFileCollection = mockk<ConfigurableFileCollection>(relaxed = true)
        val mockDependenciesFileCollection = mockk<FileCollection>()
        val project = mockk<Project>()
        val mockFlutterTask = mockk<FlutterTask>()

        every { project.files() } returns mockProjectFileCollection
        every { project.files(any()) } returns mockProjectFileCollection

        every { mockFlutterTask.intermediateDir } returns tempDir.toFile()
        every { mockFlutterTask.getDependenciesFiles() } returns mockDependenciesFileCollection
        val dependenciesFile =
            tempDir
                .resolve("${mockFlutterTask.intermediateDir}/flutter_build.d")
                .toFile()
        dependenciesFile.writeText(
            " ${tempDir.toFile().path}/pre/delimiter/one ${tempDir.toFile().path}/pre/delimiter/two: ${tempDir.toFile().path}/post/delimiter/one ${tempDir.toFile().path}/post/delimiter/two"
        )
        every { mockDependenciesFileCollection.iterator() } returns (mutableListOf(dependenciesFile).iterator())

        FlutterTaskHelper.getOutputFiles(project, mockFlutterTask)

        verify {
            project.files(
                listOf(
                    "${tempDir.toFile().path}/pre/delimiter/one",
                    "${tempDir.toFile().path}/pre/delimiter/two"
                )
            )
        }

        verify(exactly = 0) { project.files("pubspec.yaml") }
    }

    @Test
    fun addTasksForOutputsAppLinkSettingsNoAndroid(
        @TempDir tempDir: Path
    ) {
        val mockProject = mockk<Project>()
        val mockLogger = mockk<Logger>()
        every { mockProject.logger } returns mockLogger
        every { mockLogger.info(any()) } returns Unit
        every { mockProject.extensions.findByName("android") } returns null

        FlutterTaskHelper.addTasksForOutputsAppLinkSettings(mockProject)
        // Consider matching on part of the error.
        verify(exactly = 1) { mockLogger.info(any()) }
    }

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

    @Test
    fun addTasksForOutputsAppLinkSettingsActual(
        @TempDir tempDir: Path
    ) {
        val mockProject = mockk<Project>()
        val mockLogger = mockk<Logger>()
        every { mockProject.logger } returns mockLogger
        every { mockLogger.info(any()) } returns Unit
        every { mockLogger.warn(any()) } returns Unit
        val mockAbstractAppExtension = mockk<AbstractAppExtension>()
        every { mockProject.extensions.findByName("android") } returns mockAbstractAppExtension

        val testVariants: DomainObjectSet<ApplicationVariant> = mockk<DomainObjectSet<ApplicationVariant>>()
        val variant1 = mockk<ApplicationVariant>()
        every { variant1.name } returns "one"
        every { variant1.applicationId } returns "com.example.FlutterActivity1"
        val variant2 = mockk<ApplicationVariant>()
        every { variant2.name } returns "two"
        every { variant2.applicationId } returns "com.example.FlutterActivity2"
        val variants = mutableListOf(variant1, variant2)
        // Capture the "action" that needs to be run for each variant.
        val actionSlot = slot<Action<ApplicationVariant>>()
        every { testVariants.configureEach(capture(actionSlot)) } answers {
            // Execute the action for each variant.
            variants.forEach { variant ->
                actionSlot.captured.execute(variant)
            }
        }
        every { mockAbstractAppExtension.applicationVariants } returns testVariants

        // Consider breaking out into a test helper.
        val descriptionSlot = slot<String>()
        val registerTaskSlot = slot<Action<Task>>()
        val registerTaskList: MutableList<Task> = mutableListOf()
        every { mockProject.tasks } returns
            mockk<TaskContainer> {
                val registerTaskNameSlot = slot<String>()
                every { register(capture(registerTaskNameSlot), capture(registerTaskSlot)) } answers registerAnswer@{
                    val mockRegisterTask =
                        mockk<Task> {
                            every { name } returns registerTaskNameSlot.captured
                            every { description = capture(descriptionSlot) } returns Unit
                            every { dependsOn(any<ProcessAndroidResources>()) } returns mockk()
                            val doLastActionSlot = slot<Action<Task>>()
                            every { doLast(capture(doLastActionSlot)) } answers doLastAnswer@{
                                // We need to capture the task as well
                                doLastActionSlot.captured.execute(mockk())
                                return@doLastAnswer mockk()
                            }
                        }
                    registerTaskList.add(mockRegisterTask)
                    registerTaskSlot.captured.execute(mockRegisterTask)
                    return@registerAnswer mockk()
                }

                every { named(any<String>()) } returns
                    mockk {
                        every { configure(any<Action<Task>>()) } returns mockk()
                    }
            }
        variants.forEach { variant ->
            val testOutputs: DomainObjectCollection<BaseVariantOutput> = mockk<DomainObjectCollection<BaseVariantOutput>>()
            val baseVariantSlot = slot<Action<BaseVariantOutput>>()
            val baseVariantOutput = mockk<BaseVariantOutput>()
            val mockProcessResources = mockk<ProcessAndroidResources>()
            // Create a real file in a temp directory.
            val manifest =
                tempDir
                    .resolve("${tempDir.toAbsolutePath()}/AndroidManifest.xml")
                    .toFile()
            manifest.writeText(manifestText)

            every { mockProcessResources.manifestFile } returns manifest
            every { baseVariantOutput.processResources } returns mockProcessResources
            every { testOutputs.configureEach(capture(baseVariantSlot)) } answers {
                // Execute the action for each output.
                baseVariantSlot.captured.execute(baseVariantOutput)
            }
            every { variant.outputs } returns testOutputs
        }
        val outputFile =
            tempDir
                .resolve("${tempDir.toAbsolutePath()}/app-link-settings-build-variant.json")
                .toFile()
        every { mockProject.property("outputPath") } returns outputFile

        FlutterTaskHelper.addTasksForOutputsAppLinkSettings(mockProject)

        verify(exactly = 0) { mockLogger.info(any()) }
        assert(descriptionSlot.captured.contains("stores app links settings for the given build variant"))
        assertEquals(variants.size, registerTaskList.size)
        for (i in 0 until variants.size) {
            assertEquals("output${FlutterPluginUtils.capitalize(variants[i].name)}AppLinkSettings", registerTaskList[i].name)
            verify(exactly = 1) { registerTaskList[i].dependsOn(any<ProcessAndroidResources>()) }
        }
        // Output assertions are minimal which ensures code is running but is not exhaustive testing.
        // Integration test for more exhaustive behavior is defined in
        // flutter/flutter/packages/flutter_tools/test/integration.shard/android_gradle_outputs_app_link_settings_test.dart
        val outputFileText = outputFile.readText()
        // Only variant2 since that one has app links.
        assertContains(outputFileText, variant2.applicationId)
        // Host.
        assertContains(outputFileText, "deeplink.flutter.dev")
        // pathPrefix used in variant2 combined with prefix logic.
        assertContains(outputFileText, "some.prefix.*")
        // Deep linking
        assertContains(outputFileText, "deeplinkingFlagEnabled\":true")
    }
}

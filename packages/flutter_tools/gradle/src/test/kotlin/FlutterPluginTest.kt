package com.flutter.gradle

import com.android.build.api.dsl.ApplicationDefaultConfig
import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.variant.AndroidComponentsExtension
import com.android.build.gradle.AbstractAppExtension
import com.android.build.gradle.BaseExtension
import com.android.build.gradle.api.AndroidSourceDirectorySet
import com.android.build.gradle.internal.core.InternalBaseVariant
import com.android.build.gradle.tasks.MergeSourceSetFolders
import com.android.build.gradle.tasks.ProcessAndroidResources
import com.flutter.gradle.tasks.FlutterTask
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkObject
import io.mockk.slot
import io.mockk.verify
import org.gradle.api.Action
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.api.file.Directory
import org.gradle.api.tasks.Copy
import org.gradle.api.tasks.TaskContainer
import org.gradle.api.tasks.TaskProvider
import org.jetbrains.kotlin.gradle.plugin.extraProperties
import org.junit.jupiter.api.Assertions.fail
import org.junit.jupiter.api.io.TempDir
import java.nio.file.Path
import kotlin.io.path.writeText
import kotlin.test.Test

class FlutterPluginTest {
    @Test
    fun `FlutterPlugin apply() adds expected tasks`(
        @TempDir tempDir: Path
    ) {
        val projectDir = tempDir.resolve("project-dir").resolve("android").resolve("app")
        projectDir.toFile().mkdirs()
        val settingsFile = projectDir.parent.resolve("settings.gradle")
        settingsFile.writeText("empty for now")
        val fakeFlutterSdkDir = tempDir.resolve("fake-flutter-sdk")
        fakeFlutterSdkDir.toFile().mkdirs()
        val fakeCacheDir = fakeFlutterSdkDir.resolve("bin").resolve("cache")
        fakeCacheDir.toFile().mkdirs()
        val fakeEngineStampFile = fakeCacheDir.resolve("engine.stamp")
        fakeEngineStampFile.writeText(FAKE_ENGINE_STAMP)
        val fakeEngineRealmFile = fakeCacheDir.resolve("engine.realm")
        fakeEngineRealmFile.writeText(FAKE_ENGINE_REALM)
        val project = mockk<Project>(relaxed = true)
        val mockAbstractAppExtension = mockk<AbstractAppExtension>(relaxed = true)
        every { project.extensions.findByType(AbstractAppExtension::class.java) } returns mockAbstractAppExtension
        val mockAndroidComponentsExtension = mockk<AndroidComponentsExtension<*, *, *>>(relaxed = true)
        every { project.extensions.getByType(AndroidComponentsExtension::class.java) } returns mockAndroidComponentsExtension
        every { mockAndroidComponentsExtension.selector() } returns
            mockk {
                every { all() } returns mockk()
            }
        every { project.extensions.getByType(AbstractAppExtension::class.java) } returns mockAbstractAppExtension
        every { project.extensions.findByName("android") } returns mockAbstractAppExtension
        every { project.projectDir } returns projectDir.toFile()
        every { project.findProperty("flutter.sdk") } returns fakeFlutterSdkDir.toString()
        every { project.file(fakeFlutterSdkDir.toString()) } returns fakeFlutterSdkDir.toFile()
        val flutterExtension = FlutterExtension()
        every { project.extensions.create("flutter", any<Class<*>>()) } returns flutterExtension
        every { project.extensions.findByType(FlutterExtension::class.java) } returns flutterExtension
        val mockBaseExtension = mockk<BaseExtension>(relaxed = true)
        every { project.extensions.findByType(BaseExtension::class.java) } returns mockBaseExtension
        val mockApplicationExtension = mockk<ApplicationExtension>(relaxed = true)
        every { project.extensions.findByType(ApplicationExtension::class.java) } returns mockApplicationExtension
        val mockApplicationDefaultConfig = mockk<ApplicationDefaultConfig>(relaxed = true)
        every { mockApplicationExtension.defaultConfig } returns mockApplicationDefaultConfig
        every { project.rootProject } returns project
        every { project.state.failure } returns null
        val mockDirectory = mockk<Directory>(relaxed = true)
        every { project.layout.buildDirectory.get() } returns mockDirectory
        val mockAndroidSourceSet = mockk<com.android.build.gradle.api.AndroidSourceSet>(relaxed = true)
        val mockAndroidSourceDirectorySet = mockk<AndroidSourceDirectorySet>(relaxed = true)
        every { mockAndroidSourceSet.jniLibs.srcDir(any()) } returns mockAndroidSourceDirectorySet
        every { mockAbstractAppExtension.sourceSets.getByName("main") } returns mockAndroidSourceSet
        // mock return of NativePluginLoaderReflectionBridge.getPlugins
        mockkObject(NativePluginLoaderReflectionBridge)
        every { NativePluginLoaderReflectionBridge.getPlugins(any(), any()) } returns
            listOf()
        // mock method calls that are invoked by the args to NativePluginLoaderReflectionBridge
        every { project.extraProperties } returns mockk()
        every { project.file(flutterExtension.source!!) } returns mockk()
        val flutterPlugin = FlutterPlugin()
        flutterPlugin.apply(project)

        verify { project.tasks.register("generateLockfiles", any()) }
        verify { project.tasks.register("javaVersion", any()) }
        verify { project.tasks.register("printBuildVariants", any()) }
    }

    @Test
    fun `copyFlutterAssets task sets filePermissions correctly`(
        @TempDir tempDir: Path
    ) {
        val projectDir = tempDir.resolve("project-dir").resolve("android").resolve("app")
        projectDir.toFile().mkdirs()
        val settingsFile = projectDir.parent.resolve("settings.gradle")
        settingsFile.writeText("empty for now")
        val fakeFlutterSdkDir = tempDir.resolve("fake-flutter-sdk")
        fakeFlutterSdkDir.toFile().mkdirs()
        val fakeCacheDir = fakeFlutterSdkDir.resolve("bin").resolve("cache")
        fakeCacheDir.toFile().mkdirs()
        val fakeEngineStampFile = fakeCacheDir.resolve("engine.stamp")
        fakeEngineStampFile.writeText(FAKE_ENGINE_STAMP)
        val fakeEngineRealmFile = fakeCacheDir.resolve("engine.realm")
        fakeEngineRealmFile.writeText(FAKE_ENGINE_REALM)
        val project = mockk<Project>(relaxed = true)
        val mockAbstractAppExtension = mockk<AbstractAppExtension>(relaxed = true)
        every { project.extensions.findByType(AbstractAppExtension::class.java) } returns mockAbstractAppExtension
        every { project.extensions.getByType(AbstractAppExtension::class.java) } returns mockAbstractAppExtension
        every { project.extensions.findByName("android") } returns mockAbstractAppExtension
        val mockAndroidComponentsExtension = mockk<AndroidComponentsExtension<*, *, *>>(relaxed = true)
        every { project.extensions.getByType(AndroidComponentsExtension::class.java) } returns mockAndroidComponentsExtension
        every { mockAndroidComponentsExtension.selector() } returns
            mockk {
                every { all() } returns mockk()
            }
        every { project.projectDir } returns projectDir.toFile()
        every { project.findProperty("flutter.sdk") } returns fakeFlutterSdkDir.toString()
        every { project.file(fakeFlutterSdkDir.toString()) } returns fakeFlutterSdkDir.toFile()
        val flutterExtension = FlutterExtension()
        every { project.extensions.create("flutter", any<Class<*>>()) } returns flutterExtension
        every { project.extensions.findByType(FlutterExtension::class.java) } returns flutterExtension
        val mockBaseExtension = mockk<BaseExtension>(relaxed = true)
        every { project.extensions.findByType(BaseExtension::class.java) } returns mockBaseExtension
        val mockApplicationExtension = mockk<ApplicationExtension>(relaxed = true)
        every { project.extensions.findByType(ApplicationExtension::class.java) } returns mockApplicationExtension
        val mockApplicationDefaultConfig = mockk<ApplicationDefaultConfig>(relaxed = true)
        every { mockApplicationExtension.defaultConfig } returns mockApplicationDefaultConfig
        every { project.rootProject } returns project
        every { project.state.failure } returns null
        val mockDirectory = mockk<Directory>(relaxed = true)
        every { project.layout.buildDirectory.get() } returns mockDirectory
        val mockAndroidSourceSet = mockk<com.android.build.gradle.api.AndroidSourceSet>(relaxed = true)
        val mockAndroidSourceDirectorySet = mockk<AndroidSourceDirectorySet>(relaxed = true)
        every { mockAndroidSourceSet.jniLibs.srcDir(any()) } returns mockAndroidSourceDirectorySet
        every { mockAbstractAppExtension.sourceSets.getByName("main") } returns mockAndroidSourceSet
        // mock return of NativePluginLoaderReflectionBridge.getPlugins
        mockkObject(NativePluginLoaderReflectionBridge)
        every { NativePluginLoaderReflectionBridge.getPlugins(any(), any()) } returns
            listOf()
        // mock method calls that are invoked by the args to NativePluginLoaderReflectionBridge
        every { project.extraProperties } returns mockk()
        every { project.file(flutterExtension.source!!) } returns mockk()
        // Set up the task container and our task capture
        val taskContainer = mockk<TaskContainer>(relaxed = true)
        every { project.tasks } returns taskContainer
        val copyTaskActionCaptor = slot<Action<Copy>>()
        val copyTask = mockk<Copy>(relaxed = true)
        val mockVariant = mockk<com.android.build.gradle.api.ApplicationVariant>(relaxed = true)
        every { mockVariant.name } returns "debug"
        every { mockVariant.buildType.name } returns "debug"
        every { mockVariant.flavorName } returns ""
        val mergedFlavor = mockk<InternalBaseVariant.MergedFlavor>(relaxed = true)
        every { mockVariant.mergedFlavor } returns mergedFlavor
        val apiLevel = mockk<com.android.builder.model.ApiVersion>(relaxed = true)
        every { apiLevel.apiLevel } returns 21
        every { mergedFlavor.minSdkVersion } returns apiLevel
        val variantOutput = mockk<com.android.build.gradle.api.BaseVariantOutput>(relaxed = true)
        val outputsIterator = mockk<MutableIterator<com.android.build.gradle.api.BaseVariantOutput>>()
        every { outputsIterator.hasNext() } returns true andThen false
        every { outputsIterator.next() } returns variantOutput
        val variantOutputCollection = mockk<org.gradle.api.DomainObjectCollection<com.android.build.gradle.api.BaseVariantOutput>>()
        every { variantOutputCollection.iterator() } returns outputsIterator
        every { mockVariant.outputs } returns variantOutputCollection
        val processResourcesProvider = mockk<TaskProvider<ProcessAndroidResources>>(relaxed = true)
        every { processResourcesProvider.hint(ProcessAndroidResources::class).get() } returns mockk<ProcessAndroidResources>(relaxed = true)
        every { variantOutput.processResourcesProvider } returns processResourcesProvider
        val assembleTask = mockk<Task>(relaxed = true)
        val assembleTaskProvider = mockk<TaskProvider<Task>>(relaxed = true)
        every { assembleTaskProvider.get() } returns assembleTask
        every { mockVariant.assembleProvider } returns assembleTaskProvider
        val variants = listOf(mockVariant)
        val variantsIterator = mockk<MutableIterator<com.android.build.gradle.api.ApplicationVariant>>()
        every { variantsIterator.hasNext() } returns true andThen false
        every { variantsIterator.next() } returns mockVariant
        val variantCollection = mockk<org.gradle.api.DomainObjectSet<com.android.build.gradle.api.ApplicationVariant>>()
        every { mockAbstractAppExtension.applicationVariants } returns variantCollection
        every { variantCollection.iterator() } returns variantsIterator
        every {
            variantCollection.configureEach(any<Action<com.android.build.gradle.api.ApplicationVariant>>())
        } answers {
            variants.forEach { firstArg<Action<com.android.build.gradle.api.ApplicationVariant>>().execute(it) }
        }
        every { mockVariant.mergeAssetsProvider.hint(MergeSourceSetFolders::class).get() } returns
            mockk<MergeSourceSetFolders>(relaxed = true)
        val flutterTask = mockk<FlutterTask>(relaxed = true)
        val copySpec = mockk<org.gradle.api.file.CopySpec>(relaxed = true)
        every {
            (flutterTask).assets
        } returns copySpec
        val flutterTaskProvider = mockk<TaskProvider<FlutterTask>>(relaxed = true)
        every {
            flutterTaskProvider.hint(FlutterTask::class).get()
        } returns flutterTask
        every {
            taskContainer.register(
                match { it.contains("compileFlutterBuild") },
                any<Class<FlutterTask>>(),
                any()
            )
        } answers {
            flutterTaskProvider
        }
        // Actual task that should be captured to test if permissions have been set
        val mockCopyTaskProvider = mockk<TaskProvider<Copy>>(relaxed = true)
        every { mockCopyTaskProvider.hint(Copy::class).get() } returns copyTask
        every {
            taskContainer.register(
                match { it.startsWith("copyFlutterAssets") },
                eq(Copy::class.java),
                capture(copyTaskActionCaptor)
            )
        } answers {
            mockCopyTaskProvider
        }
        val mockJarTaskProvider = mockk<TaskProvider<org.gradle.api.tasks.bundling.Jar>>(relaxed = true)
        every { mockJarTaskProvider.hint(org.gradle.api.tasks.bundling.Jar::class).get() } returns
            mockk<org.gradle.api.tasks.bundling.Jar>(relaxed = true)
        every {
            taskContainer.register(
                match { it.contains("packJniLibs") },
                eq(org.gradle.api.tasks.bundling.Jar::class.java),
                any()
            )
        } answers {
            mockJarTaskProvider
        }
        val mockTaskProvider = mockk<TaskProvider<Task>>(relaxed = true)
        every { mockTaskProvider.hint(Task::class).get() } returns mockk<Task>(relaxed = true)
        every {
            taskContainer.named(any<String>())
        } returns mockTaskProvider
        val flutterPlugin = FlutterPlugin()
        flutterPlugin.apply(project)

        copyTaskActionCaptor.captured.execute(copyTask)
        val filePermissionsActionCaptor = slot<Action<org.gradle.api.file.ConfigurableFilePermissions>>()
        verify {
            copyTask.filePermissions(capture(filePermissionsActionCaptor))
        }
        if (filePermissionsActionCaptor.isCaptured) {
            val mockFilePermissionSet = mockk<org.gradle.api.file.ConfigurableFilePermissions>(relaxed = true)
            filePermissionsActionCaptor.captured.execute(mockFilePermissionSet)
            val userPermissionsActionCaptor = slot<Action<org.gradle.api.file.ConfigurableUserClassFilePermissions>>()
            verify {
                mockFilePermissionSet.user(capture(userPermissionsActionCaptor))
            }
            if (userPermissionsActionCaptor.isCaptured) {
                val mockUserPermission = mockk<org.gradle.api.file.ConfigurableUserClassFilePermissions>(relaxed = true)
                userPermissionsActionCaptor.captured.execute(mockUserPermission)
                verify {
                    mockUserPermission.read = true
                    mockUserPermission.write = true
                }
            } else {
                fail("User permissions configuration action was not captured")
            }
        } else {
            fail("FilePermissions configuration action was not captured")
        }
    }

    companion object {
        const val FAKE_ENGINE_STAMP = "901b0f1afe77c3555abee7b86a26aaa37f131379"
        const val FAKE_ENGINE_REALM = "made_up_realm"
    }
}

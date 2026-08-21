package com.flutter.gradle

import com.android.build.api.dsl.ApplicationBuildType
import com.android.build.api.dsl.ApplicationDefaultConfig
import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.dsl.LibraryExtension
import com.android.build.api.variant.AndroidComponentsExtension
import com.android.build.gradle.AbstractAppExtension
import com.android.build.gradle.BaseExtension
import com.android.build.gradle.api.AndroidSourceDirectorySet
import com.android.build.gradle.internal.core.InternalBaseVariant
import com.android.build.gradle.tasks.MergeSourceSetFolders
import com.android.build.gradle.tasks.ProcessAndroidResources
import com.flutter.gradle.tasks.FlutterTask
import com.flutter.gradle.tasks.PrintTask
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkObject
import io.mockk.slot
import io.mockk.unmockkAll
import io.mockk.verify
import org.gradle.api.Action
import org.gradle.api.NamedDomainObjectContainer
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.api.file.Directory
import org.gradle.api.tasks.Copy
import org.gradle.api.tasks.TaskContainer
import org.gradle.api.tasks.TaskProvider
import org.jetbrains.kotlin.gradle.plugin.extraProperties
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.fail
import org.junit.jupiter.api.io.TempDir
import java.io.File
import java.nio.charset.StandardCharsets
import java.nio.file.Path
import java.util.Base64
import kotlin.io.path.writeText
import kotlin.test.Test
import kotlin.test.assertContains

class FlutterPluginTest {
    // Clear global singleton mocks to prevent mock state leaking into other tests in the same JVM.
    @AfterEach
    fun tearDown() {
        unmockkAll()
    }

    @Test
    fun `FlutterPlugin apply() adds expected tasks`(
        @TempDir tempDir: Path
    ) {
        val env = setupTestProjectEnvironment(tempDir)
        setupMockApplicationExtension(env.project)
        setupMockComponentsExtension(env.project)
        setupMockNativePluginLoader(env.project, env.flutterExtension)

        val flutterPlugin = FlutterPlugin()
        flutterPlugin.apply(env.project)

        verify { env.project.tasks.register("generateLockfiles", any()) }
        val registeredPrintTasks = mutableListOf<String>()
        verify {
            env.project.tasks.register(capture(registeredPrintTasks), PrintTask::class.java, any())
        }

        assertContains(registeredPrintTasks, "javaVersion")
        assertContains(registeredPrintTasks, "kgpVersion")
        assertContains(registeredPrintTasks, "printBuildVariants")
        assertContains(registeredPrintTasks, "printNdkVersion")
    }

    @Test
    fun `FlutterPlugin apply wires flutter embedding dependencies on all build types`(
        @TempDir tempDir: Path
    ) {
        val env = setupTestProjectEnvironment(tempDir)
        setupMockApplicationExtension(env.project)
        setupMockComponentsExtension(env.project)
        setupMockNativePluginLoader(env.project, env.flutterExtension)

        val flutterPlugin = FlutterPlugin()
        flutterPlugin.apply(env.project)

        verify {
            env.project.dependencies.add(
                "debugApi",
                "io.flutter:flutter_embedding_debug:1.0.0-$FAKE_ENGINE_STAMP"
            )
        }
        verify {
            env.project.dependencies.add(
                "releaseApi",
                "io.flutter:flutter_embedding_release:1.0.0-$FAKE_ENGINE_STAMP"
            )
        }
    }

    @Test
    fun `copyFlutterAssets task sets filePermissions correctly`(
        @TempDir tempDir: Path
    ) {
        val env = setupTestProjectEnvironment(tempDir)
        val project = env.project
        setupMockApplicationExtension(project)
        val mockAbstractAppExtension = project.extensions.getByType(AbstractAppExtension::class.java)
        setupMockComponentsExtension(project)
        setupMockNativePluginLoader(project, env.flutterExtension)

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

    @Test
    fun `apply adds task for generating manifest with engine shell arguments`(
        @TempDir tempDir: Path
    ) {
        val env = setupTestProjectEnvironment(tempDir)
        val project = env.project
        val engineShellArgsJson = """["--enable-impeller=true"]"""
        val base64EngineShellArgs =
            Base64.getEncoder().encodeToString(engineShellArgsJson.toByteArray(StandardCharsets.UTF_8))
        every { project.findProperty("flutter.engineShellArgs") } returns base64EngineShellArgs

        setupMockApplicationExtension(project)
        setupMockComponentsExtension(project)
        setupMockNativePluginLoader(project, env.flutterExtension)

        mockkObject(FlutterPluginUtils)
        val flutterPlugin = FlutterPlugin()
        flutterPlugin.apply(project)

        verify {
            FlutterPluginUtils.addTaskForGeneratingEngineShellArgumentManifest(project)
        }
    }

    private data class TestProjectEnvironment(
        val projectDir: File,
        val fakeFlutterSdkDir: File,
        val project: Project,
        val flutterExtension: FlutterExtension
    )

    private fun setupTestProjectEnvironment(
        tempDir: Path,
        engineStamp: String = FAKE_ENGINE_STAMP,
        engineRealm: String = FAKE_ENGINE_REALM
    ): TestProjectEnvironment {
        val projectDir = tempDir.resolve("project-dir").resolve("android").resolve("app")
        projectDir.toFile().mkdirs()
        val settingsFile = projectDir.parent.resolve("settings.gradle")
        settingsFile.writeText("empty for now")
        val fakeFlutterSdkDir = tempDir.resolve("fake-flutter-sdk")
        fakeFlutterSdkDir.toFile().mkdirs()
        val fakeCacheDir = fakeFlutterSdkDir.resolve("bin").resolve("cache")
        fakeCacheDir.toFile().mkdirs()
        val fakeEngineStampFile = fakeCacheDir.resolve("engine.stamp")
        fakeEngineStampFile.writeText(engineStamp)
        val fakeEngineRealmFile = fakeCacheDir.resolve("engine.realm")
        fakeEngineRealmFile.writeText(engineRealm)

        val project = mockk<Project>(relaxed = true)
        every { project.projectDir } returns projectDir.toFile()
        every { project.findProperty("flutter.sdk") } returns fakeFlutterSdkDir.toString()
        every { project.file(fakeFlutterSdkDir.toString()) } returns fakeFlutterSdkDir.toFile()
        every { project.plugins.hasPlugin("com.android.application") } returns true
        every { project.rootProject } returns project
        every { project.state.failure as Throwable? } returns null
        every { project.configurations.named("api") } returns mockk()

        val flutterExtension = FlutterExtension()
        every { project.extensions.create("flutter", any<Class<*>>()) } returns flutterExtension
        every { project.extensions.findByType(FlutterExtension::class.java) } returns flutterExtension

        return TestProjectEnvironment(
            projectDir.toFile(),
            fakeFlutterSdkDir.toFile(),
            project,
            flutterExtension
        )
    }

    private fun setupMockApplicationExtension(
        project: Project,
        mockDebugBuildType: ApplicationBuildType =
            mockk<ApplicationBuildType>(relaxed = true) {
                every { name } returns "debug"
                every { isDebuggable } returns true
            },
        mockReleaseBuildType: ApplicationBuildType =
            mockk<ApplicationBuildType>(relaxed = true) {
                every { name } returns "release"
                every { isDebuggable } returns false
            }
    ): ApplicationExtension {
        val mockAbstractAppExtension =
            mockk<AbstractAppExtension>(
                moreInterfaces = arrayOf(ApplicationExtension::class),
                relaxed = true
            )
        val mockApplicationExtension = mockAbstractAppExtension as ApplicationExtension
        val mockLibraryExtension = mockk<LibraryExtension>(relaxed = true)
        every { project.extensions.findByType(AbstractAppExtension::class.java) } returns mockAbstractAppExtension
        every { project.extensions.getByType(AbstractAppExtension::class.java) } returns mockAbstractAppExtension
        every { project.extensions.getByType(LibraryExtension::class.java) } returns mockLibraryExtension
        every { project.extensions.findByName("android") } returns mockAbstractAppExtension

        every { project.extensions.findByType(BaseExtension::class.java) } returns mockk(relaxed = true)
        every { project.extensions.findByType(ApplicationExtension::class.java) } returns mockApplicationExtension
        every { project.extensions.getByType(ApplicationExtension::class.java) } returns mockApplicationExtension

        val container = mockk<NamedDomainObjectContainer<ApplicationBuildType>>(relaxed = true)
        every { container.getByName("debug") } returns mockDebugBuildType
        every { container.getByName("release") } returns mockReleaseBuildType
        every { container.all(any<Action<in ApplicationBuildType>>()) } answers {
            val action = firstArg<Action<in ApplicationBuildType>>()
            action.execute(mockDebugBuildType)
            action.execute(mockReleaseBuildType)
        }
        every { mockApplicationExtension.buildTypes } returns container

        val mockApplicationDefaultConfig =
            mockk<com.android.build.gradle.internal.dsl.DefaultConfig>(
                moreInterfaces = arrayOf(ApplicationDefaultConfig::class),
                relaxed = true
            )
        every { mockApplicationExtension.defaultConfig } returns mockApplicationDefaultConfig
        val mockDirectory = mockk<Directory>(relaxed = true)
        every { project.layout.buildDirectory.get() } returns mockDirectory
        val mockAndroidSourceSet = mockk<com.android.build.gradle.api.AndroidSourceSet>(relaxed = true)
        val mockAndroidSourceDirectorySet = mockk<AndroidSourceDirectorySet>(relaxed = true)
        every { mockAndroidSourceSet.jniLibs.srcDir(any()) } returns mockAndroidSourceDirectorySet
        every { mockAbstractAppExtension.sourceSets.getByName("main") } returns mockAndroidSourceSet

        return mockApplicationExtension
    }

    private fun setupMockComponentsExtension(project: Project): AndroidComponentsExtension<*, *, *> {
        val mockAndroidComponentsExtension = mockk<AndroidComponentsExtension<*, *, *>>(relaxed = true)
        every { project.extensions.getByType(AndroidComponentsExtension::class.java) } returns mockAndroidComponentsExtension
        every { project.extensions.findByType(AndroidComponentsExtension::class.java) } returns mockAndroidComponentsExtension
        val mockSelector = mockk<com.android.build.api.variant.VariantSelector>(relaxed = true)
        every { mockAndroidComponentsExtension.selector() } returns mockSelector
        every { mockSelector.all() } returns mockSelector
        every { mockSelector.withName(any<String>()) } returns mockSelector
        return mockAndroidComponentsExtension
    }

    private fun setupMockNativePluginLoader(
        project: Project,
        flutterExtension: FlutterExtension
    ) {
        mockkObject(NativePluginLoaderReflectionBridge)
        every { NativePluginLoaderReflectionBridge.getPlugins(any(), any()) } returns listOf()
        every { project.extraProperties } returns mockk()
        every { project.file(flutterExtension.source!!) } returns mockk()
    }

    companion object {
        const val FAKE_ENGINE_STAMP = "901b0f1afe77c3555abee7b86a26aaa37f131379"
        const val FAKE_ENGINE_REALM = "made_up_realm"
    }
}

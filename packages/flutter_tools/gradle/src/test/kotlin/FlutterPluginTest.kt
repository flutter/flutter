package com.flutter.gradle

import com.android.build.api.dsl.ApplicationBuildType
import com.android.build.api.dsl.ApplicationDefaultConfig
import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.dsl.LibraryExtension
import com.android.build.api.variant.AndroidComponentsExtension
import com.android.build.api.variant.ApplicationVariant
import com.android.build.api.variant.SourceDirectories
import com.android.build.api.variant.Sources
import com.android.build.api.variant.Variant
import com.android.build.api.variant.VariantBuilder
import com.android.build.gradle.AbstractAppExtension
import com.android.build.gradle.BaseExtension
import com.android.build.gradle.api.AndroidSourceDirectorySet
import com.flutter.gradle.tasks.CopyFlutterAssetsTask
import com.flutter.gradle.tasks.FlutterTask
import com.flutter.gradle.tasks.PrintTask
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkObject
import io.mockk.slot
import io.mockk.unmockkAll
import io.mockk.verify
import org.gradle.api.Action
import org.gradle.api.GradleException
import org.gradle.api.NamedDomainObjectContainer
import org.gradle.api.Project
import org.gradle.api.file.Directory
import org.gradle.api.tasks.TaskProvider
import org.jetbrains.kotlin.gradle.plugin.extraProperties
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.assertThrows
import org.junit.jupiter.api.io.TempDir
import java.io.File
import java.nio.charset.StandardCharsets
import java.nio.file.Path
import java.util.Base64
import kotlin.io.path.writeText
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertFalse

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

    @Test
    fun `onVariants registers compile and asset tasks and adds generated asset source directory`(
        @TempDir tempDir: Path
    ) {
        val env = setupTestProjectEnvironment(tempDir)
        val project = env.project
        setupMockApplicationExtension(project)
        val mockComponentsExtension = setupMockComponentsExtension(project)
        setupMockNativePluginLoader(project, env.flutterExtension)

        val onVariantSlot = slot<(Variant) -> Unit>()
        every { mockComponentsExtension.onVariants(any(), capture(onVariantSlot)) } returns Unit

        val mockCompileTaskProvider = mockk<TaskProvider<FlutterTask>>(relaxed = true)
        val mockCopyAssetsTaskProvider = mockk<TaskProvider<CopyFlutterAssetsTask>>(relaxed = true)
        every {
            project.tasks.register("compileFlutterBuildDebug", FlutterTask::class.java, any())
        } returns mockCompileTaskProvider
        every {
            project.tasks.register("copyFlutterAssetsDebug", CopyFlutterAssetsTask::class.java, any())
        } returns mockCopyAssetsTaskProvider

        val flutterPlugin = FlutterPlugin()
        flutterPlugin.apply(project)

        val mockVariant = mockk<ApplicationVariant>(relaxed = true)
        val mockAssetsSource = mockk<SourceDirectories.Layered>(relaxed = true)
        val mockSources = mockk<Sources>(relaxed = true)
        every { mockVariant.name } returns "debug"
        every { mockVariant.buildType } returns "debug"
        every { mockVariant.debuggable } returns true
        every { mockVariant.flavorName } returns null
        every { mockVariant.minSdk.apiLevel } returns 21
        every { mockVariant.sources } returns mockSources
        every { mockSources.assets } returns mockAssetsSource

        onVariantSlot.captured.invoke(mockVariant)

        verify {
            project.tasks.register("compileFlutterBuildDebug", FlutterTask::class.java, any())
        }
        verify {
            project.tasks.register("copyFlutterAssetsDebug", CopyFlutterAssetsTask::class.java, any())
        }
        verify {
            mockAssetsSource.addGeneratedSourceDirectory(
                mockCopyAssetsTaskProvider,
                CopyFlutterAssetsTask::destinationDir
            )
        }
    }

    @Test
    fun `onVariants throws GradleException when variant sources assets is null`(
        @TempDir tempDir: Path
    ) {
        val env = setupTestProjectEnvironment(tempDir)
        val project = env.project
        setupMockApplicationExtension(project)
        val mockComponentsExtension = setupMockComponentsExtension(project)
        setupMockNativePluginLoader(project, env.flutterExtension)

        val onVariantSlot = slot<(Variant) -> Unit>()
        every { mockComponentsExtension.onVariants(any(), capture(onVariantSlot)) } returns Unit

        val flutterPlugin = FlutterPlugin()
        flutterPlugin.apply(project)

        val mockVariant = mockk<ApplicationVariant>(relaxed = true)
        val mockSources = mockk<Sources>(relaxed = true)
        every { mockVariant.name } returns "debug"
        every { mockVariant.buildType } returns "debug"
        every { mockVariant.debuggable } returns true
        every { mockVariant.flavorName } returns null
        every { mockVariant.minSdk.apiLevel } returns 21
        every { mockVariant.sources } returns mockSources
        every { mockSources.assets } returns null

        val exception =
            assertThrows<GradleException> {
                onVariantSlot.captured.invoke(mockVariant)
            }
        assertContains(
            exception.message!!,
            "Flutter could not register its generated assets for variant 'debug'"
        )
    }

    @Test
    fun `onVariants skips Flutter compile and asset task registration when shouldConfigureFlutterTask is false`(
        @TempDir tempDir: Path
    ) {
        val env = setupTestProjectEnvironment(tempDir)
        val project = env.project
        setupMockApplicationExtension(project)
        val mockComponentsExtension = setupMockComponentsExtension(project)
        setupMockNativePluginLoader(project, env.flutterExtension)

        val mockStartParameter = mockk<org.gradle.StartParameter>()
        every { mockStartParameter.taskNames } returns listOf("assembleDebug")
        val mockGradle = mockk<org.gradle.api.invocation.Gradle>()
        every { mockGradle.startParameter } returns mockStartParameter
        every { project.gradle } returns mockGradle

        val onVariantSlot = slot<(Variant) -> Unit>()
        every { mockComponentsExtension.onVariants(any(), capture(onVariantSlot)) } returns Unit

        val flutterPlugin = FlutterPlugin()
        flutterPlugin.apply(project)

        val mockVariant = mockk<ApplicationVariant>(relaxed = true)
        every { mockVariant.name } returns "androidTest"
        every { mockVariant.buildType } returns "debug"
        every { mockVariant.debuggable } returns true
        every { mockVariant.flavorName } returns null
        every { mockVariant.minSdk.apiLevel } returns 21

        val isConfigured = FlutterPluginUtils.shouldConfigureFlutterTask(project, "assembleAndroidTest")
        assertFalse(isConfigured, "shouldConfigureFlutterTask should return false for assembleAndroidTest when cli task is assembleDebug")

        onVariantSlot.captured.invoke(mockVariant)

        val taskContainer = project.tasks
        verify(exactly = 0) {
            taskContainer.register("compileFlutterBuildAndroidTest", FlutterTask::class.java, any())
        }
        verify(exactly = 0) {
            taskContainer.register("copyFlutterAssetsAndroidTest", CopyFlutterAssetsTask::class.java, any())
        }
    }

    @Test
    fun `registerFlutterCompileTask sets compile properties from project and variant`(
        @TempDir tempDir: Path
    ) {
        val env = setupTestProjectEnvironment(tempDir)
        val project = env.project
        every { project.findProperty("filesystem-roots") } returns "root1|root2"
        every { project.findProperty("filesystem-scheme") } returns "custom-scheme"
        every { project.findProperty("track-widget-creation") } returns "false"
        every { project.findProperty("frontend-server-starter-path") } returns "starter.dart"
        every { project.findProperty("extra-front-end-options") } returns "--opt1"
        every { project.findProperty("extra-gen-snapshot-options") } returns "--opt2"
        every { project.findProperty("split-debug-info") } returns "debug/info"
        every { project.findProperty("tree-shake-icons") } returns "true"
        every { project.findProperty("dart-obfuscation") } returns "true"
        every { project.findProperty("dart-defines") } returns "key=val"
        every { project.findProperty("performance-measurement-file") } returns "perf.json"
        every { project.findProperty("code-size-directory") } returns "code/size"
        every { project.findProperty("deferred-components") } returns "true"
        every { project.findProperty("validate-deferred-components") } returns "false"

        setupMockApplicationExtension(project)
        val mockComponentsExtension = setupMockComponentsExtension(project)
        setupMockNativePluginLoader(project, env.flutterExtension)

        val onVariantSlot = slot<(Variant) -> Unit>()
        every { mockComponentsExtension.onVariants(any(), capture(onVariantSlot)) } returns Unit

        val compileActionSlot = slot<Action<FlutterTask>>()
        every {
            project.tasks.register("compileFlutterBuildDebug", FlutterTask::class.java, capture(compileActionSlot))
        } returns mockk(relaxed = true)

        val flutterPlugin = FlutterPlugin()
        flutterPlugin.apply(project)

        val mockVariant = mockk<ApplicationVariant>(relaxed = true)
        val mockAssetsSource = mockk<SourceDirectories.Layered>(relaxed = true)
        val mockSources = mockk<Sources>(relaxed = true)
        every { mockVariant.name } returns "debug"
        every { mockVariant.buildType } returns "debug"
        every { mockVariant.debuggable } returns true
        every { mockVariant.flavorName } returns "free"
        every { mockVariant.minSdk.apiLevel } returns 24
        every { mockVariant.sources } returns mockSources
        every { mockSources.assets } returns mockAssetsSource

        onVariantSlot.captured.invoke(mockVariant)

        val mockFlutterTask = mockk<FlutterTask>(relaxed = true)
        compileActionSlot.captured.execute(mockFlutterTask)

        verify { mockFlutterTask.buildMode = "debug" }
        verify { mockFlutterTask.minSdkVersion = 24 }
        verify { mockFlutterTask.flavor = "free" }
        verify { mockFlutterTask.trackWidgetCreation = false }
        verify { mockFlutterTask.dartObfuscation = true }
        verify { mockFlutterTask.treeShakeIcons = true }
        verify { mockFlutterTask.deferredComponents = true }
        verify { mockFlutterTask.validateDeferredComponents = false }
        verify { mockFlutterTask.fileSystemScheme = "custom-scheme" }
        verify { mockFlutterTask.frontendServerStarterPath = "starter.dart" }
        verify { mockFlutterTask.extraFrontEndOptions = "--opt1" }
        verify { mockFlutterTask.extraGenSnapshotOptions = "--opt2" }
        verify { mockFlutterTask.splitDebugInfo = "debug/info" }
        verify { mockFlutterTask.dartDefines = "key=val" }
        verify { mockFlutterTask.performanceMeasurementFile = "perf.json" }
        verify { mockFlutterTask.codeSizeDirectory = "code/size" }
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

    private fun setupMockComponentsExtension(project: Project): AndroidComponentsExtension<*, VariantBuilder, Variant> {
        val mockAndroidComponentsExtension =
            mockk<AndroidComponentsExtension<Any, VariantBuilder, Variant>>(relaxed = true)
        every {
            project.extensions.getByType(AndroidComponentsExtension::class.java)
        } returns (mockAndroidComponentsExtension as AndroidComponentsExtension<*, *, *>)
        every {
            project.extensions.findByType(AndroidComponentsExtension::class.java)
        } returns (mockAndroidComponentsExtension as AndroidComponentsExtension<*, *, *>)
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

package com.flutter.gradle

import com.android.build.api.artifact.SingleArtifact
import com.android.build.api.dsl.ApplicationBuildType
import com.android.build.api.dsl.ApplicationDefaultConfig
import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.dsl.LibraryBuildType
import com.android.build.api.dsl.LibraryExtension
import com.android.build.api.variant.AndroidComponentsExtension
import com.android.build.api.variant.ApplicationVariant
import com.android.build.api.variant.BuiltArtifactsLoader
import com.android.build.api.variant.LibraryVariant
import com.android.build.api.variant.SourceDirectories
import com.android.build.api.variant.Sources
import com.android.build.api.variant.Variant
import com.android.build.api.variant.VariantBuilder
import com.android.build.api.variant.VariantOutput
import com.android.build.gradle.AbstractAppExtension
import com.android.build.gradle.BaseExtension
import com.android.build.gradle.api.AndroidSourceDirectorySet
import com.flutter.gradle.tasks.CopyFlutterApksTask
import com.flutter.gradle.tasks.CopyFlutterAssetsTask
import com.flutter.gradle.tasks.CopyFlutterJniLibsTask
import com.flutter.gradle.tasks.FlutterTask
import com.flutter.gradle.tasks.PrintTask
import com.flutter.gradle.testing.mockAbiFilters
import com.flutter.gradle.testing.mockProductFlavors
import io.mockk.Runs
import io.mockk.every
import io.mockk.just
import io.mockk.mockk
import io.mockk.mockkObject
import io.mockk.slot
import io.mockk.unmockkAll
import io.mockk.verify
import org.gradle.api.Action
import org.gradle.api.GradleException
import org.gradle.api.NamedDomainObjectContainer
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.api.Transformer
import org.gradle.api.file.Directory
import org.gradle.api.provider.Property
import org.gradle.api.provider.Provider
import org.gradle.api.specs.Spec
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
import kotlin.test.assertEquals

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
        val mockCompileTaskProvider = mockk<TaskProvider<FlutterTask>>(relaxed = true)
        val mockCopyAssetsTaskProvider = mockk<TaskProvider<CopyFlutterAssetsTask>>(relaxed = true)
        every {
            project.tasks.register("compileFlutterBuildDebug", FlutterTask::class.java, any())
        } returns mockCompileTaskProvider
        every {
            project.tasks.register("copyFlutterAssetsDebug", CopyFlutterAssetsTask::class.java, any())
        } returns mockCopyAssetsTaskProvider

        val onVariant = applyPluginCapturingVariantCallback(env)
        val mockAssetsSource = mockk<SourceDirectories.Layered>(relaxed = true)
        onVariant(mockApplicationVariant(assetsSource = mockAssetsSource))

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

        val onVariant = applyPluginCapturingVariantCallback(env)

        val exception =
            assertThrows<GradleException> {
                onVariant(mockApplicationVariant(assetsSource = null))
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
        // A single assembleDebug on the command line must not configure Flutter for androidTest.
        val mockStartParameter = mockk<org.gradle.StartParameter>()
        every { mockStartParameter.taskNames } returns listOf("assembleDebug")
        val mockGradle = mockk<org.gradle.api.invocation.Gradle>()
        every { mockGradle.startParameter } returns mockStartParameter
        every { project.gradle } returns mockGradle

        val onVariant = applyPluginCapturingVariantCallback(env)
        onVariant(mockApplicationVariant(name = "androidTest"))

        val taskContainer = project.tasks
        verify(exactly = 0) {
            taskContainer.register("compileFlutterBuildAndroidTest", FlutterTask::class.java, any())
        }
        verify(exactly = 0) {
            taskContainer.register("copyFlutterAssetsAndroidTest", CopyFlutterAssetsTask::class.java, any())
        }
        verify(exactly = 0) {
            taskContainer.register("copyFlutterApksAndroidTest", CopyFlutterApksTask::class.java, any())
        }
        verify(exactly = 0) {
            taskContainer.register("copyJniLibsflutterBuildAndroidTest", CopyFlutterJniLibsTask::class.java, any())
        }
    }

    @Test
    fun `onVariants wires the jniLibs copy to the output of the variant's compile task`(
        @TempDir tempDir: Path
    ) {
        val env = setupTestProjectEnvironment(tempDir)
        val project = env.project
        val mockCompileTaskProvider = mockk<TaskProvider<FlutterTask>>(relaxed = true)
        every {
            project.tasks.register("compileFlutterBuildDebug", FlutterTask::class.java, any())
        } returns mockCompileTaskProvider
        val compileOutputSlot = slot<Transformer<File, FlutterTask>>()
        val compileOutput = mockk<Provider<File>>()
        every { mockCompileTaskProvider.map(capture(compileOutputSlot)) } returns compileOutput
        val compileOutputDir = mockk<Provider<Directory>>()
        every { project.layout.dir(compileOutput) } returns compileOutputDir
        val jniLibsActionSlot = slot<Action<CopyFlutterJniLibsTask>>()
        every {
            project.tasks.register("copyJniLibsflutterBuildDebug", CopyFlutterJniLibsTask::class.java, capture(jniLibsActionSlot))
        } returns mockk(relaxed = true)

        val onVariant = applyPluginCapturingVariantCallback(env)
        onVariant(mockApplicationVariant())
        val mockJniLibsTask = mockk<CopyFlutterJniLibsTask>(relaxed = true)
        jniLibsActionSlot.captured.execute(mockJniLibsTask)

        verify { mockJniLibsTask.intermediateDir.set(compileOutputDir) }
        val compileTask = mockk<FlutterTask>()
        val outputDirectory = File("build/intermediates/flutter/debug")
        every { compileTask.outputDirectory } returns outputDirectory
        assertEquals(outputDirectory, compileOutputSlot.captured.transform(compileTask))
        // The provider carries the task dependency, so the compile task is not looked up by name.
        val taskContainer = project.tasks
        verify(exactly = 0) { taskContainer.findByName(any()) }
        verify(exactly = 0) { taskContainer.matching(any<Spec<Task>>()) }
    }

    @Test
    fun `onVariants configures a module variant for any command line task, without APK wiring`(
        @TempDir tempDir: Path
    ) {
        val env = setupTestProjectEnvironment(tempDir)
        val project = env.project
        // A host task, whose name matches none of the module's variant names.
        every { project.gradle.startParameter.taskNames } returns listOf(":app:assembleDemoStaging")
        val mockCopyAssetsTaskProvider = mockk<TaskProvider<CopyFlutterAssetsTask>>(relaxed = true)
        every {
            project.tasks.register("copyFlutterAssetsDebug", CopyFlutterAssetsTask::class.java, any())
        } returns mockCopyAssetsTaskProvider
        val mockCopyJniLibsTaskProvider = mockk<TaskProvider<CopyFlutterJniLibsTask>>(relaxed = true)
        every {
            project.tasks.register("copyJniLibsflutterBuildDebug", CopyFlutterJniLibsTask::class.java, any())
        } returns mockCopyJniLibsTaskProvider
        val assetsSource = mockk<SourceDirectories.Layered>(relaxed = true)
        val jniLibsSource = mockk<SourceDirectories.Layered>(relaxed = true)

        val onVariant = applyPluginToModuleCapturingVariantCallback(env)
        onVariant(mockLibraryVariant(assetsSource = assetsSource, jniLibsSource = jniLibsSource))

        val taskContainer = project.tasks
        verify { taskContainer.register("compileFlutterBuildDebug", FlutterTask::class.java, any()) }
        verify { assetsSource.addGeneratedSourceDirectory(mockCopyAssetsTaskProvider, CopyFlutterAssetsTask::destinationDir) }
        verify { jniLibsSource.addGeneratedSourceDirectory(mockCopyJniLibsTaskProvider, CopyFlutterJniLibsTask::destinationDir) }
        verify(exactly = 0) { taskContainer.register(any(), CopyFlutterApksTask::class.java, any()) }
        verify(exactly = 0) { taskContainer.configureEach(any<Action<in Task>>()) }
    }

    @Test
    fun `onVariants compiles each module variant in the build mode of its build type`(
        @TempDir tempDir: Path
    ) {
        val env = setupTestProjectEnvironment(tempDir)
        val project = env.project
        val compileActionSlots =
            listOf("Debug", "Profile", "Release").associateWith { variantName ->
                val actionSlot = slot<Action<FlutterTask>>()
                every {
                    project.tasks.register("compileFlutterBuild$variantName", FlutterTask::class.java, capture(actionSlot))
                } returns mockk(relaxed = true)
                actionSlot
            }

        val onVariant = applyPluginToModuleCapturingVariantCallback(env)
        onVariant(mockLibraryVariant(name = "debug", buildType = "debug", debuggable = true, minSdkApiLevel = 24))
        // The plugin creates `profile` with initWith(debug), so it is debuggable too.
        onVariant(mockLibraryVariant(name = "profile", buildType = "profile", debuggable = true))
        onVariant(mockLibraryVariant(name = "release", buildType = "release", debuggable = false))

        val buildModes =
            compileActionSlots.mapValues { (_, actionSlot) ->
                val task = mockk<FlutterTask>(relaxed = true)
                actionSlot.captured.execute(task)
                val buildModeSlot = slot<String>()
                verify { task.buildMode = capture(buildModeSlot) }
                buildModeSlot.captured
            }
        assertEquals(mapOf("Debug" to "debug", "Profile" to "profile", "Release" to "release"), buildModes)
    }

    @Test
    fun `apply warns that flutter hostAppProjectName has no effect in a module and does not look up the host`(
        @TempDir tempDir: Path
    ) {
        val env = setupTestProjectEnvironment(tempDir)
        val project = env.project
        every { project.providers.gradleProperty(FlutterPlugin.PROP_HOST_APP_PROJECT_NAME).isPresent } returns true

        applyPluginToModuleCapturingVariantCallback(env)

        val logger = project.logger
        verify {
            logger.warn(match<String> { it.contains("'flutter.hostAppProjectName' has no effect") })
        }
        val rootProject = project.rootProject
        verify(exactly = 0) { rootProject.findProject(any()) }
    }

    @Test
    fun `apply does not warn about flutter hostAppProjectName when it is not set`(
        @TempDir tempDir: Path
    ) {
        val env = setupTestProjectEnvironment(tempDir)
        val project = env.project
        every { project.providers.gradleProperty(FlutterPlugin.PROP_HOST_APP_PROJECT_NAME).isPresent } returns false

        applyPluginToModuleCapturingVariantCallback(env)

        val logger = project.logger
        verify(exactly = 0) { logger.warn(match<String> { it.contains("hostAppProjectName") }) }
    }

    @Test
    fun `onVariants offsets the defaultConfig versionCode for each per-ABI output for split-per-abi builds`(
        @TempDir tempDir: Path
    ) {
        val env = setupTestProjectEnvironment(tempDir)
        every { env.project.findProperty("split-per-abi") } returns "true"
        val arm32 = mockVariantOutput(abi = "armeabi-v7a")
        val arm64 = mockVariantOutput(abi = "arm64-v8a")
        val x64 = mockVariantOutput(abi = "x86_64")
        val universal = mockVariantOutput(abi = null)

        val onVariant = applyPluginCapturingVariantCallback(env, defaultConfigVersionCode = 42)
        onVariant(mockApplicationVariant(outputs = listOf(arm32, arm64, x64, universal).map { it.output }))

        verify { arm32.versionCode.set(1042) }
        verify { arm64.versionCode.set(2042) }
        verify { x64.versionCode.set(4042) }
        verify(exactly = 0) { universal.versionCode.set(any<Int>()) }
    }

    @Test
    fun `onVariants offsets the versionCode of the variant's product flavor for split-per-abi builds`(
        @TempDir tempDir: Path
    ) {
        val env = setupTestProjectEnvironment(tempDir)
        every { env.project.findProperty("split-per-abi") } returns "true"
        val arm64 = mockVariantOutput(abi = "arm64-v8a")

        val onVariant =
            applyPluginCapturingVariantCallback(
                env,
                defaultConfigVersionCode = 42,
                productFlavorVersionCodes = mapOf("free" to 7, "paid" to 9)
            )
        onVariant(
            mockApplicationVariant(
                name = "paidDebug",
                flavorName = "paid",
                productFlavors = listOf("tier" to "paid"),
                outputs = listOf(arm64.output)
            )
        )

        verify { arm64.versionCode.set(2009) }
    }

    @Test
    fun `onVariants warns and leaves versionCodes unchanged when the DSL declares no versionCode`(
        @TempDir tempDir: Path
    ) {
        val env = setupTestProjectEnvironment(tempDir)
        every { env.project.findProperty("split-per-abi") } returns "true"
        val arm64 = mockVariantOutput(abi = "arm64-v8a")

        val onVariant = applyPluginCapturingVariantCallback(env, defaultConfigVersionCode = null)
        onVariant(mockApplicationVariant(outputs = listOf(arm64.output)))

        verify(exactly = 0) { arm64.versionCode.set(any<Int>()) }
        val logger = env.project.logger
        verify { logger.warn(match<String> { it.contains("variant 'debug'") && it.contains("declares no versionCode") }) }
    }

    @Test
    fun `onVariants leaves versionCodes unchanged without split-per-abi`(
        @TempDir tempDir: Path
    ) {
        val env = setupTestProjectEnvironment(tempDir)
        val arm64 = mockVariantOutput(abi = "arm64-v8a")

        val onVariant = applyPluginCapturingVariantCallback(env, defaultConfigVersionCode = 42)
        onVariant(mockApplicationVariant(outputs = listOf(arm64.output)))

        verify(exactly = 0) { arm64.versionCode.set(any<Int>()) }
    }

    @Test
    fun `onVariants leaves versionCodes unchanged when force-version-code-ignoring-abi is set`(
        @TempDir tempDir: Path
    ) {
        val env = setupTestProjectEnvironment(tempDir)
        every { env.project.findProperty("split-per-abi") } returns "true"
        every { env.project.findProperty("force-version-code-ignoring-abi") } returns "true"
        val arm64 = mockVariantOutput(abi = "arm64-v8a")

        val onVariant = applyPluginCapturingVariantCallback(env, defaultConfigVersionCode = 42)
        onVariant(mockApplicationVariant(outputs = listOf(arm64.output)))

        verify(exactly = 0) { arm64.versionCode.set(any<Int>()) }
    }

    @Test
    fun `onVariants configures the APK copy from the variant artifacts, outputs, flavor, and build mode`(
        @TempDir tempDir: Path
    ) {
        val env = setupTestProjectEnvironment(tempDir)
        val project = env.project
        val copyApksActionSlot = slot<Action<CopyFlutterApksTask>>()
        every {
            project.tasks.register("copyFlutterApksFreeRelease", CopyFlutterApksTask::class.java, capture(copyApksActionSlot))
        } returns mockk()
        val flutterApkDir = mockk<Provider<Directory>>()
        every { project.layout.buildDirectory.dir("outputs/flutter-apk") } returns flutterApkDir
        val variant =
            mockApplicationVariant(
                name = "freeRelease",
                buildType = "release",
                debuggable = false,
                flavorName = "free",
                outputs =
                    listOf(
                        mockVariantOutput(abi = "armeabi-v7a").output,
                        mockVariantOutput(abi = null).output
                    )
            )
        val apkDir = mockk<Provider<Directory>>()
        every { variant.artifacts.get(SingleArtifact.APK) } returns apkDir
        val loader = mockk<BuiltArtifactsLoader>()
        every { variant.artifacts.getBuiltArtifactsLoader() } returns loader

        val onVariant = applyPluginCapturingVariantCallback(env)
        onVariant(variant)

        val mockCopyApksTask = mockk<CopyFlutterApksTask>(relaxed = true)
        copyApksActionSlot.captured.execute(mockCopyApksTask)

        verify { mockCopyApksTask.apkDirectory.set(apkDir) }
        verify { mockCopyApksTask.builtArtifactsLoader.set(loader) }
        verify { mockCopyApksTask.destinationDir.set(flutterApkDir) }
        verify { mockCopyApksTask.outputAbis.set(listOf("armeabi-v7a", CopyFlutterApksTask.NO_ABI)) }
        verify { mockCopyApksTask.flavorName.set("free") }
        verify { mockCopyApksTask.buildMode.set("release") }
    }

    @Test
    fun `onVariants names the APK copy by Flutter build mode for profile and custom build types`(
        @TempDir tempDir: Path
    ) {
        val env = setupTestProjectEnvironment(tempDir)
        val project = env.project
        val profileActionSlot = slot<Action<CopyFlutterApksTask>>()
        every {
            project.tasks.register("copyFlutterApksProfile", CopyFlutterApksTask::class.java, capture(profileActionSlot))
        } returns mockk()
        val stagingActionSlot = slot<Action<CopyFlutterApksTask>>()
        every {
            project.tasks.register("copyFlutterApksStaging", CopyFlutterApksTask::class.java, capture(stagingActionSlot))
        } returns mockk()

        val onVariant = applyPluginCapturingVariantCallback(env)
        onVariant(mockApplicationVariant(name = "profile", buildType = "profile", debuggable = false))
        onVariant(mockApplicationVariant(name = "staging", buildType = "staging", debuggable = true))

        val profileCopyTask = mockk<CopyFlutterApksTask>(relaxed = true)
        profileActionSlot.captured.execute(profileCopyTask)
        val stagingCopyTask = mockk<CopyFlutterApksTask>(relaxed = true)
        stagingActionSlot.captured.execute(stagingCopyTask)

        verify { profileCopyTask.buildMode.set("profile") }
        // A debuggable custom build type uses debug artifacts, so its APK is named as debug.
        verify { stagingCopyTask.buildMode.set("debug") }
    }

    @Test
    fun `onVariants makes only the variant's assemble task depend on its APK copy`(
        @TempDir tempDir: Path
    ) {
        val env = setupTestProjectEnvironment(tempDir)
        val project = env.project
        val mockCopyApksTaskProvider = mockk<TaskProvider<CopyFlutterApksTask>>()
        every {
            project.tasks.register("copyFlutterApksDebug", CopyFlutterApksTask::class.java, any())
        } returns mockCopyApksTaskProvider
        val configureEachSlot = slot<Action<in Task>>()
        every { project.tasks.configureEach(capture(configureEachSlot)) } returns Unit

        val onVariant = applyPluginCapturingVariantCallback(env)
        onVariant(mockApplicationVariant())

        val assembleDebug = mockk<Task>()
        every { assembleDebug.name } returns "assembleDebug"
        every { assembleDebug.dependsOn(*anyVararg()) } returns assembleDebug
        val assembleRelease = mockk<Task>()
        every { assembleRelease.name } returns "assembleRelease"
        configureEachSlot.captured.execute(assembleDebug)
        configureEachSlot.captured.execute(assembleRelease)

        verify { assembleDebug.dependsOn(mockCopyApksTaskProvider) }
        verify(exactly = 0) { assembleRelease.dependsOn(*anyVararg()) }
    }

    // How each Gradle property is parsed is covered by FlutterCompileOptionsTest. This covers the
    // mapping of those options, and of the variant's own values, onto the FlutterTask.
    @Test
    fun `registerFlutterCompileTask applies compile options and variant values to the task`(
        @TempDir tempDir: Path
    ) {
        val env = setupTestProjectEnvironment(tempDir)
        val project = env.project
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

        val compileActionSlot = slot<Action<FlutterTask>>()
        every {
            project.tasks.register("compileFlutterBuildDebug", FlutterTask::class.java, capture(compileActionSlot))
        } returns mockk(relaxed = true)

        val onVariant = applyPluginCapturingVariantCallback(env)
        onVariant(mockApplicationVariant(flavorName = "free", minSdkApiLevel = 24))

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

    /**
     * Applies the plugin to [env]'s project, runs its `finalizeDsl` callbacks as AGP would, and
     * returns its `onVariants` callback.
     */
    private fun applyPluginCapturingVariantCallback(
        env: TestProjectEnvironment,
        defaultConfigVersionCode: Int? = null,
        productFlavorVersionCodes: Map<String, Int?> = emptyMap()
    ): (Variant) -> Unit {
        val appExtension = setupMockApplicationExtension(env.project)
        val defaultConfig = appExtension.defaultConfig
        every { defaultConfig.versionCode } returns defaultConfigVersionCode
        val productFlavors = mockProductFlavors(productFlavorVersionCodes)
        every { appExtension.productFlavors } returns productFlavors
        val mockComponentsExtension = setupMockComponentsExtension(env.project)
        setupMockNativePluginLoader(env.project, env.flutterExtension)

        val finalizeDslCallbacks = mutableListOf<(Any) -> Unit>()
        every { mockComponentsExtension.finalizeDsl(capture(finalizeDslCallbacks)) } returns Unit
        val onVariantSlot = slot<(Variant) -> Unit>()
        every { mockComponentsExtension.onVariants(any(), capture(onVariantSlot)) } returns Unit

        FlutterPlugin().apply(env.project)
        finalizeDslCallbacks.forEach { callback -> callback(appExtension) }
        return onVariantSlot.captured
    }

    /** [applyPluginCapturingVariantCallback] for an add-to-app module (Android library plugin). */
    private fun applyPluginToModuleCapturingVariantCallback(env: TestProjectEnvironment): (Variant) -> Unit {
        val project = env.project
        every { project.plugins.hasPlugin("com.android.application") } returns false
        every { project.extensions.findByType(ApplicationExtension::class.java) } returns null

        val mockLibraryExtension = mockk<LibraryExtension>(relaxed = true)
        every { project.extensions.findByName("android") } returns mockLibraryExtension
        every { project.extensions.getByType(LibraryExtension::class.java) } returns mockLibraryExtension
        val mockDebugBuildType =
            mockk<LibraryBuildType>(relaxed = true) {
                every { name } returns "debug"
            }
        val mockReleaseBuildType =
            mockk<LibraryBuildType>(relaxed = true) {
                every { name } returns "release"
            }
        val container = mockk<NamedDomainObjectContainer<LibraryBuildType>>(relaxed = true)
        every { container.getByName("debug") } returns mockDebugBuildType
        every { container.getByName("release") } returns mockReleaseBuildType
        every { container.all(any<Action<in LibraryBuildType>>()) } answers {
            val action = firstArg<Action<in LibraryBuildType>>()
            action.execute(mockDebugBuildType)
            action.execute(mockReleaseBuildType)
        }
        every { mockLibraryExtension.buildTypes } returns container

        val mockComponentsExtension = setupMockComponentsExtension(project)
        setupMockNativePluginLoader(project, env.flutterExtension)
        val onVariantSlot = slot<(Variant) -> Unit>()
        every { mockComponentsExtension.onVariants(any(), capture(onVariantSlot)) } returns Unit

        FlutterPlugin().apply(project)
        return onVariantSlot.captured
    }

    /**
     * An [ApplicationVariant] that answers everything the plugin reads while configuring a
     * variant. Pass the values a test is about; the rest are stubbed so the plugin can run.
     */
    private fun mockApplicationVariant(
        name: String = "debug",
        buildType: String = "debug",
        debuggable: Boolean = true,
        flavorName: String? = null,
        productFlavors: List<Pair<String, String>> = emptyList(),
        minSdkApiLevel: Int = 21,
        assetsSource: SourceDirectories.Layered? = mockk(relaxed = true),
        outputs: List<VariantOutput> = emptyList()
    ): ApplicationVariant {
        val mockVariant = mockk<ApplicationVariant>(relaxed = true)
        val mockSources = mockk<Sources>(relaxed = true)
        every { mockVariant.name } returns name
        every { mockVariant.buildType } returns buildType
        every { mockVariant.debuggable } returns debuggable
        every { mockVariant.flavorName } returns flavorName
        every { mockVariant.productFlavors } returns productFlavors
        every { mockVariant.minSdk.apiLevel } returns minSdkApiLevel
        every { mockVariant.sources } returns mockSources
        every { mockSources.assets } returns assetsSource
        every { mockVariant.outputs } returns outputs
        return mockVariant
    }

    /** [mockApplicationVariant] for an add-to-app module. */
    private fun mockLibraryVariant(
        name: String = "debug",
        buildType: String = "debug",
        debuggable: Boolean = true,
        minSdkApiLevel: Int = 21,
        assetsSource: SourceDirectories.Layered? = mockk(relaxed = true),
        jniLibsSource: SourceDirectories.Layered? = mockk(relaxed = true)
    ): LibraryVariant {
        val mockVariant = mockk<LibraryVariant>(relaxed = true)
        val mockSources = mockk<Sources>(relaxed = true)
        every { mockVariant.name } returns name
        every { mockVariant.buildType } returns buildType
        every { mockVariant.debuggable } returns debuggable
        every { mockVariant.flavorName } returns null
        every { mockVariant.productFlavors } returns emptyList()
        every { mockVariant.minSdk.apiLevel } returns minSdkApiLevel
        every { mockVariant.sources } returns mockSources
        every { mockSources.assets } returns assetsSource
        every { mockSources.jniLibs } returns jniLibsSource
        return mockVariant
    }

    /** A mocked [VariantOutput] and the mocked `versionCode` property it returns. */
    private data class MockVariantOutput(
        val output: VariantOutput,
        val versionCode: Property<Int>
    )

    /**
     * A [VariantOutput] with an ABI filter for [abi] (none if null). Only `set` is stubbed on its
     * versionCode, so any read fails the test, as AGP's strict mode would.
     */
    private fun mockVariantOutput(abi: String?): MockVariantOutput {
        val versionCodeProperty = mockk<Property<Int>>()
        every { versionCodeProperty.set(any<Int>()) } just Runs
        val output = mockk<VariantOutput>()
        every { output.filters } returns mockAbiFilters(abi)
        every { output.versionCode } returns versionCodeProperty
        return MockVariantOutput(output, versionCodeProperty)
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

    private fun setupMockComponentsExtension(project: Project): AndroidComponentsExtension<Any, VariantBuilder, Variant> {
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

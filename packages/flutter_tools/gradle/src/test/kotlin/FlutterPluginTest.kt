package com.flutter.gradle

import com.android.build.api.dsl.ApplicationBuildType
import com.android.build.api.dsl.ApplicationDefaultConfig
import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.dsl.CommonExtension
import com.android.build.api.dsl.LibraryExtension
import com.android.build.api.variant.AndroidComponentsExtension
import com.android.build.gradle.AbstractAppExtension
import com.android.build.gradle.BaseExtension
import com.android.build.gradle.api.AndroidSourceDirectorySet
import com.flutter.gradle.tasks.PrintTask
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkObject
import io.mockk.verify
import org.gradle.api.Project
import org.gradle.api.file.Directory
import org.jetbrains.kotlin.gradle.plugin.extraProperties
import org.junit.jupiter.api.io.TempDir
import java.nio.file.Path
import kotlin.io.path.writeText
import kotlin.test.Test
import kotlin.test.assertContains

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
        val mockAbstractAppExtension =
            mockk<AbstractAppExtension>(
                moreInterfaces = arrayOf(ApplicationExtension::class),
                relaxed = true
            )
        val mockLibraryExtension = mockk<LibraryExtension>(relaxed = true)
        every { project.extensions.findByType(AbstractAppExtension::class.java) } returns mockAbstractAppExtension
        val mockAndroidComponentsExtension = mockk<AndroidComponentsExtension<*, *, *>>(relaxed = true)
        every { project.extensions.getByType(AndroidComponentsExtension::class.java) } returns mockAndroidComponentsExtension
        every { project.extensions.findByType(AndroidComponentsExtension::class.java) } returns mockAndroidComponentsExtension
        val mockSelector = mockk<com.android.build.api.variant.VariantSelector>(relaxed = true)
        every { mockAndroidComponentsExtension.selector() } returns mockSelector
        every { mockSelector.all() } returns mockSelector
        every { mockSelector.withName(any<String>()) } returns mockSelector
        every { project.extensions.getByType(AbstractAppExtension::class.java) } returns mockAbstractAppExtension
        every { project.extensions.getByType(LibraryExtension::class.java) } returns mockLibraryExtension
        every { project.extensions.findByName("android") } returns mockAbstractAppExtension
        every { project.projectDir } returns projectDir.toFile()
        every { project.findProperty("flutter.sdk") } returns fakeFlutterSdkDir.toString()
        every { project.file(fakeFlutterSdkDir.toString()) } returns fakeFlutterSdkDir.toFile()
        val flutterExtension = FlutterExtension()
        every { project.extensions.create("flutter", any<Class<*>>()) } returns flutterExtension
        every { project.extensions.findByType(FlutterExtension::class.java) } returns flutterExtension
        val mockBaseExtension = mockk<BaseExtension>(relaxed = true)
        val mockCommonExtension = mockk<CommonExtension<*, *, *, *, *, *>>(relaxed = true)
        val mockDebugBuildType = mockk<com.android.build.api.dsl.ApplicationBuildType>(relaxed = true)
        val mockReleaseBuildType = mockk<com.android.build.api.dsl.ApplicationBuildType>(relaxed = true)

        // Cast our multi-interface mock instead of creating a brand new one
        val mockApplicationExtension = mockAbstractAppExtension as ApplicationExtension

        // Mock buildTypes on our new dual-purpose mock so AgpCommonExtensionWrapper can read them
        every { mockApplicationExtension.buildTypes.getByName("debug") } returns mockDebugBuildType
        every { mockApplicationExtension.buildTypes.getByName("release") } returns mockReleaseBuildType

        // Keep the CommonExtension mocks just in case other parts of the plugin look for it
        every { mockCommonExtension.buildTypes.getByName("debug") } returns mockDebugBuildType
        every { mockCommonExtension.buildTypes.getByName("release") } returns mockReleaseBuildType

        every { project.extensions.findByType(BaseExtension::class.java) } returns mockBaseExtension
        every { project.extensions.findByType(CommonExtension::class.java) } returns mockCommonExtension

        // Pass the dual-purpose mock for any ApplicationExtension lookups
        every { project.extensions.findByType(ApplicationExtension::class.java) } returns mockApplicationExtension
        every { project.extensions.getByType(ApplicationExtension::class.java) } returns mockApplicationExtension

        val mockApplicationDefaultConfig =
            mockk<com.android.build.gradle.internal.dsl.DefaultConfig>(
                moreInterfaces = arrayOf(ApplicationDefaultConfig::class),
                relaxed = true
            )
        every { mockApplicationExtension.defaultConfig } returns mockApplicationDefaultConfig
        every { project.rootProject } returns project
        every { project.state.failure as Throwable? } returns null
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
        val registeredPrintTasks = mutableListOf<String>()
        verify {
            project.tasks.register(capture(registeredPrintTasks), PrintTask::class.java, any())
        }

        assertContains(registeredPrintTasks, "javaVersion")
        assertContains(registeredPrintTasks, "kgpVersion")
        assertContains(registeredPrintTasks, "printBuildVariants")
        assertContains(registeredPrintTasks, "printNdkVersion")
    }

    companion object {
        const val FAKE_ENGINE_STAMP = "901b0f1afe77c3555abee7b86a26aaa37f131379"
        const val FAKE_ENGINE_REALM = "made_up_realm"
    }
}

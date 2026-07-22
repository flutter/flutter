package com.flutter.gradle

import com.android.build.api.dsl.ApplicationBuildType
import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.variant.AndroidComponentsExtension
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
        val mockApplicationExtension = mockk<ApplicationExtension>(relaxed = true)
        val mockAndroidComponentsExtension = mockk<AndroidComponentsExtension<*, *, *>>(relaxed = true)
        every { project.extensions.getByType(AndroidComponentsExtension::class.java) } returns mockAndroidComponentsExtension
        every { project.extensions.findByType(AndroidComponentsExtension::class.java) } returns mockAndroidComponentsExtension
        val mockSelector = mockk<com.android.build.api.variant.VariantSelector>(relaxed = true)
        every { mockAndroidComponentsExtension.selector() } returns mockSelector
        every { mockSelector.all() } returns mockSelector
        every { mockSelector.withName(any<String>()) } returns mockSelector
        every { project.extensions.findByName("android") } returns mockApplicationExtension
        every { project.projectDir } returns projectDir.toFile()
        every { project.findProperty("flutter.sdk") } returns fakeFlutterSdkDir.toString()
        every { project.file(fakeFlutterSdkDir.toString()) } returns fakeFlutterSdkDir.toFile()
        val flutterExtension = FlutterExtension()
        every { project.extensions.create("flutter", any<Class<*>>()) } returns flutterExtension
        every { project.extensions.findByType(FlutterExtension::class.java) } returns flutterExtension
        val mockDebugBuildType = mockk<ApplicationBuildType>(relaxed = true)
        val mockReleaseBuildType = mockk<ApplicationBuildType>(relaxed = true)

        // Mock buildTypes so AgpCommonExtensionWrapper and the profile build type
        // creation can read them.
        every { mockApplicationExtension.buildTypes.getByName("debug") } returns mockDebugBuildType
        every { mockApplicationExtension.buildTypes.getByName("release") } returns mockReleaseBuildType

        every { project.extensions.findByType(ApplicationExtension::class.java) } returns mockApplicationExtension
        every { project.extensions.getByType(ApplicationExtension::class.java) } returns mockApplicationExtension

        every { project.rootProject } returns project
        every { project.state.failure as Throwable? } returns null
        val mockDirectory = mockk<Directory>(relaxed = true)
        every { project.layout.buildDirectory.get() } returns mockDirectory
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

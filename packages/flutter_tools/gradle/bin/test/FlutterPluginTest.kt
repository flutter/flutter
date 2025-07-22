package com.flutter.gradle

import com.android.build.api.dsl.ApplicationDefaultConfig
import com.android.build.api.dsl.ApplicationExtension
import com.android.build.gradle.AbstractAppExtension
import com.android.build.gradle.BaseExtension
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

    companion object {
        const val FAKE_ENGINE_STAMP = "901b0f1afe77c3555abee7b86a26aaa37f131379"
        const val FAKE_ENGINE_REALM = "made_up_realm"
    }
}

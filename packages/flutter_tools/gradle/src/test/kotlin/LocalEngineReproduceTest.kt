package com.flutter.gradle

import com.android.build.api.dsl.ApplicationBuildType
import com.android.build.api.dsl.ApplicationDefaultConfig
import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.dsl.CommonExtension
import com.android.build.api.variant.AndroidComponentsExtension
import com.android.build.gradle.AbstractAppExtension
import com.android.build.gradle.BaseExtension
import com.android.build.gradle.api.AndroidSourceDirectorySet
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkObject
import io.mockk.verify
import org.gradle.api.Action
import org.gradle.api.Project
import org.gradle.api.artifacts.repositories.MavenArtifactRepository
import org.gradle.api.plugins.ExtraPropertiesExtension
import org.jetbrains.kotlin.gradle.plugin.extraProperties
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.io.TempDir
import java.io.File
import java.nio.file.Path
import kotlin.io.path.writeText
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class LocalEngineReproduceTest {

    @AfterEach
    fun tearDown() {
        io.mockk.unmockkAll()
    }

    @Test
    fun `local engine properties from local properties file are detected`(@TempDir tempDir: Path) {
        val projectDir = tempDir.resolve("project-dir").resolve("android").resolve("app")
        projectDir.toFile().mkdirs()
        
        // Write local.properties with local engine settings
        val localPropertiesFile = projectDir.parent.resolve("local.properties")
        val fakeLocalEngineRepo = tempDir.resolve("fake-engine-repo").toAbsolutePath().toString()
        val fakeLocalEngineOut = tempDir.resolve("fake-engine-out").toAbsolutePath().toString()
        val fakeLocalEngineHostOut = tempDir.resolve("fake-engine-host-out").toAbsolutePath().toString()
        
        localPropertiesFile.writeText("""
            flutter.sdk=${tempDir.resolve("fake-flutter-sdk").toAbsolutePath()}
            local-engine-repo=$fakeLocalEngineRepo
            local-engine-out=$fakeLocalEngineOut
            local-engine-host-out=$fakeLocalEngineHostOut
            local-engine-build-mode=debug
        """.trimIndent())

        // Create the directories on disk
        tempDir.resolve("fake-engine-repo").toFile().mkdirs()
        tempDir.resolve("fake-engine-out").toFile().mkdirs()
        tempDir.resolve("fake-engine-host-out").toFile().mkdirs()

        val fakeFlutterSdkDir = tempDir.resolve("fake-flutter-sdk")
        fakeFlutterSdkDir.toFile().mkdirs()
        val fakeCacheDir = fakeFlutterSdkDir.resolve("bin").resolve("cache")
        fakeCacheDir.toFile().mkdirs()
        fakeCacheDir.resolve("engine.stamp").writeText("123456")
        fakeCacheDir.resolve("engine.realm").writeText("")

        val project = mockk<Project>(relaxed = true)
        val rootProject = mockk<Project>(relaxed = true)
        every { project.rootProject } returns rootProject
        every { rootProject.rootProject } returns rootProject

        val mockAbstractAppExtension = mockk<AbstractAppExtension>(
            moreInterfaces = arrayOf(ApplicationExtension::class),
            relaxed = true
        )
        every { project.extensions.findByType(AbstractAppExtension::class.java) } returns mockAbstractAppExtension
        every { project.extensions.getByType(AbstractAppExtension::class.java) } returns mockAbstractAppExtension
        every { project.extensions.findByName("android") } returns mockAbstractAppExtension
        
        val mockAndroidComponentsExtension = mockk<AndroidComponentsExtension<*, *, *>>(relaxed = true)
        every { project.extensions.getByType(AndroidComponentsExtension::class.java) } returns mockAndroidComponentsExtension
        every { mockAndroidComponentsExtension.selector() } returns mockk {
            every { all() } returns mockk()
        }

        every { project.projectDir } returns projectDir.toFile()
        every { rootProject.projectDir } returns projectDir.parent.toFile()
        every { rootProject.file("local.properties") } returns localPropertiesFile.toFile()
        every { project.file(any()) } answers {
            val path = firstArg<Any>().toString()
            val file = File(path)
            if (file.isAbsolute) file else File(projectDir.toFile(), path)
        }
        every { rootProject.file(any()) } answers {
            val path = firstArg<Any>().toString()
            val file = File(path)
            if (file.isAbsolute) file else File(projectDir.parent.toFile(), path)
        }

        val flutterExtension = FlutterExtension()
        every { project.extensions.create("flutter", any<Class<*>>()) } returns flutterExtension
        every { project.extensions.findByType(FlutterExtension::class.java) } returns flutterExtension

        val mockBaseExtension = mockk<BaseExtension>(relaxed = true)
        val mockCommonExtension = mockk<CommonExtension<*, *, *, *, *, *>>(relaxed = true)
        val mockDebugBuildType = mockk<com.android.build.api.dsl.ApplicationBuildType>(relaxed = true)
        val mockReleaseBuildType = mockk<com.android.build.api.dsl.ApplicationBuildType>(relaxed = true)
        val mockApplicationExtension = mockAbstractAppExtension as ApplicationExtension
        every { mockApplicationExtension.buildTypes.getByName("debug") } returns mockDebugBuildType
        every { mockApplicationExtension.buildTypes.getByName("release") } returns mockReleaseBuildType
        every { mockCommonExtension.buildTypes.getByName("debug") } returns mockDebugBuildType
        every { mockCommonExtension.buildTypes.getByName("release") } returns mockReleaseBuildType
        every { project.extensions.findByType(BaseExtension::class.java) } returns mockBaseExtension
        every { project.extensions.findByType(CommonExtension::class.java) } returns mockCommonExtension
        every { project.extensions.findByType(ApplicationExtension::class.java) } returns mockApplicationExtension
        every { project.extensions.getByType(ApplicationExtension::class.java) } returns mockApplicationExtension

        val mockApplicationDefaultConfig = mockk<com.android.build.gradle.internal.dsl.DefaultConfig>(
            moreInterfaces = arrayOf(ApplicationDefaultConfig::class),
            relaxed = true
        )
        every { (mockAbstractAppExtension as ApplicationExtension).defaultConfig } returns mockApplicationDefaultConfig
        
        val mockAndroidSourceSet = mockk<com.android.build.gradle.api.AndroidSourceSet>(relaxed = true)
        every { mockAbstractAppExtension.sourceSets.getByName("main") } returns mockAndroidSourceSet

        mockkObject(NativePluginLoaderReflectionBridge)
        every { NativePluginLoaderReflectionBridge.getPlugins(any(), any()) } returns listOf()
        val extraProperties = mockk<ExtraPropertiesExtension>(relaxed = true)
        val propertiesMap = mutableMapOf<String, Any>()
        every { extraProperties.has(any()) } answers { propertiesMap.containsKey(firstArg()) }
        every { extraProperties.get(any()) } answers { propertiesMap[firstArg()]!! }
        every { extraProperties.set(any(), any()) } answers { propertiesMap[firstArg()] = secondArg() }
        every { project.extensions.getByType(ExtraPropertiesExtension::class.java) } returns extraProperties
        every { rootProject.extensions.getByType(ExtraPropertiesExtension::class.java) } returns extraProperties
        every { project.extensions.extraProperties } returns extraProperties
        every { rootProject.extensions.extraProperties } returns extraProperties
        every { project.extraProperties } returns extraProperties
        every { rootProject.extraProperties } returns extraProperties
        every { rootProject.uri(any()) } answers {
            val arg = firstArg<Any>()
            if (arg is java.net.URI) {
                arg
            } else {
                val str = arg.toString()
                if (str.startsWith("http://") || str.startsWith("https://") || str.startsWith("file:/")) {
                    java.net.URI(str)
                } else {
                    File(str).toURI()
                }
            }
        }
        every { project.uri(any()) } answers {
            val arg = firstArg<Any>()
            if (arg is java.net.URI) {
                arg
            } else {
                val str = arg.toString()
                if (str.startsWith("http://") || str.startsWith("https://") || str.startsWith("file:/")) {
                    java.net.URI(str)
                } else {
                    File(str).toURI()
                }
            }
        }

        // Capture repository configured by the plugin
        every { rootProject.allprojects(any<Action<Project>>()) } answers {
            firstArg<Action<Project>>().execute(rootProject)
        }
        val mavenRepos = mutableListOf<MavenArtifactRepository>()
        val repositoryHandler = mockk<org.gradle.api.artifacts.dsl.RepositoryHandler>(relaxed = true)
        every { rootProject.repositories } returns repositoryHandler
        every { project.repositories } returns repositoryHandler
        every { repositoryHandler.maven(any<Action<MavenArtifactRepository>>()) } answers {
            val repo = mockk<MavenArtifactRepository>(relaxed = true)
            val action = firstArg<Action<MavenArtifactRepository>>()
            action.execute(repo)
            mavenRepos.add(repo)
            repo
        }

        // Mock project properties to simulate NO project properties passed from CLI (IDE run)
        every { project.hasProperty("local-engine-repo") } returns false
        every { project.findProperty("local-engine-repo") } returns null
        every { project.hasProperty("local-engine-out") } returns false
        every { project.findProperty("local-engine-out") } returns null
        every { project.hasProperty("local-engine-host-out") } returns false
        every { project.findProperty("local-engine-host-out") } returns null

        val flutterPlugin = FlutterPlugin()
        
        // Assert that initially (with current implementation) it is false
        // (Wait, we want the test to fail now, so we verify that the local engine repo is NOT set or it throws exception / doesn't find it)
        // Wait, if it doesn't find it, it won't add the fakeLocalEngineRepo URL to maven repositories.
        // Let's execute apply.
        flutterPlugin.apply(project)

        // Verify that the Maven repo added contains the local engine repo path
        // In the failing case, this will fail because shouldProjectUseLocalEngine returns false,
        // and maven repo URL will be set to download.flutter.io instead.
        val urls = mutableListOf<java.net.URI>()
        mavenRepos.forEach { repo ->
            verify { repo.url = capture(urls) }
        }
        
        val localRepoUri = File(fakeLocalEngineRepo).toURI()
        assertTrue(urls.contains(localRepoUri), "Maven repositories should contain the local engine repo URI: $localRepoUri. But found: $urls")
    }
}

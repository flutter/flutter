// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.dsl.ApplicationBuildType
import com.android.build.api.dsl.ApplicationDefaultConfig
import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.dsl.CommonExtension
import com.android.build.api.variant.AndroidComponentsExtension
import com.android.build.gradle.AbstractAppExtension
import com.android.build.gradle.BaseExtension
import com.android.build.gradle.api.AndroidSourceDirectorySet
import com.android.builder.model.ProductFlavor
import com.android.build.gradle.internal.core.InternalBaseVariant
import com.android.build.gradle.tasks.MergeSourceSetFolders
import com.android.build.gradle.tasks.ProcessAndroidResources
import com.flutter.gradle.tasks.FlutterTask
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkObject
import io.mockk.unmockkObject
import io.mockk.slot
import io.mockk.verify
import org.gradle.api.Action
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.api.file.Directory
import org.gradle.api.tasks.Copy
import org.gradle.api.tasks.TaskContainer
import org.gradle.api.tasks.TaskProvider
import org.gradle.api.plugins.ExtensionAware
import org.gradle.api.plugins.ExtraPropertiesExtension
import org.jetbrains.kotlin.gradle.plugin.extraProperties
import org.junit.jupiter.api.io.TempDir
import java.nio.file.Path
import java.io.File
import kotlin.io.path.writeText
import kotlin.test.Test

class FlutterFlavorTargetReproductionTest {
    private val FAKE_ENGINE_STAMP = "901b0f1afe77c3555abee7b86a26aaa37f131379"
    private val FAKE_ENGINE_REALM = "made_up_realm"

    @Test
    fun `reproduce flavor target overriding bug`(@TempDir tempDir: Path) {
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
        every { project.findProperty("flutter.sdk") } returns fakeFlutterSdkDir.toString()
        every { project.file(fakeFlutterSdkDir.toString()) } returns fakeFlutterSdkDir.toFile()

        val projectFlutterExtension = FlutterExtension().apply { target = "lib/main_prod.dart" } // project-level fallback
        every { project.extensions.create("flutter", any<Class<*>>()) } returns projectFlutterExtension
        every { project.extensions.findByType(FlutterExtension::class.java) } returns projectFlutterExtension
        every { project.extensions.getByType(FlutterExtension::class.java) } returns projectFlutterExtension

        val mockBaseExtension = mockk<BaseExtension>(relaxed = true)
        val mockCommonExtension = mockk<CommonExtension<*, *, *, *, *, *>>(relaxed = true)
        val mockDebugBuildType = mockk<ApplicationBuildType>(relaxed = true)
        val mockReleaseBuildType = mockk<ApplicationBuildType>(relaxed = true)

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
        every { mockApplicationExtension.defaultConfig } returns mockApplicationDefaultConfig
        every { project.rootProject } returns project
        every { project.state.failure as Throwable? } returns null
        val mockDirectory = mockk<Directory>(relaxed = true)
        every { project.layout.buildDirectory.get() } returns mockDirectory

        val mockAndroidSourceSet = mockk<com.android.build.gradle.api.AndroidSourceSet>(relaxed = true)
        val mockAndroidSourceDirectorySet = mockk<AndroidSourceDirectorySet>(relaxed = true)
        every { mockAndroidSourceSet.jniLibs.srcDir(any()) } returns mockAndroidSourceDirectorySet
        every { mockAbstractAppExtension.sourceSets.getByName("main") } returns mockAndroidSourceSet

        mockkObject(NativePluginLoaderReflectionBridge)
        try {
            every { NativePluginLoaderReflectionBridge.getPlugins(any(), any()) } returns listOf()
            every { project.extraProperties } returns mockk<ExtraPropertiesExtension>(relaxed = true)
            
            // Return concrete files
            val localPropertiesFile = projectDir.parent.resolve("local.properties").toFile()
            localPropertiesFile.writeText("flutter.sdk=${fakeFlutterSdkDir.toString()}")
            every { project.file("local.properties") } returns localPropertiesFile
            every { project.file(projectFlutterExtension.source!!) } returns projectDir.parent.toFile()

            val taskContainer = mockk<TaskContainer>(relaxed = true)
            every { project.tasks } returns taskContainer

            // Mock named tasks mapping
            val mockTaskProvider = mockk<TaskProvider<Task>>(relaxed = true)
            every { mockTaskProvider.hint(Task::class).get() } returns mockk<Task>(relaxed = true)
            every { taskContainer.named(any<String>()) } returns mockTaskProvider

            // Setup two variants: devDebug and prodDebug
            val devVariant = mockk<com.android.build.gradle.api.ApplicationVariant>(relaxed = true)
            every { devVariant.name } returns "devDebug"
            every { devVariant.buildType.name } returns "debug"
            every { devVariant.flavorName } returns "dev"

            val prodVariant = mockk<com.android.build.gradle.api.ApplicationVariant>(relaxed = true)
            every { prodVariant.name } returns "prodDebug"
            every { prodVariant.buildType.name } returns "debug"
            every { prodVariant.flavorName } returns "prod"

            // Mock product flavors for the variants
            val devFlavor = mockk<ProductFlavor>(
                moreInterfaces = arrayOf(ExtensionAware::class),
                relaxed = true
            )
            every { devVariant.productFlavors } returns listOf(devFlavor)

            val prodFlavor = mockk<ProductFlavor>(
                moreInterfaces = arrayOf(ExtensionAware::class),
                relaxed = true
            )
            every { prodVariant.productFlavors } returns listOf(prodFlavor)

            // Mock flavor-specific extensions
            val devFlutterExtension = FlutterExtension().apply { target = "lib/main_dev.dart" }
            every { (devFlavor as ExtensionAware).extensions.findByType(FlutterExtension::class.java) } returns devFlutterExtension

            // prodFlavor does NOT define flavor-specific flutter extension target; it should fall back to project-level fallback
            every { (prodFlavor as ExtensionAware).extensions.findByType(FlutterExtension::class.java) } returns null

            val mergedFlavor = mockk<InternalBaseVariant.MergedFlavor>(relaxed = true)
            every { devVariant.mergedFlavor } returns mergedFlavor
            every { prodVariant.mergedFlavor } returns mergedFlavor
            val apiLevel = mockk<com.android.builder.model.ApiVersion>(relaxed = true)
            every { apiLevel.apiLevel } returns 21
            every { mergedFlavor.minSdkVersion } returns apiLevel

            val variantOutput = mockk<com.android.build.gradle.api.BaseVariantOutput>(relaxed = true)
            val variantOutputCollection = mockk<org.gradle.api.DomainObjectCollection<com.android.build.gradle.api.BaseVariantOutput>>()
            every { variantOutputCollection.iterator() } answers {
                val outputsIterator = mockk<MutableIterator<com.android.build.gradle.api.BaseVariantOutput>>()
                every { outputsIterator.hasNext() } returns true andThen false
                every { outputsIterator.next() } returns variantOutput
                outputsIterator
            }
            every { devVariant.outputs } returns variantOutputCollection
            every { prodVariant.outputs } returns variantOutputCollection

            val processResourcesProvider = mockk<TaskProvider<ProcessAndroidResources>>(relaxed = true)
            every { processResourcesProvider.hint(ProcessAndroidResources::class).get() } returns mockk<ProcessAndroidResources>(relaxed = true)
            every { variantOutput.processResourcesProvider } returns processResourcesProvider

            val assembleTask = mockk<Task>(relaxed = true)
            val assembleTaskProvider = mockk<TaskProvider<Task>>(relaxed = true)
            every { assembleTaskProvider.get() } returns assembleTask
            every { devVariant.assembleProvider } returns assembleTaskProvider
            every { prodVariant.assembleProvider } returns assembleTaskProvider

            val variants = listOf(devVariant, prodVariant)
            val variantsIterator = mockk<MutableIterator<com.android.build.gradle.api.ApplicationVariant>>()
            every { variantsIterator.hasNext() } returns true andThen true andThen false
            every { variantsIterator.next() } returns devVariant andThen prodVariant
            val variantCollection = mockk<org.gradle.api.DomainObjectSet<com.android.build.gradle.api.ApplicationVariant>>()
            every { mockAbstractAppExtension.applicationVariants } returns variantCollection
            every { variantCollection.iterator() } returns variantsIterator
            every {
                variantCollection.configureEach(any<Action<com.android.build.gradle.api.ApplicationVariant>>())
            } answers {
                variants.forEach { firstArg<Action<com.android.build.gradle.api.ApplicationVariant>>().execute(it) }
            }

            every { devVariant.mergeAssetsProvider.hint(MergeSourceSetFolders::class).get() } returns mockk<MergeSourceSetFolders>(relaxed = true)
            every { prodVariant.mergeAssetsProvider.hint(MergeSourceSetFolders::class).get() } returns mockk<MergeSourceSetFolders>(relaxed = true)

            val devFlutterTask = mockk<FlutterTask>(relaxed = true)
            val prodFlutterTask = mockk<FlutterTask>(relaxed = true)

            val devFlutterTaskProvider = mockk<TaskProvider<FlutterTask>>(relaxed = true)
            every { devFlutterTaskProvider.hint(FlutterTask::class).get() } returns devFlutterTask

            val prodFlutterTaskProvider = mockk<TaskProvider<FlutterTask>>(relaxed = true)
            every { prodFlutterTaskProvider.hint(FlutterTask::class).get() } returns prodFlutterTask

            every {
                taskContainer.register(
                    eq("compileFlutterBuildDevDebug"),
                    eq(FlutterTask::class.java),
                    any()
                )
            } answers {
                devFlutterTaskProvider
            }

            every {
                taskContainer.register(
                    eq("compileFlutterBuildProdDebug"),
                    eq(FlutterTask::class.java),
                    any()
                )
            } answers {
                prodFlutterTaskProvider
            }

            // Mock copyFlutterAssets task registration to avoid ClassCastException
            val mockCopyTask = mockk<Copy>(relaxed = true)
            val mockCopyTaskProvider = mockk<TaskProvider<Copy>>(relaxed = true)
            every { mockCopyTaskProvider.hint(Copy::class).get() } returns mockCopyTask
            every {
                taskContainer.register(
                    match { it.startsWith("copyFlutterAssets") },
                    eq(Copy::class.java),
                    any()
                )
            } answers {
                mockCopyTaskProvider
            }

            val flutterPlugin = FlutterPlugin()
            flutterPlugin.apply(project)

            // Capture and execute the configuration block passed to register("compileFlutterBuildDevDebug")
            // and register("compileFlutterBuildProdDebug").
            val devConfigActionSlot = slot<Action<FlutterTask>>()
            verify {
                taskContainer.register(
                    eq("compileFlutterBuildDevDebug"),
                    eq(FlutterTask::class.java),
                    capture(devConfigActionSlot)
                )
            }
            devConfigActionSlot.captured.execute(devFlutterTask)

            val prodConfigActionSlot = slot<Action<FlutterTask>>()
            verify {
                taskContainer.register(
                    eq("compileFlutterBuildProdDebug"),
                    eq(FlutterTask::class.java),
                    capture(prodConfigActionSlot)
                )
            }
            prodConfigActionSlot.captured.execute(prodFlutterTask)

            // Verify that compileFlutterBuildDevDebug got lib/main_dev.dart (specifically configured on devFlavor)
            verify { devFlutterTask.targetPath = "lib/main_dev.dart" }
            // Verify that compileFlutterBuildProdDebug got lib/main_prod.dart (project fallback, since prodFlavor has no specific target)
            verify { prodFlutterTask.targetPath = "lib/main_prod.dart" }
        } finally {
            unmockkObject(NativePluginLoaderReflectionBridge)
        }
    }
}

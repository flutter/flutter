// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.variant.AndroidComponentsExtension
import com.android.build.gradle.BaseExtension
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.gradle.api.Action
import org.gradle.api.Project
import kotlin.test.Test

class ValidateCompileSdkVersionOrNdkVersionAvoidAfterEvaluateReproduceTest {
    private val cameraDependency: Map<String?, Any?> =
        mapOf(
            Pair("name", "camera_android_camerax"),
            Pair("path", "/Users/someuser/.pub-cache/hosted/pub.dev/camera_android_camerax-0.6.14+1/"),
            Pair("native_build", true),
            Pair("dependencies", emptyList<String>()),
            Pair("dev_dependency", false)
        )

    @Test
    fun `detectLowCompileSdkVersionOrNdkVersion should not use project afterEvaluate or pluginProject afterEvaluate`() {
        val project = mockk<Project>(relaxed = true)
        val cameraPluginProject = mockk<Project>(relaxed = true)

        val mockExtension = mockk<BaseExtension>(relaxed = true)
        val mockPluginExtension = mockk<BaseExtension>(relaxed = true)
        val mockAndroidComponents = mockk<AndroidComponentsExtension<*, *, *>>(relaxed = true)

        // Stub Android extensions to prevent NullPointerException/crashes once afterEvaluate is removed
        val mockTaskContainer = mockk<org.gradle.api.tasks.TaskContainer>(relaxed = true)
        val mockPreBuildTask = mockk<org.gradle.api.Task>(relaxed = true)
        every { project.tasks } returns mockTaskContainer
        every { mockTaskContainer.findByName("preBuild") } returns mockPreBuildTask

        every { project.extensions.findByType(BaseExtension::class.java) } returns mockExtension
        every { project.extensions.getByType(AndroidComponentsExtension::class.java) } returns mockAndroidComponents
        every { mockExtension.compileSdkVersion } returns "android-35"
        every { mockExtension.ndkVersion } returns "26.3.11579264"

        every { project.rootProject.findProject(":camera_android_camerax") } returns cameraPluginProject
        every { cameraPluginProject.extensions.findByType(BaseExtension::class.java) } returns mockPluginExtension
        every { mockPluginExtension.compileSdkVersion } returns "android-35"
        every { mockPluginExtension.ndkVersion } returns "26.3.11579264"

        FlutterPluginUtils.detectLowCompileSdkVersionOrNdkVersion(project, listOf(cameraDependency))

        // We verify that project.afterEvaluate was never called
        verify(exactly = 0) { project.afterEvaluate(any<Action<Project>>()) }
        verify(exactly = 0) { cameraPluginProject.afterEvaluate(any<Action<Project>>()) }
    }
}

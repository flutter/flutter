// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import io.mockk.called
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.gradle.api.logging.Logger
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir
import java.nio.file.Path
import kotlin.io.path.createDirectory

class ValidateCompileSdkVersionTaskTest {
    private val cameraDependency: Map<String?, Any?> =
        mapOf(
            Pair("name", "camera_android_camerax"),
            Pair(
                "path",
                "/Users/someuser/.pub-cache/hosted/pub.dev/camera_android_camerax-0.6.14+1/"
            ),
            Pair("native_build", true),
            Pair("dependencies", emptyList<String>()),
            Pair("dev_dependency", false)
        )

    private val flutterPluginAndroidLifecycleDependency: Map<String?, Any?> =
        mapOf(
            Pair("name", "flutter_plugin_android_lifecycle"),
            Pair(
                "path",
                "/Users/someuser/.pub-cache/hosted/pub.dev/flutter_plugin_android_lifecycle-2.0.27/"
            ),
            Pair("native_build", true),
            Pair("dependencies", emptyList<String>()),
            Pair("dev_dependency", false)
        )

    @Test
    fun `detectLowCompileSdkVersionOrNdkVersion logs no warnings when no plugins have higher sdk or ndk`(
        @TempDir tempDir: Path
    ) {
        val projectDir = tempDir.resolve("app").toFile()
        val mockLogger = mockk<Logger>()

        val pluginCompileSdks = mapOf("camera_android_camerax" to 35)
        val pluginNdkVersions = mapOf("camera_android_camerax" to "26.3.11579264")

        ValidateCompileSdkVersionTask.performValidation(
            projSdk = 35,
            projNdk = "26.3.11579264",
            pluginCompileSdks = pluginCompileSdks,
            pluginNdkVersions = pluginNdkVersions,
            logger = mockLogger,
            projectDir = projectDir
        )

        verify { mockLogger wasNot called }
    }

    @Test
    fun `detectLowCompileSdkVersionOrNdkVersion logs warnings when plugins have higher sdk and ndk`(
        @TempDir tempDir: Path
    ) {
        val buildGradleFile =
            tempDir
                .resolve("app")
                .createDirectory()
                .resolve("build.gradle")
                .toFile()
        buildGradleFile.createNewFile()
        val projectDir = tempDir.resolve("app").toFile()
        val mockLogger = mockk<Logger>()
        every { mockLogger.error(any()) } returns Unit

        val cameraName = cameraDependency["name"] as String
        val lifecycleName = flutterPluginAndroidLifecycleDependency["name"] as String

        val pluginCompileSdks =
            mapOf(
                cameraName to 35,
                lifecycleName to 34
            )
        val pluginNdkVersions =
            mapOf(
                cameraName to "26.3.11579264",
                lifecycleName to "25.3.11579264"
            )

        ValidateCompileSdkVersionTask.performValidation(
            projSdk = 33,
            projNdk = "24.3.11579264",
            pluginCompileSdks = pluginCompileSdks,
            pluginNdkVersions = pluginNdkVersions,
            logger = mockLogger,
            projectDir = projectDir
        )

        verify {
            mockLogger.error(
                "Your project is configured to compile against Android SDK 33, but the " +
                    "following plugin(s) require to be compiled against a higher Android SDK version:"
            )
        }
        verify {
            mockLogger.error(
                "- $cameraName compiles against Android SDK 35"
            )
        }
        verify {
            mockLogger.error(
                "- $lifecycleName compiles against Android SDK 34"
            )
        }
        verify {
            mockLogger.error(
                """
                Fix this issue by compiling against the highest Android SDK version (they are backward compatible).
                Add the following to ${buildGradleFile.path}:

                    android {
                        compileSdk = 35
                        ...
                    }
                """.trimIndent()
            )
        }
        verify {
            mockLogger.error(
                "Your project is configured with Android NDK 24.3.11579264, but the following plugin(s) depend on a different Android NDK version:"
            )
        }
        verify {
            mockLogger.error(
                "- $cameraName requires Android NDK 26.3.11579264"
            )
        }
        verify {
            mockLogger.error(
                "- $lifecycleName requires Android NDK 25.3.11579264"
            )
        }
        verify {
            mockLogger.error(
                """
                Fix this issue by using the highest Android NDK version (they are backward compatible).
                Add the following to ${buildGradleFile.path}:

                    android {
                        ndkVersion = "26.3.11579264"
                        ...
                    }
                """.trimIndent()
            )
        }
    }

    @Test
    fun `detectLowCompileSdkVersionOrNdkVersion logs warnings only for compileSdkVersion mismatch`(
        @TempDir tempDir: Path
    ) {
        val buildGradleFile =
            tempDir
                .resolve("app")
                .createDirectory()
                .resolve("build.gradle")
                .toFile()
        buildGradleFile.createNewFile()
        val projectDir = tempDir.resolve("app").toFile()
        val mockLogger = mockk<Logger>()
        every { mockLogger.error(any()) } returns Unit

        val cameraName = cameraDependency["name"] as String

        val pluginCompileSdks = mapOf(cameraName to 35)
        val pluginNdkVersions = mapOf(cameraName to "24.3.11579264") // Same as project

        ValidateCompileSdkVersionTask.performValidation(
            projSdk = 33,
            projNdk = "24.3.11579264",
            pluginCompileSdks = pluginCompileSdks,
            pluginNdkVersions = pluginNdkVersions,
            logger = mockLogger,
            projectDir = projectDir
        )

        verify {
            mockLogger.error(
                "Your project is configured to compile against Android SDK 33, but the " +
                    "following plugin(s) require to be compiled against a higher Android SDK version:"
            )
        }
        verify(exactly = 0) {
            mockLogger.error(
                match { it.contains("Android NDK") }
            )
        }
    }

    @Test
    fun `detectLowCompileSdkVersionOrNdkVersion logs warnings only for ndkVersion mismatch`(
        @TempDir tempDir: Path
    ) {
        val buildGradleFile =
            tempDir
                .resolve("app")
                .createDirectory()
                .resolve("build.gradle")
                .toFile()
        buildGradleFile.createNewFile()
        val projectDir = tempDir.resolve("app").toFile()
        val mockLogger = mockk<Logger>()
        every { mockLogger.error(any()) } returns Unit

        val cameraName = cameraDependency["name"] as String

        val pluginCompileSdks = mapOf(cameraName to 33) // Same as project
        val pluginNdkVersions = mapOf(cameraName to "26.3.11579264")

        ValidateCompileSdkVersionTask.performValidation(
            projSdk = 33,
            projNdk = "24.3.11579264",
            pluginCompileSdks = pluginCompileSdks,
            pluginNdkVersions = pluginNdkVersions,
            logger = mockLogger,
            projectDir = projectDir
        )

        verify(exactly = 0) {
            mockLogger.error(
                match { it.contains("Android SDK 33") }
            )
        }
        verify {
            mockLogger.error(
                "Your project is configured with Android NDK 24.3.11579264, but the following plugin(s) depend on a different Android NDK version:"
            )
        }
    }
}

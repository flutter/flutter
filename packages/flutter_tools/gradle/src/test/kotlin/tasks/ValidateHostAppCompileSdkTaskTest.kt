// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import com.flutter.gradle.CompileSdkVersion
import io.mockk.every
import io.mockk.mockkObject
import io.mockk.unmockkObject
import io.mockk.verify
import org.gradle.api.GradleException
import org.gradle.testfixtures.ProjectBuilder
import org.junit.jupiter.api.assertDoesNotThrow
import org.junit.jupiter.api.assertThrows
import org.junit.jupiter.api.io.TempDir
import java.io.File
import java.nio.file.Path
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ValidateHostAppCompileSdkTaskTest {
    private fun hostApp(
        root: Path,
        compileSdk: CompileSdkVersion,
        buildFileContent: String = "android {\n    compileSdk = 35\n}\n"
    ): ValidateHostAppCompileSdkTask.HostApp {
        val projectDir = root.resolve("host/SampleApp").toFile()
        projectDir.mkdirs()
        val buildFile = File(projectDir, "build.gradle")
        buildFile.writeText(buildFileContent)
        return ValidateHostAppCompileSdkTask.HostApp(
            projectPath = ":SampleApp",
            projectDir = projectDir,
            buildFile = buildFile,
            rootDir = root.resolve("host").toFile(),
            compileSdk = compileSdk
        )
    }

    private fun moduleAar(
        root: Path,
        minCompileSdk: Int
    ) = ValidateHostAppCompileSdkTask.FlutterAar(
        projectPath = ":flutter",
        description = "Flutter module AAR \"hello\"",
        projectDir = root.resolve("hello/.android/Flutter").toFile(),
        minCompileSdk = minCompileSdk
    )

    private fun pluginAar(
        root: Path,
        minCompileSdk: Int
    ) = ValidateHostAppCompileSdkTask.FlutterAar(
        projectPath = ":myplugin",
        description = "Flutter plugin AAR \"myplugin\"",
        projectDir = root.resolve("myplugin/android").toFile(),
        minCompileSdk = minCompileSdk
    )

    @Test
    fun `passes when the host compileSdk is at least every Flutter AAR's minCompileSdk`(
        @TempDir tempDir: Path
    ) {
        assertDoesNotThrow {
            ValidateHostAppCompileSdkTask.performValidation(
                hostApp(tempDir, CompileSdkVersion(apiLevel = 36, previewCodename = null)),
                listOf(moduleAar(tempDir, 36), pluginAar(tempDir, 35))
            )
        }
    }

    @Test
    fun `passes when the host uses a compileSdk preview`(
        @TempDir tempDir: Path
    ) {
        assertDoesNotThrow {
            ValidateHostAppCompileSdkTask.performValidation(
                hostApp(tempDir, CompileSdkVersion(apiLevel = null, previewCodename = "Baklava")),
                listOf(moduleAar(tempDir, 37))
            )
        }
    }

    @Test
    fun `passes when the host compileSdk is unknown`(
        @TempDir tempDir: Path
    ) {
        assertDoesNotThrow {
            ValidateHostAppCompileSdkTask.performValidation(
                hostApp(tempDir, CompileSdkVersion(apiLevel = null, previewCodename = null)),
                listOf(moduleAar(tempDir, 37))
            )
        }
    }

    @Test
    fun `fails with the host app, Flutter AARs, declaration line, and fix`(
        @TempDir tempDir: Path
    ) {
        val host = hostApp(tempDir, CompileSdkVersion(apiLevel = 35, previewCodename = null))
        val module = moduleAar(tempDir, 36)
        val plugin = pluginAar(tempDir, 37)

        val exception =
            assertThrows<GradleException> {
                ValidateHostAppCompileSdkTask.performValidation(host, listOf(module, plugin))
            }

        val expected =
            """
            [Flutter] Your Android host app's compileSdk (35) is lower than the compileSdk required by its Flutter AARs (37).

            Starting with Android Gradle Plugin (AGP) 9, an Android app must use a compileSdk that is the
            same or higher than the compileSdk of every Android library (AAR) it depends on.

            Android host app
              Gradle project : :SampleApp
              Directory      : ${host.projectDir.path}
              compileSdk     : 35
              Declared in    : ${host.buildFile.path}:2

            Flutter AARs that require a higher compileSdk
              - Flutter plugin AAR "myplugin"
                  Gradle project : :myplugin
                  Directory      : ${plugin.projectDir!!.path}
                  Requires       : compileSdk 37 or higher
              - Flutter module AAR "hello"
                  Gradle project : :flutter
                  Directory      : ${module.projectDir!!.path}
                  Requires       : compileSdk 36 or higher

            How to fix
              Raise the host app's compileSdk to at least 37 in ${host.buildFile.path}:

                  android {
                      compileSdk = 37
                  }

              Raising compileSdk does not change your app's targetSdk (runtime behavior) or
              minSdk (supported devices).
              Learn more: https://docs.flutter.dev/add-to-app/android/project-setup
            """.trimIndent()
        assertEquals(expected, exception.message)
    }

    @Test
    fun `only lists Flutter AARs that require a higher compileSdk`(
        @TempDir tempDir: Path
    ) {
        val exception =
            assertThrows<GradleException> {
                ValidateHostAppCompileSdkTask.performValidation(
                    hostApp(tempDir, CompileSdkVersion(apiLevel = 35, previewCodename = null)),
                    listOf(moduleAar(tempDir, 36), pluginAar(tempDir, 35))
                )
            }

        val message = exception.message!!
        assertTrue(message.contains("Flutter module AAR \"hello\""))
        assertTrue(!message.contains("Flutter plugin AAR \"myplugin\""))
    }

    @Test
    fun `points at the version catalog when compileSdk comes from libs versions toml`(
        @TempDir tempDir: Path
    ) {
        val host =
            hostApp(
                tempDir,
                CompileSdkVersion(apiLevel = 35, previewCodename = null),
                buildFileContent = "android {\n    compileSdk = libs.versions.compileSdk.get().toInt()\n}\n"
            )
        val catalog = File(host.rootDir, "gradle/libs.versions.toml")
        catalog.parentFile.mkdirs()
        catalog.writeText("[versions]\ncompileSdk = \"35\"\n")

        val exception =
            assertThrows<GradleException> {
                ValidateHostAppCompileSdkTask.performValidation(host, listOf(moduleAar(tempDir, 36)))
            }

        val message = exception.message!!
        assertTrue(
            message.contains(
                "Declared in    : ${catalog.path}:2 (key \"compileSdk\", referenced from ${host.buildFile.path}:2)"
            )
        )
        assertTrue(message.contains("Raise \"compileSdk\" to at least 36 in ${catalog.path}:"))
        assertTrue(message.contains("compileSdk = \"36\""))
    }

    @Test
    fun `reports unresolved compileSdk expressions`(
        @TempDir tempDir: Path
    ) {
        val host =
            hostApp(
                tempDir,
                CompileSdkVersion(apiLevel = 35, previewCodename = null),
                buildFileContent = "android {\n    compileSdk = rootProject.ext.compileSdkVersion\n}\n"
            )

        val exception =
            assertThrows<GradleException> {
                ValidateHostAppCompileSdkTask.performValidation(host, listOf(moduleAar(tempDir, 36)))
            }

        val message = exception.message!!
        assertTrue(message.contains("Declared in    : ${host.buildFile.path}:2 via \"rootProject.ext.compileSdkVersion\""))
        assertTrue(message.contains("Raise the host app's compileSdk to at least 36 where it is defined"))
    }

    @Test
    fun `task action passes configured properties to performValidation`(
        @TempDir tempDir: Path
    ) {
        val project = ProjectBuilder.builder().build()
        val task =
            project.tasks
                .register(
                    "testValidateHostAppCompileSdk",
                    ValidateHostAppCompileSdkTask::class.java
                ).get()
        val hostDir = tempDir.resolve("host/SampleApp").toFile()
        val moduleDir = tempDir.resolve("hello/.android/Flutter").toFile()

        task.hostProjectPath.set(":SampleApp")
        task.hostCompileSdk.set(35)
        task.hostProjectDir.set(hostDir.path)
        task.hostBuildFile.set(File(hostDir, "build.gradle").path)
        task.rootDir.set(tempDir.resolve("host").toFile().path)
        task.flutterAarMinCompileSdks.set(mapOf(":flutter" to 36))
        task.flutterAarDescriptions.set(mapOf(":flutter" to "Flutter module AAR \"hello\""))
        task.flutterAarDirectories.set(mapOf(":flutter" to moduleDir.path))

        mockkObject(ValidateHostAppCompileSdkTask.Companion)
        every { ValidateHostAppCompileSdkTask.performValidation(any(), any()) } returns Unit
        try {
            task.run()

            verify {
                ValidateHostAppCompileSdkTask.performValidation(
                    ValidateHostAppCompileSdkTask.HostApp(
                        projectPath = ":SampleApp",
                        projectDir = hostDir,
                        buildFile = File(hostDir, "build.gradle"),
                        rootDir = tempDir.resolve("host").toFile(),
                        compileSdk = CompileSdkVersion(apiLevel = 35, previewCodename = null)
                    ),
                    listOf(
                        ValidateHostAppCompileSdkTask.FlutterAar(
                            projectPath = ":flutter",
                            description = "Flutter module AAR \"hello\"",
                            projectDir = moduleDir,
                            minCompileSdk = 36
                        )
                    )
                )
            }
        } finally {
            unmockkObject(ValidateHostAppCompileSdkTask.Companion)
        }
    }
}

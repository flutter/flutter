// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import io.mockk.every
import io.mockk.mockkObject
import io.mockk.unmockkObject
import io.mockk.verify
import org.gradle.testfixtures.ProjectBuilder
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir
import java.nio.file.Path

class ValidateCompileSdkVersionTaskExecutionTest {
    @Test
    fun `ValidateCompileSdkVersionTask execution calls performValidation`(
        @TempDir tempDir: Path
    ) {
        val project = ProjectBuilder.builder().build()
        val task = project.tasks.register("testValidateTask", ValidateCompileSdkVersionTask::class.java).get()

        val projectDir = tempDir.resolve("app").toFile()

        task.projectCompileSdk.set(33)
        task.projectNdkVersion.set("24.3.11579264")
        task.pluginCompileSdks.set(mapOf("camera" to 35))
        task.pluginNdkVersions.set(mapOf("camera" to "26.3.11579264"))
        task.projectDir.set(projectDir)

        mockkObject(ValidateCompileSdkVersionTask.Companion)
        every {
            ValidateCompileSdkVersionTask.performValidation(any(), any(), any(), any(), any(), any())
        } returns Unit

        try {
            task.run()

            verify {
                ValidateCompileSdkVersionTask.performValidation(
                    projSdk = 33,
                    projNdk = "24.3.11579264",
                    pluginCompileSdks = mapOf("camera" to 35),
                    pluginNdkVersions = mapOf("camera" to "26.3.11579264"),
                    logger = any(),
                    projectDir = projectDir
                )
            }
        } finally {
            unmockkObject(ValidateCompileSdkVersionTask.Companion)
        }
    }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import org.gradle.api.Project
import org.gradle.testfixtures.ProjectBuilder
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import java.io.ByteArrayOutputStream
import java.io.PrintStream
import kotlin.test.assertEquals

class PrintTaskTest {
    private val standardOut = System.out
    private val outputStreamCaptor = ByteArrayOutputStream()
    private lateinit var project: Project

    @BeforeEach
    fun setUp() {
        System.setOut(PrintStream(outputStreamCaptor))
        project = ProjectBuilder.builder().build()
    }

    @AfterEach
    fun tearDown() {
        System.setOut(standardOut)
    }

    @Test
    fun `PrintTask prints simple string value`() {
        val task = project.tasks.create("printJavaVersion", PrintTask::class.java)
        task.message.set("17.0.1")

        task.run()

        assertEquals("17.0.1", outputStreamCaptor.toString().trim())
    }

    @Test
    fun `PrintTask prints mapped list property like build variants`() {
        val task = project.tasks.create("printVariants", PrintTask::class.java)
        val variantsList = project.objects.listProperty(String::class.java)
        variantsList.add("debug")
        variantsList.add("release")

        task.message.set(
            variantsList.map { list -> list.joinToString("\n") { name -> "BuildVariant: $name" } },
        )

        task.run()

        assertEquals("BuildVariant: debug\nBuildVariant: release", outputStreamCaptor.toString().trim())
    }
}

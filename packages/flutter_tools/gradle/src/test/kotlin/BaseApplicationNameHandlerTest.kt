// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.dsl.ApplicationDefaultConfig
import com.android.build.api.dsl.ApplicationExtension
import com.flutter.gradle.BaseApplicationNameHandler.GRADLE_BASE_APPLICATION_NAME_PROPERTY
import org.gradle.api.Project
import org.gradle.api.plugins.ExtensionContainer
import org.junit.jupiter.api.Assertions.assertEquals
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import kotlin.test.Test

class BaseApplicationNameHandlerTest {
    @Test
    fun `setBaseName respects Flutter tool property`() {
        val baseApplicationNamePassedByFlutterTool = "toolSetBaseApplicationName"

        // Set up mocks.
        val mockProject = mockk<Project>()
        val mockAndroidComponentsExtension = mockk<ApplicationExtension>()
        val mockExtensionContainer = mockk<ExtensionContainer>()
        val mockDefaultConfig = mockk<ApplicationDefaultConfig>()
        val mockManifestPlaceholders = HashMap<String, Any>()

        every { mockProject.hasProperty(GRADLE_BASE_APPLICATION_NAME_PROPERTY) } returns true
        every { mockProject.property(GRADLE_BASE_APPLICATION_NAME_PROPERTY) } returns baseApplicationNamePassedByFlutterTool

        every { mockProject.extensions } returns mockExtensionContainer
        every { mockExtensionContainer.findByType(ApplicationExtension::class.java) } returns mockAndroidComponentsExtension
        every { mockAndroidComponentsExtension.defaultConfig } returns mockDefaultConfig
        every { mockDefaultConfig.manifestPlaceholders } returns mockManifestPlaceholders

        // Call the base name handler.
        BaseApplicationNameHandler.setBaseName(mockProject)

        // Make sure we set the value passed by the tool.
        assertEquals(mockManifestPlaceholders["applicationName"], baseApplicationNamePassedByFlutterTool)
    }

    @Test
    fun `setBaseName defaults to correct value`() {
        // Set up mocks.
        val mockProject = mockk<Project>()
        val mockAndroidComponentsExtension = mockk<ApplicationExtension>()
        val mockExtensionContainer = mockk<ExtensionContainer>()
        val mockDefaultConfig = mockk<ApplicationDefaultConfig>()
        val mockManifestPlaceholders = HashMap<String, Any>()

        every { mockProject.hasProperty(GRADLE_BASE_APPLICATION_NAME_PROPERTY) } returns false

        every { mockProject.extensions } returns mockExtensionContainer
        every { mockExtensionContainer.findByType(ApplicationExtension::class.java) } returns mockAndroidComponentsExtension
        every { mockAndroidComponentsExtension.defaultConfig } returns mockDefaultConfig
        every { mockDefaultConfig.manifestPlaceholders } returns mockManifestPlaceholders

        // Call the base name handler.
        BaseApplicationNameHandler.setBaseName(mockProject)

        // Make sure we default to the correct value.
        assertEquals(mockManifestPlaceholders["applicationName"], BaseApplicationNameHandler.DEFAULT_BASE_APPLICATION_NAME)
    }
}

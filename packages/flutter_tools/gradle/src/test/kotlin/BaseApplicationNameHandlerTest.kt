// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.dsl.ApplicationDefaultConfig
import com.android.build.api.dsl.ApplicationExtension
import com.flutter.gradle.BaseApplicationNameHandler.GRADLE_BASE_APPLICATION_NAME_PROPERTY
import org.gradle.api.Action
import org.gradle.api.Project
import org.gradle.api.plugins.ExtensionContainer
import org.junit.jupiter.api.Assertions.assertEquals
import org.mockito.Mockito
import kotlin.test.Test

class BaseApplicationNameHandlerTest {
    @Test
    fun `setBaseName respects Flutter tool property`() {
        val baseApplicationNamePassedByFlutterTool = "toolSetBaseApplicationName"

        // Set up mocks.
        val mockProject: Project = Mockito.mock(Project::class.java)
        val mockAndroidComponentsExtension: ApplicationExtension = Mockito.mock(ApplicationExtension::class.java)
        val mockExtensionContainer: ExtensionContainer = Mockito.mock(ExtensionContainer::class.java)
        val mockDefaultConfig = Mockito.mock(ApplicationDefaultConfig::class.java)
        val mockManifestPlaceholders = HashMap<String, Any>()

        Mockito.`when`(mockProject.hasProperty(GRADLE_BASE_APPLICATION_NAME_PROPERTY)).thenReturn(true)
        Mockito.`when`(mockProject.property(GRADLE_BASE_APPLICATION_NAME_PROPERTY)).thenReturn(baseApplicationNamePassedByFlutterTool)

        Mockito.`when`(mockProject.extensions).thenReturn(mockExtensionContainer)
        Mockito.`when`(mockExtensionContainer.findByType(ApplicationExtension::class.java)).thenReturn(mockAndroidComponentsExtension)
        Mockito.`when`(mockDefaultConfig.manifestPlaceholders).thenReturn(mockManifestPlaceholders)

        // Mock the defaultConfig { ... } lambda invocation to execute against our mockDefaultConfig
        Mockito
            .doAnswer { invocation ->
                val arg = invocation.arguments[0]
                if (arg is Action<*>) {
                    @Suppress("UNCHECKED_CAST")
                    (arg as Action<ApplicationDefaultConfig>).execute(mockDefaultConfig)
                } else {
                    @Suppress("UNCHECKED_CAST")
                    val action = arg as (ApplicationDefaultConfig) -> Unit
                    action(mockDefaultConfig)
                }
                null
            }.`when`(mockAndroidComponentsExtension)
            .defaultConfig(any())

        // Call the base name handler.
        BaseApplicationNameHandler.setBaseName(mockProject)

        // Make sure we set the value passed by the tool.
        assertEquals(mockManifestPlaceholders["applicationName"], baseApplicationNamePassedByFlutterTool)
    }

    @Test
    fun `setBaseName defaults to correct value`() {
        // Set up mocks.
        val mockProject: Project = Mockito.mock(Project::class.java)
        val mockAndroidComponentsExtension: ApplicationExtension = Mockito.mock(ApplicationExtension::class.java)
        val mockExtensionContainer: ExtensionContainer = Mockito.mock(ExtensionContainer::class.java)
        val mockDefaultConfig = Mockito.mock(ApplicationDefaultConfig::class.java)
        val mockManifestPlaceholders = HashMap<String, Any>()

        Mockito.`when`(mockProject.hasProperty(GRADLE_BASE_APPLICATION_NAME_PROPERTY)).thenReturn(false)

        Mockito.`when`(mockProject.extensions).thenReturn(mockExtensionContainer)
        Mockito.`when`(mockExtensionContainer.findByType(ApplicationExtension::class.java)).thenReturn(mockAndroidComponentsExtension)
        Mockito.`when`(mockDefaultConfig.manifestPlaceholders).thenReturn(mockManifestPlaceholders)

        // Mock the defaultConfig { ... } lambda invocation to execute against our mockDefaultConfig
        Mockito
            .doAnswer { invocation ->
                val arg = invocation.arguments[0]
                if (arg is Action<*>) {
                    @Suppress("UNCHECKED_CAST")
                    (arg as Action<ApplicationDefaultConfig>).execute(mockDefaultConfig)
                } else {
                    @Suppress("UNCHECKED_CAST")
                    val action = arg as (ApplicationDefaultConfig) -> Unit
                    action(mockDefaultConfig)
                }
                null
            }.`when`(mockAndroidComponentsExtension)
            .defaultConfig(any())

        // Call the base name handler.
        BaseApplicationNameHandler.setBaseName(mockProject)

        // Make sure we default to the correct value.
        assertEquals(mockManifestPlaceholders["applicationName"], BaseApplicationNameHandler.DEFAULT_BASE_APPLICATION_NAME)
    }

    // Helper to avoid Kotlin NullPointerExceptions when using Mockito.any() with non-null parameters
    @Suppress("UNCHECKED_CAST")
    private fun <T> any(): T {
        Mockito.any<T>()
        return null as T
    }
}

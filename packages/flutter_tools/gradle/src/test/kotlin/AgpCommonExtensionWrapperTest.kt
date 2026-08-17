// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.dsl.ApplicationBuildType
import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.dsl.DynamicFeatureBuildType
import com.android.build.api.dsl.DynamicFeatureExtension
import com.android.build.api.dsl.LibraryBuildType
import com.android.build.api.dsl.LibraryExtension
import com.android.build.api.dsl.Splits
import com.android.build.api.dsl.TestBuildType
import com.android.build.api.dsl.TestExtension
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.gradle.api.NamedDomainObjectContainer
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertSame

class AgpCommonExtensionWrapperTest {
    @Test
    fun `compileSdk delegates to application, library, dynamicFeature, and test extensions`() {
        val appExt = mockk<ApplicationExtension>(relaxed = true) { every { compileSdk } returns 35 }
        val libExt = mockk<LibraryExtension>(relaxed = true) { every { compileSdk } returns 34 }
        val dfExt = mockk<DynamicFeatureExtension>(relaxed = true) { every { compileSdk } returns 33 }
        val testExt = mockk<TestExtension>(relaxed = true) { every { compileSdk } returns 32 }

        assertEquals(35, AgpCommonExtensionWrapper(appExt).compileSdk)
        assertEquals(34, AgpCommonExtensionWrapper(libExt).compileSdk)
        assertEquals(33, AgpCommonExtensionWrapper(dfExt).compileSdk)
        assertEquals(32, AgpCommonExtensionWrapper(testExt).compileSdk)

        AgpCommonExtensionWrapper(appExt).compileSdk = 36
        verify { appExt.compileSdk = 36 }

        AgpCommonExtensionWrapper(libExt).compileSdk = 36
        verify { libExt.compileSdk = 36 }

        AgpCommonExtensionWrapper(dfExt).compileSdk = 36
        verify { dfExt.compileSdk = 36 }

        AgpCommonExtensionWrapper(testExt).compileSdk = 36
        verify { testExt.compileSdk = 36 }
    }

    @Test
    fun `compileSdkPreview delegates to application, library, dynamicFeature, and test extensions`() {
        val appExt = mockk<ApplicationExtension>(relaxed = true) { every { compileSdkPreview } returns "Baklava" }
        val libExt = mockk<LibraryExtension>(relaxed = true) { every { compileSdkPreview } returns "Vanilla" }
        val dfExt = mockk<DynamicFeatureExtension>(relaxed = true) { every { compileSdkPreview } returns "UpsideDownCake" }
        val testExt = mockk<TestExtension>(relaxed = true) { every { compileSdkPreview } returns "Tiramisu" }

        assertEquals("Baklava", AgpCommonExtensionWrapper(appExt).compileSdkPreview)
        assertEquals("Vanilla", AgpCommonExtensionWrapper(libExt).compileSdkPreview)
        assertEquals("UpsideDownCake", AgpCommonExtensionWrapper(dfExt).compileSdkPreview)
        assertEquals("Tiramisu", AgpCommonExtensionWrapper(testExt).compileSdkPreview)

        AgpCommonExtensionWrapper(appExt).compileSdkPreview = "Next"
        verify { appExt.compileSdkPreview = "Next" }

        AgpCommonExtensionWrapper(libExt).compileSdkPreview = "Next"
        verify { libExt.compileSdkPreview = "Next" }

        AgpCommonExtensionWrapper(dfExt).compileSdkPreview = "Next"
        verify { dfExt.compileSdkPreview = "Next" }

        AgpCommonExtensionWrapper(testExt).compileSdkPreview = "Next"
        verify { testExt.compileSdkPreview = "Next" }
    }

    @Test
    fun `buildTypes delegates to application, library, dynamicFeature, and test extensions`() {
        val appContainer = mockk<NamedDomainObjectContainer<ApplicationBuildType>>()
        val libContainer = mockk<NamedDomainObjectContainer<LibraryBuildType>>()
        val dfContainer = mockk<NamedDomainObjectContainer<DynamicFeatureBuildType>>()
        val testContainer = mockk<NamedDomainObjectContainer<TestBuildType>>()

        val appExt = mockk<ApplicationExtension>(relaxed = true) { every { buildTypes } returns appContainer }
        val libExt = mockk<LibraryExtension>(relaxed = true) { every { buildTypes } returns libContainer }
        val dfExt = mockk<DynamicFeatureExtension>(relaxed = true) { every { buildTypes } returns dfContainer }
        val testExt = mockk<TestExtension>(relaxed = true) { every { buildTypes } returns testContainer }

        assertSame(appContainer, AgpCommonExtensionWrapper(appExt).buildTypes)
        assertSame(libContainer, AgpCommonExtensionWrapper(libExt).buildTypes)
        assertSame(dfContainer, AgpCommonExtensionWrapper(dfExt).buildTypes)
        assertSame(testContainer, AgpCommonExtensionWrapper(testExt).buildTypes)
    }

    @Test
    fun `splits delegates to application, library, dynamicFeature, and test extensions`() {
        val mockSplits = mockk<Splits>(relaxed = true)
        val appExt = mockk<ApplicationExtension>(relaxed = true) { every { splits } returns mockSplits }
        val libExt = mockk<LibraryExtension>(relaxed = true) { every { splits } returns mockSplits }
        val dfExt = mockk<DynamicFeatureExtension>(relaxed = true) { every { splits } returns mockSplits }
        val testExt = mockk<TestExtension>(relaxed = true) { every { splits } returns mockSplits }

        assertSame(mockSplits, AgpCommonExtensionWrapper(appExt).splits)
        assertSame(mockSplits, AgpCommonExtensionWrapper(libExt).splits)
        assertSame(mockSplits, AgpCommonExtensionWrapper(dfExt).splits)
        assertSame(mockSplits, AgpCommonExtensionWrapper(testExt).splits)
    }

    @Test
    fun `wrapper throws for an unsupported backing extension type`() {
        val wrapper = AgpCommonExtensionWrapper("not an android extension")

        assertFailsWith<IllegalArgumentException> { wrapper.splits }
        assertFailsWith<IllegalArgumentException> { wrapper.buildTypes }
        assertFailsWith<IllegalArgumentException> { wrapper.compileSdk }
        assertFailsWith<IllegalArgumentException> { wrapper.compileSdk = 35 }
        assertFailsWith<IllegalArgumentException> { wrapper.compileSdkPreview }
        assertFailsWith<IllegalArgumentException> { wrapper.compileSdkPreview = "Baklava" }
        assertFailsWith<IllegalArgumentException> { wrapper.namespace }
        assertFailsWith<IllegalArgumentException> { wrapper.namespace = "com.example" }
        assertFailsWith<IllegalArgumentException> { wrapper.ndkVersion }
        assertFailsWith<IllegalArgumentException> { wrapper.ndkVersion = "29.0.0" }
        assertFailsWith<IllegalArgumentException> { wrapper.getDefaultProguardFile("proguard-android.txt") }
        assertFailsWith<IllegalArgumentException> { wrapper.compileOptions {} }
    }
}

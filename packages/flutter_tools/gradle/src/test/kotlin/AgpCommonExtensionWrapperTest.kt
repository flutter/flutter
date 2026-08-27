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
import java.io.File
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

        AgpCommonExtensionWrapper(libExt).compileSdk = 37
        verify { libExt.compileSdk = 37 }

        AgpCommonExtensionWrapper(dfExt).compileSdk = 38
        verify { dfExt.compileSdk = 38 }

        AgpCommonExtensionWrapper(testExt).compileSdk = 39
        verify { testExt.compileSdk = 39 }
    }

    @Test
    fun `compileSdkPreview delegates to application, library, dynamicFeature, and test extensions`() {
        val appExt = mockk<ApplicationExtension>(relaxed = true) { every { compileSdkPreview } returns "Baklava" }
        val libExt = mockk<LibraryExtension>(relaxed = true) { every { compileSdkPreview } returns "VanillaIceCream" }
        val dfExt = mockk<DynamicFeatureExtension>(relaxed = true) { every { compileSdkPreview } returns "UpsideDownCake" }
        val testExt = mockk<TestExtension>(relaxed = true) { every { compileSdkPreview } returns "Tiramisu" }

        assertEquals("Baklava", AgpCommonExtensionWrapper(appExt).compileSdkPreview)
        assertEquals("VanillaIceCream", AgpCommonExtensionWrapper(libExt).compileSdkPreview)
        assertEquals("UpsideDownCake", AgpCommonExtensionWrapper(dfExt).compileSdkPreview)
        assertEquals("Tiramisu", AgpCommonExtensionWrapper(testExt).compileSdkPreview)

        AgpCommonExtensionWrapper(appExt).compileSdkPreview = "AppPreview"
        verify { appExt.compileSdkPreview = "AppPreview" }

        AgpCommonExtensionWrapper(libExt).compileSdkPreview = "LibPreview"
        verify { libExt.compileSdkPreview = "LibPreview" }

        AgpCommonExtensionWrapper(dfExt).compileSdkPreview = "DfPreview"
        verify { dfExt.compileSdkPreview = "DfPreview" }

        AgpCommonExtensionWrapper(testExt).compileSdkPreview = "TestPreview"
        verify { testExt.compileSdkPreview = "TestPreview" }
    }

    @Test
    fun `namespace delegates to application, library, dynamicFeature, and test extensions`() {
        val appExt = mockk<ApplicationExtension>(relaxed = true) { every { namespace } returns "com.example.app" }
        val libExt = mockk<LibraryExtension>(relaxed = true) { every { namespace } returns "com.example.lib" }
        val dfExt = mockk<DynamicFeatureExtension>(relaxed = true) { every { namespace } returns "com.example.df" }
        val testExt = mockk<TestExtension>(relaxed = true) { every { namespace } returns "com.example.test" }

        assertEquals("com.example.app", AgpCommonExtensionWrapper(appExt).namespace)
        assertEquals("com.example.lib", AgpCommonExtensionWrapper(libExt).namespace)
        assertEquals("com.example.df", AgpCommonExtensionWrapper(dfExt).namespace)
        assertEquals("com.example.test", AgpCommonExtensionWrapper(testExt).namespace)

        AgpCommonExtensionWrapper(appExt).namespace = "com.example.app.updated"
        verify { appExt.namespace = "com.example.app.updated" }

        AgpCommonExtensionWrapper(libExt).namespace = "com.example.lib.updated"
        verify { libExt.namespace = "com.example.lib.updated" }

        AgpCommonExtensionWrapper(dfExt).namespace = "com.example.df.updated"
        verify { dfExt.namespace = "com.example.df.updated" }

        AgpCommonExtensionWrapper(testExt).namespace = "com.example.test.updated"
        verify { testExt.namespace = "com.example.test.updated" }
    }

    @Test
    fun `ndkVersion delegates to application, library, dynamicFeature, and test extensions`() {
        val appExt = mockk<ApplicationExtension>(relaxed = true) { every { ndkVersion } returns "29.0.1" }
        val libExt = mockk<LibraryExtension>(relaxed = true) { every { ndkVersion } returns "29.0.2" }
        val dfExt = mockk<DynamicFeatureExtension>(relaxed = true) { every { ndkVersion } returns "29.0.3" }
        val testExt = mockk<TestExtension>(relaxed = true) { every { ndkVersion } returns "29.0.4" }

        assertEquals("29.0.1", AgpCommonExtensionWrapper(appExt).ndkVersion)
        assertEquals("29.0.2", AgpCommonExtensionWrapper(libExt).ndkVersion)
        assertEquals("29.0.3", AgpCommonExtensionWrapper(dfExt).ndkVersion)
        assertEquals("29.0.4", AgpCommonExtensionWrapper(testExt).ndkVersion)

        AgpCommonExtensionWrapper(appExt).ndkVersion = "29.0.5"
        verify { appExt.ndkVersion = "29.0.5" }

        AgpCommonExtensionWrapper(libExt).ndkVersion = "29.0.6"
        verify { libExt.ndkVersion = "29.0.6" }

        AgpCommonExtensionWrapper(dfExt).ndkVersion = "29.0.7"
        verify { dfExt.ndkVersion = "29.0.7" }

        AgpCommonExtensionWrapper(testExt).ndkVersion = "29.0.8"
        verify { testExt.ndkVersion = "29.0.8" }
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
    fun `getDefaultProguardFile delegates to application, library, dynamicFeature, and test extensions`() {
        val fileApp = File("/app/proguard.txt")
        val fileLib = File("/lib/proguard.txt")
        val fileDf = File("/df/proguard.txt")
        val fileTest = File("/test/proguard.txt")

        val appExt = mockk<ApplicationExtension>(relaxed = true) { every { getDefaultProguardFile("file.txt") } returns fileApp }
        val libExt = mockk<LibraryExtension>(relaxed = true) { every { getDefaultProguardFile("file.txt") } returns fileLib }
        val dfExt = mockk<DynamicFeatureExtension>(relaxed = true) { every { getDefaultProguardFile("file.txt") } returns fileDf }
        val testExt = mockk<TestExtension>(relaxed = true) { every { getDefaultProguardFile("file.txt") } returns fileTest }

        assertSame(fileApp, AgpCommonExtensionWrapper(appExt).getDefaultProguardFile("file.txt"))
        assertSame(fileLib, AgpCommonExtensionWrapper(libExt).getDefaultProguardFile("file.txt"))
        assertSame(fileDf, AgpCommonExtensionWrapper(dfExt).getDefaultProguardFile("file.txt"))
        assertSame(fileTest, AgpCommonExtensionWrapper(testExt).getDefaultProguardFile("file.txt"))
    }

    @Test
    fun `compileOptions delegates to application, library, dynamicFeature, and test extensions`() {
        val appExt = mockk<ApplicationExtension>(relaxed = true)
        val libExt = mockk<LibraryExtension>(relaxed = true)
        val dfExt = mockk<DynamicFeatureExtension>(relaxed = true)
        val testExt = mockk<TestExtension>(relaxed = true)

        AgpCommonExtensionWrapper(appExt).compileOptions {}
        verify { appExt.compileOptions(any()) }

        AgpCommonExtensionWrapper(libExt).compileOptions {}
        verify { libExt.compileOptions(any()) }

        AgpCommonExtensionWrapper(dfExt).compileOptions {}
        verify { dfExt.compileOptions(any()) }

        AgpCommonExtensionWrapper(testExt).compileOptions {}
        verify { testExt.compileOptions(any()) }
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

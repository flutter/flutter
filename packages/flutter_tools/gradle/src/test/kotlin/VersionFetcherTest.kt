// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.AndroidPluginVersion
import com.android.build.api.variant.AndroidComponentsExtension
import io.mockk.every
import io.mockk.mockk
import org.gradle.api.Project
import org.jetbrains.kotlin.gradle.plugin.KotlinAndroidPluginWrapper
import kotlin.test.Test
import kotlin.test.assertEquals

class VersionFetcherTest {
    // getGradleVersion
    @Test
    fun `getGradleVersion returns version when gradleVersion is set`() {
        val gradleVersion = Version(1, 9, 20)
        val project = mockk<Project>()
        every { project.gradle.gradleVersion } returns gradleVersion.toString()
        assertEquals(VersionFetcher.getGradleVersion(project), gradleVersion)
    }

    @Test
    fun `getGradleVersion returns version when gradleVersion has hyphen`() {
        val project = mockk<Project>()
        every { project.gradle.gradleVersion } returns "2.1.20-2"
        assertEquals(VersionFetcher.getGradleVersion(project), Version(2, 1, 20))
    }

    // getAGPVersion
    @Test
    fun `getAGPVersion returns version when agpVersion is set`() {
        val agpVersion = AndroidPluginVersion(8, 3, 0)
        val project = mockk<Project>()
        val mockAndroidComponentsExtension = mockk<AndroidComponentsExtension<*, *, *>>()
        every { project.extensions.findByType(AndroidComponentsExtension::class.java) } returns mockAndroidComponentsExtension
        every { mockAndroidComponentsExtension.pluginVersion } returns agpVersion
        assertEquals(VersionFetcher.getAGPVersion(project).toString(), agpVersion.toString())
    }

    // getKGPVersion
    @Test
    fun `getKGPVersion returns version when kotlin_version is set`() {
        val kgpVersion = Version(1, 9, 20)
        val project = mockk<Project>()
        every { project.hasProperty(eq("kotlin_version")) } returns true
        every { project.properties["kotlin_version"] } returns kgpVersion.toString()
        val result = VersionFetcher.getKGPVersion(project)
        assertEquals(kgpVersion, result!!)
    }

    @Test
    fun `getKGPVersion returns version from KotlinAndroidPluginWrapper`() {
        val kgpVersion = Version(1, 9, 20)
        val project = mockk<Project>()
        every { project.hasProperty(eq("kotlin_version")) } returns false
        every { project.plugins.findPlugin(KotlinAndroidPluginWrapper::class.java) } returns
            mockk<KotlinAndroidPluginWrapper> {
                every { pluginVersion } returns kgpVersion.toString()
            }
        val result = VersionFetcher.getKGPVersion(project)
        assertEquals(kgpVersion, result!!)
    }

    @Test
    fun `getKGPVersion returns null when the Kotlin Gradle plugin is absent`() {
        // Expected under AGP's built-in Kotlin support, where no standalone KGP is applied.
        val project = mockk<Project>()
        every { project.hasProperty(eq("kotlin_version")) } returns false
        every { project.plugins.findPlugin(KotlinAndroidPluginWrapper::class.java) } returns null
        val result = VersionFetcher.getKGPVersion(project)
        assertEquals(null, result)
    }

    // CompileSdkVersion.isHigherThan
    @Test
    fun `isHigherThan compares numeric api levels numerically`() {
        val sdk35 = CompileSdkVersion(apiLevel = 35, previewCodename = null)
        val sdk36 = CompileSdkVersion(apiLevel = 36, previewCodename = null)
        assertEquals(true, sdk36.isHigherThan(sdk35))
        assertEquals(false, sdk35.isHigherThan(sdk36))
        assertEquals(false, sdk35.isHigherThan(sdk35))
    }

    @Test
    fun `isHigherThan treats a preview codename as higher than any numeric api level`() {
        val preview = CompileSdkVersion(apiLevel = null, previewCodename = "Baklava")
        val numeric = CompileSdkVersion(apiLevel = 36, previewCodename = null)
        assertEquals(true, preview.isHigherThan(numeric))
        assertEquals(false, numeric.isHigherThan(preview))
    }

    @Test
    fun `isHigherThan treats distinct preview codenames as incomparable`() {
        // Codenames stopped being alphabetically ordered at the "Baklava" alphabet reset,
        // so neither side may claim to be higher.
        val baklava = CompileSdkVersion(apiLevel = null, previewCodename = "Baklava")
        val vanilla = CompileSdkVersion(apiLevel = null, previewCodename = "VanillaIceCream")
        assertEquals(false, baklava.isHigherThan(vanilla))
        assertEquals(false, vanilla.isHigherThan(baklava))
        assertEquals(false, baklava.isHigherThan(baklava))
    }

    @Test
    fun `isHigherThan returns false when either side is unset`() {
        val unset = CompileSdkVersion(apiLevel = null, previewCodename = null)
        val numeric = CompileSdkVersion(apiLevel = 36, previewCodename = null)
        assertEquals(false, unset.isHigherThan(numeric))
        assertEquals(false, numeric.isHigherThan(unset))
    }
}

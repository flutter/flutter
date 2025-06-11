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
}

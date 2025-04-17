// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import io.mockk.every
import io.mockk.mockk
import org.gradle.api.Project
import org.jetbrains.kotlin.gradle.plugin.KotlinAndroidPluginWrapper
import kotlin.test.Test
import kotlin.test.assertEquals

class VersionFetcherTest {
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

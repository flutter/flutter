// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.testing

import com.android.build.api.dsl.ApplicationBuildType
import com.android.build.api.dsl.ApplicationExtension
import io.mockk.every
import io.mockk.mockk
import org.gradle.api.NamedDomainObjectContainer
import org.gradle.api.Project

/**
 * Mocks the Android extension for unit tests reading `compileSdk`, `ndkVersion`, or `buildTypes` via the public DSL.
 *
 * Default parameter values (e.g. `compileSdk = 35`, `ndkVersion = "29.0.13846066"`) serve as representative
 * test fixtures reflecting modern AGP project configurations to avoid NPEs when tested logic reads project extensions.
 * In actual generated Flutter projects, these values are populated from template properties.
 *
 * Note: This helper also stubs `project.gradle.startParameter.taskNames` (empty) and
 * `project.gradle.startParameter.isOffline` (`false`) because plugin lifecycle and reflection bridge
 * utilities read Gradle execution parameters during project configuration.
 */
fun setUpMockAndroidExtension(
    project: Project,
    compileSdk: Int? = 35,
    compileSdkPreview: String? = null,
    ndkVersion: String? = "29.0.13846066",
    buildTypes: List<ApplicationBuildType> = emptyList()
): ApplicationExtension {
    val mockAndroidExtension = mockk<ApplicationExtension>()

    every { mockAndroidExtension.compileSdk } returns compileSdk
    every { mockAndroidExtension.compileSdkPreview } returns compileSdkPreview
    if (ndkVersion != null) {
        every { mockAndroidExtension.ndkVersion } returns ndkVersion
    }

    val container = mockk<NamedDomainObjectContainer<ApplicationBuildType>>()
    // A fresh iterator per call: the container is iterated by multiple loops.
    every { container.iterator() } answers { buildTypes.toMutableList().iterator() }
    every { mockAndroidExtension.buildTypes } returns container

    every { project.extensions.findByType(ApplicationExtension::class.java) } returns mockAndroidExtension
    every { project.extensions.findByName("android") } returns mockAndroidExtension

    every { project.gradle.startParameter.taskNames } returns emptyList()
    every { project.gradle.startParameter.isOffline } returns false

    return mockAndroidExtension
}

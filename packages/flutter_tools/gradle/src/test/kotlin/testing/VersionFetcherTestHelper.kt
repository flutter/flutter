package com.flutter.gradle.testing

import io.mockk.every
import io.mockk.mockk
import org.gradle.api.Project
import org.jetbrains.kotlin.gradle.plugin.KotlinBaseApiPlugin

/**
 * Prevent AGP's kotlin version checker from throwing `no answer found`
 *
 * Intended to be called by tests that call `VersionFetcher.getKGPVersion(project)`
 * and who do not care about the internal implementation of
 * `com.android.build.gradle.internal.utils.getKotlinAndroidPluginVersion`
 */
internal fun setAgpKotlinVersionToNull(mockProject: Project) {
    // The internals of `getKotlinAndroidPluginVersion` depend on `getKotlinPluginVersionFromPlugin`
    // which relies on reflection to get the value. Instead make sure fetching the plugin has valid
    // response then rely on the default behavior in `getKotlinPluginVersionFromPlugin` to
    // return null.
    every { mockProject.plugins.findPlugin(any<Class<KotlinBaseApiPlugin>>()) } returns mockk()
    every { mockProject.plugins.findPlugin("kotlin-android") } returns mockk()
}

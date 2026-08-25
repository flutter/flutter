// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.dsl.ApplicationExtension
import org.gradle.api.Project

/**
 * Helper to set the base application name for Android application projects.
 *
 * This is defensive: it only runs when an ApplicationExtension is present
 * (i.e., the project is an Android application). It reads a Gradle property
 * named "base-application-name" if present; otherwise it uses the default
 * value "android.app.Application".
 */
object BaseApplicationNameHandler {
    internal const val DEFAULT_BASE_APPLICATION_NAME: String = "android.app.Application"

    internal const val GRADLE_BASE_APPLICATION_NAME_PROPERTY: String = "base-application-name"

    @JvmStatic
    fun setBaseName(project: Project) {
        // Only set the base application name for Android application projects.
        val androidExtension = project.extensions.findByType(ApplicationExtension::class.java) ?: return

        // Default value
        var baseApplicationName: String = DEFAULT_BASE_APPLICATION_NAME

        // Respect property if set by the Flutter tool or user
        if (project.hasProperty(GRADLE_BASE_APPLICATION_NAME_PROPERTY)) {
            baseApplicationName = project.property(GRADLE_BASE_APPLICATION_NAME_PROPERTY).toString()
        }

        // Ensure manifestPlaceholders map exists and set the applicationName placeholder
        try {
            val placeholders = androidExtension.defaultConfig.manifestPlaceholders
            placeholders["applicationName"] = baseApplicationName
        } catch (t: Throwable) {
            // Be defensive: if the AGP API shape differs, log to stdout but do not fail the build.
            println("Warning: could not set applicationName manifest placeholder: ${t.message}")
        }
    }
}

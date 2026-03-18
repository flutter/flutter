// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.dsl.ApplicationExtension
import org.gradle.api.Project

// TODO(gmackall): maybe migrate this to a package-level function when FGP conversion is done.
object BaseApplicationNameHandler {
    internal const val DEFAULT_BASE_APPLICATION_NAME: String = "android.app.Application"

    internal const val GRADLE_BASE_APPLICATION_NAME_PROPERTY: String = "base-application-name"

    @JvmStatic fun setBaseName(project: Project) {
        val androidExtension =
            project.extensions.findByType(ApplicationExtension::class.java) ?: return

        var baseApplicationName: String = DEFAULT_BASE_APPLICATION_NAME

        if (project.hasProperty(GRADLE_BASE_APPLICATION_NAME_PROPERTY)) {
            baseApplicationName = project.property(GRADLE_BASE_APPLICATION_NAME_PROPERTY).toString()
        }

        @Suppress("UNCHECKED_CAST")
        val commonExtension = androidExtension as? com.android.build.api.dsl.CommonExtension
        commonExtension?.defaultConfig?.manifestPlaceholders?.put("applicationName", baseApplicationName)
    }
}

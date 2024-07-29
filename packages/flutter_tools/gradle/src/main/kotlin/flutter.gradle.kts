// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

apply<FlutterPluginKts>()

class FlutterPluginKts : Plugin<Project> {
    override fun apply(project: Project) {
        val androidExtension = project.extensions.findByType(com.android.build.gradle.AppExtension::class.java)

        androidExtension?.let { android ->
            android.defaultConfig.let { defaultConfig ->
                val baseApplicationName = project.findProperty("base-application-name")?.toString() ?: "android.app.Application"
                defaultConfig.manifestPlaceholders["applicationName"] = baseApplicationName
            }
        }
    }
}

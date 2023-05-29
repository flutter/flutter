// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import org.gradle.api.Project
import org.gradle.api.Plugin
import com.android.build.api.variant.AndroidComponentsExtension
import org.gradle.api.tasks.Copy


class FlutterPluginKts : Plugin<Project> {
    override fun apply(project: Project) {
        // From https://developer.android.com/build/extend-agp
//        val androidComponents = project.extensions.getByType(AndroidComponentsExtension::class.java)
//        androidComponents.finalizeDsl { extension ->
//            extension.defaultConfig {
//                if (project.hasProperty("multidex-enabled") &&
//                        project.property("multidex-enabled").toString().toBoolean()) {
//                    multiDexEnabled = true
//                    manifestPlaceholders["applicationName"] = "io.flutter.app.FlutterMultiDexApplication"
//                } else {
//                    var baseApplicationName: String = "android.app.Application"
//                    if (project.hasProperty("base-application-name")) {
//                        baseApplicationName = project.property("base-application-name").toString()
//                    }
//                    // Setting to android.app.Application is the same as omitting the attribute.
//                    manifestPlaceholders["applicationName"] = baseApplicationName
//                }
//
//                it.multiDexEnabled = true
//            }
//        }
    }
}

// apply<FlutterPluginKts>()
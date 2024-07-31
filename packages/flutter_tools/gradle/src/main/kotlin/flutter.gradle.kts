// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This buildscript block supplies dependencies for this file's own import
// declarations above. It exists solely for compatibility with projects that
// have not migrated to declaratively apply the Flutter Gradle Plugin;
// for those that have, FGP's `build.gradle.kts`  takes care of this.
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // When bumping, also update:
        //  * ndkVersion in FlutterExtension in packages/flutter_tools/gradle/src/main/groovy/flutter.groovy
        //  * AGP version in the buildscript block in packages/flutter_tools/gradle/src/main/kotlin/dependency_version_checker.gradle.kts
        //  * AGP version constants in packages/flutter_tools/lib/src/android/gradle_utils.dart
        //  * AGP version in dependencies block in packages/flutter_tools/gradle/build.gradle.kts
        classpath("com.android.tools.build:gradle:7.3.0")
    }
}

apply<FlutterPluginKts>()

class FlutterPluginKts : Plugin<Project> {
    override fun apply(project: Project) {
        // Attempt to find the extension using CommonExtension.
        var androidExtension = project.extensions.findByType(com.android.build.api.dsl.CommonExtension::class.java)

        // Delegate to the legacy method of using Groovy dynamic dispatch if we can't find the
        // android extension.
        if (androidExtension == null || androidExtension.defaultConfig == null) {
            delegateToLegacyGroovyBuilder(project)
            return
        }
        val baseApplicationName = project.findProperty("base-application-name")?.toString() ?: "android.app.Application"
        androidExtension.let { android ->
            android.defaultConfig!!.manifestPlaceholders["applicationName"] = baseApplicationName
        }
    }

    // Use Groovy dynamic dispatch when we can't find the android extension by it's common type.
    // For some reason, despite the internal AGP class BaseAppModuleExtension (eventually) implementing
    // CommonExtension, a decorated (presumably generated) version of that classs
    // (BaseAppModuleExtension_decorated) doesn't do the same.
    fun delegateToLegacyGroovyBuilder(project: Project) {
        // Use withGroovyBuilder and getProperty() to access Groovy metaprogramming.
        project.withGroovyBuilder {
            getProperty("android").withGroovyBuilder {
                getProperty("defaultConfig").withGroovyBuilder {
                    var baseApplicationName: String = "android.app.Application"
                    if (project.hasProperty("base-application-name")) {
                        baseApplicationName = project.property("base-application-name").toString()
                    }
                    // Setting to android.app.Application is the same as omitting the attribute.
                    getProperty("manifestPlaceholders").withGroovyBuilder {
                        setProperty("applicationName", baseApplicationName)
                    }
                }
            }
        }
    }
}

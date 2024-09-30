package com.flutter.gradle

import com.android.build.api.dsl.ApplicationExtension
import org.gradle.api.Project

// TODO(gmackall): maybe migrate this to a package-level function when FGP conversion is done.
class BaseApplicationNameHandler {
    companion object {
        @JvmStatic fun setBaseName(project: Project) {
            val androidComponentsExtension: ApplicationExtension = project.extensions.getByType(ApplicationExtension::class.java)
            androidComponentsExtension.defaultConfig.applicationId

            // Setting to android.app.Application is the same as omitting the attribute.
            var baseApplicationName: String = "android.app.Application"
            if (project.hasProperty("base-application-name")) {
                baseApplicationName = project.property("base-application-name").toString()
            }

            androidComponentsExtension.defaultConfig.manifestPlaceholders["applicationName"] =
                baseApplicationName
        }
    }
}

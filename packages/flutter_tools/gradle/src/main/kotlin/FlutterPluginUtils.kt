package com.flutter.gradle

import org.gradle.api.Project
import java.util.Locale

object FlutterPluginUtils {
    // TODO docs
    @JvmStatic fun shouldShrinkResources(project: Project): Boolean {
        val propShrink = "shrink"
        if (project.hasProperty(propShrink)) {
            val propertyValue = project.property(propShrink)
            return propertyValue.toString().toBoolean()
        }
        return true
    }

    @JvmStatic fun toCamelCase(parts: List<String>): String {
        if (parts.isEmpty()) {
            return ""
        }
        return parts[0] +
            parts.drop(1).joinToString("") { FlutterPluginUtils.capitalize(it) }
    }

    // Kotlin's capitalize function is deprecated. This is the suggested replacement.
    @JvmStatic internal fun capitalize(string: String): String =
        string.replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.getDefault()) else it.toString() }
}

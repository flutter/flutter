package com.flutter.gradle

import org.gradle.api.Project
import org.gradle.api.logging.Logger
import org.gradle.api.logging.Logging
import org.gradle.kotlin.dsl.*
import org.gradle.api.file.CopySpec
import org.gradle.process.ExecSpec

/**
 * PluginHandler for configuring Flutter-related Gradle behavior.
 *
 * This implementation is intentionally conservative:
 *  - avoids relying on fragile Kotlin-DSL inference by using explicit types where helpful
 *  - provides a small, well-typed helper (buildModeFor) used by other build code
 *  - exposes a simple factory method for easy usage from build scripts
 *
 * Place this file at:
 *  C:\src\flutter\packages\flutter_tools\gradle\src\main\kotlin\plugins\PluginHandler.kt
 *
 * Adjust package or class name if your project expects a different layout.
 */
class PluginHandler(private val project: Project) {

    private val logger: Logger = Logging.getLogger(PluginHandler::class.java)

    /**
     * Configure plugin-related behavior for the given project.
     * Keep this method idempotent and side-effect safe.
     */
    fun configure() {
        logger.info("Configuring Flutter plugin handler for project: ${project.path}")

        // Example safe checks / configuration hooks.
        if (project.plugins.hasPlugin("com.android.application") || project.plugins.hasPlugin("com.android.library")) {
            logger.info("Android plugin detected in ${project.path}")
            configureAndroidProject(project)
        } else {
            logger.debug("No Android plugin detected in ${project.path}")
        }
    }

    private fun configureAndroidProject(project: Project) {
        // Example: add a simple task or configuration only if needed.
        // Keep this minimal to avoid surprising side effects.
        project.tasks.register("flutterPluginInfo") { task ->
            task.group = "flutter"
            task.description = "Prints basic Flutter plugin information for ${project.path}"
            task.doLast {
                logger.lifecycle("Flutter plugin configured for project: ${project.path}")
            }
        }
    }

    /**
     * Determine a canonical Flutter build mode string for a given variant or build type name.
     *
     * Normalizes common variant/build-type names to the Flutter build modes:
     * "debug", "profile", "release".
     *
     * @param variantOrBuildType the variant name or build type (e.g., "debug", "release", "profile", "stagingRelease")
     * @return one of "debug", "profile", or "release"
     */
    fun buildModeFor(variantOrBuildType: String): String {
        val normalized = variantOrBuildType.trim().lowercase()
        return when {
            normalized.contains("debug") -> "debug"
            normalized.contains("profile") -> "profile"
            normalized.contains("release") -> "release"
            else -> "release"
        }
    }

    companion object {
        /**
         * Convenience factory to create and configure a PluginHandler for a project.
         *
         * Example usage from build scripts:
         * PluginHandler.applyTo(project)
         */
        @JvmStatic
        fun applyTo(project: Project) {
            PluginHandler(project).configure()
        }
    }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import com.flutter.gradle.FlutterPluginUtils
import com.flutter.gradle.VersionUtils
import org.gradle.api.DefaultTask
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.logging.Logger
import org.gradle.api.provider.MapProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.Internal
import org.gradle.api.tasks.TaskAction
import java.io.File

/**
 * Task to validate that the project's compileSdkVersion and ndkVersion are not lower than
 * those required by any of the plugins.
 *
 * This version is defensive about nulls and uses the helper utilities from
 * the com.flutter.gradle package (FlutterPluginUtils and VersionUtils).
 */
abstract class ValidateCompileSdkVersionTask : DefaultTask() {
    @get:Input
    abstract val projectCompileSdk: Property<Int>

    @get:Input
    abstract val projectNdkVersion: Property<String>

    @get:Input
    abstract val pluginCompileSdks: MapProperty<String, Int>

    @get:Input
    abstract val pluginNdkVersions: MapProperty<String, String>

    @get:Internal
    abstract val projectDir: DirectoryProperty

    @TaskAction
    fun run() {
        // Use safe getters to avoid throwing if properties are not configured.
        val projSdk = try { projectCompileSdk.get() } catch (_: Throwable) { -1 }
        val projNdk = try { projectNdkVersion.get() } catch (_: Throwable) { "" }
        val pluginSdks = try { pluginCompileSdks.get() } catch (_: Throwable) { emptyMap() }
        val pluginNdks = try { pluginNdkVersions.get() } catch (_: Throwable) { emptyMap() }
        val projDir = try { projectDir.get().asFile } catch (_: Throwable) { project.projectDir }

        performValidation(
            projSdk = projSdk,
            projNdk = projNdk,
            pluginCompileSdks = pluginSdks,
            pluginNdkVersions = pluginNdks,
            logger = logger,
            projectDir = projDir
        )
    }

    companion object {
        internal fun performValidation(
            projSdk: Int,
            projNdk: String,
            pluginCompileSdks: Map<String, Int>,
            pluginNdkVersions: Map<String, String>,
            logger: Logger,
            projectDir: File
        ) {
            // If project SDK is not set or invalid, bail out early with a warning.
            if (projSdk <= 0) {
                logger.warn("Project compileSdk not configured or invalid; skipping plugin compileSdk validation.")
                return
            }

            var maxPluginCompileSdkVersion = projSdk
            var maxPluginNdkVersion = projNdk

            val pluginsWithHigherSdkVersion = mutableListOf<PluginVersionPair>()
            val pluginsWithDifferentNdkVersion = mutableListOf<PluginVersionPair>()

            // Determine highest compileSdk required by plugins and collect those that require higher.
            pluginCompileSdks.forEach { (name, sdk) ->
                try {
                    maxPluginCompileSdkVersion = maxOf(maxPluginCompileSdkVersion, sdk)
                    if (sdk > projSdk) {
                        pluginsWithHigherSdkVersion.add(PluginVersionPair(name, sdk.toString()))
                    }
                } catch (t: Throwable) {
                    logger.warn("Could not evaluate compileSdk for plugin $name: ${t.message}")
                }
            }

            // Determine most recent NDK version among plugins and collect those that differ.
            pluginNdkVersions.forEach { (name, ndk) ->
                try {
                    maxPluginNdkVersion = VersionUtils.mostRecentSemanticVersion(ndk, maxPluginNdkVersion)
                    if (ndk != projNdk) {
                        pluginsWithDifferentNdkVersion.add(PluginVersionPair(name, ndk))
                    }
                } catch (t: Throwable) {
                    logger.warn("Could not evaluate ndkVersion for plugin $name: ${t.message}")
                }
            }

            if (maxPluginCompileSdkVersion > projSdk) {
                logPluginCompileSdkWarnings(
                    maxPluginCompileSdkVersion = maxPluginCompileSdkVersion,
                    projectCompileSdkVersion = projSdk,
                    logger = logger,
                    pluginsWithHigherSdkVersion = pluginsWithHigherSdkVersion,
                    projectDirectory = projectDir
                )
            }

            if (maxPluginNdkVersion.isNotEmpty() && maxPluginNdkVersion != projNdk) {
                logPluginNdkWarnings(
                    maxPluginNdkVersion = maxPluginNdkVersion,
                    projectNdkVersion = projNdk,
                    logger = logger,
                    pluginsWithDifferentNdkVersion = pluginsWithDifferentNdkVersion,
                    projectDirectory = projectDir
                )
            }
        }

        private fun logPluginCompileSdkWarnings(
            maxPluginCompileSdkVersion: Int,
            projectCompileSdkVersion: Int,
            logger: Logger,
            pluginsWithHigherSdkVersion: List<PluginVersionPair>,
            projectDirectory: File
        ) {
            logger.error(
                "Your project is configured to compile against Android SDK $projectCompileSdkVersion, but the following plugin(s) require to be compiled against a higher Android SDK version:"
            )
            for (pluginToCompileSdkVersion in pluginsWithHigherSdkVersion) {
                logger.error(
                    "- ${pluginToCompileSdkVersion.name} compiles against Android SDK ${pluginToCompileSdkVersion.version}"
                )
            }

            val buildGradleFile = try {
                FlutterPluginUtils.getBuildGradleFileFromProjectDir(projectDirectory, logger)
            } catch (t: Throwable) {
                logger.warn("Could not locate build.gradle file: ${t.message}")
                null
            }

            val buildGradlePath = buildGradleFile?.path ?: File(projectDirectory, "build.gradle").path

            logger.error(
                """
                Fix this issue by compiling against the highest Android SDK version (they are backward compatible).
                Add the following to $buildGradlePath:
                
                    android {
                        compileSdk = $maxPluginCompileSdkVersion
                        ...
                    }
                """.trimIndent()
            )
        }

        private fun logPluginNdkWarnings(
            maxPluginNdkVersion: String,
            projectNdkVersion: String,
            logger: Logger,
            pluginsWithDifferentNdkVersion: List<PluginVersionPair>,
            projectDirectory: File
        ) {
            logger.error(
                "Your project is configured with Android NDK $projectNdkVersion, but the following plugin(s) depend on a different Android NDK version:"
            )
            for (pluginToNdkVersion in pluginsWithDifferentNdkVersion) {
                logger.error("- ${pluginToNdkVersion.name} requires Android NDK ${pluginToNdkVersion.version}")
            }

            val buildGradleFile = try {
                FlutterPluginUtils.getBuildGradleFileFromProjectDir(projectDirectory, logger)
            } catch (t: Throwable) {
                logger.warn("Could not locate build.gradle file: ${t.message}")
                null
            }

            val buildGradlePath = buildGradleFile?.path ?: File(projectDirectory, "build.gradle").path

            logger.error(
                """
                Fix this issue by using the highest Android NDK version (they are backward compatible).
                Add the following to $buildGradlePath:
                
                    android {
                        ndkVersion = "$maxPluginNdkVersion"
                        ...
                    }
                """.trimIndent()
            )
        }
    }
}

private data class PluginVersionPair(
    val name: String,
    val version: String
)

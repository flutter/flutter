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
        performValidation(
            projSdk = projectCompileSdk.get(),
            projNdk = projectNdkVersion.get(),
            pluginCompileSdks = pluginCompileSdks.get(),
            pluginNdkVersions = pluginNdkVersions.get(),
            logger = logger,
            projectDir = projectDir.get().asFile
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
            var maxPluginCompileSdkVersion = projSdk
            var maxPluginNdkVersion = projNdk

            val pluginsWithHigherSdkVersion = mutableListOf<PluginVersionPair>()
            val pluginsWithDifferentNdkVersion = mutableListOf<PluginVersionPair>()

            pluginCompileSdks.forEach { (name, sdk) ->
                maxPluginCompileSdkVersion = maxOf(maxPluginCompileSdkVersion, sdk)
                if (sdk > projSdk) {
                    pluginsWithHigherSdkVersion.add(PluginVersionPair(name, sdk.toString()))
                }
            }

            pluginNdkVersions.forEach { (name, ndk) ->
                maxPluginNdkVersion = VersionUtils.mostRecentSemanticVersion(ndk, maxPluginNdkVersion)
                if (ndk != projNdk) {
                    pluginsWithDifferentNdkVersion.add(PluginVersionPair(name, ndk))
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

            if (maxPluginNdkVersion != projNdk) {
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
            val buildGradleFile =
                FlutterPluginUtils.getBuildGradleFileFromProjectDir(
                    projectDirectory,
                    logger
                )
            logger.error(
                """
                Fix this issue by compiling against the highest Android SDK version (they are backward compatible).
                Add the following to ${buildGradleFile.path}:
                
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
            val buildGradleFile =
                FlutterPluginUtils.getBuildGradleFileFromProjectDir(
                    projectDirectory,
                    logger
                )
            logger.error(
                """
                Fix this issue by using the highest Android NDK version (they are backward compatible).
                Add the following to ${buildGradleFile.path}:
                
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

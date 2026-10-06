// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import com.flutter.gradle.CompileSdkLocation
import com.flutter.gradle.CompileSdkLocator
import com.flutter.gradle.CompileSdkVersion
import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.provider.MapProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.Internal
import org.gradle.api.tasks.Optional
import org.gradle.api.tasks.TaskAction
import java.io.File

/**
 * Add-to-app only: fails the build with an actionable message when the native Android host app
 * compiles against a lower Android SDK than one of the Flutter AARs (the Flutter module or a
 * Flutter plugin) it depends on.
 *
 * Starting with AGP 9, an app must use a compileSdk that is the same or higher than the
 * `minCompileSdk` recorded in every AAR it consumes, and AGP fails `check<Variant>AarMetadata`
 * otherwise. This task runs before that check so users see which host app, which Flutter AARs,
 * and which file to edit.
 */
abstract class ValidateHostAppCompileSdkTask : DefaultTask() {
    /** Gradle path of the host app project, e.g. `:app`. */
    @get:Input
    abstract val hostProjectPath: Property<String>

    /** The host app's numeric compileSdk, if configured. */
    @get:Input
    @get:Optional
    abstract val hostCompileSdk: Property<Int>

    /** The host app's compileSdkPreview codename, if configured. */
    @get:Input
    @get:Optional
    abstract val hostCompileSdkPreview: Property<String>

    /** Gradle project path of each Flutter AAR -> the `minCompileSdk` it requires of consumers. */
    @get:Input
    abstract val flutterAarMinCompileSdks: MapProperty<String, Int>

    /** Gradle project path of each Flutter AAR -> description, e.g. `Flutter plugin AAR "camera"`. */
    @get:Internal
    abstract val flutterAarDescriptions: MapProperty<String, String>

    /** Gradle project path of each Flutter AAR -> its project directory. */
    @get:Internal
    abstract val flutterAarDirectories: MapProperty<String, String>

    /** Absolute path of the host app's project directory. Used only in messages. */
    @get:Internal
    abstract val hostProjectDir: Property<String>

    /** Absolute path of the host app's build script. Used only in messages. */
    @get:Internal
    abstract val hostBuildFile: Property<String>

    /** Absolute path of the root project directory, used to find the version catalog. */
    @get:Internal
    abstract val rootDir: Property<String>

    @TaskAction
    fun run() {
        val descriptions = flutterAarDescriptions.get()
        val directories = flutterAarDirectories.get()
        performValidation(
            hostApp =
                HostApp(
                    projectPath = hostProjectPath.get(),
                    projectDir = File(hostProjectDir.get()),
                    buildFile = File(hostBuildFile.get()),
                    rootDir = File(rootDir.get()),
                    compileSdk =
                        CompileSdkVersion(
                            apiLevel = if (hostCompileSdkPreview.isPresent) null else hostCompileSdk.orNull,
                            previewCodename = hostCompileSdkPreview.orNull
                        )
                ),
            flutterAars =
                flutterAarMinCompileSdks.get().map { (path, minCompileSdk) ->
                    FlutterAar(
                        projectPath = path,
                        description = descriptions[path] ?: "Flutter AAR",
                        projectDir = directories[path]?.let(::File),
                        minCompileSdk = minCompileSdk
                    )
                }
        )
    }

    /** The native Android host app that consumes the Flutter AARs. */
    internal data class HostApp(
        val projectPath: String,
        val projectDir: File,
        val buildFile: File,
        val rootDir: File,
        val compileSdk: CompileSdkVersion
    )

    /** A Flutter module or Flutter plugin library consumed by the host app as an AAR. */
    internal data class FlutterAar(
        val projectPath: String,
        val description: String,
        val projectDir: File?,
        val minCompileSdk: Int
    )

    companion object {
        const val TASK_NAME = "validateHostAppCompileSdk"

        /**
         * Stable prefix of the error message. The `flutter` tool looks for this to avoid printing
         * a second, less specific message for the same failure.
         */
        const val ERROR_MARKER = "[Flutter] Your Android host app's compileSdk"

        private const val ADD_TO_APP_DOCS_URL = "https://docs.flutter.dev/add-to-app/android/project-setup"

        /** Throws a [GradleException] if [hostApp] compiles against a lower SDK than any of [flutterAars]. */
        internal fun performValidation(
            hostApp: HostApp,
            flutterAars: List<FlutterAar>
        ) {
            // A preview codename targets an unreleased SDK, which satisfies any numeric requirement.
            // If the compileSdk is unknown, let AGP report the problem.
            if (hostApp.compileSdk.previewCodename != null) {
                return
            }
            val hostApiLevel = hostApp.compileSdk.apiLevel ?: return
            val violations =
                flutterAars
                    .filter { it.minCompileSdk > hostApiLevel }
                    .sortedWith(compareByDescending<FlutterAar> { it.minCompileSdk }.thenBy { it.projectPath })
            if (violations.isEmpty()) {
                return
            }
            val location = CompileSdkLocator.locate(hostApp.buildFile, hostApp.rootDir)
            throw GradleException(buildErrorMessage(hostApp, hostApiLevel, violations, location))
        }

        internal fun buildErrorMessage(
            hostApp: HostApp,
            hostApiLevel: Int,
            violations: List<FlutterAar>,
            location: CompileSdkLocation
        ): String {
            val required = violations.maxOf { it.minCompileSdk }
            return buildString {
                appendLine(
                    "$ERROR_MARKER ($hostApiLevel) is lower than the compileSdk required by its Flutter AARs ($required)."
                )
                appendLine()
                appendLine("Starting with Android Gradle Plugin (AGP) 9, an Android app must use a compileSdk that is the")
                appendLine("same or higher than the compileSdk of every Android library (AAR) it depends on.")
                appendLine()
                appendLine("Android host app")
                appendLine("  Gradle project : ${hostApp.projectPath}")
                appendLine("  Directory      : ${hostApp.projectDir.path}")
                appendLine("  compileSdk     : $hostApiLevel")
                appendLine("  Declared in    : ${describeLocation(location)}")
                appendLine()
                appendLine("Flutter AARs that require a higher compileSdk")
                for (aar in violations) {
                    appendLine("  - ${aar.description}")
                    appendLine("      Gradle project : ${aar.projectPath}")
                    if (aar.projectDir != null) {
                        appendLine("      Directory      : ${aar.projectDir.path}")
                    }
                    appendLine("      Requires       : compileSdk ${aar.minCompileSdk} or higher")
                }
                appendLine()
                appendLine("How to fix")
                append(describeFix(location, required))
                appendLine()
                appendLine("  Raising compileSdk does not change your app's targetSdk (runtime behavior) or")
                appendLine("  minSdk (supported devices).")
                append("  Learn more: $ADD_TO_APP_DOCS_URL")
            }
        }

        private fun describeLocation(location: CompileSdkLocation): String =
            when (location) {
                is CompileSdkLocation.BuildFile -> "${location.file.path}:${location.line}"
                is CompileSdkLocation.VersionCatalog ->
                    "${location.file.path}:${location.line} " +
                        "(key \"${location.key}\", referenced from ${location.referencedFrom.path}:${location.referencedFromLine})"
                is CompileSdkLocation.Unresolved ->
                    if (location.line != null) {
                        "${location.file.path}:${location.line} via \"${location.expression}\""
                    } else {
                        "not found in ${location.file.path} " +
                            "(it may be set by a convention plugin, buildSrc, or another build script)"
                    }
            }

        private fun describeFix(
            location: CompileSdkLocation,
            required: Int
        ): String =
            when (location) {
                is CompileSdkLocation.VersionCatalog ->
                    """
                    |  Raise "${location.key}" to at least $required in ${location.file.path}:
                    |
                    |      [versions]
                    |      ${location.key} = "$required"
                    |
                    """.trimMargin()
                is CompileSdkLocation.BuildFile ->
                    """
                    |  Raise the host app's compileSdk to at least $required in ${location.file.path}:
                    |
                    |      android {
                    |          compileSdk = $required
                    |      }
                    |
                    """.trimMargin()
                is CompileSdkLocation.Unresolved ->
                    """
                    |  Raise the host app's compileSdk to at least $required where it is defined
                    |  (for example ${location.file.path}, the root build script, buildSrc, or a convention plugin):
                    |
                    |      android {
                    |          compileSdk = $required
                    |      }
                    |
                    """.trimMargin()
            }
    }
}

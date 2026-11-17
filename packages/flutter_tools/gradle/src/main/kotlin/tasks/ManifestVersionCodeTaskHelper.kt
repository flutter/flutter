// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import com.android.build.api.variant.ApplicationVariant
import com.flutter.gradle.FlutterPluginConstants
import com.flutter.gradle.FlutterPluginUtils
import org.gradle.api.Project
import org.gradle.api.provider.Provider
import org.xml.sax.SAXException
import java.io.File
import java.io.IOException
import javax.xml.parsers.DocumentBuilderFactory

/**
 * Reads `android:versionCode` from the main `AndroidManifest.xml` for `--split-per-abi` builds
 * that do not set `versionCode` in the `android {}` block.
 *
 * This matches AGP's fallback behavior. When the DSL omits `versionCode`, AGP reads it only from
 * the main source set's manifest (`src/main/AndroidManifest.xml` by default) and ignores
 * build-type, flavor, and generated manifests. If the main manifest sets a positive integer, AGP
 * injects that value into the merged manifest over any overlay manifest.
 *
 * Kept separate from [ManifestVersionCodeTask] so unit tests can call [readVersionCode] directly.
 */
object ManifestVersionCodeTaskHelper {
    private const val ANDROID_NAMESPACE = "http://schemas.android.com/apk/res/android"

    /** Outcome of reading `android:versionCode` with [readVersionCode]. */
    sealed interface Result {
        /** A positive integer [versionCode] read from the main manifest. */
        data class Found(
            val versionCode: Int
        ) : Result

        /** The main manifest did not provide a valid `versionCode`; [reason] explains why. */
        data class NotFound(
            val reason: String
        ) : Result
    }

    /**
     * Registers a [ManifestVersionCodeTask] for [variant] and returns a lazy [Provider] for the
     * parsed `versionCode`.
     *
     * No manifest file is read during configuration. Any task that consumes the returned provider
     * automatically runs after [ManifestVersionCodeTask].
     */
    internal fun registerTask(
        project: Project,
        variant: ApplicationVariant
    ): Provider<Int> {
        val task =
            project.tasks.register(
                "resolveManifestVersionCode${FlutterPluginUtils.capitalize(variant.name)}",
                ManifestVersionCodeTask::class.java
            ) {
                // AGP's Variant API has no direct getter for the main manifest. ManifestFiles.all
                // orders sources from highest to lowest priority (generated, overlays, then main;
                // AGP itself gets overlays with all.dropLast(1)), so last() is the main manifest.
                // Using map keeps this lazy because manifests.all can contain other tasks' outputs.
                mainManifest.set(
                    variant.sources.manifests.all
                        .map { it.last() }
                )
                variantName.set(variant.name)
                // Internal output read only by the provider below, not by AGP. Keep this outside
                // intermediates/flutter/<variant>/ because FlutterTask claims that directory as an
                // @OutputDirectory, and overlapping outputs disable Gradle caching.
                versionCodeFile.set(
                    project.layout.buildDirectory.file(
                        "${FlutterPluginConstants.INTERMEDIATES_DIR}/flutter_manifest_version_code/" +
                            "${variant.name}/version_code.txt"
                    )
                )
            }
        // Map through task.flatMap (not providers.fileContents, which drops task dependencies)
        // so wiring this provider into output.versionCode runs this task before AGP's manifest
        // task.
        return task.flatMap { it.versionCodeFile }.map { it.asFile.readText().toInt() }
    }

    /**
     * Reads the `android:versionCode` attribute from [manifest]'s root `<manifest>` element.
     *
     * For example, `<manifest xmlns:android="http://schemas.android.com/apk/res/android"
     * android:versionCode="7">` returns `Result.Found(7)`. Returns [Result.NotFound] if the file
     * cannot be read or parsed, omits `android:versionCode`, uses a placeholder such as
     * `${versionCode}`, or sets a value `<= 0`. AGP ignores values `<= 0` and Google Play rejects
     * them.
     */
    internal fun readVersionCode(manifest: File): Result {
        val root =
            try {
                parse(manifest).documentElement
            } catch (e: SAXException) {
                return Result.NotFound("$manifest could not be parsed (${e.message})")
            } catch (e: IOException) {
                return Result.NotFound("$manifest could not be read (${e.message})")
            }
        val value = root.getAttributeNS(ANDROID_NAMESPACE, "versionCode").trim()
        val versionCode = value.toIntOrNull()
        return when {
            value.isEmpty() -> Result.NotFound("$manifest does not set android:versionCode")
            versionCode == null -> Result.NotFound("android:versionCode=\"$value\" in $manifest is not an integer")
            versionCode <= 0 -> Result.NotFound("android:versionCode=\"$value\" in $manifest is not positive")
            else -> Result.Found(versionCode)
        }
    }

    private fun parse(manifest: File) =
        DocumentBuilderFactory
            .newInstance()
            .apply {
                // Match android:versionCode by namespace URI so custom prefixes (such as
                // xmlns:a="...") still resolve.
                isNamespaceAware = true
                // Reject <!DOCTYPE> declarations to block XML external entity (XXE) reads and
                // entity-expansion bombs. Android manifests never use DOCTYPE.
                setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)
            }.newDocumentBuilder()
            .apply {
                // Suppress Xerces's default "[Fatal Error]" stderr output on malformed XML;
                // readVersionCode catches SAXException and reports the failure instead.
                setErrorHandler(null)
            }.parse(manifest)

    /**
     * Formats the `--split-per-abi` error for [variantName] when `android {}` omits `versionCode`
     * and reading the main manifest fails ([reason]).
     */
    internal fun errorMessage(
        variantName: String,
        reason: String
    ): String =
        "Flutter cannot give each split APK of variant '$variantName' a distinct " +
            "versionCode: its android {} block sets no versionCode, and $reason. " +
            "Google Play does not accept split APKs that share a versionCode. Set " +
            "versionCode = flutter.versionCode in defaultConfig (or on each product " +
            "flavor), or pass -P ${FlutterPluginUtils.PROP_FORCE_VERSION_CODE_IGNORING_ABI}=true to keep one versionCode."
}

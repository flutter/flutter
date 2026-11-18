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
                // AGP's Variant API has no direct getter for the main manifest; see
                // `manifestOverlayFiles` in AGP's `SourcesImpl.kt` for `manifests.all` ordering:
                // https://android.googlesource.com/platform/tools/base/+/refs/heads/mirror-goog-studio-main/build-system/gradle-core/src/main/java/com/android/build/api/variant/impl/SourcesImpl.kt
                // Using `map` keeps this lazy because `manifests.all` can contain task outputs.
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
     * Returns [Result.Found] when `android:versionCode` is a positive 32-bit decimal integer (for
     * example, `android:versionCode="7"` returns `Result.Found(7)`). Returns [Result.NotFound]
     * otherwise, including when [manifest] cannot be read, omits `android:versionCode`, or uses a
     * placeholder such as `${versionCode}`.
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
        // Reject non-decimal values (${versionCode}, @integer/..., 0x10) and values <= 0 to match
        // AGP. When the DSL omits versionCode, AGP's ManifestData parser runs Integer.parseInt on
        // the raw main manifest before ProcessApplicationManifest replaces manifestPlaceholders.
        // AGP also ignores values <= 0, and Google Play rejects them. Reading
        // SingleArtifact.MERGED_MANIFEST instead would create a task cycle because
        // ProcessApplicationManifest takes VariantOutput.versionCode as an input.
        //
        // Parse as a BigInteger so values outside the Int range get a specific reason. Strip a
        // leading + first: Integer.parseInt (and so AGP) accepts it, but toBigIntegerOrNull() does
        // not. Reject "+-7" before stripping, or it would parse as -7.
        val versionCode = value.takeUnless { it.startsWith("+-") }?.removePrefix("+")?.toBigIntegerOrNull()
        return when {
            value.isEmpty() -> Result.NotFound("$manifest does not set android:versionCode")
            versionCode == null -> Result.NotFound("android:versionCode=\"$value\" in $manifest is not a decimal integer")
            versionCode.signum() <= 0 -> Result.NotFound("android:versionCode=\"$value\" in $manifest is not positive")
            versionCode > Int.MAX_VALUE.toBigInteger() ->
                Result.NotFound("android:versionCode=\"$value\" in $manifest is larger than ${Int.MAX_VALUE}")
            else -> Result.Found(versionCode.toInt())
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
     *
     * Used with and without `force-version-code-ignoring-abi`, so it does not suggest that flag.
     * Without a positive `versionCode`, AGP builds APKs with no `versionCode`, which Android reads
     * as 0. Such an APK installs on a device that does not have the app, but Google Play rejects
     * it, and installing it over a build with a positive `versionCode` fails with
     * `INSTALL_FAILED_VERSION_DOWNGRADE`.
     */
    internal fun errorMessage(
        variantName: String,
        reason: String
    ): String =
        "Flutter cannot give the split APKs of variant '$variantName' a versionCode: its " +
            "android {} block sets no versionCode, and $reason. Android reads an APK without a " +
            "versionCode as versionCode 0. Google Play rejects such APKs, and they cannot be " +
            "installed over a build of the app that has a versionCode. Set " +
            "versionCode = flutter.versionCode in defaultConfig (or on each product flavor)."
}

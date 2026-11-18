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
 * that omit `versionCode` in the `android {}` block.
 *
 * Matches AGP's fallback: when the DSL omits `versionCode`, AGP reads only the main source set's
 * manifest (`src/main/AndroidManifest.xml` by default) and ignores build-type, flavor, and
 * generated manifests.
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
     * Registers a [ManifestVersionCodeTask] for [variant] and returns the main manifest's
     * `versionCode` as a [Provider].
     *
     * Tasks that consume the returned provider run after [ManifestVersionCodeTask].
     */
    internal fun registerTask(
        project: Project,
        variant: ApplicationVariant
    ): Provider<Int> {
        // Use a task rather than a Provider transform so Gradle resolves `mainManifest` only at
        // execution time, after any manifest-generating tasks in `manifests.all` have run.
        val task =
            project.tasks.register(
                "resolveManifestVersionCode${FlutterPluginUtils.capitalize(variant.name)}",
                ManifestVersionCodeTask::class.java
            ) {
                // AGP's Variant API has no direct getter for the main manifest; `manifests.all`
                // puts it last (see `manifestOverlayFiles` in AGP's `SourcesImpl.kt`):
                // https://android.googlesource.com/platform/tools/base/+/refs/heads/mirror-goog-studio-main/build-system/gradle-core/src/main/java/com/android/build/api/variant/impl/SourcesImpl.kt
                // Using `map` keeps this lazy while `manifests.all` has unbuilt task outputs.
                mainManifest.set(
                    variant.sources.manifests.all
                        .map { it.last() }
                )
                variantName.set(variant.name)
                // Keep outside intermediates/flutter/<variant>/, which FlutterTask claims as an
                // @OutputDirectory; overlapping task outputs disable Gradle caching.
                versionCodeFile.set(
                    project.layout.buildDirectory.file(
                        "${FlutterPluginConstants.INTERMEDIATES_DIR}/flutter_manifest_version_code/" +
                            "${variant.name}/version_code.txt"
                    )
                )
            }
        // task.flatMap preserves the task dependency (unlike providers.fileContents) so AGP's
        // manifest task runs ManifestVersionCodeTask first.
        return task.flatMap { it.versionCodeFile }.map { it.asFile.readText().toInt() }
    }

    /**
     * Reads `android:versionCode` from [manifest]'s root `<manifest>` element.
     *
     * Returns [Result.Found] if the attribute is a positive 32-bit decimal integer, or
     * [Result.NotFound] otherwise (for example, if [manifest] cannot be read, omits
     * `android:versionCode`, or uses a placeholder such as `${versionCode}`).
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
        // Match AGP's ManifestData parser, which runs Integer.parseInt on the raw main manifest
        // (before manifestPlaceholders substitution) and ignores values <= 0. Reading
        // SingleArtifact.MERGED_MANIFEST instead would create a task cycle with
        // ProcessApplicationManifest, which consumes VariantOutput.versionCode.
        //
        // Use BigInteger to separate Int overflow from non-decimal input, and strip a leading '+'
        // that Integer.parseInt accepts but toBigIntegerOrNull() rejects.
        val versionCode = value.removePrefix("+").toBigIntegerOrNull()
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
     * Returns the `--split-per-abi` failure message for [variantName] when `android {}` omits
     * `versionCode` and reading the main manifest fails with [reason] (from [Result.NotFound]).
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

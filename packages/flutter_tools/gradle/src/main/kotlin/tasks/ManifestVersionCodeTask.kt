// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import com.flutter.gradle.FlutterPluginUtils
import com.flutter.gradle.ManifestVersionCode
import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.file.RegularFile
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.ListProperty
import org.gradle.api.provider.Property
import org.gradle.api.provider.Provider
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction
import org.gradle.work.DisableCachingByDefault

/**
 * Writes the base versionCode that `--split-per-abi` offsets for a variant whose android {}
 * block declares none: the `android:versionCode` of the variant's manifest sources (see
 * [ManifestVersionCode]). Fails with a message that says what to do if there is none.
 *
 * The manifests are read in a task, not in a provider, because some of them can be written by
 * other tasks (with `addGeneratedManifestFile`, as Flutter's engine flags manifest is). Gradle
 * cannot query a provider derived from those files before the task graph runs.
 */
@DisableCachingByDefault(because = "Reading a few small files is faster than the build cache")
abstract class ManifestVersionCodeTask : DefaultTask() {
    /** The variant's manifest sources, highest priority first, as `ManifestFiles.all` lists them. */
    @get:InputFiles
    @get:PathSensitive(PathSensitivity.ABSOLUTE)
    abstract val manifests: ListProperty<RegularFile>

    /** The order of [manifests], which sets their priority. `@InputFiles` does not track it. */
    @get:Input
    val manifestOrder: Provider<List<String>>
        get() = manifests.map { files -> files.map { it.asFile.absolutePath } }

    /** The variant name, for the error message. */
    @get:Input
    abstract val variantName: Property<String>

    /** The file the base versionCode is written to, as a decimal integer. */
    @get:OutputFile
    abstract val versionCodeFile: RegularFileProperty

    @TaskAction
    fun writeVersionCode() {
        val contents =
            manifests.get().map { manifest ->
                val file = manifest.asFile
                file.path to file.takeIf { it.isFile }?.readBytes()
            }
        val versionCode =
            when (val result = ManifestVersionCode.from(contents)) {
                is ManifestVersionCode.Result.Found -> result.versionCode

                is ManifestVersionCode.Result.Unresolved -> throw GradleException(message(variantName.get(), result.reason))

                // AGP requires a value once Flutter sets the property, so an absent value would
                // fail the build with no hint. Fail with one that says what to do.
                ManifestVersionCode.Result.None -> throw GradleException(message(variantName.get(), "no manifest sets one"))
            }
        versionCodeFile.get().asFile.writeText(versionCode.toString())
    }

    internal companion object {
        /**
         * The error for a `--split-per-abi` build of [variantName] whose base versionCode Flutter
         * cannot read, because the DSL declares none and [reason].
         */
        internal fun message(
            variantName: String,
            reason: String
        ): String =
            "Flutter cannot give each split APK of variant '$variantName' a distinct " +
                "versionCode: its android {} block declares no versionCode, and $reason. " +
                "Google Play does not accept split APKs that share a versionCode. Set " +
                "versionCode = flutter.versionCode in defaultConfig (or on each product " +
                "flavor), or pass -P ${FlutterPluginUtils.PROP_FORCE_VERSION_CODE_IGNORING_ABI}=true to keep one versionCode."
    }
}

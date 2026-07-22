// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import com.android.build.api.variant.BuiltArtifact
import com.android.build.api.variant.BuiltArtifactsLoader
import com.android.build.api.variant.FilterConfiguration
import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.FileSystemOperations
import org.gradle.api.provider.MapProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.Internal
import org.gradle.api.tasks.Optional
import org.gradle.api.tasks.OutputFiles
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction
import javax.inject.Inject

/**
 * Copies the APKs produced for a variant ([apkDirectory], the `SingleArtifact.APK` directory)
 * into the flutter-apk output directory, under the names the Flutter tool expects:
 * `app[-abi][-flavor]-<build-mode>.apk`.
 *
 * Replaces the pre-migration `assemble<Variant>.doLast` copy. Because every variant copies
 * into the same flutter-apk directory, this task declares its individual [outputApks] (which
 * are predictable at configuration time) rather than the shared directory, keeping the task
 * UP-TO-DATE-capable without overlapping outputs between variants.
 */
abstract class CopyFlutterApksTask : DefaultTask() {
    @get:InputFiles
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val apkDirectory: DirectoryProperty

    @get:Internal
    abstract val builtArtifactsLoader: Property<BuiltArtifactsLoader>

    /** The Flutter build mode segment of the file name ("debug", "profile" or "release"). */
    @get:Input
    abstract val buildModeName: Property<String>

    /** The variant's flavor name; empty when the project has no flavors. */
    @get:Input
    abstract val flavorName: Property<String>

    /**
     * The files this task produces, computed at configuration time from the target platforms
     * (for `--split-per-abi` builds) or the single universal APK name.
     */
    @get:OutputFiles
    abstract val outputApks: ConfigurableFileCollection

    /**
     * The destination directory. Not an output directory: it is shared between the per-variant
     * copies, so the tracked outputs are the individual [outputApks].
     */
    @get:Internal
    abstract val destinationDir: DirectoryProperty

    /**
     * The per-ABI versionCodes Flutter configured on the variant outputs, keyed by ABI
     * identifier. Only set for `--split-per-abi` builds; used to warn when something mutated
     * the versionCode after Flutter configured it.
     */
    @get:Optional
    @get:Input
    abstract val expectedVersionCodes: MapProperty<String, Int>

    @get:Inject
    abstract val fileSystemOperations: FileSystemOperations

    @TaskAction
    fun copyApks() {
        val builtArtifacts =
            builtArtifactsLoader.get().load(apkDirectory.get())
                ?: throw GradleException(
                    "Flutter could not read the built APK metadata from " +
                        "${apkDirectory.get()}. The flutter-apk copy cannot run; please file " +
                        "an issue at https://github.com/flutter/flutter/issues."
                )
        val expectedNames = outputApks.files.map { it.name }.toSet()
        builtArtifacts.elements.forEach { artifact ->
            val filename = apkFileNameFor(artifact)
            if (filename !in expectedNames) {
                logger.warn(
                    "Flutter staged APK '$filename' which was not among the expected output " +
                        "names $expectedNames; incremental builds may re-run this copy."
                )
            }
            warnOnVersionCodeDivergence(artifact)
            fileSystemOperations.copy {
                from(artifact.outputFile)
                into(destinationDir)
                rename { filename }
            }
        }
    }

    private fun abiFor(artifact: BuiltArtifact): String? =
        artifact.filters
            .find { it.filterType == FilterConfiguration.FilterType.ABI }
            ?.identifier

    /** Mirrors the pre-migration name: `app[-abi][-flavor]-<build-mode>.apk`. */
    private fun apkFileNameFor(artifact: BuiltArtifact): String {
        var filename = "app"
        val abi = abiFor(artifact)
        if (!abi.isNullOrEmpty()) {
            filename += "-$abi"
        }
        if (flavorName.get().isNotEmpty()) {
            filename += "-${flavorName.get().lowercase()}"
        }
        filename += "-${buildModeName.get()}"
        return "$filename.apk"
    }

    private fun warnOnVersionCodeDivergence(artifact: BuiltArtifact) {
        val expected: Int = expectedVersionCodes.getOrElse(emptyMap())[abiFor(artifact)] ?: return
        val actual: Int? = artifact.versionCode
        if (actual != expected) {
            logger.warn(
                "Warning: the versionCode of ${artifact.outputFile} is $actual, but Flutter " +
                    "configured $expected for this ABI. Something modified the versionCode " +
                    "after Flutter did (for example an afterEvaluate block); with the Android " +
                    "Gradle Plugin's variant API, versionCode should be set through " +
                    "androidComponents.onVariants instead."
            )
        }
    }
}

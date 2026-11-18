// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import com.android.build.api.variant.BuiltArtifactsLoader
import com.android.build.api.variant.FilterConfiguration
import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.FileSystemOperations
import org.gradle.api.file.RegularFile
import org.gradle.api.provider.ListProperty
import org.gradle.api.provider.Property
import org.gradle.api.provider.Provider
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputDirectory
import org.gradle.api.tasks.Internal
import org.gradle.api.tasks.Optional
import org.gradle.api.tasks.OutputFiles
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction
import org.gradle.work.DisableCachingByDefault
import javax.inject.Inject

/**
 * Copies one variant's APKs into the flutter-apk directory, renamed to what the Flutter tool
 * expects (see [apkFileName]).
 *
 * Every variant writes into the same directory, so the task declares the individual
 * [outputApks] as outputs rather than the directory.
 *
 * Fails if another plugin transforms `SingleArtifact.APK` without writing `output-metadata.json`,
 * or into APKs whose ABI filters differ from the variant outputs. Flutter cannot fix either, so
 * the error points at that plugin.
 */
@DisableCachingByDefault(because = "Copies local APKs; a cache entry would only duplicate them")
abstract class CopyFlutterApksTask : DefaultTask() {
    /** The variant's `SingleArtifact.APK` directory: the APKs and AGP's metadata file. */
    @get:InputDirectory
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val apkDirectory: DirectoryProperty

    /** Reads the metadata in [apkDirectory], which already covers its inputs. */
    @get:Internal
    abstract val builtArtifactsLoader: Property<BuiltArtifactsLoader>

    /** The ABI of each variant output, or [NO_ABI] for an output without an ABI filter. */
    @get:Input
    abstract val outputAbis: ListProperty<String>

    /** The variant's flavor name. Absent when the project has no product flavors. */
    @get:Optional
    @get:Input
    abstract val flavorName: Property<String>

    /** The Flutter build mode: "debug", "profile" or "release". */
    @get:Input
    abstract val buildMode: Property<String>

    /** The flutter-apk directory, shared by every variant, so not an output itself. */
    @get:Internal
    abstract val destinationDir: DirectoryProperty

    /** The files this task writes into [destinationDir], one per entry in [outputAbis]. */
    @get:OutputFiles
    val outputApks: Provider<List<RegularFile>>
        get() =
            destinationDir.zip(outputAbis) { dir, abis ->
                abis.map { abi -> dir.file(apkFileName(abi, flavorName.orNull, buildMode.get())) }
            }

    @get:Inject
    abstract val fileSystemOperations: FileSystemOperations

    @TaskAction
    fun copyApks() {
        val apkDir = apkDirectory.get()
        // `load` returns null only when `output-metadata.json` is missing.
        val builtArtifacts =
            builtArtifactsLoader.get().load(apkDir)
                ?: throw transformedApkError(
                    problem =
                        "Flutter could not read the APK metadata in $apkDir " +
                            "(no output-metadata.json), so it cannot copy the APKs to " +
                            "${destinationDir.get()}.",
                    fix =
                        "write output-metadata.json, for example with " +
                            "ArtifactTransformationRequest or BuiltArtifacts.save()"
                )
        val declaredAbis = outputAbis.get()
        builtArtifacts.elements.forEach { artifact ->
            val abi = abiOf(artifact.filters)
            // With AGP alone this always matches, because both come from the variant outputs.
            if (abi !in declaredAbis) {
                throw transformedApkError(
                    problem =
                        "Flutter expected APKs for the ABIs $declaredAbis, but the APK metadata " +
                            "in $apkDir lists ${artifact.outputFile} for ABI '$abi'.",
                    fix = "keep one APK per variant output, with the same ABI filters"
                )
            }
            val fileName = apkFileName(abi, flavorName.orNull, buildMode.get())
            fileSystemOperations.copy {
                from(artifact.outputFile)
                into(destinationDir)
                rename { fileName }
            }
        }
    }

    companion object {
        /** The [outputAbis] entry for an APK that has no ABI filter. */
        const val NO_ABI: String = ""

        /** The ABI that [filters] select, or [NO_ABI] if they have no ABI filter. */
        internal fun abiOf(filters: Collection<FilterConfiguration>): String =
            filters.find { it.filterType == FilterConfiguration.FilterType.ABI }?.identifier ?: NO_ABI

        /**
         * `app[-<abi>][-<flavor>]-<build mode>.apk`, with the flavor in lower case.
         *
         * Must match `listApkPaths` in `packages/flutter_tools/lib/src/android/gradle.dart`.
         */
        internal fun apkFileName(
            abi: String,
            flavorName: String?,
            buildMode: String
        ): String {
            val abiPart = if (abi == NO_ABI) "" else "-$abi"
            val flavorPart = if (flavorName.isNullOrEmpty()) "" else "-${flavorName.lowercase()}"
            return "app$abiPart$flavorPart-$buildMode.apk"
        }

        private fun transformedApkError(
            problem: String,
            fix: String
        ): GradleException =
            GradleException(
                "$problem Another Gradle plugin or build script in this project transforms the " +
                    "APK artifact (SingleArtifact.APK). Find the plugin or script that transforms " +
                    "SingleArtifact.APK, and ask its maintainer to $fix."
            )
    }
}

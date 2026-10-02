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
 * Copies the APKs that AGP built for one variant into the flutter-apk directory, where
 * `flutter run` and `flutter build apk` look for them, under the names the Flutter tool expects
 * (see [apkFileName]).
 *
 * Every variant copies into the same flutter-apk directory, so declaring that directory as an
 * output would make the variants' outputs overlap. The task declares the individual
 * [outputApks] instead. Those and the files the copy writes are both named by [apkFileName] from
 * the same inputs, so the declared outputs cannot drift from what the task produces.
 *
 * The task only copies files, so like Gradle's own `Copy` and `Sync` tasks, which carry the same
 * annotation and reason, it is not cached.
 *
 * The task fails, and names the APK artifact (`SingleArtifact.APK`) in its error, when another
 * plugin or build script transforms that artifact so that either:
 * - the directory has no `output-metadata.json`. A transform registered with `toTransformMany`
 *   and `ArtifactTransformationRequest` gets the file written by AGP. A transform registered with
 *   `toTransform` must write it with `BuiltArtifacts.save`.
 * - an APK has an ABI filter that none of the variant's outputs has.
 *
 * The task cannot fix either case, so the errors point at the plugin that did the transform, not
 * at Flutter. Plugins that only read the APK artifact, or that write extra APKs after `assemble`
 * (as channel-packaging plugins do), do not cause either failure.
 */
@DisableCachingByDefault(because = "Not worth caching")
abstract class CopyFlutterApksTask : DefaultTask() {
    /** The variant's `SingleArtifact.APK` directory: the APKs and AGP's metadata file. */
    @get:InputDirectory
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val apkDirectory: DirectoryProperty

    /**
     * Reads the metadata in [apkDirectory]. Not an input itself, because [apkDirectory] already
     * covers every file it reads.
     */
    @get:Internal
    abstract val builtArtifactsLoader: Property<BuiltArtifactsLoader>

    /**
     * The ABI of each APK the variant produces, taken from the ABI filters of the variant's
     * outputs. An output without an ABI filter is listed as [NO_ABI]: the single APK of a build
     * without ABI splits, or a universal APK.
     */
    @get:Input
    abstract val outputAbis: ListProperty<String>

    /** The variant's flavor name. Absent when the project has no product flavors. */
    @get:Optional
    @get:Input
    abstract val flavorName: Property<String>

    /** The Flutter build mode: "debug", "profile" or "release". */
    @get:Input
    abstract val buildMode: Property<String>

    /**
     * The flutter-apk directory. Shared by every variant's copy task, so it is not declared as an
     * output; [outputApks] are the declared outputs.
     */
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
        // `load` returns null only when the directory has no `output-metadata.json`. AGP's
        // packaging task always writes one. A plugin that transforms the APK artifact with
        // `toTransformMany` and `ArtifactTransformationRequest` gets one written by AGP. So this
        // means another plugin or build script replaced the artifact with `toTransform` and did
        // not call `BuiltArtifacts.save`. An unreadable or malformed file throws instead.
        val builtArtifacts =
            builtArtifactsLoader.get().load(apkDir)
                ?: throw GradleException(
                    "Flutter could not read the APK metadata in $apkDir (no output-metadata.json), " +
                        "so it cannot copy the APKs to ${destinationDir.get()}. Another Gradle " +
                        "plugin or build script in this project replaced the APK artifact " +
                        "(SingleArtifact.APK) without writing output-metadata.json. Find the " +
                        "plugin or script that transforms SingleArtifact.APK, and ask its " +
                        "maintainer to write the metadata, for example with " +
                        "ArtifactTransformationRequest or BuiltArtifacts.save()."
                )
        val declaredAbis = outputAbis.get()
        builtArtifacts.elements.forEach { artifact ->
            val abi = abiOf(artifact.filters)
            // AGP writes one APK per variant output, and the declared ABIs come from those same
            // outputs, so with AGP alone they always match. They differ only if another plugin
            // or build script transforms the APK artifact into APKs with different ABI filters.
            // Fail rather than write a file that Gradle does not track.
            if (abi !in declaredAbis) {
                throw GradleException(
                    "Flutter expected APKs for the ABIs $declaredAbis, but the APK metadata in " +
                        "$apkDir lists ${artifact.outputFile} for ABI '$abi'. Another Gradle " +
                        "plugin or build script in this project changed the APK artifact " +
                        "(SingleArtifact.APK). Find the plugin or script that transforms " +
                        "SingleArtifact.APK, and ask its maintainer to keep one APK per variant " +
                        "output with the same ABI filters."
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

        /**
         * The ABI that [filters] select, or [NO_ABI] if they have no ABI filter.
         *
         * Used both for the variant outputs at configuration time and for the built APKs at
         * execution time, so the two always agree on what "no ABI" means.
         */
        internal fun abiOf(filters: Collection<FilterConfiguration>): String =
            filters.find { it.filterType == FilterConfiguration.FilterType.ABI }?.identifier ?: NO_ABI

        /**
         * The file name the Flutter tool expects for an APK:
         * `app[-<abi>][-<flavor>]-<build mode>.apk`, with the flavor in lower case.
         *
         * Must stay in sync with `listApkPaths` in
         * `packages/flutter_tools/lib/src/android/gradle.dart`, which is how the Flutter tool
         * finds these files.
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
    }
}

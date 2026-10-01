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
 */
@DisableCachingByDefault(because = "Copying local APKs is faster than unpacking cache archives")
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
        val builtArtifacts =
            builtArtifactsLoader.get().load(apkDir)
                ?: throw GradleException(
                    "Flutter could not read the APK metadata in $apkDir, so it cannot copy the " +
                        "APKs to ${destinationDir.get()}. Please file an issue at " +
                        "https://github.com/flutter/flutter/issues."
                )
        val declaredAbis = outputAbis.get()
        builtArtifacts.elements.forEach { artifact ->
            val abi = abiOf(artifact.filters)
            // The declared ABIs come from the same variant outputs that AGP built, so a mismatch
            // means AGP built an APK that Flutter did not declare as an output. Fail rather than
            // write a file that Gradle does not track.
            if (abi !in declaredAbis) {
                throw GradleException(
                    "Flutter expected APKs for the ABIs $declaredAbis, but the Android Gradle " +
                        "Plugin built ${artifact.outputFile} for ABI '$abi'. Please file an " +
                        "issue at https://github.com/flutter/flutter/issues."
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

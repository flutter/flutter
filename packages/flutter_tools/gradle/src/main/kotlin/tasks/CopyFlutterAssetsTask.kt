// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import org.gradle.api.DefaultTask
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.tasks.InputDirectory
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction
import org.gradle.work.DisableCachingByDefault
import java.io.File
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption

/**
 * Adds the `flutter_assets` directory produced by the Flutter build to the variant's merged
 * assets.
 *
 * This task transforms AGP's merged assets artifact (`SingleArtifact.ASSETS`): [destinationDir]
 * receives every file in [mergedAssetsDir], with `flutter_assets/` from [intermediateDir] laid
 * over it, so Flutter's assets win on a path collision.
 *
 * Flutter's assets are added after AGP's merge instead of as an assets source directory, because
 * AGP filters assets source directories with `androidResources.ignoreAssetsPattern`. Its default
 * pattern drops files whose name starts with `.` (such as `.env`) and directories whose name
 * starts with `_`, which are valid Flutter asset paths. See
 * https://github.com/flutter/flutter/issues/196444.
 *
 * The files are copied with `java.nio` rather than a Gradle copy spec, because copy specs apply
 * Gradle's default excludes (such as `.gitignore` and `._*`), which would drop those assets too.
 */
@DisableCachingByDefault(because = "Copying local asset directories is faster than unpacking cache archives")
abstract class CopyFlutterAssetsTask : DefaultTask() {
    /**
     * The Flutter build output directory (the `flutter assemble` `--output` location).
     *
     * Required, because this task is only registered together with its variant's compile task.
     */
    @get:InputDirectory
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val intermediateDir: DirectoryProperty

    /** The assets AGP merged from the variant's assets sources. Set by AGP's transform wiring. */
    @get:InputDirectory
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val mergedAssetsDir: DirectoryProperty

    /** The merged assets plus `flutter_assets/`. Set by AGP's transform wiring. */
    @get:OutputDirectory
    abstract val destinationDir: DirectoryProperty

    @TaskAction
    fun copy() {
        val destination: File = destinationDir.get().asFile
        // Remove everything from a previous run, so assets that are no longer produced are pruned.
        destination.deleteRecursively()
        destination.mkdirs()
        copyTree(mergedAssetsDir.get().asFile.toPath(), destination.toPath())
        // The engine loads assets from `flutter_assets/` by default, so keep the prefix.
        val flutterAssets: File = intermediateDir.get().asFile.resolve(FLUTTER_ASSETS_DIRECTORY_NAME)
        copyTree(flutterAssets.toPath(), destination.resolve(FLUTTER_ASSETS_DIRECTORY_NAME).toPath())
    }

    private fun copyTree(
        source: Path,
        destination: Path
    ) {
        if (!Files.isDirectory(source)) {
            return
        }
        Files.walk(source).use { paths ->
            paths.forEach { path ->
                val target = destination.resolve(source.relativize(path).toString())
                if (Files.isDirectory(path)) {
                    Files.createDirectories(target)
                } else {
                    Files.createDirectories(target.parent)
                    Files.copy(path, target, StandardCopyOption.REPLACE_EXISTING)
                    // Assets inherited from the pub cache can be read-only, and a packaging step
                    // downstream has to be able to replace the copy.
                    val file = target.toFile()
                    file.setReadable(true, true)
                    file.setWritable(true, true)
                }
            }
        }
    }

    private companion object {
        const val FLUTTER_ASSETS_DIRECTORY_NAME = "flutter_assets"
    }
}

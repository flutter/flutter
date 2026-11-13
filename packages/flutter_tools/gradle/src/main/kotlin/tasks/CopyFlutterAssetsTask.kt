// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import org.gradle.api.DefaultTask
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.DuplicatesStrategy
import org.gradle.api.file.FileSystemOperations
import org.gradle.api.tasks.InputDirectory
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction
import org.gradle.work.DisableCachingByDefault
import javax.inject.Inject

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
 * The copy applies Gradle's default excludes (such as `.gitignore`, `.DS_Store` and `._*`), as the
 * `Copy` task that staged Flutter's assets before Flutter 3.50 did.
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

    @get:Inject
    abstract val fileSystemOperations: FileSystemOperations

    @TaskAction
    fun copy() {
        // sync() prunes files that are no longer produced, so no separate delete is needed.
        fileSystemOperations.sync {
            into(destinationDir)
            from(mergedAssetsDir)
            // The engine loads assets from `flutter_assets/` by default, so keep the prefix.
            from(intermediateDir.dir(FLUTTER_ASSETS_DIRECTORY_NAME)) {
                into(FLUTTER_ASSETS_DIRECTORY_NAME)
            }
            // Flutter's assets are copied last, so on a path collision they replace the merged
            // native asset, as they did before 3.50.
            duplicatesStrategy = DuplicatesStrategy.INCLUDE
            // Assets from the pub cache can be read-only, and a packaging step downstream has to be
            // able to replace the copy.
            filePermissions {
                user {
                    read = true
                    write = true
                }
            }
        }
    }

    private companion object {
        const val FLUTTER_ASSETS_DIRECTORY_NAME = "flutter_assets"
    }
}

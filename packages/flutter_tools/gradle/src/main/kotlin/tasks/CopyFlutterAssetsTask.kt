// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import org.gradle.api.DefaultTask
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.FileSystemOperations
import org.gradle.api.tasks.InputDirectory
import org.gradle.api.tasks.Optional
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction
import javax.inject.Inject

/**
 * Stages the `flutter_assets` directory produced by the Flutter build into a dedicated
 * [destinationDir], which is registered with the variant as a generated assets source
 * directory (`variant.sources.assets.addGeneratedSourceDirectory`). AGP then merges it like
 * any other assets source; collisions with user assets resolve by AGP source-set priority.
 * (The pre-migration behavior was a copy into the merged-assets output after merging, which
 * silently overwrote colliding user assets.)
 *
 * It deliberately writes to its own output directory rather than reusing the Flutter task's
 * output directory, for the same overlapping-output reasons as [CopyFlutterJniLibsTask].
 */
abstract class CopyFlutterAssetsTask : DefaultTask() {
    /**
     * The Flutter build output directory (the `flutter assemble` `--output` location).
     *
     * Optional for the same reason as [CopyFlutterJniLibsTask.intermediateDir]: absent when
     * there is no Flutter compile task for the variant, in which case this task stages
     * nothing.
     */
    @get:Optional
    @get:InputDirectory
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val intermediateDir: DirectoryProperty

    @get:OutputDirectory
    abstract val destinationDir: DirectoryProperty

    @get:Inject
    abstract val fileSystemOperations: FileSystemOperations

    @TaskAction
    fun copy() {
        fileSystemOperations.sync {
            into(destinationDir)
            if (intermediateDir.isPresent) {
                from(intermediateDir) {
                    // Keeps the `flutter_assets/` prefix, so the staged layout matches what
                    // the pre-migration copy produced inside the merged-assets directory.
                    include(FlutterTaskHelper.FLUTTER_ASSETS_INCLUDE_DIRECTORY)
                }
            }
            filePermissions {
                user {
                    read = true
                    write = true
                }
            }
        }
    }
}

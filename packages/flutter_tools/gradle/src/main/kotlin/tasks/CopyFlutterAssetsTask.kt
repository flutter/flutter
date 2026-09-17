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
import org.gradle.work.DisableCachingByDefault
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
@DisableCachingByDefault(because = "Syncing local asset directories is faster than unpacking cache archives")
abstract class CopyFlutterAssetsTask : DefaultTask() {
    /**
     * The Flutter build output directory (the `flutter assemble` `--output` location).
     *
     * Always present on the application path: this task is only registered for variants that
     * Flutter compiles for, and it is wired directly to that variant's compile task, which
     * always sets an output directory. A variant Flutter does not compile for gets no task at
     * all, rather than a task with an absent input. That is the opposite of
     * [CopyFlutterJniLibsTask.intermediateDir], which is registered unconditionally and so
     * genuinely can be absent.
     *
     * Declared `@Optional` regardless, because the add-to-app module path registers this task
     * for library variants once it migrates
     * (https://github.com/flutter/flutter/issues/166550), where an absent value is expected.
     * Until then, an absent value here means Flutter assets would silently be missing from the
     * APK, so the registration site asserts the value is set rather than letting it default.
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

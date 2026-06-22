// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import com.flutter.gradle.FlutterPluginConstants
import org.gradle.api.DefaultTask
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.FileSystemOperations
import org.gradle.api.provider.ListProperty
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputDirectory
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction
import javax.inject.Inject

/**
 * Stages the native libraries produced by the Flutter build (`libapp.so` and any bundled native
 * assets) into a dedicated [destinationDir], laid out as `<abi>/lib*.so`.
 *
 * It deliberately writes to its own output directory rather than into the Flutter task's output
 * directory. Two earlier approaches dropped `libapp.so` from the APK/app bundle: nesting this output
 * inside the Flutter task's output directory created overlapping task outputs that broke Gradle's
 * incremental checks (flavored single-ABI rebuilds), and registering the staged directory eagerly as
 * a source set `srcDir` captured the build directory before it had been redirected. See
 * https://github.com/flutter/flutter/issues/186810 and
 * https://github.com/flutter/flutter/issues/187388.
 */
abstract class CopyFlutterJniLibsTask : DefaultTask() {
    /** The Flutter build output directory (the `flutter assemble` `--output` location). */
    @get:InputDirectory
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val intermediateDir: DirectoryProperty

    @get:Input
    abstract val targetPlatforms: ListProperty<String>

    @get:OutputDirectory
    abstract val destinationDir: DirectoryProperty

    @get:Inject
    abstract val fileSystemOperations: FileSystemOperations

    @TaskAction
    fun copy() {
        fileSystemOperations.sync {
            into(destinationDir)
            targetPlatforms.get().forEach { targetPlatform ->
                val abi: String? = FlutterPluginConstants.PLATFORM_ARCH_MAP[targetPlatform]
                from(intermediateDir.dir(abi ?: "null")) {
                    include("*.so")
                    rename { filename: String -> "lib$filename" }
                    into(abi ?: "null")
                }
                val nativeAssetsDir = intermediateDir.dir("native_assets/jniLibs/lib/$abi")
                from(nativeAssetsDir) {
                    include("*.so")
                    into(abi ?: "null")
                }
            }
        }
    }
}

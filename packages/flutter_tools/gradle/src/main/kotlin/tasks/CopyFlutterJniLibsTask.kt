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
import org.gradle.api.tasks.TaskAction
import javax.inject.Inject

abstract class CopyFlutterJniLibsTask : DefaultTask() {
    @get:InputDirectory
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

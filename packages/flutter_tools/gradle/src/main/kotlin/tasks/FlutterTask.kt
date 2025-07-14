// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import org.gradle.api.file.CopySpec
import org.gradle.api.file.FileCollection
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.Internal
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.OutputFiles
import org.gradle.api.tasks.TaskAction
import java.io.File

// IMPORTANT: Do not add logic to the methods in this class directly,
// instead add logic to [FlutterTaskHelper].

/**
 * Flutter's implementation of a Gradle task. Gradle tasks can not be instantiated for testing,
 * so this class delegates all logic to [FlutterTaskHelper].
 */
abstract class FlutterTask : BaseFlutterTask() {
    @get:OutputDirectory
    val outputDirectory: File?
        get() = FlutterTaskHelper.getOutputDirectory(flutterTask = this)

    @get:Internal
    val assetsDirectory: String
        get() = FlutterTaskHelper.getAssetsDirectory(flutterTask = this)

    @get:Internal
    val assets: CopySpec
        get() = FlutterTaskHelper.getAssets(project, flutterTask = this)

    @get:Internal
    val snapshots: CopySpec
        get() = FlutterTaskHelper.getSnapshots(project, flutterTask = this)

    @get:InputFiles
    val sourceFiles: FileCollection
        get() = FlutterTaskHelper.getSourceFiles(project, flutterTask = this)

    @get:OutputFiles
    val outputFiles: FileCollection
        get() = FlutterTaskHelper.getOutputFiles(project, flutterTask = this)

    @TaskAction
    fun build() = FlutterTaskHelper.build(flutterTask = this)
}

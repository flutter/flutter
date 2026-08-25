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
 * Flutter's implementation of a Gradle task. Gradle tasks cannot be instantiated for testing,
 * so this class delegates all logic to [FlutterTaskHelper].
 *
 * This class intentionally exposes only task inputs/outputs and delegates behavior to the helper
 * to keep the task class simple and easy to test and compatible across Gradle/AGP versions.
 */
abstract class FlutterTask : BaseFlutterTask() {
    @get:OutputDirectory
    val outputDirectory: File?
        get() = FlutterTaskHelper.getOutputDirectory(flutterTask = this)

    // Assets directory path (internal, not an input/output tracked by Gradle directly).
    @get:Internal
    val assetsDirectory: String
        get() = FlutterTaskHelper.getAssetsDirectory(flutterTask = this)

    // Assets CopySpec for wiring into other tasks; marked Internal to avoid Gradle tracking here.
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

    /**
     * Task action that delegates the actual build work to [FlutterTaskHelper.build].
     *
     * Keeping the action minimal ensures the task class remains a thin wrapper and
     * the heavy logic is testable in the helper.
     */
    @TaskAction
    fun build() = FlutterTaskHelper.build(flutterTask = this)
}

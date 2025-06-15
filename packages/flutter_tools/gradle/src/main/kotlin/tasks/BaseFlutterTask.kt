// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import org.gradle.api.DefaultTask
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.Internal
import org.gradle.api.tasks.Optional
import org.gradle.api.tasks.OutputFiles
import java.io.File

// IMPORTANT: Do not add logic to the methods in this class directly,
// instead add logic to [BaseFlutterTaskHelper].

/**
 * Base implementation of a Gradle task. Gradle tasks can not be instantiated for testing,
 * so this class delegates all logic to [BaseFlutterTaskHelper].
 */
open class BaseFlutterTask : DefaultTask() {
    @Internal
    var flutterRoot: File? = null

    @Internal
    var flutterExecutable: File? = null

    @Input
    var buildMode: String? = null

    @Input
    var minSdkVersion: Int? = null

    @Optional
    @Input
    var localEngine: String? = null

    @Optional
    @Input
    var localEngineHost: String? = null

    @Optional
    @Input
    var localEngineSrcPath: String? = null

    @Optional
    @Input
    var fastStart: Boolean? = null

    @Input
    var targetPath: String? = null

    @Optional
    @Input
    var verbose: Boolean? = null

    @Optional
    @Input
    var fileSystemRoots: Array<String>? = null

    @Optional
    @Input
    var fileSystemScheme: String? = null

    @Input
    var trackWidgetCreation: Boolean? = null

    @Optional
    @Input
    var targetPlatformValues: List<String>? = null

    @Internal
    var sourceDir: File? = null

    @Internal
    var intermediateDir: File? = null

    @Optional
    @Input
    var frontendServerStarterPath: String? = null

    @Optional
    @Input
    var extraFrontEndOptions: String? = null

    @Optional
    @Input
    var extraGenSnapshotOptions: String? = null

    @Optional
    @Input
    var splitDebugInfo: String? = null

    @Optional
    @Input
    var treeShakeIcons: Boolean? = null

    @Optional
    @Input
    var dartObfuscation: Boolean? = null

    @Optional
    @Input
    var dartDefines: String? = null

    @Optional
    @Input
    var bundleSkSLPath: String? = null

    @Optional
    @Input
    var codeSizeDirectory: String? = null

    @Optional
    @Input
    var performanceMeasurementFile: String? = null

    @Optional
    @Input
    var deferredComponents: Boolean? = null

    @Optional
    @Input
    var validateDeferredComponents: Boolean? = null

    @Optional
    @Input
    var skipDependencyChecks: Boolean? = null

    @Optional
    @Input
    var flavor: String? = null

    /**
     * Gets the dependency file(s) by calling [com.flutter.gradle.tasks.BaseFlutterTaskHelper.getDependenciesFiles].
     *
     * @return the dependency file(s) based on the current intermediate directory path.
     */
    @OutputFiles
    fun getDependenciesFiles() = BaseFlutterTaskHelper.getDependenciesFiles(baseFlutterTask = this)

    /**
     * Builds a Flutter Android application bundle by verifying the Flutter source directory,
     * creating an intermediate build directory if necessary, and running flutter assemble by
     * configuring and executing with a set of build configurations.
     */
    fun buildBundle() = BaseFlutterTaskHelper.buildBundle(baseFlutterTask = this)
}

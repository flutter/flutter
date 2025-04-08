// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import androidx.annotation.VisibleForTesting
import org.gradle.api.Action
import org.gradle.api.GradleException
import org.gradle.api.file.FileCollection
import org.gradle.api.logging.LogLevel
import org.gradle.api.tasks.OutputFiles
import org.gradle.kotlin.dsl.support.serviceOf
import org.gradle.process.ExecOperations
import org.gradle.process.ExecSpec
import java.nio.file.Paths

/**
 * Stateless object to contain the logic used in [BaseFlutterTask]. Any required state should be stored
 * on [BaseFlutterTask] instead, while any logic needed by [BaseFlutterTask] should be added here.
 */
object BaseFlutterTaskHelper {
    @VisibleForTesting
    internal fun getGradleErrorMessage(baseFlutterTask: BaseFlutterTask): String =
        "Invalid Flutter source directory: ${baseFlutterTask.sourceDir}"

    /**
     * Gets the dependency file(s) that tracks the dependencies or input files used for a specific
     * Flutter build step based on the current intermediate directory.
     *
     * @return the dependency file(s) based on the current intermediate directory.
     */
    @OutputFiles
    @VisibleForTesting
    internal fun getDependenciesFiles(baseFlutterTask: BaseFlutterTask): FileCollection {
        var depfiles: FileCollection = baseFlutterTask.project.files()

        // TODO(jesswon): During cleanup determine if .../flutter_build.d is ever a directory and refactor accordingly
        // Includes all sources used in the flutter compilation.
        depfiles += baseFlutterTask.project.files("${baseFlutterTask.intermediateDir}/flutter_build.d")
        return depfiles
    }

    /**
     * Checks precondition to ensures sourceDir is not null and is a directory. Also checks
     * if intermediateDir is valid valid and creates it (and parent directories if needed) if invalid.
     *
     * @throws GradleException if sourceDir is null or is not a directory
     */
    @VisibleForTesting
    internal fun checkPreConditions(baseFlutterTask: BaseFlutterTask) {
        if (baseFlutterTask.sourceDir == null || !baseFlutterTask.sourceDir!!.isDirectory) {
            throw GradleException(getGradleErrorMessage(baseFlutterTask))
        }
        baseFlutterTask.intermediateDir!!.mkdirs()
    }

    /**
     * Computes the rule names for flutter assemble. To speed up builds that contain
     * multiple ABIs, the target name is used to communicate which ones are required
     * rather than the TargetPlatform. This allows multiple builds to share the same
     * cache.
     *
     * @param baseFlutterTask is a BaseFlutterTask to access its properties
     * @return the list of rule names for flutter assemble.
     */
    @VisibleForTesting
    internal fun generateRuleNames(baseFlutterTask: BaseFlutterTask): List<String> {
        val ruleNames: List<String> =
            when {
                baseFlutterTask.buildMode == "debug" -> listOf("debug_android_application")
                baseFlutterTask.deferredComponents!! ->
                    baseFlutterTask.targetPlatformValues!!
                        .map {
                            "android_aot_deferred_components_bundle_${baseFlutterTask.buildMode}_$it"
                        }

                else -> baseFlutterTask.targetPlatformValues!!.map { "android_aot_bundle_${baseFlutterTask.buildMode}_$it" }
            }
        return ruleNames
    }

    /**
     * Creates and configures the build processes of an Android Flutter application to be executed.
     * The configuration includes setting the executable to the Flutter command-line tool (Flutter CLI),
     * setting the working directory to the Flutter project's source directory, adding command-line arguments and build rules
     * to configure various build options.
     *
     * @return an Action<ExecSpec> of build processes and options to be executed.
     */
    internal fun createExecSpecActionFromTask(baseFlutterTask: BaseFlutterTask): Action<ExecSpec> =
        Action<ExecSpec> {
            executable(baseFlutterTask.flutterExecutable!!.absolutePath)
            workingDir(baseFlutterTask.sourceDir)
            baseFlutterTask.localEngine?.let {
                args("--local-engine", it)
                args("--local-engine-src-path", baseFlutterTask.localEngineSrcPath)
            }
            baseFlutterTask.localEngineHost?.let {
                args("--local-engine-host", it)
            }
            if (baseFlutterTask.verbose == true) {
                args("--verbose")
            } else {
                args("--quiet")
            }
            args("assemble")
            args("--no-version-check")
            args("--depfile", "${baseFlutterTask.intermediateDir}/flutter_build.d")
            args("--output", "${baseFlutterTask.intermediateDir}")
            baseFlutterTask.performanceMeasurementFile?.let {
                args("--performance-measurement-file=$it")
            }
            if (!baseFlutterTask.fastStart!! || baseFlutterTask.buildMode != "debug") {
                args("-dTargetFile=${baseFlutterTask.targetPath}")
            } else {
                args(
                    "-dTargetFile=${
                        Paths.get(
                            baseFlutterTask.flutterRoot!!.absolutePath,
                            "examples",
                            "splash",
                            "lib",
                            "main.dart"
                        )
                    }"
                )
            }
            args("-dTargetPlatform=android")
            args("-dBuildMode=${baseFlutterTask.buildMode}")
            baseFlutterTask.trackWidgetCreation?.let {
                args("-dTrackWidgetCreation=$it")
            }
            baseFlutterTask.splitDebugInfo?.let {
                args("-dSplitDebugInfo=$it")
            }
            if (baseFlutterTask.treeShakeIcons == true) {
                args("-dTreeShakeIcons=true")
            }
            if (baseFlutterTask.dartObfuscation == true) {
                args("-dDartObfuscation=true")
            }
            baseFlutterTask.dartDefines?.let {
                args("--DartDefines=$it")
            }
            baseFlutterTask.bundleSkSLPath?.let {
                args("-dBundleSkSLPath=$it")
            }
            baseFlutterTask.codeSizeDirectory?.let {
                args("-dCodeSizeDirectory=$it")
            }
            baseFlutterTask.flavor?.let {
                args("-dFlavor=$it")
            }
            baseFlutterTask.extraGenSnapshotOptions?.let {
                args("--ExtraGenSnapshotOptions=$it")
            }
            baseFlutterTask.frontendServerStarterPath?.let {
                args("-dFrontendServerStarterPath=$it")
            }
            baseFlutterTask.extraFrontEndOptions?.let {
                args("--ExtraFrontEndOptions=$it")
            }

            args("-dAndroidArchs=${baseFlutterTask.targetPlatformValues!!.joinToString(" ")}")
            args("-dMinSdkVersion=${baseFlutterTask.minSdkVersion}")
            args(generateRuleNames(baseFlutterTask))
        }

    fun buildBundle(baseFlutterTask: BaseFlutterTask) {
        checkPreConditions(baseFlutterTask)
        baseFlutterTask.logging.captureStandardError(LogLevel.ERROR)
        val execOps = baseFlutterTask.project.serviceOf<ExecOperations>()
        execOps.exec(createExecSpecActionFromTask(baseFlutterTask = baseFlutterTask))
    }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import org.gradle.api.Project

/**
 * The subset of [FlutterTask][com.flutter.gradle.tasks.FlutterTask] configuration that comes from
 * Gradle project properties rather than from the Android variant.
 *
 * The Flutter tool passes these as `-P<name>=<value>` when it invokes Gradle, so they are constant
 * for a build invocation and identical for every variant. Resolving them once, in [from], keeps
 * property lookups out of task configuration and gives the property names a single definition
 * site.
 *
 * The name of the Gradle property backing each value is the correspondingly named constant in the
 * companion object, for example [fileSystemRoots] is read from [FILE_SYSTEM_ROOTS_PROPERTY].
 * Kotlin does not allow declarations between primary constructor parameters, so the constants are
 * declared as one block in the same order as the parameters.
 */
internal data class FlutterCompileOptions(
    val fileSystemRoots: List<String>?,
    val fileSystemScheme: String?,
    val trackWidgetCreation: Boolean,
    val frontendServerStarterPath: String?,
    val extraFrontEndOptions: String?,
    val extraGenSnapshotOptions: String?,
    val splitDebugInfo: String?,
    val dartObfuscation: Boolean,
    val treeShakeIcons: Boolean,
    val dartDefines: String?,
    val performanceMeasurementFile: String?,
    val codeSizeDirectory: String?,
    val deferredComponents: Boolean,
    val validateDeferredComponents: Boolean
) {
    companion object {
        const val FILE_SYSTEM_ROOTS_PROPERTY = "filesystem-roots"
        const val FILE_SYSTEM_SCHEME_PROPERTY = "filesystem-scheme"
        const val TRACK_WIDGET_CREATION_PROPERTY = "track-widget-creation"
        const val FRONTEND_SERVER_STARTER_PATH_PROPERTY = "frontend-server-starter-path"
        const val EXTRA_FRONT_END_OPTIONS_PROPERTY = "extra-front-end-options"
        const val EXTRA_GEN_SNAPSHOT_OPTIONS_PROPERTY = "extra-gen-snapshot-options"
        const val SPLIT_DEBUG_INFO_PROPERTY = "split-debug-info"
        const val DART_OBFUSCATION_PROPERTY = "dart-obfuscation"
        const val TREE_SHAKE_ICONS_PROPERTY = "tree-shake-icons"
        const val DART_DEFINES_PROPERTY = "dart-defines"
        const val PERFORMANCE_MEASUREMENT_FILE_PROPERTY = "performance-measurement-file"
        const val CODE_SIZE_DIRECTORY_PROPERTY = "code-size-directory"
        const val DEFERRED_COMPONENTS_PROPERTY = "deferred-components"
        const val VALIDATE_DEFERRED_COMPONENTS_PROPERTY = "validate-deferred-components"

        /**
         * Separator used to split [FILE_SYSTEM_ROOTS_PROPERTY] into individual roots.
         *
         * The Flutter tool joins the roots with a single `|`, see `gradle.dart`. Kotlin's
         * [String.split] takes a literal delimiter rather than a regular expression, so this
         * two-character delimiter never matches and the property arrives as a single element.
         * The behavior predates the variant API migration and is preserved here unchanged.
         *
         * TODO(reidbaker): Split on "|" so that multiple `--filesystem-root` values reach
         *  `flutter assemble`. https://github.com/flutter/flutter/issues/192824
         */
        private const val FILE_SYSTEM_ROOTS_SEPARATOR = "\\|"

        /** Reads every Gradle property that configures a Flutter compile task from [project]. */
        fun from(project: Project): FlutterCompileOptions =
            FlutterCompileOptions(
                fileSystemRoots =
                    project
                        .findProperty(FILE_SYSTEM_ROOTS_PROPERTY)
                        ?.toString()
                        ?.split(FILE_SYSTEM_ROOTS_SEPARATOR),
                fileSystemScheme = project.findProperty(FILE_SYSTEM_SCHEME_PROPERTY)?.toString(),
                trackWidgetCreation =
                    project.findProperty(TRACK_WIDGET_CREATION_PROPERTY)?.toString()?.toBoolean() ?: true,
                frontendServerStarterPath =
                    project.findProperty(FRONTEND_SERVER_STARTER_PATH_PROPERTY)?.toString(),
                extraFrontEndOptions = project.findProperty(EXTRA_FRONT_END_OPTIONS_PROPERTY)?.toString(),
                extraGenSnapshotOptions =
                    project.findProperty(EXTRA_GEN_SNAPSHOT_OPTIONS_PROPERTY)?.toString(),
                splitDebugInfo = project.findProperty(SPLIT_DEBUG_INFO_PROPERTY)?.toString(),
                dartObfuscation =
                    project.findProperty(DART_OBFUSCATION_PROPERTY)?.toString()?.toBoolean() ?: false,
                treeShakeIcons =
                    project.findProperty(TREE_SHAKE_ICONS_PROPERTY)?.toString()?.toBoolean() ?: false,
                dartDefines = project.findProperty(DART_DEFINES_PROPERTY)?.toString(),
                performanceMeasurementFile =
                    project.findProperty(PERFORMANCE_MEASUREMENT_FILE_PROPERTY)?.toString(),
                codeSizeDirectory = project.findProperty(CODE_SIZE_DIRECTORY_PROPERTY)?.toString(),
                deferredComponents =
                    project.findProperty(DEFERRED_COMPONENTS_PROPERTY)?.toString()?.toBoolean() ?: false,
                validateDeferredComponents =
                    project.findProperty(VALIDATE_DEFERRED_COMPONENTS_PROPERTY)?.toString()?.toBoolean() ?: true
            )
    }
}

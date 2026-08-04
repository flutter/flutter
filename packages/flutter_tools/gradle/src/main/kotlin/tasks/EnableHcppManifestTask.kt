// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import org.gradle.api.DefaultTask
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.CacheableTask
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputFile
import org.gradle.api.tasks.Optional
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction

/**
 * Manages the `io.flutter.embedding.android.EnableHcpp` meta-data in the merged
 * AndroidManifest.
 *
 * If [requestedEnableHcpp] is true, injects the metadata element if absent.
 * If [explicitEnableHcpp] is provided and conflicts with an explicit metadata value
 * in the merged manifest, logs a warning.
 */
@CacheableTask
abstract class EnableHcppManifestTask : DefaultTask() {
    @get:InputFile
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val manifestFile: RegularFileProperty

    @get:OutputFile
    abstract val updatedManifest: RegularFileProperty

    @get:Input
    @get:Optional
    abstract val requestedEnableHcpp: Property<Boolean>

    @get:Input
    @get:Optional
    abstract val explicitEnableHcpp: Property<Boolean>

    @TaskAction
    fun processManifest() {
        EnableHcppManifestTaskHelper.processHcppManifest(
            manifestFile = manifestFile.get().asFile,
            updatedManifest = updatedManifest.get().asFile,
            requestedEnableHcpp = requestedEnableHcpp.getOrElse(true),
            explicitEnableHcpp = explicitEnableHcpp.orNull,
            logger = logger
        )
    }
}

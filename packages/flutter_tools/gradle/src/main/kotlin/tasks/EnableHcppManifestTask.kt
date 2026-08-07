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
 * If [explicitEnableHcpp] is provided it is written to the manifest, replacing any value already
 * there. Otherwise [requestedEnableHcpp] is injected only when the manifest does not set the
 * metadata at all. See [EnableHcppManifestTaskHelper.processHcppManifest] for the precedence.
 *
 * The message reporting that the flag overrode the manifest is emitted from the task action, so it
 * is only printed when the task actually runs. A subsequent up-to-date or cached build produces the
 * same (correct) manifest without repeating the message.
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
            requestedEnableHcpp = requestedEnableHcpp.getOrElse(false),
            explicitEnableHcpp = explicitEnableHcpp.orNull,
            logger = logger
        )
    }
}

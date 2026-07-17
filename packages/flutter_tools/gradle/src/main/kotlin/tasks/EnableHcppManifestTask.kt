// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import org.gradle.api.DefaultTask
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.tasks.CacheableTask
import org.gradle.api.tasks.InputFile
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction

/**
 * Adds the `io.flutter.embedding.android.EnableHcpp` meta-data to the merged
 * AndroidManifest, unless the merged manifest already contains it.
 *
 * This task is only registered when the flutter tool passes `-Penable-hcpp=true`, which it
 * does when the `enable-hcpp` feature flag is enabled. Because the injection is skipped when
 * the meta-data is already present, an explicit value from the developer's manifest (or one
 * merged in from a manifest of a dependency) always takes priority over the feature flag.
 */
@CacheableTask
abstract class EnableHcppManifestTask : DefaultTask() {
    @get:InputFile
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val manifestFile: RegularFileProperty

    @get:OutputFile
    abstract val updatedManifest: RegularFileProperty

    @TaskAction
    fun processManifest() {
        EnableHcppManifestTaskHelper.addEnableHcppMetadataIfAbsent(
            manifestFile.get().asFile,
            updatedManifest.get().asFile
        )
    }
}

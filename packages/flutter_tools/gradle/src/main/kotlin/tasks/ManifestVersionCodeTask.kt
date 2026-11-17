// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.CacheableTask
import org.gradle.api.tasks.InputFile
import org.gradle.api.tasks.Internal
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction

/**
 * Extracts `android:versionCode` from [mainManifest] into [versionCodeFile] as the fallback base
 * `versionCode` for `--split-per-abi` builds (see [ManifestVersionCodeTaskHelper.registerTask]).
 *
 * `variant.sources.manifests.all` combines the static main manifest with any manifests generated
 * by other tasks in one `Provider`. Reading that list in a plain `Provider` transform fails
 * task-graph resolution whenever another task generates a manifest. Wiring [mainManifest] as a task
 * input instead makes Gradle run any manifest-generating tasks first, even though the main manifest
 * is a static source file.
 */
@CacheableTask
abstract class ManifestVersionCodeTask : DefaultTask() {
    /** The app's main `AndroidManifest.xml`. */
    @get:InputFile
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val mainManifest: RegularFileProperty

    /**
     * Variant name included in failure messages.
     *
     * `@Internal` rather than an input, so variants that share [mainManifest] share a build-cache
     * entry. The message stays correct because Gradle never caches a failed task.
     */
    @get:Internal
    abstract val variantName: Property<String>

    /** Output file containing the resolved base `versionCode` as a decimal integer. */
    @get:OutputFile
    abstract val versionCodeFile: RegularFileProperty

    /**
     * Parses `android:versionCode` from [mainManifest] and writes it to [versionCodeFile].
     *
     * @throws GradleException if [mainManifest] cannot be read or does not declare a positive
     *   integer `versionCode`.
     */
    @TaskAction
    fun writeVersionCode() {
        when (val result = ManifestVersionCodeTaskHelper.readVersionCode(mainManifest.get().asFile)) {
            is ManifestVersionCodeTaskHelper.Result.Found -> {
                versionCodeFile.get().asFile.writeText(result.versionCode.toString())
            }

            is ManifestVersionCodeTaskHelper.Result.NotFound -> {
                throw GradleException(ManifestVersionCodeTaskHelper.errorMessage(variantName.get(), result.reason))
            }
        }
    }
}

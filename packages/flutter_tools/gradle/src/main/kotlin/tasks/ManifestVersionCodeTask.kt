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
 * Extracts `android:versionCode` from [mainManifest] into [versionCodeFile] as the fallback
 * `versionCode` for `--split-per-abi` builds (see [ManifestVersionCodeTaskHelper.registerTask]).
 */
@CacheableTask
abstract class ManifestVersionCodeTask : DefaultTask() {
    /** The app's main `AndroidManifest.xml`. */
    @get:InputFile
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val mainManifest: RegularFileProperty

    /** Variant name included in failure messages. */
    @get:Internal
    // @Internal so variants sharing mainManifest share cache entries; Gradle never caches failed
    // tasks.
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

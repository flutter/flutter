// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import org.gradle.api.DefaultTask
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputFile
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.TaskAction

/**
 * Create a json file of deeplink settings from an AndroidManifest.
 *
 * This task does not modify the manifest despite using an api
 * designed for modification. The task is responsible for an exact copy of the input
 * manifest being used for the output manifest.
*/
abstract class DeepLinkJsonFromManifestTask : DefaultTask() {
    // Input property to receive the manifest file
    @get:InputFile
    abstract val manifestFile: RegularFileProperty

    // In the past for this task namespace was the ApplicationId.
    @get:Input
    abstract val namespace: Property<String>

    // Does not need to transform manifest at all but there does not appear to be another dsl
    // supported way to depend on the merged manifest.
    @get:OutputFile
    abstract val updatedManifest: RegularFileProperty

    @get:OutputFile
    abstract val deepLinkJson: RegularFileProperty

    @TaskAction
    fun processManifest() {
        manifestFile.get().asFile.copyTo(updatedManifest.get().asFile, overwrite = true)
        logger.debug("DeepLinkJsonFromManifestTask: Unmodified manifest written.")

        DeepLinkJsonFromManifestTaskHelper.createAppLinkSettingsFile(namespace.get(), manifestFile, deepLinkJson)
        logger.debug("DeepLinkJsonFromManifestTask: appLinkSettings written to ${deepLinkJson.get().asFile.absolutePath}.")
    }
}

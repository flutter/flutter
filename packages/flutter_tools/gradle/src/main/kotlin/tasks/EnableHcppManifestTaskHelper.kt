// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import groovy.util.Node
import groovy.xml.XmlNodePrinter
import groovy.xml.XmlParser
import java.io.File
import java.io.PrintWriter

import org.gradle.api.logging.Logger

/**
 * Stateless object to contain the logic used in [EnableHcppManifestTask].
 */
object EnableHcppManifestTaskHelper {
    private const val MANIFEST_NAME_KEY = "android:name"
    private const val MANIFEST_VALUE_KEY = "android:value"
    internal const val HCPP_METADATA_NAME = "io.flutter.embedding.android.EnableHcpp"

    /**
     * Processes [manifestFile] and writes to [updatedManifest].
     *
     * If [requestedEnableHcpp] is true and no `EnableHcpp` metadata is present, injects:
     * `<meta-data android:name="io.flutter.embedding.android.EnableHcpp" android:value="true"/>`.
     *
     * If [explicitEnableHcpp] is specified (non-null) and conflicts with an existing metadata
     * value in the merged manifest, logs a warning via [logger].
     */
    fun processHcppManifest(
        manifestFile: File,
        updatedManifest: File,
        requestedEnableHcpp: Boolean = true,
        explicitEnableHcpp: Boolean? = null,
        logger: Logger? = null,
    ) {
        val manifest: Node =
            XmlParser(false, false)
                .parse(manifestFile)
        val applicationNode: Node =
            manifest.children().filterIsInstance<Node>().find { node ->
                node.name() == "application"
            } ?: Node(manifest, "application")
        val metaDataNode: Node? =
            applicationNode.children().filterIsInstance<Node>().find { node ->
                node.name() == "meta-data" && node.attribute(MANIFEST_NAME_KEY) == HCPP_METADATA_NAME
            }

        if (metaDataNode != null) {
            val existingValueStr = metaDataNode.attribute(MANIFEST_VALUE_KEY)?.toString()
            val existingValueBool = existingValueStr?.toBoolean()

            if (explicitEnableHcpp != null && existingValueBool != null && explicitEnableHcpp != existingValueBool) {
                val flagName = if (explicitEnableHcpp) "--enable-hcpp" else "--no-enable-hcpp"
                logger?.warn(
                    "The merged Android manifest explicitly sets $HCPP_METADATA_NAME to \"$existingValueStr\"; " +
                        "therefore $flagName does not affect this artifact."
                )
            }
            manifestFile.copyTo(updatedManifest, overwrite = true)
            return
        }

        if (requestedEnableHcpp) {
            applicationNode.appendNode(
                "meta-data",
                mapOf(MANIFEST_NAME_KEY to HCPP_METADATA_NAME, MANIFEST_VALUE_KEY to "true")
            )
            updatedManifest.printWriter().use { writer: PrintWriter ->
                writer.println("""<?xml version="1.0" encoding="utf-8"?>""")
                XmlNodePrinter(writer).print(manifest)
            }
        } else {
            manifestFile.copyTo(updatedManifest, overwrite = true)
        }
    }

    /**
     * Legacy wrapper for [processHcppManifest] with [requestedEnableHcpp] = true.
     */
    fun addEnableHcppMetadataIfAbsent(
        manifestFile: File,
        updatedManifest: File,
    ) {
        processHcppManifest(
            manifestFile = manifestFile,
            updatedManifest = updatedManifest,
            requestedEnableHcpp = true,
        )
    }
}

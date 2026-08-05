// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import groovy.util.Node
import groovy.xml.XmlNodePrinter
import groovy.xml.XmlParser
import org.gradle.api.logging.Logger
import java.io.File
import java.io.PrintWriter

/**
 * Stateless object to contain the logic used in [EnableHcppManifestTask].
 */
object EnableHcppManifestTaskHelper {
    private const val MANIFEST_NAME_KEY = "android:name"
    private const val MANIFEST_VALUE_KEY = "android:value"
    internal const val HCPP_METADATA_NAME = "io.flutter.embedding.android.EnableHcpp"

    // The flutter tool flags that set the properties this task consumes. Only used to name the
    // flag the developer passed when reporting that it overrode the manifest.
    internal const val ENABLE_HCPP_FLAG = "--enable-hcpp"
    internal const val NO_ENABLE_HCPP_FLAG = "--no-enable-hcpp"

    /**
     * Processes [manifestFile] and writes to [updatedManifest].
     *
     * [explicitEnableHcpp] is the value of an explicit `--[no-]enable-hcpp`, or null when the
     * developer did not pass the flag. When it is non-null it is written to the merged manifest,
     * replacing any value already there: a flag passed at invocation time takes priority over
     * checked in configuration, matching how the same flag behaves at launch for
     * `flutter run`/`test`/`drive`, and how Gradle orders `-P` properties ahead of
     * `gradle.properties`.
     *
     * With no explicit flag, [requestedEnableHcpp] is only a default: it is injected when the
     * merged manifest does not set `EnableHcpp` at all, so an entry in the manifest wins.
     *
     * The resulting precedence is `--[no-]enable-hcpp` > AndroidManifest.xml > the tool's default.
     *
     * Note that the manifest is re-serialized from the parsed tree whenever it is modified,
     * which drops XML comments (including the provenance comments the manifest merger emits).
     * This is invisible to aapt2, but does affect the merged manifest as read by a human.
     */
    fun processHcppManifest(
        manifestFile: File,
        updatedManifest: File,
        requestedEnableHcpp: Boolean,
        explicitEnableHcpp: Boolean? = null,
        logger: Logger? = null
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

        val valueToWrite: String? =
            when {
                // An explicit flag always wins, whether or not the manifest already says something.
                explicitEnableHcpp != null -> explicitEnableHcpp.toString()
                // Otherwise only supply a default, and only when the manifest is silent.
                metaDataNode == null && requestedEnableHcpp -> true.toString()
                else -> null
            }
        if (valueToWrite == null) {
            manifestFile.copyTo(updatedManifest, overwrite = true)
            return
        }

        if (metaDataNode != null) {
            val existingValue = metaDataNode.attribute(MANIFEST_VALUE_KEY)?.toString()
            if (existingValue == valueToWrite) {
                manifestFile.copyTo(updatedManifest, overwrite = true)
                return
            }
            val flagName = if (explicitEnableHcpp == true) ENABLE_HCPP_FLAG else NO_ENABLE_HCPP_FLAG
            logger?.lifecycle(
                "$flagName overrides the merged Android manifest, which sets $HCPP_METADATA_NAME " +
                    "to \"$existingValue\". This artifact is built with $HCPP_METADATA_NAME=$valueToWrite."
            )
            metaDataNode.attributes()[MANIFEST_VALUE_KEY] = valueToWrite
        } else {
            applicationNode.appendNode(
                "meta-data",
                mapOf(MANIFEST_NAME_KEY to HCPP_METADATA_NAME, MANIFEST_VALUE_KEY to valueToWrite)
            )
        }
        updatedManifest.printWriter().use { writer: PrintWriter ->
            writer.println("""<?xml version="1.0" encoding="utf-8"?>""")
            XmlNodePrinter(writer).print(manifest)
        }
    }
}

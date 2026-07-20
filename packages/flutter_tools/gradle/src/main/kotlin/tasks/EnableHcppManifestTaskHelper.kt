// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import groovy.util.Node
import groovy.xml.XmlNodePrinter
import groovy.xml.XmlParser
import java.io.File
import java.io.PrintWriter

/**
 * Stateless object to contain the logic used in [EnableHcppManifestTask].
 */
object EnableHcppManifestTaskHelper {
    private const val MANIFEST_NAME_KEY = "android:name"
    private const val MANIFEST_VALUE_KEY = "android:value"
    internal const val HCPP_METADATA_NAME = "io.flutter.embedding.android.EnableHcpp"

    /**
     * Copies [manifestFile] to [updatedManifest], adding a
     * `<meta-data android:name="io.flutter.embedding.android.EnableHcpp" android:value="true"/>`
     * element to the `<application>` element if no meta-data with that name is already present.
     *
     * If the meta-data is already present (with any value), the manifest is copied unmodified so
     * that an explicit value always wins over the feature flag based injection.
     *
     * When injecting, the manifest is reparsed and rewritten. XML comments are not preserved;
     * the merged manifest is an intermediate artifact consumed by aapt2, which ignores them.
     * All elements and attributes are preserved.
     */
    fun addEnableHcppMetadataIfAbsent(
        manifestFile: File,
        updatedManifest: File
    ) {
        val manifest: Node =
            XmlParser(false, false)
                .parse(manifestFile)
        val applicationNode: Node =
            manifest.children().filterIsInstance<Node>().find { node ->
                node.name() == "application"
            } ?: Node(manifest, "application")
        val alreadySpecified: Boolean =
            applicationNode.children().filterIsInstance<Node>().any { node ->
                node.name() == "meta-data" && node.attribute(MANIFEST_NAME_KEY) == HCPP_METADATA_NAME
            }
        if (alreadySpecified) {
            manifestFile.copyTo(updatedManifest, overwrite = true)
            return
        }
        applicationNode.appendNode(
            "meta-data",
            mapOf(MANIFEST_NAME_KEY to HCPP_METADATA_NAME, MANIFEST_VALUE_KEY to "true")
        )
        updatedManifest.printWriter().use { writer: PrintWriter ->
            writer.println("""<?xml version="1.0" encoding="utf-8"?>""")
            XmlNodePrinter(writer).print(manifest)
        }
    }
}

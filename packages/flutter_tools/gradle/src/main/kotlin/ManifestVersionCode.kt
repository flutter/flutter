// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import org.xml.sax.InputSource
import java.io.StringReader
import javax.xml.parsers.DocumentBuilderFactory

/**
 * Reads a versionCode set with `android:versionCode` in a variant's manifest sources, for apps
 * that do not declare one in the DSL.
 */
internal object ManifestVersionCode {
    private const val ANDROID_NAMESPACE = "http://schemas.android.com/apk/res/android"
    private const val TOOLS_NAMESPACE = "http://schemas.android.com/tools"

    /** The result of [from]. */
    sealed interface Result {
        /** The highest-priority manifest that declares a versionCode sets it to [versionCode]. */
        data class Found(
            val versionCode: Int
        ) : Result

        /** The merged versionCode cannot be known without the manifest merger, see [reason]. */
        data class Unresolved(
            val reason: String
        ) : Result

        /** No manifest declares a versionCode. */
        data object None : Result
    }

    /**
     * Returns the `android:versionCode` of the highest-priority of [manifests] that declares one.
     *
     * [manifests] pairs each manifest's path with its contents, in priority order, highest first,
     * which is the order of AGP's `ManifestFiles.all`. Empty contents (a missing file) are skipped.
     * The result is [Result.Unresolved] if that
     * manifest's value is not an integer (for example a `${placeholder}`), or if a higher-priority
     * manifest removes `android:versionCode` with `tools:remove` or sets a `tools:node` other than
     * `merge` on its root element.
     */
    fun from(manifests: List<Pair<String, String>>): Result {
        for ((manifest, contents) in manifests) {
            if (contents.isBlank()) {
                continue
            }
            val factory = DocumentBuilderFactory.newInstance()
            factory.isNamespaceAware = true
            factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)
            val root = factory.newDocumentBuilder().parse(InputSource(StringReader(contents))).documentElement
            val removed = root.getAttributeNS(TOOLS_NAMESPACE, "remove").split(',').map { it.trim() }
            val node = root.getAttributeNS(TOOLS_NAMESPACE, "node")
            if ("android:versionCode" in removed || (node.isNotEmpty() && node != "merge")) {
                return Result.Unresolved(
                    "$manifest uses tools:remove=\"android:versionCode\" or tools:node on <manifest>"
                )
            }
            if (root.hasAttributeNS(ANDROID_NAMESPACE, "versionCode")) {
                val value = root.getAttributeNS(ANDROID_NAMESPACE, "versionCode")
                return value.trim().toIntOrNull()?.let { Result.Found(it) }
                    ?: Result.Unresolved("$manifest sets android:versionCode=\"$value\", which is not an integer")
            }
        }
        return Result.None
    }
}

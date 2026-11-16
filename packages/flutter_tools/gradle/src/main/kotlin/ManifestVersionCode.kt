// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import org.w3c.dom.Element
import org.xml.sax.SAXException
import java.io.ByteArrayInputStream
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
     * Returns the versionCode that AGP gives a variant whose DSL declares none.
     *
     * [manifests] pairs each manifest's path with its bytes, in the order of AGP's
     * `ManifestFiles.all`: highest priority first, and the main manifest
     * (`src/main/AndroidManifest.xml` by default) last. A null or empty manifest (a missing file)
     * is skipped. The bytes are parsed as XML, so a byte order mark or an `encoding` declaration
     * is honored.
     *
     * AGP injects the main manifest's integer `android:versionCode` into the merged manifest,
     * over any value or `tools:` rule in a higher-priority manifest, so that value wins. Only
     * when the main manifest declares no integer versionCode does the manifest merger decide,
     * and then the highest-priority manifest that declares one wins.
     *
     * In that case the result is [Result.Unresolved] if that manifest's value is not an integer
     * (for example a `${placeholder}`), if a manifest cannot be parsed, or if a higher-priority
     * manifest that does not declare a versionCode drops the lower-priority ones: it removes
     * `android:versionCode` with `tools:remove`, or sets `tools:node="replace"` or
     * `tools:node="strict"` on its root element.
     */
    fun from(manifests: List<Pair<String, ByteArray?>>): Result {
        val factory = DocumentBuilderFactory.newInstance()
        factory.isNamespaceAware = true
        factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)
        val builder = factory.newDocumentBuilder()
        // Without this, Xerces prints "[Fatal Error]" to System.err before throwing.
        builder.setErrorHandler(null)
        val roots =
            manifests.mapNotNull { (manifest, contents) ->
                if (contents == null || contents.isEmpty()) {
                    return@mapNotNull null
                }
                try {
                    manifest to builder.parse(ByteArrayInputStream(contents)).documentElement
                } catch (e: SAXException) {
                    return Result.Unresolved("$manifest could not be parsed (${e.message})")
                }
            }
        // The main manifest is last in ManifestFiles.all. AGP injects its integer versionCode.
        val (lastManifest, lastRoot) = roots.lastOrNull() ?: return Result.None
        if (lastManifest == manifests.last().first) {
            lastRoot.getAttributeNS(ANDROID_NAMESPACE, "versionCode").trim().toIntOrNull()?.let {
                return Result.Found(it)
            }
        }
        for ((manifest, root) in roots) {
            if (removesVersionCode(root)) {
                return Result.Unresolved("$manifest removes it with tools:remove")
            }
            if (root.hasAttributeNS(ANDROID_NAMESPACE, "versionCode")) {
                val value = root.getAttributeNS(ANDROID_NAMESPACE, "versionCode")
                return value.trim().toIntOrNull()?.let { Result.Found(it) }
                    ?: Result.Unresolved("$manifest sets android:versionCode=\"$value\", which is not an integer")
            }
            // A manifest that declares no versionCode, but replaces the lower-priority <manifest>
            // elements or must match them exactly, leaves the merged versionCode to the merger.
            val node = root.getAttributeNS(TOOLS_NAMESPACE, "node")
            if (node == "replace" || node == "strict") {
                return Result.Unresolved("$manifest sets tools:node=\"$node\" on <manifest>")
            }
        }
        return Result.None
    }

    /**
     * Whether [root]'s `tools:remove` lists `android:versionCode`, under any prefix bound to the
     * Android namespace.
     */
    private fun removesVersionCode(root: Element): Boolean =
        root.getAttributeNS(TOOLS_NAMESPACE, "remove").split(',').any { name ->
            val prefix = name.trim().substringBefore(':', missingDelimiterValue = "")
            name.trim().substringAfter(':') == "versionCode" &&
                prefix.isNotEmpty() &&
                root.lookupNamespaceURI(prefix) == ANDROID_NAMESPACE
        }
}

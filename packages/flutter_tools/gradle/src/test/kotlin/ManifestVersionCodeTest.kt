// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.flutter.gradle.ManifestVersionCode.Result
import java.io.ByteArrayOutputStream
import java.io.PrintStream
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertIs

class ManifestVersionCodeTest {
    private fun manifestText(attributes: String): String =
        """
        <manifest xmlns:android="http://schemas.android.com/apk/res/android"
            xmlns:tools="http://schemas.android.com/tools" $attributes>
            <application android:label="app" />
        </manifest>
        """.trimIndent()

    private fun manifest(
        name: String,
        attributes: String
    ): Pair<String, ByteArray?> = name to manifestText(attributes).toByteArray()

    // ManifestFiles.all lists the main manifest last.
    private val mainWithout = manifest("main.xml", "")

    @Test
    fun `reads android versionCode from the main manifest`() {
        assertEquals(Result.Found(7), ManifestVersionCode.from(listOf(manifest("main.xml", "android:versionCode=\" 7 \""))))
    }

    @Test
    fun `the main manifest's integer versionCode wins over higher-priority manifests`() {
        // AGP injects it into the merged manifest, over values and tools rules in overlays.
        val main = manifest("main.xml", "android:versionCode=\"7\"")
        val overlays =
            listOf(
                manifest("release.xml", "android:versionCode=\"9\" tools:replace=\"android:versionCode\""),
                manifest("release.xml", "android:versionCode=\"9\" tools:node=\"replace\""),
                manifest("release.xml", "tools:remove=\"android:versionCode\""),
                manifest("release.xml", "tools:node=\"replace\""),
                manifest("release.xml", "android:versionCode=\"\${vc}\" tools:replace=\"android:versionCode\"")
            )
        for (overlay in overlays) {
            assertEquals(Result.Found(7), ManifestVersionCode.from(listOf(overlay, main)))
        }
    }

    @Test
    fun `without one in the main manifest, the first manifest that declares a versionCode wins`() {
        val missing = "missing.xml" to null
        val empty = "empty.xml" to ByteArray(0)
        val release = manifest("release.xml", "tools:remove=\"android:sharedUserId\" tools:node=\"merge\"")
        val flavor = manifest("free.xml", "android:versionCode=\"9\"")
        val buildType = manifest("debug.xml", "android:versionCode=\"8\"")

        assertEquals(Result.Found(9), ManifestVersionCode.from(listOf(missing, empty, release, flavor, buildType, mainWithout)))
    }

    @Test
    fun `without a main manifest, the lowest-priority overlay is not read as the main manifest`() {
        val flavor = manifest("free.xml", "android:versionCode=\"9\"")
        val buildType = manifest("debug.xml", "android:versionCode=\"8\"")

        assertEquals(Result.Found(9), ManifestVersionCode.from(listOf(flavor, buildType, "main.xml" to null)))
    }

    @Test
    fun `a placeholder in the main manifest is unresolved`() {
        val main = manifest("main.xml", "android:versionCode=\"\${vc}\"")

        val result = assertIs<Result.Unresolved>(ManifestVersionCode.from(listOf(main)))
        assertContains(result.reason, "\${vc}")
    }

    @Test
    fun `a placeholder in a higher-priority manifest is unresolved, not skipped`() {
        val release = manifest("release.xml", "android:versionCode=\"\${vc}\"")
        val flavor = manifest("free.xml", "android:versionCode=\"8\"")

        val result = assertIs<Result.Unresolved>(ManifestVersionCode.from(listOf(release, flavor, mainWithout)))
        assertContains(result.reason, "\${vc}")
    }

    @Test
    fun `tools remove of versionCode in a higher-priority manifest is unresolved`() {
        val release = manifest("release.xml", "tools:remove=\"android:label, android:versionCode\"")
        val flavor = manifest("free.xml", "android:versionCode=\"8\"")

        val result = assertIs<Result.Unresolved>(ManifestVersionCode.from(listOf(release, flavor, mainWithout)))
        assertContains(result.reason, "tools:remove")
    }

    @Test
    fun `tools remove of versionCode under another Android namespace prefix is unresolved`() {
        val release =
            "release.xml" to
                """
                <manifest xmlns:a="http://schemas.android.com/apk/res/android"
                    xmlns:tools="http://schemas.android.com/tools" tools:remove="a:versionCode" />
                """.trimIndent().toByteArray()
        val flavor = manifest("free.xml", "android:versionCode=\"8\"")

        assertIs<Result.Unresolved>(ManifestVersionCode.from(listOf(release, flavor, mainWithout)))
    }

    @Test
    fun `tools node replace or strict without a versionCode in a higher-priority manifest is unresolved`() {
        val flavor = manifest("free.xml", "android:versionCode=\"8\"")
        for (node in listOf("replace", "strict")) {
            val release = manifest("release.xml", "tools:node=\"$node\"")

            val result = assertIs<Result.Unresolved>(ManifestVersionCode.from(listOf(release, flavor, mainWithout)))
            assertContains(result.reason, "tools:node=\"$node\"")
        }
    }

    @Test
    fun `a manifest with tools node replace that declares a versionCode wins`() {
        val release = manifest("release.xml", "tools:node=\"replace\" android:versionCode=\"9\"")
        val flavor = manifest("free.xml", "android:versionCode=\"8\"")

        assertEquals(Result.Found(9), ManifestVersionCode.from(listOf(release, flavor, mainWithout)))
    }

    @Test
    fun `tools node merge or mergeOnlyAttributes without a versionCode is skipped`() {
        val flavor = manifest("free.xml", "android:versionCode=\"8\"")
        for (node in listOf("merge", "mergeOnlyAttributes")) {
            val release = manifest("release.xml", "tools:node=\"$node\"")

            assertEquals(Result.Found(8), ManifestVersionCode.from(listOf(release, flavor, mainWithout)))
        }
    }

    @Test
    fun `reads a manifest with a byte order mark`() {
        val bom = byteArrayOf(0xEF.toByte(), 0xBB.toByte(), 0xBF.toByte())
        val main = "main.xml" to bom + manifestText("android:versionCode=\"7\"").toByteArray()

        assertEquals(Result.Found(7), ManifestVersionCode.from(listOf(main)))
    }

    @Test
    fun `reads a manifest in the encoding its XML declaration names`() {
        val text = "<?xml version=\"1.0\" encoding=\"UTF-16\"?>\n" + manifestText("android:versionCode=\"7\"")
        val main = "main.xml" to text.toByteArray(Charsets.UTF_16)

        assertEquals(Result.Found(7), ManifestVersionCode.from(listOf(main)))
    }

    @Test
    fun `a manifest that cannot be parsed is unresolved`() {
        val stderr = ByteArrayOutputStream()
        val originalErr = System.err
        System.setErr(PrintStream(stderr))
        val result =
            try {
                assertIs<Result.Unresolved>(ManifestVersionCode.from(listOf("broken.xml" to "<manifest".toByteArray())))
            } finally {
                System.setErr(originalErr)
            }
        assertContains(result.reason, "broken.xml could not be parsed")
        // The reason carries the parser's message, so nothing is printed to stderr.
        assertEquals("", stderr.toString())
    }

    @Test
    fun `ignores a versionCode outside the android namespace`() {
        assertEquals(Result.None, ManifestVersionCode.from(listOf(manifest("main.xml", "versionCode=\"7\""))))
    }

    @Test
    fun `returns None when no manifest declares a versionCode`() {
        assertEquals(Result.None, ManifestVersionCode.from(listOf(manifest("debug.xml", ""), mainWithout)))
        assertEquals(Result.None, ManifestVersionCode.from(listOf(mainWithout, "missing.xml" to null)))
        assertEquals(Result.None, ManifestVersionCode.from(emptyList()))
    }
}

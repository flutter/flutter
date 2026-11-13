// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.flutter.gradle.ManifestVersionCode.Result
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs

class ManifestVersionCodeTest {
    private fun manifest(
        name: String,
        attributes: String
    ): Pair<String, String> =
        name to
            """
            <manifest xmlns:android="http://schemas.android.com/apk/res/android"
                xmlns:tools="http://schemas.android.com/tools" $attributes>
                <application android:label="app" />
            </manifest>
            """.trimIndent()

    @Test
    fun `reads android versionCode from the manifest`() {
        assertEquals(Result.Found(7), ManifestVersionCode.from(listOf(manifest("main.xml", "android:versionCode=\" 7 \""))))
    }

    @Test
    fun `the first manifest that declares a versionCode wins`() {
        val missing = "missing.xml" to ""
        val release = manifest("release.xml", "tools:remove=\"android:sharedUserId\" tools:node=\"merge\"")
        val flavor = manifest("free.xml", "android:versionCode=\"9\" tools:replace=\"android:versionCode\"")
        val main = manifest("main.xml", "android:versionCode=\"7\"")

        assertEquals(Result.Found(9), ManifestVersionCode.from(listOf(missing, release, flavor, main)))
    }

    @Test
    fun `a placeholder in a higher-priority manifest is unresolved, not skipped`() {
        val release = manifest("release.xml", "android:versionCode=\"\${vc}\" tools:replace=\"android:versionCode\"")
        val main = manifest("main.xml", "android:versionCode=\"8\"")

        val result = assertIs<Result.Unresolved>(ManifestVersionCode.from(listOf(release, main)))
        assertEquals(true, result.reason.contains("\${vc}"))
    }

    @Test
    fun `tools remove of versionCode in a higher-priority manifest is unresolved`() {
        val release = manifest("release.xml", "tools:remove=\"android:label, android:versionCode\"")
        val main = manifest("main.xml", "android:versionCode=\"8\"")

        assertIs<Result.Unresolved>(ManifestVersionCode.from(listOf(release, main)))
    }

    @Test
    fun `tools node other than merge in a higher-priority manifest is unresolved`() {
        val release = manifest("release.xml", "tools:node=\"replace\"")
        val main = manifest("main.xml", "android:versionCode=\"8\"")

        assertIs<Result.Unresolved>(ManifestVersionCode.from(listOf(release, main)))
    }

    @Test
    fun `ignores a versionCode outside the android namespace`() {
        assertEquals(Result.None, ManifestVersionCode.from(listOf(manifest("main.xml", "versionCode=\"7\""))))
    }

    @Test
    fun `returns None when no manifest declares a versionCode`() {
        assertEquals(Result.None, ManifestVersionCode.from(listOf(manifest("main.xml", ""))))
        assertEquals(Result.None, ManifestVersionCode.from(emptyList()))
    }
}

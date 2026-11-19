// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import com.flutter.gradle.tasks.ManifestVersionCodeTaskHelper.Result
import org.junit.jupiter.api.io.TempDir
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.PrintStream
import java.nio.file.Path
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs

class ManifestVersionCodeTaskHelperTest {
    @TempDir
    lateinit var tempDir: Path

    /** Writes an AndroidManifest.xml whose root element has [attributes], and returns it. */
    private fun manifest(attributes: String): File =
        tempDir.resolve("AndroidManifest.xml").toFile().apply {
            writeText(
                """
                <manifest xmlns:android="http://schemas.android.com/apk/res/android" $attributes>
                    <application android:label="app" />
                </manifest>
                """.trimIndent()
            )
        }

    private fun readVersionCode(attributes: String): Result = ManifestVersionCodeTaskHelper.readVersionCode(manifest(attributes))

    @Test
    fun `reads a positive android versionCode`() {
        assertEquals(Result.Found(7), readVersionCode("android:versionCode=\"7\""))
        assertEquals(Result.Found(7), readVersionCode("android:versionCode=\" 7 \""))
        assertEquals(Result.Found(7), readVersionCode("android:versionCode=\"+7\""))
    }

    @Test
    fun `matches the Android namespace, not the android prefix`() {
        val manifest =
            tempDir.resolve("AndroidManifest.xml").toFile().apply {
                writeText("""<manifest xmlns:a="http://schemas.android.com/apk/res/android" a:versionCode="7"/>""")
            }
        assertEquals(Result.Found(7), ManifestVersionCodeTaskHelper.readVersionCode(manifest))
        assertIs<Result.NotFound>(readVersionCode("versionCode=\"7\""))
    }

    @Test
    fun `a missing versionCode is not found`() {
        val result = assertIs<Result.NotFound>(readVersionCode(""))
        assertContains(result.reason, "does not set android:versionCode")
    }

    @Test
    fun `a value that is not a decimal integer is not found`() {
        // AGP parses android:versionCode with Integer.parseInt, so it rejects these too.
        for (value in listOf("\${versionCode}", "@integer/version_code", "0x10", "++7", "+")) {
            val result = assertIs<Result.NotFound>(readVersionCode("android:versionCode=\"$value\""))
            assertContains(result.reason, "android:versionCode=\"$value\"")
            assertContains(result.reason, "is not a decimal integer")
        }
    }

    @Test
    fun `a versionCode larger than Int MAX_VALUE is not found`() {
        for (value in listOf("2147483648", "+2147483648")) {
            val result = assertIs<Result.NotFound>(readVersionCode("android:versionCode=\"$value\""))
            assertContains(result.reason, "android:versionCode=\"$value\"")
            assertContains(result.reason, "is larger than 2147483647")
        }
        assertEquals(Result.Found(Int.MAX_VALUE), readVersionCode("android:versionCode=\"2147483647\""))
    }

    @Test
    fun `zero or a negative versionCode is not found`() {
        // AGP does not write these into the merged manifest, and Google Play rejects them.
        for (value in listOf("0", "-1", "+-7", "-99999999999")) {
            val result = assertIs<Result.NotFound>(readVersionCode("android:versionCode=\"$value\""))
            assertContains(result.reason, "is not positive")
        }
    }

    @Test
    fun `a manifest with a DOCTYPE is not parsed`() {
        val manifest =
            tempDir.resolve("AndroidManifest.xml").toFile().apply {
                writeText(
                    """
                    <!DOCTYPE manifest [<!ENTITY vc "7">]>
                    <manifest xmlns:android="http://schemas.android.com/apk/res/android" android:versionCode="&vc;"/>
                    """.trimIndent()
                )
            }
        val result = assertIs<Result.NotFound>(ManifestVersionCodeTaskHelper.readVersionCode(manifest))
        assertContains(result.reason, "could not be parsed")
    }

    @Test
    fun `a manifest that cannot be parsed is not found, and nothing is printed`() {
        val manifest = tempDir.resolve("AndroidManifest.xml").toFile().apply { writeText("<manifest") }
        val stderr = ByteArrayOutputStream()
        val originalErr = System.err
        System.setErr(PrintStream(stderr))
        val result =
            try {
                assertIs<Result.NotFound>(ManifestVersionCodeTaskHelper.readVersionCode(manifest))
            } finally {
                System.setErr(originalErr)
            }
        assertContains(result.reason, "$manifest could not be parsed")
        assertEquals("", stderr.toString())
    }

    @Test
    fun `a missing manifest is not found`() {
        val missing = tempDir.resolve("missing.xml").toFile()
        val result = assertIs<Result.NotFound>(ManifestVersionCodeTaskHelper.readVersionCode(missing))
        assertContains(result.reason, "$missing could not be read")
    }

    @Test
    fun `reads a manifest in the encoding its XML declaration names`() {
        val manifest =
            tempDir.resolve("AndroidManifest.xml").toFile().apply {
                writeBytes(
                    (
                        "<?xml version=\"1.0\" encoding=\"UTF-16\"?>\n" +
                            "<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\" android:versionCode=\"7\"/>"
                    ).toByteArray(Charsets.UTF_16)
                )
            }
        assertEquals(Result.Found(7), ManifestVersionCodeTaskHelper.readVersionCode(manifest))
    }

    @Test
    fun `the error message names the variant, the reason, and the fix`() {
        val message = ManifestVersionCodeTaskHelper.errorMessage("freeRelease", "the manifest does not set android:versionCode")
        assertContains(message, "variant 'freeRelease'")
        assertContains(message, "the manifest does not set android:versionCode")
        assertContains(message, "versionCode = flutter.versionCode")
        assertContains(message, "versionCode 0")
        // The build fails with that flag too, so suggesting it would not help.
        assertFalse(message.contains("force-version-code-ignoring-abi"))
    }
}

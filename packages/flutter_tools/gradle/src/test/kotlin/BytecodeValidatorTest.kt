// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import org.junit.jupiter.api.io.TempDir
import java.io.File
import java.nio.file.Path
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Validates the bytecode search pattern and file filtering algorithm used by the
 * `:validateNoCommonExtensionInBytecode` task in packages/flutter_tools/gradle/build.gradle.kts.
 *
 * Keep the scanning needle and class filtering logic in sync with build.gradle.kts.
 */
class BytecodeValidatorTest {
    private val needle = "com/android/build/api/dsl/CommonExtension".toByteArray(Charsets.ISO_8859_1)

    /** Returns true if [bytes] contains the forbidden binary needle pattern. */
    private fun containsForbiddenReference(bytes: ByteArray): Boolean =
        (0..bytes.size - needle.size).any { start ->
            needle.indices.all { i -> bytes[start + i] == needle[i] }
        }

    /** Walks [dir] recursively and returns names of any `.class` files containing forbidden references. */
    private fun findOffendingClasses(dir: File): List<String> =
        dir
            .walkTopDown()
            .filter { it.isFile && it.extension == "class" }
            .filter { containsForbiddenReference(it.readBytes()) }
            .map { it.name }
            .toList()

    @Test
    fun `detects forbidden CommonExtension byte sequence in class bytes`() {
        val cleanBytes = "com/android/build/api/dsl/ApplicationExtension".toByteArray(Charsets.ISO_8859_1)
        val dirtyBytes = "SomeHeader/com/android/build/api/dsl/CommonExtension/SomeFooter".toByteArray(Charsets.ISO_8859_1)

        assertFalse(containsForbiddenReference(cleanBytes))
        assertTrue(containsForbiddenReference(dirtyBytes))
    }

    @Test
    fun `findOffendingClasses identifies violating class files in directory`(
        @TempDir tempDir: Path
    ) {
        val root = tempDir.toFile()
        val cleanClass = File(root, "CleanPlugin.class")
        cleanClass.writeBytes("com/android/build/api/dsl/LibraryExtension".toByteArray(Charsets.ISO_8859_1))

        val dirtyClass = File(root, "ViolatingPlugin.class")
        dirtyClass.writeBytes("Lcom/android/build/api/dsl/CommonExtension;".toByteArray(Charsets.ISO_8859_1))

        val nonClassFile = File(root, "Readme.txt")
        nonClassFile.writeBytes("com/android/build/api/dsl/CommonExtension".toByteArray(Charsets.ISO_8859_1))

        val offenders = findOffendingClasses(root)
        assertEquals(listOf("ViolatingPlugin.class"), offenders)
    }

    @Test
    fun `findOffendingClasses returns empty list for empty directory or non-class files`(
        @TempDir tempDir: Path
    ) {
        val root = tempDir.toFile()
        assertEquals(emptyList(), findOffendingClasses(root))

        val nonClassFile = File(root, "Notes.md")
        nonClassFile.writeText("No compiled classes here")
        assertEquals(emptyList(), findOffendingClasses(root))
    }
}

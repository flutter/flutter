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
 * Validates that no compiled main class in the Flutter Gradle Plugin references
 * `com.android.build.api.dsl.CommonExtension`.
 *
 * `CommonExtension` is binary-incompatible between AGP 8 and AGP 9 (the interface methods and
 * generic descriptors changed when `android.newDsl=true` became default in AGP 9.0). FGP routes
 * all DSL access through [AgpCommonExtensionWrapper] to maintain binary compatibility across both
 * AGP 8 and 9.
 *
 * This test and [AgpCommonExtensionWrapper] can be safely deleted when Flutter drops support for
 * AGP 8.x (i.e. when the minimum supported AGP version is >= 9.0.0).
 */
class BytecodeValidatorTest {
    private val needle = "com/android/build/api/dsl/CommonExtension".toByteArray(Charsets.ISO_8859_1)

    /** Returns true if [bytes] contains the forbidden binary needle pattern. */
    private fun containsForbiddenReference(bytes: ByteArray): Boolean =
        (0..bytes.size - needle.size).any { start ->
            needle.indices.all { i -> bytes[start + i] == needle[i] }
        }

    /** Walks [dir] recursively and returns relative paths of any `.class` files containing forbidden references. */
    private fun findOffendingClasses(dir: File): List<String> =
        dir
            .walkTopDown()
            .filter { it.isFile && it.extension == "class" }
            .filter { containsForbiddenReference(it.readBytes()) }
            .map { it.relativeTo(dir).path }
            .toList()

    @Test
    fun `no compiled main classes reference CommonExtension`() {
        val testClassesUri =
            BytecodeValidatorTest::class.java
                .protectionDomain
                .codeSource
                .location
                .toURI()
        val testClassesDir = File(testClassesUri)
        val mainClassesDir = testClassesDir.parentFile.resolve("main")
        assertTrue(mainClassesDir.exists(), "Main classes directory does not exist at: ${mainClassesDir.absolutePath}")

        val offendingClasses = findOffendingClasses(mainClassesDir)
        assertTrue(
            offendingClasses.isEmpty(),
            "CommonExtension must not be referenced from Flutter Gradle Plugin bytecode " +
                "(binary incompatible between AGP 8 and 9). Route DSL access through " +
                "AgpCommonExtensionWrapper instead. Offending classes: $offendingClasses"
        )
    }

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

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import java.io.File
import kotlin.test.Test
import kotlin.test.assertTrue

/**
 * Guards the AGP public-API migration (https://github.com/flutter/flutter/issues/180137):
 * production sources must not use AGP internals. AGP 10 removes access to internals
 * entirely, and the Flutter Gradle Plugin will compile against the `gradle-api` artifact,
 * where they do not exist. Test sources may still reference internal types until the
 * dependency swap.
 */
class InternalAgpApiImportTest {
    @Test
    fun `main sources do not import AGP internals`() {
        // The Gradle test JVM runs with the project directory
        // (packages/flutter_tools/gradle) as its working directory.
        val mainSources = File("src/main")
        assertTrue(
            mainSources.isDirectory,
            "Expected to find src/main relative to the test working directory " +
                "(${File(".").absolutePath})."
        )
        val internalImport = Regex("""^\s*import\s+com\.android\.build\.gradle\.internal\.""")
        val offendingLines =
            mainSources
                .walkTopDown()
                .filter { it.isFile && it.extension in setOf("kt", "java", "groovy", "gradle") }
                .flatMap { file ->
                    file.readLines().mapIndexedNotNull { index, line ->
                        if (internalImport.containsMatchIn(line)) {
                            "${file.path}:${index + 1}: ${line.trim()}"
                        } else {
                            null
                        }
                    }
                }.toList()
        assertTrue(
            offendingLines.isEmpty(),
            "AGP internal APIs must not be used in production sources; they are removed in " +
                "AGP 10. Use the public com.android.build.api surface (see " +
                "docs/platforms/android/Migrating-Flutter-Gradle-Plugin-to-AGP-public-API.md).\n" +
                offendingLines.joinToString("\n")
        )
    }
}

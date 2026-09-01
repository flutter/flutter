// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.validation

import java.io.File
import kotlin.test.Test
import kotlin.test.assertTrue

/**
 * Guards the AGP public-API migration (https://github.com/flutter/flutter/issues/180137):
 * production sources must use the public AGP DSL surface rather than AGP internals
 * (`com.android.build.gradle.internal.*`), ensuring the Flutter Gradle Plugin is ready
 * to compile against the public `gradle-api` artifact where internal packages are absent.
 * Test sources may still reference internal types until the compile-time dependency swap.
 */
class InternalAgpApiImportTest {
    @Test
    fun `main sources do not import AGP internals`() {
        val workingDir = File(".")
        val mainSources =
            listOf(
                File("src/main"),
                File("packages/flutter_tools/gradle/src/main")
            ).firstOrNull { it.isDirectory }
        assertTrue(
            mainSources != null,
            "Expected to find src/main relative to test working directory (${workingDir.absolutePath})."
        )
        val internalApiPattern = Regex("""\bcom\.android\.build\.gradle\.internal\b|\bcom\.android\.builder\.internal\b""")
        val offendingLines =
            mainSources
                .walkTopDown()
                .filter { it.isFile && it.extension in setOf("kt", "java", "groovy", "gradle") }
                .flatMap { file ->
                    file.readLines().mapIndexedNotNull { index, line ->
                        if (internalApiPattern.containsMatchIn(line)) {
                            "${file.path}:${index + 1}: ${line.trim()}"
                        } else {
                            null
                        }
                    }
                }.toList()
        assertTrue(
            offendingLines.isEmpty(),
            "AGP internal APIs must not be used in production sources. Use the public " +
                "com.android.build.api surface (see " +
                "docs/platforms/android/Migrating-Flutter-Gradle-Plugin-to-AGP-public-API.md).\n" +
                offendingLines.joinToString("\n")
        )
    }
}

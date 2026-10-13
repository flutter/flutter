// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import org.junit.jupiter.api.io.TempDir
import java.io.File
import java.nio.file.Path
import kotlin.test.Test
import kotlin.test.assertEquals

class CompileSdkLocatorTest {
    private fun writeFile(
        root: Path,
        relativePath: String,
        content: String
    ): File {
        val file = root.resolve(relativePath).toFile()
        file.parentFile.mkdirs()
        file.writeText(content.trimIndent())
        return file
    }

    @Test
    fun `locates an integer literal in a Groovy build file`(
        @TempDir tempDir: Path
    ) {
        val buildFile =
            writeFile(
                tempDir,
                "app/build.gradle",
                """
                apply plugin: 'com.android.application'

                android {
                    namespace = "io.flutter.add2app"
                    compileSdk = 35
                }
                """
            )

        val location = CompileSdkLocator.locate(buildFile, tempDir.toFile())

        assertEquals(CompileSdkLocation.BuildFile(buildFile, line = 5), location)
    }

    @Test
    fun `locates compileSdkVersion without an equals sign`(
        @TempDir tempDir: Path
    ) {
        val buildFile =
            writeFile(
                tempDir,
                "app/build.gradle",
                """
                android {
                    compileSdkVersion 34
                }
                """
            )

        val location = CompileSdkLocator.locate(buildFile, tempDir.toFile())

        assertEquals(CompileSdkLocation.BuildFile(buildFile, line = 2), location)
    }

    @Test
    fun `locates compileSdkVersion call syntax in a Kotlin build file`(
        @TempDir tempDir: Path
    ) {
        val buildFile =
            writeFile(
                tempDir,
                "app/build.gradle.kts",
                """
                android {
                    compileSdkVersion(34)
                }
                """
            )

        val location = CompileSdkLocator.locate(buildFile, tempDir.toFile())

        assertEquals(CompileSdkLocation.BuildFile(buildFile, line = 2), location)
    }

    @Test
    fun `locates compileSdkPreview string literal`(
        @TempDir tempDir: Path
    ) {
        val buildFile =
            writeFile(
                tempDir,
                "app/build.gradle.kts",
                """
                android {
                    compileSdkPreview = "Baklava"
                }
                """
            )

        val location = CompileSdkLocator.locate(buildFile, tempDir.toFile())

        assertEquals(CompileSdkLocation.BuildFile(buildFile, line = 2), location)
    }

    @Test
    fun `locates the AGP 9 block form`(
        @TempDir tempDir: Path
    ) {
        val buildFile =
            writeFile(
                tempDir,
                "app/build.gradle.kts",
                """
                android {
                    compileSdk {
                        version = release(36) { minorApiLevel = 1 }
                    }
                }
                """
            )

        val location = CompileSdkLocator.locate(buildFile, tempDir.toFile())

        assertEquals(CompileSdkLocation.BuildFile(buildFile, line = 2), location)
    }

    @Test
    fun `ignores commented out declarations and similarly named properties`(
        @TempDir tempDir: Path
    ) {
        val buildFile =
            writeFile(
                tempDir,
                "app/build.gradle.kts",
                """
                android {
                    // compileSdk = 30
                    defaultConfig {
                        aarMetadata { minCompileSdk = 29 }
                        compileSdkExtension = 1
                    }
                    compileSdk = 36
                }
                """
            )

        val location = CompileSdkLocator.locate(buildFile, tempDir.toFile())

        assertEquals(CompileSdkLocation.BuildFile(buildFile, line = 7), location)
    }

    @Test
    fun `resolves a version catalog reference to the toml entry`(
        @TempDir tempDir: Path
    ) {
        val catalogFile =
            writeFile(
                tempDir,
                "gradle/libs.versions.toml",
                """
                [versions]
                agp = "9.3.1"
                compileSdk = "35"

                [libraries]
                compileSdk = { module = "not:a-version", version = "1.0" }
                """
            )
        val buildFile =
            writeFile(
                tempDir,
                "app/build.gradle.kts",
                """
                android {
                    compileSdk = libs.versions.compileSdk.get().toInt()
                }
                """
            )

        val location = CompileSdkLocator.locate(buildFile, tempDir.toFile())

        assertEquals(
            CompileSdkLocation.VersionCatalog(
                file = catalogFile,
                line = 3,
                key = "compileSdk",
                referencedFrom = buildFile,
                referencedFromLine = 2
            ),
            location
        )
    }

    @Test
    fun `resolves version catalog aliases that use separators`(
        @TempDir tempDir: Path
    ) {
        val catalogFile =
            writeFile(
                tempDir,
                "gradle/libs.versions.toml",
                """
                [versions]
                android-compileSdk = "35"
                """
            )
        val buildFile =
            writeFile(
                tempDir,
                "app/build.gradle",
                """
                android {
                    compileSdk libs.versions.android.compileSdk.get().toInteger()
                }
                """
            )

        val location = CompileSdkLocator.locate(buildFile, tempDir.toFile())

        assertEquals(
            CompileSdkLocation.VersionCatalog(
                file = catalogFile,
                line = 2,
                key = "android-compileSdk",
                referencedFrom = buildFile,
                referencedFromLine = 2
            ),
            location
        )
    }

    @Test
    fun `falls back to unresolved when the version catalog entry is missing`(
        @TempDir tempDir: Path
    ) {
        writeFile(
            tempDir,
            "gradle/libs.versions.toml",
            """
            [versions]
            agp = "9.3.1"
            """
        )
        val buildFile =
            writeFile(
                tempDir,
                "app/build.gradle.kts",
                """
                android {
                    compileSdk = libs.versions.compileSdk.get().toInt()
                }
                """
            )

        val location = CompileSdkLocator.locate(buildFile, tempDir.toFile())

        assertEquals(
            CompileSdkLocation.Unresolved(
                buildFile,
                line = 2,
                expression = "libs.versions.compileSdk.get().toInt()"
            ),
            location
        )
    }

    @Test
    fun `reports unresolved expressions such as ext properties`(
        @TempDir tempDir: Path
    ) {
        val buildFile =
            writeFile(
                tempDir,
                "app/build.gradle",
                """
                android {
                    compileSdk = rootProject.ext.compileSdkVersion
                }
                """
            )

        val location = CompileSdkLocator.locate(buildFile, tempDir.toFile())

        assertEquals(
            CompileSdkLocation.Unresolved(buildFile, line = 2, expression = "rootProject.ext.compileSdkVersion"),
            location
        )
    }

    @Test
    fun `reports unresolved without a line when no declaration exists`(
        @TempDir tempDir: Path
    ) {
        val buildFile =
            writeFile(
                tempDir,
                "app/build.gradle.kts",
                """
                plugins { id("my.convention.plugin") }
                """
            )

        val location = CompileSdkLocator.locate(buildFile, tempDir.toFile())

        assertEquals(CompileSdkLocation.Unresolved(buildFile, line = null, expression = null), location)
    }

    @Test
    fun `reports unresolved when the build file does not exist`(
        @TempDir tempDir: Path
    ) {
        val buildFile = tempDir.resolve("app/build.gradle").toFile()

        val location = CompileSdkLocator.locate(buildFile, tempDir.toFile())

        assertEquals(CompileSdkLocation.Unresolved(buildFile, line = null, expression = null), location)
    }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.AndroidPluginVersion
import com.android.build.api.dsl.ApplicationExtension
import com.flutter.gradle.DependencyVersionChecker.AGPDeclaration
import com.flutter.gradle.DependencyVersionChecker.checkAGPMaxVersion
import com.flutter.gradle.DependencyVersionChecker.findAGPDeclaration
import com.flutter.gradle.DependencyVersionChecker.getPotentialAGPFix
import io.mockk.every
import io.mockk.mockk
import org.gradle.api.Project
import org.gradle.api.plugins.ExtraPropertiesExtension
import org.gradle.internal.extensions.core.extra
import org.junit.jupiter.api.io.TempDir
import java.io.File
import java.nio.file.Path
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertTrue

class DependencyVersionCheckerAGPFixTest {
    private fun writeFile(
        rootDir: File,
        relativePath: String,
        contents: String
    ): File {
        val file = File(rootDir, relativePath)
        file.parentFile.mkdirs()
        file.writeText(contents.trimIndent())
        return file
    }

    @Test
    fun `finds AGP in the settings plugins block`(
        @TempDir tempDir: Path
    ) {
        val rootDir = tempDir.toFile()
        val settings =
            writeFile(
                rootDir,
                "settings.gradle.kts",
                """
                plugins {
                    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
                    id("com.android.application") version "8.11.1" apply false
                }
                """
            )

        assertEquals(
            AGPDeclaration(settings, 3, "    id(\"com.android.application\") version \"8.11.1\" apply false"),
            findAGPDeclaration(rootDir)
        )
        assertEquals(
            "Your project's AGP version is set in ${settings.path}:3:\n" +
                "    id(\"com.android.application\") version \"8.11.1\" apply false\n" +
                "Change the version on that line.\n",
            getPotentialAGPFix(rootDir, isAddToApp = false)
        )
    }

    @Test
    fun `prefers settings_gradle_kts over settings_gradle`(
        @TempDir tempDir: Path
    ) {
        val rootDir = tempDir.toFile()
        writeFile(rootDir, "settings.gradle", """plugins { id "com.android.application" version "8.1.0" }""")
        val kts = writeFile(rootDir, "settings.gradle.kts", """plugins { id("com.android.application") version "9.0.0" }""")

        assertEquals(kts, findAGPDeclaration(rootDir)?.file)
    }

    @Test
    fun `finds AGP on the buildscript classpath of an older template`(
        @TempDir tempDir: Path
    ) {
        val rootDir = tempDir.toFile()
        writeFile(rootDir, "settings.gradle", """include ':app'""")
        val buildFile =
            writeFile(
                rootDir,
                "build.gradle",
                """
                buildscript {
                    dependencies {
                        // classpath 'com.android.tools.build:gradle:7.0.0'
                        classpath 'com.android.tools.build:gradle:8.1.0'
                    }
                }
                """
            )

        assertEquals(
            AGPDeclaration(buildFile, 4, "        classpath 'com.android.tools.build:gradle:8.1.0'"),
            findAGPDeclaration(rootDir)
        )
    }

    @Test
    fun `finds the versions entry referenced by the AGP plugin in the version catalog`(
        @TempDir tempDir: Path
    ) {
        val rootDir = tempDir.toFile()
        // The settings file references the catalog, so it has no literal AGP version.
        writeFile(rootDir, "settings.gradle.kts", """plugins { alias(libs.plugins.android.application) apply false }""")
        val catalog =
            writeFile(
                rootDir,
                "gradle/libs.versions.toml",
                """
                [versions]
                kotlin = "2.3.20"
                agp = "9.0.1"

                [plugins]
                android-application = { id = "com.android.application", version.ref = "agp" }
                """
            )

        val declaration = findAGPDeclaration(rootDir)

        assertEquals(
            AGPDeclaration(
                catalog,
                3,
                "agp = \"9.0.1\"",
                referencedBy =
                    AGPDeclaration(
                        catalog,
                        6,
                        "android-application = { id = \"com.android.application\", version.ref = \"agp\" }"
                    )
            ),
            declaration
        )
        assertEquals(
            "Your project's AGP version is set in ${catalog.path}:3:\n" +
                "    agp = \"9.0.1\"\n" +
                "It is referenced by the declaration on line 6:\n" +
                "    android-application = { id = \"com.android.application\", version.ref = \"agp\" }\n" +
                "Change the version on that line.\n",
            getPotentialAGPFix(rootDir, isAddToApp = false)
        )
    }

    @Test
    fun `finds the AGP library in the version catalog and ignores other artifacts in its group`(
        @TempDir tempDir: Path
    ) {
        val rootDir = tempDir.toFile()
        val catalog =
            writeFile(
                rootDir,
                "gradle/libs.versions.toml",
                """
                [versions]
                gradleApi = "9.0.1"
                androidGradlePlugin = "8.11.1"

                [libraries]
                # android-gradle = { module = "com.android.tools.build:gradle", version = "1.0.0" }
                android-gradle-api = { module = "com.android.tools.build:gradle-api", version.ref = "gradleApi" }
                android-gradle = { group = "com.android.tools.build", name = "gradle", version.ref = "androidGradlePlugin" }
                """
            )

        val declaration = findAGPDeclaration(rootDir)

        assertEquals(catalog, declaration?.file)
        assertEquals(3, declaration?.lineNumber)
        assertEquals(8, declaration?.referencedBy?.lineNumber)
    }

    @Test
    fun `reports the version catalog line itself when it has an inline version`(
        @TempDir tempDir: Path
    ) {
        val rootDir = tempDir.toFile()
        val catalog =
            writeFile(
                rootDir,
                "gradle/libs.versions.toml",
                """
                [plugins]
                android-application = { id = "com.android.application", version = "8.11.1" }
                """
            )

        assertEquals(
            AGPDeclaration(catalog, 2, "android-application = { id = \"com.android.application\", version = \"8.11.1\" }"),
            findAGPDeclaration(rootDir)
        )
    }

    @Test
    fun `falls back to the generic fix when no declaration is found`(
        @TempDir tempDir: Path
    ) {
        val rootDir = tempDir.toFile()
        writeFile(rootDir, "settings.gradle.kts", """include(":app")""")

        assertNull(findAGPDeclaration(rootDir))
        assertEquals(getPotentialAGPFix(rootDir.path), getPotentialAGPFix(rootDir, isAddToApp = false))
    }

    @Test
    fun `add-to-app fix points at the host app's declaration`(
        @TempDir tempDir: Path
    ) {
        val hostAppDir = tempDir.toFile()
        val catalog =
            writeFile(
                hostAppDir,
                "gradle/libs.versions.toml",
                """
                [versions]
                agp = "8.11.1"

                [plugins]
                android-application = { id = "com.android.application", version.ref = "agp" }
                """
            )

        val fix = getPotentialAGPFix(hostAppDir, isAddToApp = true)

        assertTrue(
            fix.startsWith(
                "This Flutter module is built as part of the host Android app at ${hostAppDir.path}, " +
                    "so the AGP version comes from the host app, not the Flutter module. " +
                    "Change the AGP version in the host app's build files.\n" +
                    "The host app's AGP version is set in ${catalog.path}:2:\n"
            ),
            fix
        )
    }

    @Test
    fun `add-to-app fallback fix points at the host app's version catalog`(
        @TempDir tempDir: Path
    ) {
        val hostAppDir = tempDir.toFile()

        val fix = getPotentialAGPFix(hostAppDir, isAddToApp = true)

        assertTrue(fix.startsWith("This Flutter module is built as part of the host Android app at ${hostAppDir.path}"), fix)
        assertTrue(fix.contains("${hostAppDir.path}/gradle/libs.versions.toml"), fix)
    }

    private fun mockProject(
        rootDir: File,
        isApp: Boolean
    ): Project {
        val project = mockk<Project>()
        every { project.rootDir.path } returns rootDir.path
        every { project.extensions.findByType(ApplicationExtension::class.java) } returns
            if (isApp) mockk() else null
        val extraProperties = mockk<ExtraPropertiesExtension>()
        every { extraProperties.set(any(), any()) } returns Unit
        every { project.extra } returns extraProperties
        return project
    }

    @Test
    fun `unsupported AGP major version error points a Flutter app at its settings file`(
        @TempDir tempDir: Path
    ) {
        val appAndroidDir = tempDir.toFile()
        val settings =
            writeFile(
                appAndroidDir,
                "settings.gradle.kts",
                """
                plugins {
                    id("com.android.application") version "10.0.0" apply false
                }
                """
            )

        val exception =
            assertFailsWith<DependencyValidationException> {
                checkAGPMaxVersion(AndroidPluginVersion(10, 0, 0), mockProject(appAndroidDir, isApp = true))
            }

        assertTrue(
            exception.message!!.endsWith(
                "Potential fix: Your project's AGP version is set in ${settings.path}:2:\n" +
                    "    id(\"com.android.application\") version \"10.0.0\" apply false\n" +
                    "Change the version on that line.\n"
            ),
            exception.message
        )
    }

    @Test
    fun `unsupported AGP major version error points an add-to-app host at its version catalog`(
        @TempDir tempDir: Path
    ) {
        val hostAppDir = tempDir.toFile()
        val catalog =
            writeFile(
                hostAppDir,
                "gradle/libs.versions.toml",
                """
                [versions]
                agp = "10.0.0"

                [plugins]
                android-application = { id = "com.android.application", version.ref = "agp" }
                """
            )

        val exception =
            assertFailsWith<DependencyValidationException> {
                checkAGPMaxVersion(AndroidPluginVersion(10, 0, 0), mockProject(hostAppDir, isApp = false))
            }

        assertTrue(
            exception.message!!.contains(
                "Potential fix: This Flutter module is built as part of the host Android app at " +
                    "${hostAppDir.path}, so the AGP version comes from the host app, not the Flutter " +
                    "module. Change the AGP version in the host app's build files.\n" +
                    "The host app's AGP version is set in ${catalog.path}:2:\n" +
                    "    agp = \"10.0.0\"\n"
            ),
            exception.message
        )
    }

    @Test
    fun `app projects are not treated as add-to-app`(
        @TempDir tempDir: Path
    ) {
        val rootDir = tempDir.toFile()

        assertEquals(
            getPotentialAGPFix(rootDir, isAddToApp = false),
            getPotentialAGPFix(mockProject(rootDir, isApp = true))
        )
    }

    @Test
    fun `library projects in a host app build are treated as add-to-app`(
        @TempDir tempDir: Path
    ) {
        val hostAppDir = tempDir.toFile()

        assertEquals(
            getPotentialAGPFix(hostAppDir, isAddToApp = true),
            getPotentialAGPFix(mockProject(hostAppDir, isApp = false))
        )
    }

    @Test
    fun `library projects in a Flutter module's generated android build are not treated as add-to-app`(
        @TempDir tempDir: Path
    ) {
        val generatedAndroidDir = File(tempDir.toFile(), ".android").apply { mkdirs() }

        assertEquals(
            getPotentialAGPFix(generatedAndroidDir, isAddToApp = false),
            getPotentialAGPFix(mockProject(generatedAndroidDir, isApp = false))
        )
    }
}

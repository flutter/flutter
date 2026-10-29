// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import io.mockk.every
import io.mockk.mockk
import org.gradle.api.Project
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class FlutterCompileOptionsTest {
    @Test
    fun `from reads each compile property from the project`() {
        val project =
            projectWithProperties(
                FlutterCompileOptions.FILE_SYSTEM_ROOTS_PROPERTY to "root1",
                FlutterCompileOptions.FILE_SYSTEM_SCHEME_PROPERTY to "custom-scheme",
                FlutterCompileOptions.TRACK_WIDGET_CREATION_PROPERTY to "false",
                FlutterCompileOptions.FRONTEND_SERVER_STARTER_PATH_PROPERTY to "starter.dart",
                FlutterCompileOptions.EXTRA_FRONT_END_OPTIONS_PROPERTY to "--opt1",
                FlutterCompileOptions.EXTRA_GEN_SNAPSHOT_OPTIONS_PROPERTY to "--opt2",
                FlutterCompileOptions.SPLIT_DEBUG_INFO_PROPERTY to "debug/info",
                FlutterCompileOptions.DART_OBFUSCATION_PROPERTY to "true",
                FlutterCompileOptions.TREE_SHAKE_ICONS_PROPERTY to "true",
                FlutterCompileOptions.DART_DEFINES_PROPERTY to "key=val",
                FlutterCompileOptions.PERFORMANCE_MEASUREMENT_FILE_PROPERTY to "perf.json",
                FlutterCompileOptions.CODE_SIZE_DIRECTORY_PROPERTY to "code/size",
                FlutterCompileOptions.DEFERRED_COMPONENTS_PROPERTY to "true",
                FlutterCompileOptions.VALIDATE_DEFERRED_COMPONENTS_PROPERTY to "false"
            )

        val options = FlutterCompileOptions.from(project)

        assertEquals(listOf("root1"), options.fileSystemRoots)
        assertEquals("custom-scheme", options.fileSystemScheme)
        assertEquals(false, options.trackWidgetCreation)
        assertEquals("starter.dart", options.frontendServerStarterPath)
        assertEquals("--opt1", options.extraFrontEndOptions)
        assertEquals("--opt2", options.extraGenSnapshotOptions)
        assertEquals("debug/info", options.splitDebugInfo)
        assertEquals(true, options.dartObfuscation)
        assertEquals(true, options.treeShakeIcons)
        assertEquals("key=val", options.dartDefines)
        assertEquals("perf.json", options.performanceMeasurementFile)
        assertEquals("code/size", options.codeSizeDirectory)
        assertEquals(true, options.deferredComponents)
        assertEquals(false, options.validateDeferredComponents)
    }

    @Test
    fun `from falls back to defaults when no properties are set`() {
        val options = FlutterCompileOptions.from(projectWithProperties())

        assertNull(options.fileSystemRoots)
        assertNull(options.fileSystemScheme)
        assertNull(options.frontendServerStarterPath)
        assertNull(options.extraFrontEndOptions)
        assertNull(options.extraGenSnapshotOptions)
        assertNull(options.splitDebugInfo)
        assertNull(options.dartDefines)
        assertNull(options.performanceMeasurementFile)
        assertNull(options.codeSizeDirectory)
        assertEquals(true, options.trackWidgetCreation)
        assertEquals(false, options.dartObfuscation)
        assertEquals(false, options.treeShakeIcons)
        assertEquals(false, options.deferredComponents)
        assertEquals(true, options.validateDeferredComponents)
    }

    // The generated data class equals is only correct because every property has value equality.
    // An Array property would compare by identity and make two identically configured builds look
    // different, so this asserts the property that lets the generated implementation stand.
    @Test
    fun `options resolved from equivalent projects are equal`() {
        val properties =
            arrayOf(
                FlutterCompileOptions.FILE_SYSTEM_ROOTS_PROPERTY to "root1",
                FlutterCompileOptions.DART_DEFINES_PROPERTY to "key=val"
            )

        val options = FlutterCompileOptions.from(projectWithProperties(*properties))
        val sameOptions = FlutterCompileOptions.from(projectWithProperties(*properties))

        assertEquals(options, sameOptions)
        assertEquals(options.hashCode(), sameOptions.hashCode())
        assertTrue(
            options !=
                FlutterCompileOptions.from(
                    projectWithProperties(
                        FlutterCompileOptions.FILE_SYSTEM_ROOTS_PROPERTY to "other-root",
                        FlutterCompileOptions.DART_DEFINES_PROPERTY to "key=val"
                    )
                )
        )
    }

    /** A project whose `findProperty` answers [properties] and null for everything else. */
    private fun projectWithProperties(vararg properties: Pair<String, String>): Project {
        val project = mockk<Project>()
        every { project.findProperty(any()) } returns null
        properties.forEach { (name, value) ->
            every { project.findProperty(name) } returns value
        }
        return project
    }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import org.gradle.api.GradleException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class FlutterExtensionTest {
    @Test
    fun `getVersionCode() throws GradleException when flutterVersion is not set`() {
        val flutterExtension: FlutterExtension = FlutterExtension()
        assertFailsWith<GradleException> { flutterExtension.getVersionCode() }
    }

    @Test
    fun `getVersionCode() throws GradleException when flutterVersion is not an integer`() {
        val flutterExtension: FlutterExtension = FlutterExtension()
        flutterExtension.flutterVersionCode = "not an integer"
        assertFailsWith<GradleException> { flutterExtension.getVersionCode() }
    }

    @Test
    fun `getVersionCode() returns flutterVersion without error when set and is a number`() {
        val flutterExtension: FlutterExtension = FlutterExtension()
        flutterExtension.flutterVersionCode = "123"
        assertEquals(123, flutterExtension.getVersionCode())
    }

    @Test
    fun `getVersionName() throws GradleException when flutterVersionName is not set`() {
        val flutterExtension: FlutterExtension = FlutterExtension()
        assertFailsWith<GradleException> { flutterExtension.getVersionName() }
    }

    @Test
    fun `getVersionName() returns flutterVersionName without error when set`() {
        val flutterExtension: FlutterExtension = FlutterExtension()
        flutterExtension.flutterVersionName = "1.2.3"
        assertEquals("1.2.3", flutterExtension.getVersionName())
    }
}

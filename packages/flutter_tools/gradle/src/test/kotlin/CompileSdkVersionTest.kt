// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class CompileSdkVersionTest {
    @Test
    fun `constructor rejects both apiLevel and previewCodename set`() {
        assertFailsWith<IllegalArgumentException> {
            CompileSdkVersion(apiLevel = 36, previewCodename = "Baklava")
        }
    }

    @Test
    fun `constructor accepts numeric api level`() {
        val version = CompileSdkVersion(apiLevel = 35, previewCodename = null)
        assertEquals(35, version.apiLevel)
        assertEquals(null, version.previewCodename)
    }

    @Test
    fun `constructor accepts preview codename`() {
        val version = CompileSdkVersion(apiLevel = null, previewCodename = "Baklava")
        assertEquals(null, version.apiLevel)
        assertEquals("Baklava", version.previewCodename)
    }

    @Test
    fun `constructor accepts unset values`() {
        val version = CompileSdkVersion(apiLevel = null, previewCodename = null)
        assertEquals(null, version.apiLevel)
        assertEquals(null, version.previewCodename)
    }

    @Test
    fun `isHigherThan compares numeric api levels numerically`() {
        val sdk35 = CompileSdkVersion(apiLevel = 35, previewCodename = null)
        val sdk36 = CompileSdkVersion(apiLevel = 36, previewCodename = null)
        assertEquals(true, sdk36.isHigherThan(sdk35))
        assertEquals(false, sdk35.isHigherThan(sdk36))
        assertEquals(false, sdk35.isHigherThan(sdk35))
    }

    @Test
    fun `isHigherThan treats a preview codename as higher than any numeric api level`() {
        val preview = CompileSdkVersion(apiLevel = null, previewCodename = "Baklava")
        val numeric = CompileSdkVersion(apiLevel = 36, previewCodename = null)
        assertEquals(true, preview.isHigherThan(numeric))
        assertEquals(false, numeric.isHigherThan(preview))
    }

    @Test
    fun `isHigherThan treats distinct preview codenames as incomparable`() {
        // Codenames stopped being alphabetically ordered at the "Baklava" alphabet reset,
        // so neither side may claim to be higher.
        val baklava = CompileSdkVersion(apiLevel = null, previewCodename = "Baklava")
        val vanilla = CompileSdkVersion(apiLevel = null, previewCodename = "VanillaIceCream")
        assertEquals(false, baklava.isHigherThan(vanilla))
        assertEquals(false, vanilla.isHigherThan(baklava))
        assertEquals(false, baklava.isHigherThan(baklava))
    }

    @Test
    fun `isHigherThan returns false when either side is unset`() {
        val unset = CompileSdkVersion(apiLevel = null, previewCodename = null)
        val numeric = CompileSdkVersion(apiLevel = 36, previewCodename = null)
        assertEquals(false, unset.isHigherThan(numeric))
        assertEquals(false, numeric.isHigherThan(unset))
    }

    @Test
    fun `toString formats preview or apiLevel or unknown`() {
        assertEquals("Baklava", CompileSdkVersion(apiLevel = null, previewCodename = "Baklava").toString())
        assertEquals("35", CompileSdkVersion(apiLevel = 35, previewCodename = null).toString())
        assertEquals("unknown", CompileSdkVersion(apiLevel = null, previewCodename = null).toString())
    }
}

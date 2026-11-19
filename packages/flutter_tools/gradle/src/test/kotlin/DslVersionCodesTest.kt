// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.dsl.ApplicationDefaultConfig
import com.android.build.api.dsl.ApplicationExtension
import com.flutter.gradle.testing.mockProductFlavors
import io.mockk.every
import io.mockk.mockk
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class DslVersionCodesTest {
    @Test
    fun `from reads the defaultConfig versionCode and the flavors that set one`() {
        val extension =
            mockApplicationExtension(
                defaultConfigVersionCode = 42,
                productFlavorVersionCodes = mapOf("free" to 7, "paid" to null, "demo" to 9)
            )

        assertEquals(
            DslVersionCodes(
                defaultConfigVersionCode = 42,
                productFlavorVersionCodes = mapOf("free" to 7, "demo" to 9)
            ),
            DslVersionCodes.from(extension)
        )
    }

    @Test
    fun `from reads a null defaultConfig versionCode`() {
        val extension = mockApplicationExtension(defaultConfigVersionCode = null)

        assertEquals(
            DslVersionCodes(defaultConfigVersionCode = null, productFlavorVersionCodes = emptyMap()),
            DslVersionCodes.from(extension)
        )
    }

    @Test
    fun `forVariant returns the versionCode of the first flavor, in dimension order, that sets one`() {
        val versionCodes =
            DslVersionCodes(
                defaultConfigVersionCode = 42,
                productFlavorVersionCodes = mapOf("paid" to 7, "demo" to 9)
            )

        assertEquals(7, versionCodes.forVariant(listOf("tier" to "paid", "mode" to "demo")))
        assertEquals(9, versionCodes.forVariant(listOf("tier" to "free", "mode" to "demo")))
    }

    @Test
    fun `forVariant falls back to the defaultConfig versionCode`() {
        val versionCodes =
            DslVersionCodes(defaultConfigVersionCode = 42, productFlavorVersionCodes = mapOf("paid" to 7))

        assertEquals(42, versionCodes.forVariant(emptyList()))
        assertEquals(42, versionCodes.forVariant(listOf("tier" to "free")))
    }

    @Test
    fun `forVariant returns null when neither the flavors nor defaultConfig set a versionCode`() {
        val versionCodes =
            DslVersionCodes(defaultConfigVersionCode = null, productFlavorVersionCodes = mapOf("paid" to 7))

        assertNull(versionCodes.forVariant(listOf("tier" to "free")))
    }

    private fun mockApplicationExtension(
        defaultConfigVersionCode: Int?,
        productFlavorVersionCodes: Map<String, Int?> = emptyMap()
    ): ApplicationExtension {
        val defaultConfig = mockk<ApplicationDefaultConfig>()
        every { defaultConfig.versionCode } returns defaultConfigVersionCode
        val productFlavors = mockProductFlavors(productFlavorVersionCodes)
        val extension = mockk<ApplicationExtension>()
        every { extension.defaultConfig } returns defaultConfig
        every { extension.productFlavors } returns productFlavors
        return extension
    }
}

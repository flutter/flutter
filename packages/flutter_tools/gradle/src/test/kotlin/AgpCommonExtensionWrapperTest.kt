// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.dsl.DynamicFeatureExtension
import com.android.build.api.dsl.LibraryExtension
import com.android.build.api.dsl.Splits
import com.android.build.api.dsl.TestExtension
import io.mockk.every
import io.mockk.mockk
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.assertThrows
import kotlin.test.Test

class AgpCommonExtensionWrapperTest {
    @Test
    fun `splits delegates to the backing ApplicationExtension`() {
        val mockSplits = mockk<Splits>()
        val backingExtension = mockk<ApplicationExtension>()
        every { backingExtension.splits } returns mockSplits

        val wrapper = AgpCommonExtensionWrapper(backingExtension)

        assertEquals(mockSplits, wrapper.splits)
    }

    @Test
    fun `splits delegates to the backing LibraryExtension`() {
        val mockSplits = mockk<Splits>()
        val backingExtension = mockk<LibraryExtension>()
        every { backingExtension.splits } returns mockSplits

        val wrapper = AgpCommonExtensionWrapper(backingExtension)

        assertEquals(mockSplits, wrapper.splits)
    }

    @Test
    fun `splits delegates to the backing DynamicFeatureExtension`() {
        val mockSplits = mockk<Splits>()
        val backingExtension = mockk<DynamicFeatureExtension>()
        every { backingExtension.splits } returns mockSplits

        val wrapper = AgpCommonExtensionWrapper(backingExtension)

        assertEquals(mockSplits, wrapper.splits)
    }

    @Test
    fun `splits delegates to the backing TestExtension`() {
        val mockSplits = mockk<Splits>()
        val backingExtension = mockk<TestExtension>()
        every { backingExtension.splits } returns mockSplits

        val wrapper = AgpCommonExtensionWrapper(backingExtension)

        assertEquals(mockSplits, wrapper.splits)
    }

    @Test
    fun `splits throws for an unsupported backing extension type`() {
        val wrapper = AgpCommonExtensionWrapper(backingExtension = "not an android extension")

        assertThrows<IllegalArgumentException> {
            wrapper.splits
        }
    }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.dsl.AndroidSourceSet
import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.dsl.LibraryExtension
import com.android.build.api.dsl.Splits
import io.mockk.every
import io.mockk.mockk
import org.gradle.api.NamedDomainObjectContainer
import kotlin.test.Test
import kotlin.test.assertFailsWith
import kotlin.test.assertSame

class AgpCommonExtensionWrapperTest {
    @Test
    fun `splits delegates to the backing application extension`() {
        val mockSplits = mockk<Splits>(relaxed = true)
        val mockApplicationExtension =
            mockk<ApplicationExtension>(relaxed = true) {
                every { splits } returns mockSplits
            }

        val wrapper = AgpCommonExtensionWrapper(mockApplicationExtension)

        assertSame(mockSplits, wrapper.splits)
    }

    @Test
    fun `splits delegates to the backing library extension`() {
        val mockSplits = mockk<Splits>(relaxed = true)
        val mockLibraryExtension =
            mockk<LibraryExtension>(relaxed = true) {
                every { splits } returns mockSplits
            }

        val wrapper = AgpCommonExtensionWrapper(mockLibraryExtension)

        assertSame(mockSplits, wrapper.splits)
    }

    @Test
    fun `sourceSets delegates to the backing application extension`() {
        val mockSourceSets = mockk<NamedDomainObjectContainer<AndroidSourceSet>>(relaxed = true)
        val mockApplicationExtension =
            mockk<ApplicationExtension>(relaxed = true) {
                every { sourceSets } returns mockSourceSets
            }

        val wrapper = AgpCommonExtensionWrapper(mockApplicationExtension)

        assertSame(mockSourceSets, wrapper.sourceSets)
    }

    @Test
    fun `sourceSets delegates to the backing library extension`() {
        val mockSourceSets = mockk<NamedDomainObjectContainer<AndroidSourceSet>>(relaxed = true)
        val mockLibraryExtension =
            mockk<LibraryExtension>(relaxed = true) {
                every { sourceSets } returns mockSourceSets
            }

        val wrapper = AgpCommonExtensionWrapper(mockLibraryExtension)

        assertSame(mockSourceSets, wrapper.sourceSets)
    }

    @Test
    fun `splits throws for an unsupported backing extension type`() {
        val wrapper = AgpCommonExtensionWrapper("not an android extension")

        assertFailsWith<IllegalArgumentException> { wrapper.splits }
    }

    @Test
    fun `sourceSets throws for an unsupported backing extension type`() {
        val wrapper = AgpCommonExtensionWrapper("not an android extension")

        assertFailsWith<IllegalArgumentException> { wrapper.sourceSets }
    }
}

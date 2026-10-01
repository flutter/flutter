// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.testing

import com.android.build.api.variant.FilterConfiguration
import io.mockk.every
import io.mockk.mockk

/**
 * The filters of a variant output or built APK for [abi]: one ABI filter, or none if [abi] is
 * null (the APK of a build without ABI splits, or a universal APK).
 */
fun mockAbiFilters(abi: String?): List<FilterConfiguration> {
    if (abi == null) {
        return emptyList()
    }
    val abiFilter = mockk<FilterConfiguration>()
    every { abiFilter.filterType } returns FilterConfiguration.FilterType.ABI
    every { abiFilter.identifier } returns abi
    return listOf(abiFilter)
}

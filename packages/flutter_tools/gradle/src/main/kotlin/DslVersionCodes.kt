// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.dsl.ApplicationExtension

/**
 * The versionCodes declared on `defaultConfig` and on each product flavor.
 *
 * Flutter computes per-ABI versionCodes from these instead of reading `VariantOutput.versionCode`,
 * which AGP rejects during configuration when `android.compatibility.enableLegacyApi=false`.
 * Create it with [from] in `finalizeDsl`. It does not see changes made by `finalizeDsl` callbacks
 * registered after Flutter's.
 *
 * @property productFlavorVersionCodes keyed by flavor name, which is unique across dimensions.
 */
internal data class DslVersionCodes(
    val defaultConfigVersionCode: Int?,
    val productFlavorVersionCodes: Map<String, Int>
) {
    /**
     * The versionCode AGP merges for a variant: the first of [productFlavors] (in dimension
     * priority order) that sets one, else `defaultConfig`. Null if none is set in the DSL.
     */
    fun forVariant(productFlavors: List<Pair<String, String>>): Int? =
        productFlavors.firstNotNullOfOrNull { (_, flavorName) -> productFlavorVersionCodes[flavorName] }
            ?: defaultConfigVersionCode

    companion object {
        /** Reads the versionCodes declared in [extension]'s DSL. */
        fun from(extension: ApplicationExtension): DslVersionCodes =
            DslVersionCodes(
                defaultConfigVersionCode = extension.defaultConfig.versionCode,
                productFlavorVersionCodes =
                    extension.productFlavors
                        .mapNotNull { flavor -> flavor.versionCode?.let { flavor.name to it } }
                        .toMap()
            )
    }
}

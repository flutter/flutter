// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.dsl.ApplicationExtension

/**
 * The versionCodes an application project declares in its Android DSL, on `defaultConfig` and on
 * each product flavor.
 *
 * Flutter offsets the versionCode of each per-ABI APK from these values instead of reading
 * `VariantOutput.versionCode`. AGP disallows reading that property during configuration when its
 * compatibility mode (`android.compatibility.enableLegacyApi`) is off, and its lazy form would
 * make the property depend on itself. Create an instance with [from] in
 * `androidComponents.finalizeDsl`, where the DSL is complete and reading it is supported.
 * AGP runs `finalizeDsl` callbacks in registration order, so the snapshot does not see versionCode
 * changes made by a `finalizeDsl` callback registered after Flutter's, such as one in the app's
 * build script.
 *
 * @property defaultConfigVersionCode the versionCode set on `defaultConfig`, or null if unset.
 * @property productFlavorVersionCodes the versionCode of each product flavor that sets one, keyed
 *   by flavor name. Flavor names are unique across dimensions, so one map covers all of them.
 */
internal data class DslVersionCodes(
    val defaultConfigVersionCode: Int?,
    val productFlavorVersionCodes: Map<String, Int>
) {
    /**
     * Returns the versionCode AGP gives a variant built from [productFlavors], or null if neither
     * those flavors nor `defaultConfig` set one.
     *
     * Matches AGP's merge: the first flavor in [productFlavors] that sets a versionCode wins, and
     * `defaultConfig` is the fallback. When the DSL sets no versionCode, AGP reads it from the
     * merged manifest instead, which is not available at configuration time.
     *
     * @param productFlavors the variant's `(dimension, flavor name)` pairs in dimension priority
     *   order, as returned by `ComponentIdentity.productFlavors`.
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

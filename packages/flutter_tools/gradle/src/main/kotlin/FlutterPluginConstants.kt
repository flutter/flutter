// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import org.gradle.api.GradleException

// TODO(gmackall): this should be collapsed back into the core FlutterPlugin once the Groovy to
//                 kotlin conversion is complete.
object FlutterPluginConstants {
    /** The platforms that can be passed to the `--Ptarget-platform` flag. */
    private const val PLATFORM_ARM32 = platformArm32
    private const val PLATFORM_ARM64 = platformArm64
    private const val PLATFORM_X86_64 = platformX86_64

    /** The ABI architectures supported by Flutter. */
    private const val ARCH_ARM32 = archArm32
    private const val ARCH_ARM64 = archArm64
    private const val ARCH_X86_64 = archX86_64

    const val INTERMEDIATES_DIR = "intermediates"
    const val FLUTTER_STORAGE_BASE_URL = "FLUTTER_STORAGE_BASE_URL"
    const val DEFAULT_MAVEN_HOST = "https://storage.googleapis.com"

    /** Maps platforms to ABI architectures. */
    @JvmStatic val PLATFORM_ARCH_MAP =
        mapOf(
            PLATFORM_ARM32 to ARCH_ARM32,
            PLATFORM_ARM64 to ARCH_ARM64,
            PLATFORM_X86_64 to ARCH_X86_64
        )

    /**
     * The version code that gives each ABI a value.
     * For each APK variant, use the following versions to override the version of the Universal APK.
     * Otherwise, the Play Store will complain that the APK variants have the same version.
     */
    @JvmStatic val ABI_VERSION =
        mapOf(
            ARCH_ARM32 to abiVersionArm32.toInt(),
            ARCH_ARM64 to abiVersionArm64.toInt(),
            // 3 was reserved for ARCH_X86, whose support was removed in https://github.com/flutter/flutter/pull/169884
            ARCH_X86_64 to abiVersionX86_64.toInt()
        )

    /** When split is enabled, multiple APKs are generated per each ABI. */
    @JvmStatic val DEFAULT_PLATFORMS =
        listOf(
            PLATFORM_ARM32,
            PLATFORM_ARM64,
            PLATFORM_X86_64
        )

    /**
     * List of supported ABIs as strings.
     *
     * @throws GradleException if not all platforms in `DEFAULT_PLATFORMS` have an entry in `PLATFORM_ARCH_MAP`.
     */
    @JvmStatic val PLATFORM_ABI_LIST: List<String> =
        DEFAULT_PLATFORMS.map { platform ->
            PLATFORM_ARCH_MAP[platform] ?: throw GradleException("Invalid platform: $platform")
        }
}

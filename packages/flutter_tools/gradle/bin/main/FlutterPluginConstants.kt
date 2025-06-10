// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

// TODO(gmackall): this should be collapsed back into the core FlutterPlugin once the Groovy to
//                 kotlin conversion is complete.
object FlutterPluginConstants {
    /** The platforms that can be passed to the `--Ptarget-platform` flag. */
    private const val PLATFORM_ARM32 = "android-arm"
    private const val PLATFORM_ARM64 = "android-arm64"
    private const val PLATFORM_X86 = "android-x86"
    private const val PLATFORM_X86_64 = "android-x64"

    /** The ABI architectures supported by Flutter. */
    private const val ARCH_ARM32 = "armeabi-v7a"
    private const val ARCH_ARM64 = "arm64-v8a"
    private const val ARCH_X86 = "x86"
    private const val ARCH_X86_64 = "x86_64"

    const val INTERMEDIATES_DIR = "intermediates"
    const val FLUTTER_STORAGE_BASE_URL = "FLUTTER_STORAGE_BASE_URL"
    const val DEFAULT_MAVEN_HOST = "https://storage.googleapis.com"

    /** Maps platforms to ABI architectures. */
    @JvmStatic val PLATFORM_ARCH_MAP =
        mapOf(
            PLATFORM_ARM32 to ARCH_ARM32,
            PLATFORM_ARM64 to ARCH_ARM64,
            PLATFORM_X86 to ARCH_X86,
            PLATFORM_X86_64 to ARCH_X86_64
        )

    /**
     * The version code that gives each ABI a value.
     * For each APK variant, use the following versions to override the version of the Universal APK.
     * Otherwise, the Play Store will complain that the APK variants have the same version.
     */
    @JvmStatic val ABI_VERSION =
        mapOf(
            ARCH_ARM32 to 1,
            ARCH_ARM64 to 2,
            ARCH_X86 to 3,
            ARCH_X86_64 to 4
        )

    /** When split is enabled, multiple APKs are generated per each ABI. */
    @JvmStatic val DEFAULT_PLATFORMS =
        listOf(
            PLATFORM_ARM32,
            PLATFORM_ARM64,
            PLATFORM_X86_64
        )
}

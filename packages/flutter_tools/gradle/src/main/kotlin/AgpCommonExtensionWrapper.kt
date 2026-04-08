// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.dsl.BuildType
import com.android.build.api.dsl.DynamicFeatureExtension
import com.android.build.api.dsl.LibraryExtension
import com.android.build.api.dsl.TestExtension
import org.gradle.api.NamedDomainObjectContainer
import java.io.File

/**
 * A wrapper to bypass binary incompatibilities in AGP's CommonExtension between 8.x and 9.x.
 * * CRITICAL: Do not import or reference `com.android.build.api.dsl.CommonExtension`
 * anywhere in this file, or the compiler may weave the broken type into the bytecode.
 */
class AgpCommonExtensionWrapper(
    private val backingExtension: Any
) {
    var compileSdk: Int?
        get() =
            when (backingExtension) {
                is ApplicationExtension -> backingExtension.compileSdk
                is LibraryExtension -> backingExtension.compileSdk
                is DynamicFeatureExtension -> backingExtension.compileSdk
                is TestExtension -> backingExtension.compileSdk
                else -> throw IllegalArgumentException(unsupportedMessage())
            }
        set(value) {
            when (backingExtension) {
                is ApplicationExtension -> backingExtension.compileSdk = value
                is LibraryExtension -> backingExtension.compileSdk = value
                is DynamicFeatureExtension -> backingExtension.compileSdk = value
                is TestExtension -> backingExtension.compileSdk = value
                else -> throw IllegalArgumentException(unsupportedMessage())
            }
        }

    var namespace: String?
        get() =
            when (backingExtension) {
                is ApplicationExtension -> backingExtension.namespace
                is LibraryExtension -> backingExtension.namespace
                is DynamicFeatureExtension -> backingExtension.namespace
                is TestExtension -> backingExtension.namespace
                else -> throw IllegalArgumentException(unsupportedMessage())
            }
        set(value) {
            when (backingExtension) {
                is ApplicationExtension -> backingExtension.namespace = value
                is LibraryExtension -> backingExtension.namespace = value
                is DynamicFeatureExtension -> backingExtension.namespace = value
                is TestExtension -> backingExtension.namespace = value
                else -> throw IllegalArgumentException(unsupportedMessage())
            }
        }

    var ndkVersion: String
        get() =
            when (backingExtension) {
                is ApplicationExtension -> backingExtension.ndkVersion
                is LibraryExtension -> backingExtension.ndkVersion
                is DynamicFeatureExtension -> backingExtension.ndkVersion
                is TestExtension -> backingExtension.ndkVersion
                else -> throw IllegalArgumentException(unsupportedMessage())
            }
        set(value) {
            when (backingExtension) {
                is ApplicationExtension -> backingExtension.ndkVersion = value
                is LibraryExtension -> backingExtension.ndkVersion = value
                is DynamicFeatureExtension -> backingExtension.ndkVersion = value
                is TestExtension -> backingExtension.ndkVersion = value
                else -> throw IllegalArgumentException(unsupportedMessage())
            }
        }

    val buildTypes: NamedDomainObjectContainer<out BuildType>
        get() =
            when (backingExtension) {
                is ApplicationExtension -> backingExtension.buildTypes
                is LibraryExtension -> backingExtension.buildTypes
                is DynamicFeatureExtension -> backingExtension.buildTypes
                is TestExtension -> backingExtension.buildTypes
                else -> throw IllegalArgumentException(unsupportedMessage())
            }

    fun getDefaultProguardFile(fileName: String): File =
        when (backingExtension) {
            is ApplicationExtension -> backingExtension.getDefaultProguardFile(fileName)
            is LibraryExtension -> backingExtension.getDefaultProguardFile(fileName)
            is DynamicFeatureExtension -> backingExtension.getDefaultProguardFile(fileName)
            is TestExtension -> backingExtension.getDefaultProguardFile(fileName)
            else -> throw IllegalArgumentException(unsupportedMessage())
        }

    // Example of wrapping a method rather than a property
    fun compileOptions(action: (Any) -> Unit) {
        when (backingExtension) {
            is ApplicationExtension -> backingExtension.compileOptions { action(this) }
            is LibraryExtension -> backingExtension.compileOptions { action(this) }
            is DynamicFeatureExtension -> backingExtension.compileOptions { action(this) }
            is TestExtension -> backingExtension.compileOptions { action(this) }
            else -> throw IllegalArgumentException(unsupportedMessage())
        }
    }

    private fun unsupportedMessage() = "Unsupported Android extension type: ${backingExtension.javaClass.name}"
}

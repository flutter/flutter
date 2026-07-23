// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json

// Co-evolve with packages/flutter_tools/lib/src/android/android_support_versions.dart

@Serializable
internal data class VersionRange(
    val warn: String,
    val error: String
)

@Serializable
internal data class MinSdkVersionRange(
    val warn: Int,
    val error: Int
)

@Serializable
internal data class MaxKnownVersions(
    val gradle: String,
    val kgp: String,
    val agp: String,
    @SerialName("agp_with_kotlin")
    val agpWithKotlin: String
)

@Serializable
internal data class OldestConsideredVersions(
    val gradle: String,
    val agp: String,
    val kgp: String,
    @SerialName("java_agp")
    val javaAgp: String,
    val java: String,
    @SerialName("java_gradle")
    val javaGradle: String
)

@Serializable
internal data class GradleAgpCompat(
    val agpMin: String,
    val agpMax: String,
    val gradleMin: String,
    val inclusiveMaxAgp: Boolean = true
)

@Serializable
internal data class JavaGradleCompat(
    val javaMin: String,
    val javaMax: String,
    val gradleMin: String,
    val gradleMax: String? = null
)

@Serializable
internal data class JavaAgpCompat(
    val javaMin: String,
    val javaDefault: String,
    val agpMin: String,
    val agpMax: String
)

@Serializable
internal data class KgpGradleCompat(
    val kgpMin: String,
    val kgpMax: String,
    val gradleMin: String,
    val gradleMax: String,
    val inclusiveMaxKgp: Boolean = true,
    val inclusiveMaxGradle: Boolean = true
)

@Serializable
internal data class AgpKgpCompat(
    val kgpMin: String,
    val kgpMax: String,
    val agpMin: String,
    val agpMax: String,
    val inclusiveMaxKgp: Boolean = true,
    val inclusiveMaxAgp: Boolean = true
)

@Serializable
internal data class GradleVersionForAgp(
    val agpMin: String,
    val agpMax: String,
    val minRequiredGradle: String
)

@Serializable
internal data class AndroidSupportVersions(
    val gradle: VersionRange,
    val java: VersionRange,
    val agp: VersionRange,
    val kgp: VersionRange,
    val minSdkVersion: MinSdkVersionRange,
    val maxKnownVersions: MaxKnownVersions,
    val oldestConsideredVersions: OldestConsideredVersions,
    val oneMajorVersionHigherJavaVersion: String,
    @SerialName("gradle_agp_compat")
    val gradleAgpCompat: List<GradleAgpCompat>,
    @SerialName("java_gradle_compat")
    val javaGradleCompat: List<JavaGradleCompat>,
    @SerialName("java_agp_compat")
    val javaAgpCompat: List<JavaAgpCompat>,
    @SerialName("kgp_gradle_compat")
    val kgpGradleCompat: List<KgpGradleCompat>,
    @SerialName("agp_kgp_compat")
    val agpKgpCompat: List<AgpKgpCompat>,
    @SerialName("gradle_version_for_agp")
    val gradleVersionForAgp: List<GradleVersionForAgp>
) {
    companion object {
        private val json =
            Json {
                ignoreUnknownKeys = true
                coerceInputValues = true
            }

        fun fromJson(jsonText: String): AndroidSupportVersions = json.decodeFromString(jsonText)
    }
}

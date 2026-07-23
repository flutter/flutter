// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.AndroidPluginVersion
import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import org.gradle.api.GradleException
import org.gradle.api.JavaVersion

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
    val agpWithKotlin: String
)

@Serializable
internal data class OldestConsideredVersions(
    val gradle: String,
    val agp: String,
    val kgp: String,
    val javaAgp: String,
    val java: String,
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
internal data class CompatMatrix<T>(
    val comment: String,
    val sourceUrl: String,
    val rules: List<T>
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
    val gradleAgpCompat: CompatMatrix<GradleAgpCompat>,
    val javaGradleCompat: CompatMatrix<JavaGradleCompat>,
    val javaAgpCompat: CompatMatrix<JavaAgpCompat>,
    val kgpGradleCompat: CompatMatrix<KgpGradleCompat>,
    val agpKgpCompat: CompatMatrix<AgpKgpCompat>,
    val gradleVersionForAgp: CompatMatrix<GradleVersionForAgp>
) {
    val oneMajorVersionHigherJavaVersion: String by lazy {
        javaGradleCompat.rules
            .maxByOrNull { Version.fromString(it.javaMax) }
            ?.javaMax ?: "26"
    }

    val warnGradleVersion: Version by lazy { Version.fromString(gradle.warn) }
    val errorGradleVersion: Version by lazy { Version.fromString(gradle.error) }

    val warnJavaVersion: JavaVersion by lazy { JavaVersion.toVersion(java.warn) }
    val errorJavaVersion: JavaVersion by lazy { JavaVersion.toVersion(java.error) }

    val warnAGPVersion: AndroidPluginVersion by lazy { parseAgpVersion(agp.warn) }
    val errorAGPVersion: AndroidPluginVersion by lazy { parseAgpVersion(agp.error) }

    val warnKGPVersion: Version by lazy { Version.fromString(kgp.warn) }
    val errorKGPVersion: Version by lazy { Version.fromString(kgp.error) }

    companion object {
        private const val AGP_MAJOR_VERSION_INDEX = 0
        private const val AGP_MINOR_VERSION_INDEX = 1
        private const val AGP_PATCH_VERSION_INDEX = 2
        private const val AGP_DEFAULT_VERSION_COMPONENT = 0

        private val json =
            Json {
                ignoreUnknownKeys = true
                coerceInputValues = true
            }

        fun fromJson(jsonText: String): AndroidSupportVersions = json.decodeFromString(jsonText)

        fun load(): AndroidSupportVersions {
            val stream =
                AndroidSupportVersions::class.java.getResourceAsStream("/android_support_versions.json")
                    ?: throw GradleException("Required resource android_support_versions.json not found")
            val jsonText = stream.bufferedReader().use { it.readText() }
            return fromJson(jsonText)
        }

        fun parseAgpVersion(versionString: String): AndroidPluginVersion {
            val parts = versionString.split(".").map { it.toInt() }
            val major = parts.getOrElse(AGP_MAJOR_VERSION_INDEX) { AGP_DEFAULT_VERSION_COMPONENT }
            val minor = parts.getOrElse(AGP_MINOR_VERSION_INDEX) { AGP_DEFAULT_VERSION_COMPONENT }
            val patch = parts.getOrElse(AGP_PATCH_VERSION_INDEX) { AGP_DEFAULT_VERSION_COMPONENT }
            return AndroidPluginVersion(major, minor, patch)
        }
    }
}

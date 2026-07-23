// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.AndroidPluginVersion
import com.android.build.api.variant.AndroidComponentsExtension
import org.gradle.api.JavaVersion
import org.gradle.api.Project
import org.jetbrains.kotlin.gradle.plugin.KotlinAndroidPluginWrapper

internal object VersionFetcher {
    /**
     * Returns the version of the JVM.
     */
    internal fun getJavaVersion(): JavaVersion = JavaVersion.current()

    /**
     * Returns the version of Gradle.
     */
    internal fun getGradleVersion(project: Project): Version {
        // https://docs.gradle.org/current/kotlin-dsl/gradle/org.gradle.api.invocation/-gradle/index.html#-837060600%2FFunctions%2F-1793262594
        val untrimmedGradleVersion: String = project.gradle.gradleVersion
        // Trim to handle candidate gradle versions (example 7.6-rc-4). This means we treat all
        // candidate versions of gradle as the same as their base version
        // (i.e., "7.6"="7.6-rc-4").
        return Version.fromString(untrimmedGradleVersion.substringBefore('-'))
    }

    /**
     * Returns the version of the Android Gradle plugin.
     */
    internal fun getAGPVersion(project: Project): AndroidPluginVersion? {
        val androidPluginVersion: AndroidPluginVersion? =
            project.extensions
                .findByType(
                    AndroidComponentsExtension::class.java
                )?.pluginVersion
        return androidPluginVersion
    }

    /**
     * Returns the version of the Kotlin Gradle plugin, or null if it cannot be determined.
     *
     * Null is an expected result when the Kotlin Gradle plugin has not been applied to the
     * project — most notably under AGP's built-in Kotlin support (`android.builtInKotlin`),
     * where there is no standalone KGP. Callers must treat null as "unknown/not applied",
     * not as an error.
     */
    internal fun getKGPVersion(project: Project): Version? {
        // KGP's version in org.jetbrains.kotlin.gradle.plugin.DefaultKotlinBasePlugin is not
        // available when this method is called.
        val kotlinVersionProperty = "kotlin_version"
        val firstKotlinVersionFieldName = "pluginVersion"
        val secondKotlinVersionFieldName = "kotlinPluginVersion"
        // This property corresponds to application of the Kotlin Gradle plugin in the
        // top-level build.gradle file.
        if (project.hasProperty(kotlinVersionProperty)) {
            return Version.fromString(project.properties[kotlinVersionProperty] as String)
        }
        val kotlinPlugin =
            project.plugins
                .findPlugin(KotlinAndroidPluginWrapper::class.java)
        // Partial implementation of getKotlinPluginVersion from the comment above.
        var versionString: String? = kotlinPlugin?.pluginVersion
        if (!versionString.isNullOrEmpty()) {
            return Version.fromString(versionString)
        }
        // Fall back to reflection.
        val versionField =
            kotlinPlugin?.javaClass?.kotlin?.members?.firstOrNull {
                it.name == firstKotlinVersionFieldName || it.name == secondKotlinVersionFieldName
            }
        versionString = versionField?.call(kotlinPlugin) as String?
        return if (versionString == null) {
            null
        } else {
            Version.fromString(versionString)
        }
    }
}

/**
 * Helper class to parse the versions that are provided as plain strings (Gradle, Kotlin) and
 * perform easy comparisons. All versions will have a major, minor, and patch value. These values
 * default to 0 when they are not provided or are otherwise unparseable.
 * For example the version strings "8.2", "8.2.2hfd", and "8.2.0" would parse to the same version.
 */
internal class Version(
    val major: Int,
    val minor: Int,
    val patch: Int
) : Comparable<Version> {
    companion object {
        fun fromString(version: String): Version {
            val asList: List<String> = version.split(".")
            val convertedToNumbers: List<Int> = asList.map { it.toIntOrNull() ?: 0 }
            return Version(
                major = convertedToNumbers.getOrElse(0) { 0 },
                minor = convertedToNumbers.getOrElse(1) { 0 },
                patch = convertedToNumbers.getOrElse(2) { 0 }
            )
        }
    }

    override fun compareTo(other: Version): Int {
        if (major != other.major) {
            return major - other.major
        }
        if (minor != other.minor) {
            return minor - other.minor
        }
        if (patch != other.patch) {
            return patch - other.patch
        }
        return 0
    }

    override fun equals(other: Any?): Boolean = other is Version && compareTo(other) == 0

    override fun hashCode(): Int = major.hashCode() or minor.hashCode() or patch.hashCode()

    override fun toString(): String = "$major.$minor.$patch"
}

/**
 * The compile SDK configured on a project's Android extension: either a numeric API level
 * (`compileSdk = 36`) or a preview codename (`compileSdkPreview = "Baklava"`). Both are null
 * when the DSL has not been configured (yet).
 */
internal data class CompileSdkVersion(
    val apiLevel: Int?,
    val previewCodename: String?
) {
    /**
     * Whether this compile SDK is known to be higher than [other].
     *
     * - numeric vs numeric: numeric comparison.
     * - preview vs numeric: a preview codename targets an unreleased SDK, so it is
     *   considered higher than any numeric API level.
     * - preview vs preview: codenames stopped being alphabetically ordered when the
     *   alphabet reset at "Baklava", so distinct codenames are incomparable and this
     *   returns false rather than guessing.
     * - if either side is unset, returns false.
     */
    fun isHigherThan(other: CompileSdkVersion): Boolean =
        when {
            previewCodename != null && other.previewCodename != null -> false
            previewCodename != null && other.apiLevel != null -> true
            apiLevel != null && other.apiLevel != null -> apiLevel > other.apiLevel
            else -> false
        }

    /** The human-readable form used in log messages, e.g. "35" or "Baklava". */
    override fun toString(): String = previewCodename ?: apiLevel?.toString() ?: "unknown"
}

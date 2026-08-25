// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.AndroidPluginVersion
import com.android.build.api.variant.AndroidComponentsExtension
import com.android.build.gradle.internal.utils.getKotlinAndroidPluginVersion
import org.gradle.api.JavaVersion
import org.gradle.api.Project
import org.gradle.kotlin.dsl.* // Kotlin DSL helpers if needed
import org.gradle.api.plugins.PluginContainer
import java.lang.reflect.Method

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
     * Returns the version of the Kotlin Gradle plugin.
     *
     * This implementation tries multiple strategies in a defensive order:
     * 1. Use AGP helper getKotlinAndroidPluginVersion (may return "unknown").
     * 2. Read a top-level project property "kotlin_version" if present.
     * 3. Inspect applied plugins for the Kotlin Android plugin and attempt to read a
     *    pluginVersion-like property via reflection.
     *
     * The code avoids compile-time dependency on Kotlin plugin implementation types
     * by using plugin id lookup and reflection.
     */
    internal fun getKGPVersion(project: Project): Version? {
        // 1) Try AGP-provided helper (may be internal but commonly available)
        val agpDefinedKgpVersion = try {
            getKotlinAndroidPluginVersion(project)
        } catch (_: Throwable) {
            null
        }
        if (agpDefinedKgpVersion != null && agpDefinedKgpVersion != "unknown") {
            return Version.fromString(agpDefinedKgpVersion)
        }

        // 2) Check for an explicit kotlin_version property in the project (top-level build.gradle)
        val kotlinVersionProperty = "kotlin_version"
        if (project.hasProperty(kotlinVersionProperty)) {
            val prop = project.properties[kotlinVersionProperty]
            if (prop is String) {
                return Version.fromString(prop)
            }
        }

        // 3) Try to find the Kotlin Android plugin by id and inspect it for a version field
        // Use plugin id to avoid compile-time dependency on Kotlin plugin classes.
        val kotlinPluginIds = listOf(
            "org.jetbrains.kotlin.android",
            "org.jetbrains.kotlin.jvm",
            "org.jetbrains.kotlin.kapt",
            "org.jetbrains.kotlin.multiplatform"
        )

        val pluginContainer: PluginContainer = project.plugins
        var versionString: String? = null

        for (pluginId in kotlinPluginIds) {
            val plugin = try {
                pluginContainer.findPlugin(pluginId)
            } catch (_: Throwable) {
                null
            }
            if (plugin != null) {
                // Try common property names first
                versionString = tryGetPluginVersionViaReflection(plugin)
                if (!versionString.isNullOrEmpty()) {
                    break
                }
            }
        }

        // 4) As a last resort, try to inspect any plugin instance for common field names
        if (versionString.isNullOrEmpty()) {
            val anyKotlinPlugin = pluginContainer.firstOrNull { p ->
                val id = try {
                    // plugin has no guaranteed id accessor; use toString fallback
                    p.toString().contains("kotlin", ignoreCase = true)
                } catch (_: Throwable) {
                    false
                }
                id
            }
            if (anyKotlinPlugin != null) {
                versionString = tryGetPluginVersionViaReflection(anyKotlinPlugin)
            }
        }

        return if (versionString.isNullOrEmpty()) {
            null
        } else {
            Version.fromString(versionString)
        }
    }

    /**
     * Attempt to read a version-like property from a plugin instance using reflection.
     * Common property/method names include: pluginVersion, getPluginVersion, kotlinPluginVersion.
     */
    private fun tryGetPluginVersionViaReflection(plugin: Any): String? {
        try {
            // Try direct property access via Kotlin reflection if available
            val kClass = plugin::class
            // Look for a member named "pluginVersion" or "kotlinPluginVersion"
            val candidateNames = listOf("pluginVersion", "kotlinPluginVersion", "getPluginVersion", "getKotlinPluginVersion")
            for (name in candidateNames) {
                // Try Java getter first
                try {
                    val method: Method? = plugin.javaClass.methods.firstOrNull { it.name.equals(name, ignoreCase = true) && it.parameterCount == 0 }
                    if (method != null) {
                        val result = method.invoke(plugin)
                        if (result is String && result.isNotBlank()) {
                            return result
                        }
                    }
                } catch (_: Throwable) {
                    // ignore and continue
                }

                // Try Kotlin member invocation via kotlin.members if available
                try {
                    val member = plugin.javaClass.kotlin.members.firstOrNull { it.name == name }
                    if (member != null) {
                        val result = member.call(plugin)
                        if (result is String && result.isNotBlank()) {
                            return result
                        }
                    }
                } catch (_: Throwable) {
                    // ignore and continue
                }
            }
        } catch (_: Throwable) {
            // Reflection failed; return null
        }
        return null
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

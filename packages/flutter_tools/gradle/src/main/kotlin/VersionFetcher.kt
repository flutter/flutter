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
import kotlin.reflect.full.memberFunctions
import kotlin.reflect.full.memberProperties

internal object VersionFetcher {
    /**
     * Returns the version of the JVM.
     */
    internal fun getJavaVersion(): JavaVersion = JavaVersion.current()

    /**
     * Returns the version of Gradle.
     */
    internal fun getGradleVersion(project: Project): Version {
        val untrimmedGradleVersion: String = project.gradle.gradleVersion
        return Version.fromString(untrimmedGradleVersion.substringBefore('-'))
    }

    /**
     * Returns the version of the Android Gradle plugin.
     */
    internal fun getAGPVersion(project: Project): AndroidPluginVersion? {
        return project.extensions
            .findByType(AndroidComponentsExtension::class.java)
            ?.pluginVersion
    }

    /**
     * Returns the version of the Kotlin Gradle plugin.
     *
     * This implementation tries multiple strategies in a defensive order:
     * 1. Use AGP helper getKotlinAndroidPluginVersion (may return "unknown").
     * 2. Read a top-level project property "kotlin_version" if present.
     * 3. Inspect applied plugins for the Kotlin Android plugin and attempt to read a
     *    pluginVersion-like property via reflection.
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

        // 3) Try to find the Kotlin plugin by id and inspect it for a version field
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
                versionString = tryGetPluginVersionViaReflection(plugin)
                if (!versionString.isNullOrEmpty()) {
                    break
                }
            }
        }

        // 4) As a last resort, try to inspect any plugin instance for common field names
        if (versionString.isNullOrEmpty()) {
            val anyKotlinPlugin = pluginContainer.firstOrNull { p ->
                try {
                    p.toString().contains("kotlin", ignoreCase = true)
                } catch (_: Throwable) {
                    false
                }
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
            val candidateNames = listOf(
                "pluginVersion",
                "kotlinPluginVersion",
                "getPluginVersion",
                "getKotlinPluginVersion",
                "version"
            )

            // Try Java reflection getters first
            for (name in candidateNames) {
                try {
                    val method: Method? = plugin.javaClass.methods
                        .firstOrNull { it.name.equals(name, ignoreCase = true) && it.parameterCount == 0 }
                    if (method != null) {
                        val result = method.invoke(plugin)
                        if (result is String && result.isNotBlank()) {
                            return result
                        }
                    }
                } catch (_: Throwable) {
                    // ignore and continue
                }
            }

            // Try Kotlin reflection as a fallback (if kotlin-reflect is available)
            try {
                val kClass = plugin::class
                // Look for parameterless functions or properties that match candidate names
                for (name in candidateNames) {
                    try {
                        val fn = kClass.memberFunctions.firstOrNull { it.name.equals(name, ignoreCase = true) && it.parameters.size == 1 }
                        if (fn != null) {
                            val result = fn.call(plugin)
                            if (result is String && result.isNotBlank()) {
                                return result
                            }
                        }
                    } catch (_: Throwable) {
                        // ignore and continue
                    }
                    try {
                        val prop = kClass.memberProperties.firstOrNull { it.name.equals(name, ignoreCase = true) }
                        if (prop != null) {
                            val result = prop.getter.call(plugin)
                            if (result is String && result.isNotBlank()) {
                                return result
                            }
                        }
                    } catch (_: Throwable) {
                        // ignore and continue
                    }
                }
            } catch (_: Throwable) {
                // kotlin-reflect not available or failed; ignore
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
        if (major != other.major) return major - other.major
        if (minor != other.minor) return minor - other.minor
        if (patch != other.patch) return patch - other.patch
        return 0
    }

    override fun equals(other: Any?): Boolean = other is Version && compareTo(other) == 0

    override fun hashCode(): Int {
        var result = major
        result = 31 * result + minor
        result = 31 * result + patch
        return result
    }

    override fun toString(): String = "$major.$minor.$patch"
}

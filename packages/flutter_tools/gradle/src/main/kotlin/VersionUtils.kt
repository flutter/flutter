// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import kotlin.math.max

object VersionUtils {
    /**
     * Compares semantic versions ignoring labels.
     *
     * If the versions are equal (ignoring labels), returns one of the two strings arbitrarily.
     * If minor or patch are omitted (non-conformant to semantic versioning), they are considered zero.
     * If the provided versions in both are equal, the longest version string is returned.
     * For example, "2.8.0" vs "2.8" will always consider "2.8.0" to be the most recent version.
     * For another example, "8.7-rc-2" vs "8.7.2" will always consider "8.7.2" to be the most recent version.
     */
    fun mostRecentSemanticVersion(version1: String, version2: String):String {
        val v1Parts = version1.split(".", "-")
        val v2Parts = version2.split(".", "-")
        val maxSize = max(v1Parts.size, v2Parts.size)

        for (i in 1..maxSize) {
            val v1Part :String = if(i < v1Parts.size) v1Parts[i] else "0"
            val v2Part :String = if(i < v2Parts.size) v2Parts[i] else "0"

            val v1Num :Int = v1Part.toIntOrNull() ?: 0
            val v2Num :Int = v2Part.toIntOrNull() ?: 0
            if (v1Num != v2Num) {
                if(v1Num > v2Num) {
                    return version1
                } else {
                    return version2
                }
            }

            if (v1Part.toIntOrNull() !== null && v2Part.toIntOrNull() === null) {
                return version1
            } else if (v1Part.toIntOrNull() === null && v2Part.toIntOrNull() !== null) {
                return version2
            } else if (v1Part != v2Part) {
                if(comparePreReleaseIdentifiers(v1Part, v2Part)) {
                    return version1
                } else {
                    return version2
                }
            }
        }

        // If versions are equal, return the longest version string
        if(version1.length >= version2.length) {
            return version1
        } else {
            return version2
        }
    }

    fun comparePreReleaseIdentifiers(v1Part:String, v2Part:String): Boolean {
        val v1PreRelease = v1Part.replace(Regex("\\d"), "")
        val v2PreRelease = v2Part.replace(Regex("\\d"), "")
        return v1PreRelease < v2PreRelease
    }
}
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

/**
 * The compile SDK configured on a project's Android extension: either a numeric API level
 * (`compileSdk = 36`) or a preview codename (`compileSdkPreview = "Baklava"`). Both are null
 * when the DSL has not been configured (yet).
 */
internal data class CompileSdkVersion(
    val apiLevel: Int?,
    val previewCodename: String?
) {
    init {
        require(apiLevel == null || previewCodename == null) {
            "CompileSdkVersion cannot have both apiLevel ($apiLevel) and previewCodename ($previewCodename) set."
        }
    }

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
    fun isHigherThan(other: CompileSdkVersion): Boolean {
        if (other.previewCodename != null) {
            return false
        }
        if (previewCodename != null && other.apiLevel != null) {
            return true
        }
        if (apiLevel != null && other.apiLevel != null) {
            return apiLevel > other.apiLevel
        }
        return false
    }

    /** The human-readable form used in log messages, e.g. "35" or "Baklava". */
    override fun toString(): String = previewCodename ?: apiLevel?.toString() ?: "unknown"
}

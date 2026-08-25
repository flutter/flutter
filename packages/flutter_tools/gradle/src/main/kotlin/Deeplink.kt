// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import androidx.annotation.VisibleForTesting
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * Represents a deep link entry used by the Gradle plugin.
 *
 * Note: equality and hashCode intentionally consider only scheme, host and path
 * (keeps parity with the original Groovy behavior).
 */
class DeepLink(
    @VisibleForTesting
    val scheme: String?,
    @VisibleForTesting
    val host: String?,
    @VisibleForTesting
    val path: String?,
    @VisibleForTesting
    val intentFilterCheck: IntentFilterCheck
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other == null) return false
        if (other.javaClass != javaClass) return false
        other as DeepLink
        return scheme == other.scheme &&
            host == other.host &&
            path == other.path
    }

    override fun hashCode(): Int {
        var result = scheme?.hashCode() ?: 0
        result = 31 * result + (host?.hashCode() ?: 0)
        result = 31 * result + (path?.hashCode() ?: 0)
        return result
    }

    fun toJson(): JsonObject =
        buildJsonObject {
            put("scheme", scheme)
            put("host", host)
            put("path", path)
            put("intentFilterCheck", intentFilterCheck.toJson())
        }
}

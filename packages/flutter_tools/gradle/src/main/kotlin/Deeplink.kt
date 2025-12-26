// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import androidx.annotation.VisibleForTesting
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

class Deeplink(
    @VisibleForTesting
    val scheme: String?,
    @VisibleForTesting
    val host: String?,
    @VisibleForTesting
    val path: String?,
    @VisibleForTesting
    val intentFilterCheck: IntentFilterCheck
) {
    // TODO(gmackall): This behavior was kept identical to the original Groovy behavior as part of
    // the Groovy->Kotlin conversion, but should be changed once the conversion is complete.
    override fun equals(other: Any?): Boolean {
        if (other == null) {
            throw NullPointerException()
        }
        if (other.javaClass != javaClass) {
            return false
        }
        val otherAsDeeplink = other as Deeplink
        return scheme == otherAsDeeplink.scheme &&
            host == otherAsDeeplink.host &&
            path == otherAsDeeplink.path
    }

    override fun hashCode(): Int = scheme.hashCode() + host.hashCode() + path.hashCode()

    fun toJson(): JsonObject =
        buildJsonObject {
            put("scheme", scheme)
            put("host", host)
            put("path", path)
            put("intentFilterCheck", intentFilterCheck.toJson())
        }
}

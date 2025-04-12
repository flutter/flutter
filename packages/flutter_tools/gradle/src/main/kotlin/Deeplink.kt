// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

// TODO(gmackall): Identify which of these can be val instead of var.
class Deeplink(
    private var scheme: String?,
    private var host: String?,
    var path: String?,
    private var intentFilterCheck: IntentFilterCheck
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

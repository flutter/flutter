// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * Simple holder for intent-filter checks discovered when parsing Android manifests.
 *
 * Kept intentionally small and defensive so it can be used from the Gradle plugin
 * without introducing additional runtime dependencies.
 */
class IntentFilterCheck(
    var hasAutoVerify: Boolean = false,
    var hasActionView: Boolean = false,
    var hasDefaultCategory: Boolean = false,
    var hasBrowsableCategory: Boolean = false
) {
    fun toJson(): JsonObject =
        buildJsonObject {
            put("hasAutoVerify", hasAutoVerify)
            put("hasActionView", hasActionView)
            put("hasDefaultCategory", hasDefaultCategory)
            put("hasBrowsableCategory", hasBrowsableCategory)
        }
}

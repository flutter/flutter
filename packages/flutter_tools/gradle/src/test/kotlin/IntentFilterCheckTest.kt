// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class IntentFilterCheckTest {
    @Test
    fun canCreateIntentFilterJson() {
        val intentFilterCheck = IntentFilterCheck()
        intentFilterCheck.hasActionView = true
        intentFilterCheck.hasDefaultCategory = true

        val intentJson = intentFilterCheck.toJson()

        // Keys are not a reference because the key values are accessed
        // across the gradle/dart boundery.
        assertTrue(intentJson.containsKey("hasAutoVerify"))
        assertTrue(intentJson.containsKey("hasActionView"))
        assertTrue(intentJson.containsKey("hasDefaultCategory"))
        assertTrue(intentJson.containsKey("hasBrowsableCategory"))

        assertEquals("false", intentJson.get(key = "hasAutoVerify").toString())
        assertEquals("true", intentJson.get(key = "hasActionView").toString())
        assertEquals("true", intentJson.get(key = "hasDefaultCategory").toString())
        assertEquals("false", intentJson.get(key = "hasBrowsableCategory").toString())
    }
}

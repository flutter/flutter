// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import org.gradle.internal.impldep.org.junit.Assert.assertThrows
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class DeeplinkTest {
    @Test
    fun `equals should return true for equal objects`() {
        val deeplink1 = Deeplink("scheme1", "host1", "path1", IntentFilterCheck())
        val deeplink2 = Deeplink("scheme1", "host1", "path1", IntentFilterCheck())

        assertTrue { deeplink1 == deeplink2 }
    }

    @Test
    fun `equals should return false for unequal objects`() {
        val deeplink1 = Deeplink("scheme1", "host1", "path1", IntentFilterCheck())
        val deeplink2 = Deeplink("scheme2", "host2", "path2", IntentFilterCheck())

        assertFalse { deeplink1 == deeplink2 }
    }

    @Test
    fun `equals should return false for other of different type`() {
        val deeplink1 = Deeplink("scheme1", "host1", "path1", IntentFilterCheck())
        val notADeeplink = 5

        assertFalse { deeplink1.equals(notADeeplink) }
    }

    @Suppress("UnusedEquals")
    @Test
    fun `equals should throw NullPointerException for null other`() {
        val deeplink1 = Deeplink("scheme1", "host1", "path1", IntentFilterCheck())
        val deeplink2 = null

        assertThrows(NullPointerException::class.java) { deeplink1.equals(deeplink2) }
    }

    @Test
    fun canCreateDeeplinkJsonWithIntentFilter() {
        val intentFilterCheck = IntentFilterCheck()
        intentFilterCheck.hasActionView = true
        intentFilterCheck.hasDefaultCategory = true
        val deeplink = Deeplink("scheme1", "host1", "path1", intentFilterCheck)
        val linkJson = deeplink.toJson()
        // Keys are not a reference because the key values are accessed
        // across the gradle/dart boundary.
        assertTrue(linkJson.containsKey("scheme"))
        assertTrue(linkJson.containsKey("host"))
        assertTrue(linkJson.containsKey("path"))
        assertTrue(linkJson.containsKey("intentFilterCheck"))
        assertContains(linkJson.toString(), intentFilterCheck.toJson().toString())
    }
}

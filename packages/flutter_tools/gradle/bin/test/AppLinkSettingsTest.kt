// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
package com.flutter.gradle

import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class AppLinkSettingsTest {
    @Test
    fun canCreateThenEditDeeplinks() {
        val deeplink1 = Deeplink("scheme1", "host1", "path1", IntentFilterCheck())
        val deeplink2 = Deeplink("scheme2", "host2", "path2", IntentFilterCheck())
        val appLinkSettings = AppLinkSettings(applicationId = "testApplicationId")

        appLinkSettings.deeplinks.add(deeplink1)
        assert(appLinkSettings.deeplinks.contains(deeplink1))
        // Check default value.
        assertFalse(appLinkSettings.deeplinkingFlagEnabled)
        // Can change the default value.
        appLinkSettings.deeplinkingFlagEnabled = true

        appLinkSettings.deeplinks.add(deeplink2)

        assert(appLinkSettings.deeplinks.contains(deeplink1))
        assert(appLinkSettings.deeplinks.contains(deeplink2))
    }

    @Test
    fun canCreateAppLinkSettingsJson() {
        val deeplink1 = Deeplink("scheme1", "host1", "path1", IntentFilterCheck())
        val deeplink2 = Deeplink("scheme2", "host2", "path2", IntentFilterCheck())
        val appLinkSettings = AppLinkSettings(applicationId = "testApplicationId")
        appLinkSettings.deeplinkingFlagEnabled = true
        appLinkSettings.deeplinks.addAll(listOf(deeplink1, deeplink2))

        val settingsJson = appLinkSettings.toJson()

        // Keys are not a reference because the key values are accessed
        // across the gradle/dart boundery.
        assertTrue(settingsJson.containsKey("applicationId"))
        assertTrue(settingsJson.containsKey("deeplinkingFlagEnabled"))
        assertTrue(settingsJson.containsKey("deeplinks"))
        assertContains(settingsJson.toString(), deeplink1.toJson().toString())
        assertContains(settingsJson.toString(), deeplink2.toJson().toString())
    }
}

package com.flutter.gradle

import org.junit.jupiter.api.Test

class AppLinkSettingsTest {

    @Test
    fun canCreateAppLinkSettings() {
        val deeplink1 = Deeplink("scheme1", "host1", "path1", null)
        val deeplink2 = Deeplink("scheme2", "host2", "path2", null)
        val appLinkSettings = AppLinkSettings(applicationId = "testApplicationId", deeplinks = mutableSetOf(deeplink1) , deeplinkingFlagEnabled = true)

        assert(appLinkSettings.deeplinks.contains(deeplink1));

        appLinkSettings.deeplinks.add(deeplink2);

        assert(appLinkSettings.deeplinks.contains(deeplink1));
        assert(appLinkSettings.deeplinks.contains(deeplink2));
    }
}
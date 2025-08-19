// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import com.flutter.gradle.Deeplink
import com.flutter.gradle.IntentFilterCheck
import io.mockk.every
import io.mockk.mockk
import org.gradle.api.file.RegularFileProperty
import org.xml.sax.SAXParseException
import java.io.File
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.test.fail

/**
 * Tests for [DeepLinkJsonFromManifestTaskHelper].
 *
 * Parsing tests for corner cases are in
 * `flutter/packages/flutter_tools/test/integration.shard/android_gradle_outputs_app_link_settings_test.dart`.
 * Json tests are in `flutter/packages/flutter_tools/gradle/src/test/kotlin/AppLinkSettingsTest.kt` and
 * `flutter/packages/flutter_tools/gradle/src/test/kotlin/DeeplinkTest.kt`.
 *
 * Tests here are focused on malformed manifest behavior and that there are some tests that cover
 * reading from files. The contents of DeepLinks should not be tested in this file.
 */
class DeepLinkJsonFromManifestTaskTest {
    private val defaultNamespace = "dev.flutter.example"
    private val defaultActivity = ".MainActivity"

    private fun createTempManifestFile(content: String): File {
        val manifestFile = File.createTempFile("AndroidManifestTest", ".xml")
        manifestFile.deleteOnExit()
        manifestFile.writeText(content.trimIndent())
        return manifestFile
    }

    @Test
    fun createAppLinkSettingsFileCreation() {
        val scheme = "http"
        val host = "example.com"
        val pathPrefix = "/profile"
        val manifestContent =
            DeeplinkManifestBuilder()
                .addActivity(defaultActivity)
                .addDeeplinks(defaultActivity, listOf(Deeplink(scheme, host, pathPrefix, IntentFilterCheck(hasActionView = true))))
                .build()
        val manifestFile =
            createTempManifestFile(manifestContent)
        val manifest = mockk<RegularFileProperty>()
        every { manifest.get().asFile } returns manifestFile

        val jsonFile = File.createTempFile("deeplink", ".json")
        jsonFile.deleteOnExit()
        val json = mockk<RegularFileProperty>()
        every { json.get().asFile } returns jsonFile

        try {
            DeepLinkJsonFromManifestTaskHelper.createAppLinkSettingsFile(
                defaultNamespace,
                manifest,
                json
            )
        } catch (e: SAXParseException) {
            fail("Failed to parse Manifest:\n$manifestContent", e)
        }
        assertEquals(
            DeepLinkJsonFromManifestTaskHelper.createAppLinkSettings(defaultNamespace, manifestFile).toJson().toString(),
            jsonFile.readText()
        )
    }

    @Test
    fun noApplicationInManifest() {
        val manifestContent = """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android"
                package="$defaultNamespace">
            </manifest>
            """
        val manifestFile = createTempManifestFile(manifestContent)
        val appLinkSettings = DeepLinkJsonFromManifestTaskHelper.createAppLinkSettings(defaultNamespace, manifestFile)

        assertEquals(defaultNamespace, appLinkSettings.applicationId)
        assertFalse(appLinkSettings.deeplinkingFlagEnabled)
        assertTrue(appLinkSettings.deeplinks.isEmpty())
    }

    @Test
    fun applicationNoDeepLinkingElements() {
        val manifestContent = DeeplinkManifestBuilder().build()
        val manifestFile = createTempManifestFile(manifestContent)
        try {
            val appLinkSettings = DeepLinkJsonFromManifestTaskHelper.createAppLinkSettings(defaultNamespace, manifestFile)
            assertEquals(defaultNamespace, appLinkSettings.applicationId)
            assertFalse(appLinkSettings.deeplinkingFlagEnabled)
            assertTrue(appLinkSettings.deeplinks.isEmpty())
        } catch (e: SAXParseException) {
            fail("Failed to parse Manifest:\n$manifestContent", e)
        }
    }

    @Test
    fun metaDataDeepLinkingEnabledTrue() {
        val manifestContent = DeeplinkManifestBuilder().addActivity("$defaultNamespace.MainActivity").setDeeplinkEnabled(true).build()
        val manifestFile = createTempManifestFile(manifestContent)
        try {
            val appLinkSettings =
                DeepLinkJsonFromManifestTaskHelper
                    .createAppLinkSettings(
                        defaultNamespace,
                        manifestFile
                    )
            assertEquals(defaultNamespace, appLinkSettings.applicationId)
            assertTrue(appLinkSettings.deeplinkingFlagEnabled)
            assertTrue(appLinkSettings.deeplinks.isEmpty())
        } catch (e: SAXParseException) {
            fail("Failed to parse Manifest:\n$manifestContent", e)
        }
    }

    @Test
    fun metaDataDeepLinkingEnabledFalse() {
        val manifestContent = DeeplinkManifestBuilder().addActivity("$defaultNamespace.MainActivity").setDeeplinkEnabled(false).build()
        val manifestFile = createTempManifestFile(manifestContent)

        try {
            val appLinkSettings = DeepLinkJsonFromManifestTaskHelper.createAppLinkSettings(defaultNamespace, manifestFile)
            assertEquals(defaultNamespace, appLinkSettings.applicationId)
            assertFalse(appLinkSettings.deeplinkingFlagEnabled)
            assertTrue(appLinkSettings.deeplinks.isEmpty())
        } catch (e: SAXParseException) {
            fail("Failed to parse Manifest:\n$manifestContent", e)
        }
    }

    @Test
    fun metaDataDeepLinkingEnabledInvalidValue() {
        val manifestContent = """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android"
                package="$defaultNamespace">
                <application android:label="Test App">
                    <meta-data android:name="flutter_deeplinking_enabled" android:value="not_a_boolean" />
                </application>
            </manifest>
            """
        val manifestFile = createTempManifestFile(manifestContent)
        val appLinkSettings = DeepLinkJsonFromManifestTaskHelper.createAppLinkSettings(defaultNamespace, manifestFile)

        assertEquals(defaultNamespace, appLinkSettings.applicationId)
        assertFalse(appLinkSettings.deeplinkingFlagEnabled, "Should default to false for invalid meta-data value")
        assertTrue(appLinkSettings.deeplinks.isEmpty())
    }

    @Test
    fun metaDataDeepLinkingNoValue() {
        val manifestContent = """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android"
                package="$defaultNamespace">
                <application android:label="Test App">
                    <meta-data android:name="flutter_deeplinking_enabled" />
                </application>
            </manifest>
            """
        val manifestFile = createTempManifestFile(manifestContent)
        val appLinkSettings = DeepLinkJsonFromManifestTaskHelper.createAppLinkSettings(defaultNamespace, manifestFile)

        assertEquals(defaultNamespace, appLinkSettings.applicationId)
        assertFalse(appLinkSettings.deeplinkingFlagEnabled, "Should default to false if meta-data value is missing")
        assertTrue(appLinkSettings.deeplinks.isEmpty())
    }

    @Test
    fun basicDeepLink() {
        val scheme = "http"
        val host = "example.com"
        val pathPrefix = "/profile"
        val expectedDeeplink = Deeplink(scheme, host, pathPrefix, IntentFilterCheck(hasActionView = true))
        val manifestContent =
            DeeplinkManifestBuilder()
                .addActivity(
                    defaultActivity
                ).addDeeplinks(defaultActivity, listOf(expectedDeeplink))
                .build()
        val manifestFile = createTempManifestFile(manifestContent)
        try {
            val appLinkSettings =
                DeepLinkJsonFromManifestTaskHelper.createAppLinkSettings(
                    defaultNamespace,
                    manifestFile
                )

            assertEquals(defaultNamespace, appLinkSettings.applicationId)
            assertTrue(appLinkSettings.deeplinkingFlagEnabled)
            assertEquals(1, appLinkSettings.deeplinks.size)
            assertContains(
                appLinkSettings.deeplinks,
                expectedDeeplink,
                "Did not find $expectedDeeplink in ${appLinkSettings.deeplinks.joinToString { it.toJson().toString() }}"
            )
        } catch (e: SAXParseException) {
            fail("Failed to parse Manifest:\n$manifestContent", e)
        }
    }

    @Test
    fun deepLinkWithAutoVerify() {
        val scheme = "https"
        val host = "secure.example.com"
        val expectedDeeplink =
            Deeplink(scheme, host, "", IntentFilterCheck(hasAutoVerify = true, hasDefaultCategory = true, hasBrowsableCategory = true))
        val manifestContent =
            DeeplinkManifestBuilder()
                .addActivity(
                    defaultActivity
                ).addDeeplinks(defaultActivity, listOf(expectedDeeplink))
                .build()
        val manifestFile = createTempManifestFile(manifestContent)
        try {
            val appLinkSettings =
                DeepLinkJsonFromManifestTaskHelper.createAppLinkSettings(
                    defaultNamespace,
                    manifestFile
                )
            assertEquals(1, appLinkSettings.deeplinks.size)
            assertContains(
                appLinkSettings.deeplinks,
                expectedDeeplink,
                "Did not find $expectedDeeplink in ${appLinkSettings.deeplinks.joinToString { it.toJson().toString() }}"
            )
        } catch (e: SAXParseException) {
            fail("Failed to parse Manifest:\n$manifestContent", e)
        }
    }

    @Test
    fun multipleIntentFilters() {
        // TODO start here
        val expectedLink1 =
            Deeplink(
                "custom",
                "filter.one",
                ".*",
                IntentFilterCheck(hasAutoVerify = false, hasActionView = true, hasDefaultCategory = true, hasBrowsableCategory = true)
            )
        val expectedLink2 =
            Deeplink(
                "https",
                "filter.two",
                "/product.*",
                IntentFilterCheck(hasAutoVerify = true, hasActionView = true, hasDefaultCategory = true, hasBrowsableCategory = true)
            )
        val manifestContent =
            DeeplinkManifestBuilder()
                .addActivity(
                    defaultActivity
                ).addDeeplinks(defaultActivity, listOf(expectedLink1, expectedLink2))
                .build()
        val manifestFile = createTempManifestFile(manifestContent)
        try {
            val appLinkSettings =
                DeepLinkJsonFromManifestTaskHelper.createAppLinkSettings(
                    defaultNamespace,
                    manifestFile
                )
            assertEquals(2, appLinkSettings.deeplinks.size)
            assertContains(
                appLinkSettings.deeplinks,
                expectedLink1,
                "Did not find $expectedLink1 in ${appLinkSettings.deeplinks.joinToString { it.toJson().toString() }}"
            )
            assertContains(
                appLinkSettings.deeplinks,
                expectedLink2,
                "Did not find $expectedLink2 in ${appLinkSettings.deeplinks.joinToString { it.toJson().toString() }}"
            )
        } catch (e: SAXParseException) {
            fail("Failed to parse Manifest:\n$manifestContent", e)
        }
    }

    @Test
    fun multipleActivitiesWithDeepLinks() {
        val otherActivity = ".OtherActivity"
        val expectedDeeplink1 =
            Deeplink(
                "app",
                "main.activity",
                null,
                IntentFilterCheck(hasActionView = true, hasDefaultCategory = true, hasBrowsableCategory = true)
            )
        val expectedDeeplink2 =
            Deeplink(
                "http",
                "other.activity",
                ".*user.*",
                IntentFilterCheck(hasAutoVerify = true, hasActionView = true, hasBrowsableCategory = true)
            )
        val manifestContent =
            DeeplinkManifestBuilder()
                .addActivity(defaultActivity)
                .addActivity(otherActivity)
                .addDeeplinks(defaultActivity, listOf(expectedDeeplink1))
                .addDeeplinks(otherActivity, listOf(expectedDeeplink2))
                .build()
        val manifestFile = createTempManifestFile(manifestContent)
        try {
            val appLinkSettings =
                DeepLinkJsonFromManifestTaskHelper.createAppLinkSettings(
                    defaultNamespace,
                    manifestFile
                )
            assertEquals(2, appLinkSettings.deeplinks.size)
            assertContains(
                appLinkSettings.deeplinks,
                // Path when not set is assumed to be ".*"
                Deeplink(expectedDeeplink1.scheme, expectedDeeplink1.host, ".*", expectedDeeplink1.intentFilterCheck),
                "Did not find $expectedDeeplink1 in ${appLinkSettings.deeplinks.joinToString { it.toJson().toString() }}"
            )
            assertContains(
                appLinkSettings.deeplinks,
                expectedDeeplink2,
                "Did not find $expectedDeeplink2 in ${appLinkSettings.deeplinks.joinToString { it.toJson().toString() }}"
            )
        } catch (e: SAXParseException) {
            fail("Failed to parse Manifest:\n$manifestContent", e)
        }
    }

    @Test
    fun intentFilterMissingHostInData() {
        val expectedDeeplink =
            Deeplink(
                "http",
                host = null,
                path = null,
                IntentFilterCheck(hasActionView = true, hasBrowsableCategory = true, hasDefaultCategory = true)
            )
        val manifestContent =
            DeeplinkManifestBuilder()
                .addActivity(
                    defaultActivity
                ).addDeeplinks(defaultActivity, listOf(expectedDeeplink))
                .build()
        val manifestFile = createTempManifestFile(manifestContent)
        val appLinkSettings = DeepLinkJsonFromManifestTaskHelper.createAppLinkSettings(defaultNamespace, manifestFile)
        assertTrue(appLinkSettings.deeplinks.isEmpty(), "Intent filter with data missing host should be ignored")
    }

    @Test
    fun malformedManifestXML() {
        val manifestFile = createTempManifestFile("<manifest><application></application><manifest>") // Malformed XML
        assertFailsWith<SAXParseException> {
            DeepLinkJsonFromManifestTaskHelper.createAppLinkSettings(defaultNamespace, manifestFile)
        }
    }

    /**
     * Helper class for creating valid android manifest file that contains deep links.
     */
    class DeeplinkManifestBuilder {
        val activitySectionDefault =
            """
            <activity android:name=".MainActivity">
                    <intent-filter>
                        <action android:name="android.intent.action.VIEW" />
                        <category android:name="android.intent.category.DEFAULT" />
                        <category android:name="android.intent.category.BROWSABLE" />
                        <data android:scheme="http" />
                    </intent-filter>
                </activity>
            """.trimIndent()
        private var namespace: String = "dev.flutter.example"

        private var deeplinkEnabled = true
        private val activitySet: MutableSet<String> = mutableSetOf()
        private val deeplinkMap: MutableMap<String, List<Deeplink>> = mutableMapOf()

        fun setNamespace(namespace: String): DeeplinkManifestBuilder {
            this.namespace = namespace
            return this
        }

        fun addActivity(activity: String): DeeplinkManifestBuilder {
            activitySet.add(activity)
            return this
        }

        fun addDeeplinks(
            activity: String,
            deeplinks: List<Deeplink>
        ): DeeplinkManifestBuilder {
            deeplinkMap[activity] = deeplinks
            return this
        }

        fun setDeeplinkEnabled(enabled: Boolean): DeeplinkManifestBuilder {
            deeplinkEnabled = enabled
            return this
        }

        fun build(): String {
            var activitySection = ""
            // Warning: Xml parsing can be sensitive to whitespace changes.
            if (activitySet.isNotEmpty()) {
                for (activity in activitySet) {
                    activitySection += "\t<activity android:name=\"$activity\" android:exported=\"true\">\n"
                    if (deeplinkEnabled) {
                        activitySection +=
                            "\t\t" + """<meta-data android:name="flutter_deeplinking_enabled" android:value="true" />""" + "\n"
                    }
                    if (deeplinkMap[activity] == null) {
                        // Close activity and do not continue to deep link parsing.
                        activitySection += "\t</activity>"
                        continue
                    }
                    for (deeplink in deeplinkMap[activity]!!) {
                        if (deeplink.intentFilterCheck.hasAutoVerify) {
                            activitySection += ("\t\t" + """<intent-filter android:autoVerify="true">""" + "\n")
                        } else {
                            activitySection += ("\t\t" + """<intent-filter>""" + "\n")
                        }
                        if (deeplink.intentFilterCheck.hasActionView) {
                            activitySection += "\t\t\t" + """<action android:name="android.intent.action.VIEW" />""" + "\n"
                        }
                        if (deeplink.intentFilterCheck.hasDefaultCategory) {
                            activitySection += "\t\t\t" + """<category android:name="android.intent.category.DEFAULT" />""" + "\n"
                        }
                        if (deeplink.intentFilterCheck.hasBrowsableCategory) {
                            activitySection += "\t\t\t" + """<category android:name="android.intent.category.BROWSABLE" />""" + "\n"
                        }
                        val scheme =
                            deeplink.scheme?.let { scheme -> """android:scheme="$scheme"""" } ?: ""
                        val host = deeplink.host?.let { host -> """android:host="$host"""" } ?: ""
                        val path = deeplink.path?.let { path -> """android:path="$path"""" } ?: ""
                        activitySection += "\t\t\t<data $scheme $host $path/>\n"
                        activitySection += "\t\t" + """</intent-filter>""" + "\n"
                    }
                    activitySection += "\t</activity>\n"
                }
            }

            return """
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="$namespace">
    <application android:label="Test App">
    $activitySection
    </application>
</manifest>
"""
        }
    }
}

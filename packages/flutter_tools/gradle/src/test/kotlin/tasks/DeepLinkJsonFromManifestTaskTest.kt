// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import io.mockk.every
import io.mockk.mockk
import org.gradle.api.file.RegularFileProperty
import org.xml.sax.SAXParseException
import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertTrue

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
        val manifestContent = """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android"
                package="$defaultNamespace">
                <application android:label="Test App">
                    <activity android:name=".MainActivity">
                    <meta-data android:name="flutter_deeplinking_enabled" android:value="true" />
                        <intent-filter>
                            <action android:name="android.intent.action.VIEW" />
                            <data android:scheme="$scheme" android:host="$host" android:pathPrefix="$pathPrefix" />
                        </intent-filter>
                    </activity>
                </application>
            </manifest>
            """
        val manifestFile = createTempManifestFile(manifestContent)
        val manifest = mockk<RegularFileProperty>()
        every { manifest.get().asFile } returns manifestFile

        val jsonFile = File.createTempFile("deeplink", ".json")
        jsonFile.deleteOnExit()
        val json = mockk<RegularFileProperty>()
        every { json.get().asFile } returns jsonFile

        DeepLinkJsonFromManifestTaskHelper.createAppLinkSettingsFile(defaultNamespace, manifest, json)
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
        val manifestContent = """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android"
                package="$defaultNamespace">
                <application android:label="Test App" android:icon="@mipmap/ic_launcher">
                </application>
            </manifest>
            """
        val manifestFile = createTempManifestFile(manifestContent)
        val appLinkSettings = DeepLinkJsonFromManifestTaskHelper.createAppLinkSettings(defaultNamespace, manifestFile)

        assertEquals(defaultNamespace, appLinkSettings.applicationId)
        assertFalse(appLinkSettings.deeplinkingFlagEnabled)
        assertTrue(appLinkSettings.deeplinks.isEmpty())
    }

    @Test
    fun metaDataDeepLinkingEnabledTrue() {
        val manifestContent = """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android"
                package="$defaultNamespace">
                <application android:label="Test App">
                <activity
                    android:name="$defaultNamespace.MainActivity"
                    android:exported="true"
                    android:theme="@style/WhiteBackgroundTheme" >
                    <meta-data android:name="flutter_deeplinking_enabled" android:value="true" />
                </activity>
                </application>
            </manifest>
            """
        val manifestFile = createTempManifestFile(manifestContent)
        val appLinkSettings = DeepLinkJsonFromManifestTaskHelper.createAppLinkSettings(defaultNamespace, manifestFile)

        assertEquals(defaultNamespace, appLinkSettings.applicationId)
        assertTrue(appLinkSettings.deeplinkingFlagEnabled)
        assertTrue(appLinkSettings.deeplinks.isEmpty())
    }

    @Test
    fun metaDataDeepLinkingEnabledFalse() {
        val manifestContent = """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android"
                package="$defaultNamespace">
                <application android:label="Test App">
                <activity
                    android:name="$defaultNamespace.MainActivity"
                    android:exported="true"
                    android:theme="@style/WhiteBackgroundTheme" >
                    <meta-data android:name="flutter_deeplinking_enabled" android:value="false" />
                </activity>
                </application>
            </manifest>
            """
        val manifestFile = createTempManifestFile(manifestContent)
        val appLinkSettings = DeepLinkJsonFromManifestTaskHelper.createAppLinkSettings(defaultNamespace, manifestFile)

        assertEquals(defaultNamespace, appLinkSettings.applicationId)
        assertFalse(appLinkSettings.deeplinkingFlagEnabled)
        assertTrue(appLinkSettings.deeplinks.isEmpty())
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
        val manifestContent = """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android"
                package="$defaultNamespace">
                <application android:label="Test App">
                    <activity android:name=".MainActivity">
                    <meta-data android:name="flutter_deeplinking_enabled" android:value="true" />
                        <intent-filter>
                            <action android:name="android.intent.action.VIEW" />
                            <data android:scheme="$scheme" android:host="$host" android:pathPrefix="$pathPrefix" />
                        </intent-filter>
                    </activity>
                </application>
            </manifest>
            """
        val manifestFile = createTempManifestFile(manifestContent)
        val appLinkSettings = DeepLinkJsonFromManifestTaskHelper.createAppLinkSettings(defaultNamespace, manifestFile)

        assertEquals(defaultNamespace, appLinkSettings.applicationId)
        assertTrue(appLinkSettings.deeplinkingFlagEnabled)
        assertEquals(1, appLinkSettings.deeplinks.size)
    }

    @Test
    fun deepLinkWithAutoVerify() {
        val manifestContent = """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android"
                package="$defaultNamespace">
                <application android:label="Test App">
                    <activity android:name=".MainActivity">
                        <intent-filter android:autoVerify="true">
                            <action android:name="android.intent.action.VIEW" />
                            <category android:name="android.intent.category.DEFAULT" />
                            <category android:name="android.intent.category.BROWSABLE" />
                            <data android:scheme="https" android:host="secure.example.com" />
                        </intent-filter>
                    </activity>
                </application>
            </manifest>
            """
        val manifestFile = createTempManifestFile(manifestContent)
        val appLinkSettings = DeepLinkJsonFromManifestTaskHelper.createAppLinkSettings(defaultNamespace, manifestFile)
        assertEquals(1, appLinkSettings.deeplinks.size)
    }

    @Test
    fun multipleIntentFilters() {
        val manifestContent = """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android"
                package="$defaultNamespace">
                <application android:label="Test App">
                    <activity android:name=".MainActivity">
                        <intent-filter>
                            <action android:name="android.intent.action.VIEW" />
                            <category android:name="android.intent.category.DEFAULT" />
                            <category android:name="android.intent.category.BROWSABLE" />
                            <data android:scheme="custom" android:host="filter.one" />
                        </intent-filter>
                        <intent-filter android:autoVerify="true">
                            <action android:name="android.intent.action.VIEW" />
                            <category android:name="android.intent.category.DEFAULT" />
                            <category android:name="android.intent.category.BROWSABLE" />
                            <data android:scheme="https" android:host="filter.two" android:pathPrefix="/product"/>
                        </intent-filter>
                    </activity>
                </application>
            </manifest>
            """
        val manifestFile = createTempManifestFile(manifestContent)
        val appLinkSettings = DeepLinkJsonFromManifestTaskHelper.createAppLinkSettings(defaultNamespace, manifestFile)
        assertEquals(2, appLinkSettings.deeplinks.size)
    }

    @Test
    fun multipleActivitiesWithDeepLinks() {
        val manifestContent = """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android"
                package="$defaultNamespace">
                <application android:label="Test App">
                    <activity android:name=".MainActivity">
                        <intent-filter>
                            <action android:name="android.intent.action.VIEW" />
                            <category android:name="android.intent.category.DEFAULT" />
                            <category android:name="android.intent.category.BROWSABLE" />
                            <data android:scheme="app" android:host="main.activity" />
                        </intent-filter>
                    </activity>
                    <activity android:name=".OtherActivity">
                        <intent-filter android:autoVerify="true">
                            <action android:name="android.intent.action.VIEW" />
                            <category android:name="android.intent.category.DEFAULT" />
                            <category android:name="android.intent.category.BROWSABLE" />
                            <data android:scheme="http" android:host="other.activity" android:pathPattern=".*user.*"/>
                        </intent-filter>
                    </activity>
                </application>
            </manifest>
            """
        val manifestFile = createTempManifestFile(manifestContent)
        val appLinkSettings = DeepLinkJsonFromManifestTaskHelper.createAppLinkSettings(defaultNamespace, manifestFile)
        assertEquals(2, appLinkSettings.deeplinks.size)
    }

    @Test
    fun intentFilterMissingHostInData() {
        val manifestContent = """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android"
                package="$defaultNamespace">
                <application android:label="Test App">
                    <activity android:name=".MainActivity">
                        <intent-filter>
                            <action android:name="android.intent.action.VIEW" />
                            <category android:name="android.intent.category.DEFAULT" />
                            <category android:name="android.intent.category.BROWSABLE" />
                            <data android:scheme="http" />
                        </intent-filter>
                    </activity>
                </application>
            </manifest>
            """
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
}

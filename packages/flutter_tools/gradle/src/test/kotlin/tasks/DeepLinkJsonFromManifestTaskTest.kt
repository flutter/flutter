// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse

class DeepLinkJsonFromManifestTaskTest {
    // TODO test createAppLinkSettingsFile
    @Test
    fun noApplicationInManifest() {
        val manifest = File.createTempFile("AndroidManifestNoApplication", ".xml")
        manifest.deleteOnExit() // Ensures the file is deleted when the JVM exits
        val namespace = "dev.flutter.packages.file_selector_android_example"
        val content =
            """
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android"
                package="$namespace"
                android:versionCode="1"
                android:versionName="1.0" >
            </manifest>
            """.trimIndent()
        manifest.writeText(content)
        val appLinkSettings = DeepLinkJsonFromManifestTaskHelper.createAppLinkSettings(namespace, manifest)
        assertEquals(namespace, appLinkSettings.applicationId)
        assertFalse(appLinkSettings.deeplinkingFlagEnabled)
        assertEquals(0, appLinkSettings.deeplinks.size)
    }
}

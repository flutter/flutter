// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import groovy.util.Node
import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

/**
 * Tests for [EnableHcppManifestTaskHelper].
 */
class EnableHcppManifestTaskTest {
    private val defaultNamespace = "dev.flutter.example"

    private fun createTempManifestFile(content: String): File {
        val manifestFile = File.createTempFile("AndroidManifestTest", ".xml")
        manifestFile.deleteOnExit()
        manifestFile.writeText(content.trimIndent())
        return manifestFile
    }

    private fun createTempOutputFile(): File {
        val outputFile = File.createTempFile("AndroidManifestUpdated", ".xml")
        outputFile.deleteOnExit()
        return outputFile
    }

    private fun findHcppMetadataValue(manifestFile: File): String? {
        val manifest: Node =
            groovy.xml
                .XmlParser(false, false)
                .parse(manifestFile)
        val applicationNode: Node =
            manifest.children().filterIsInstance<Node>().find { node ->
                node.name() == "application"
            } ?: return null
        val metadataNode: Node? =
            applicationNode.children().filterIsInstance<Node>().find { node ->
                node.name() == "meta-data" &&
                    node.attribute("android:name") == EnableHcppManifestTaskHelper.HCPP_METADATA_NAME
            }
        return metadataNode?.attribute("android:value")?.toString()
    }

    @Test
    fun addsMetadataWhenAbsent() {
        val manifestFile =
            createTempManifestFile(
                """
                <?xml version="1.0" encoding="utf-8"?>
                <manifest xmlns:android="http://schemas.android.com/apk/res/android"
                    package="$defaultNamespace">
                    <application android:label="Test App">
                        <activity android:name=".MainActivity" android:exported="true" />
                    </application>
                </manifest>
                """
            )
        val updatedManifest = createTempOutputFile()

        EnableHcppManifestTaskHelper.addEnableHcppMetadataIfAbsent(manifestFile, updatedManifest)

        assertEquals("true", findHcppMetadataValue(updatedManifest))
    }

    @Test
    fun doesNotOverrideExplicitlyDisabledMetadata() {
        val manifestFile =
            createTempManifestFile(
                """
                <?xml version="1.0" encoding="utf-8"?>
                <manifest xmlns:android="http://schemas.android.com/apk/res/android"
                    package="$defaultNamespace">
                    <application android:label="Test App">
                        <meta-data android:name="${EnableHcppManifestTaskHelper.HCPP_METADATA_NAME}" android:value="false" />
                    </application>
                </manifest>
                """
            )
        val updatedManifest = createTempOutputFile()

        EnableHcppManifestTaskHelper.addEnableHcppMetadataIfAbsent(manifestFile, updatedManifest)

        assertEquals("false", findHcppMetadataValue(updatedManifest))
        assertEquals(
            manifestFile.readText(),
            updatedManifest.readText(),
            "Manifest with an explicit value should be copied unmodified"
        )
    }

    @Test
    fun leavesExplicitlyEnabledMetadataUnmodified() {
        val manifestFile =
            createTempManifestFile(
                """
                <?xml version="1.0" encoding="utf-8"?>
                <manifest xmlns:android="http://schemas.android.com/apk/res/android"
                    package="$defaultNamespace">
                    <application android:label="Test App">
                        <meta-data android:name="${EnableHcppManifestTaskHelper.HCPP_METADATA_NAME}" android:value="true" />
                    </application>
                </manifest>
                """
            )
        val updatedManifest = createTempOutputFile()

        EnableHcppManifestTaskHelper.addEnableHcppMetadataIfAbsent(manifestFile, updatedManifest)

        assertEquals("true", findHcppMetadataValue(updatedManifest))
        assertEquals(
            manifestFile.readText(),
            updatedManifest.readText(),
            "Manifest with an explicit value should be copied unmodified"
        )
    }

    @Test
    fun addsApplicationElementWhenAbsent() {
        // A library (add-to-app module) manifest may not contain an application element.
        val manifestFile =
            createTempManifestFile(
                """
                <?xml version="1.0" encoding="utf-8"?>
                <manifest xmlns:android="http://schemas.android.com/apk/res/android"
                    package="$defaultNamespace">
                </manifest>
                """
            )
        val updatedManifest = createTempOutputFile()

        EnableHcppManifestTaskHelper.addEnableHcppMetadataIfAbsent(manifestFile, updatedManifest)

        assertEquals("true", findHcppMetadataValue(updatedManifest))
    }

    @Test
    fun keepsOtherMetadataIntact() {
        val manifestFile =
            createTempManifestFile(
                """
                <?xml version="1.0" encoding="utf-8"?>
                <manifest xmlns:android="http://schemas.android.com/apk/res/android"
                    package="$defaultNamespace">
                    <application android:label="Test App">
                        <meta-data android:name="io.flutter.embedding.android.EnableImpeller" android:value="true" />
                    </application>
                </manifest>
                """
            )
        val updatedManifest = createTempOutputFile()

        EnableHcppManifestTaskHelper.addEnableHcppMetadataIfAbsent(manifestFile, updatedManifest)

        assertEquals("true", findHcppMetadataValue(updatedManifest))
        val manifest: Node =
            groovy.xml
                .XmlParser(false, false)
                .parse(updatedManifest)
        val applicationNode: Node? =
            manifest.children().filterIsInstance<Node>().find { node ->
                node.name() == "application"
            }
        assertNotNull(applicationNode)
        val impellerNode: Node? =
            applicationNode.children().filterIsInstance<Node>().find { node ->
                node.name() == "meta-data" &&
                    node.attribute("android:name") == "io.flutter.embedding.android.EnableImpeller"
            }
        assertNotNull(impellerNode, "Existing meta-data should be preserved")
        assertEquals("Test App", applicationNode.attribute("android:label"))
    }

    @Test
    fun noMetadataInManifestWithoutInjection() {
        // Sanity check that the test helper does not find metadata that is not there.
        val manifestFile =
            createTempManifestFile(
                """
                <?xml version="1.0" encoding="utf-8"?>
                <manifest xmlns:android="http://schemas.android.com/apk/res/android"
                    package="$defaultNamespace">
                    <application android:label="Test App" />
                </manifest>
                """
            )
        assertNull(findHcppMetadataValue(manifestFile))
    }
}

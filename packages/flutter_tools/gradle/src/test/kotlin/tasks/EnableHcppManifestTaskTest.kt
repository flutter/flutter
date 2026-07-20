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
    fun preservesRealMergedManifestContent() {
        // Fixture captured from an actual AGP 8.11.1 processDebugMainManifest output
        // (MERGED_MANIFEST artifact), which is what this task transforms in practice.
        val manifestFile =
            createTempManifestFile(
                """
                <?xml version="1.0" encoding="utf-8"?>
                <manifest xmlns:android="http://schemas.android.com/apk/res/android"
                    package="com.example.host" >

                    <uses-sdk
                        android:minSdkVersion="24"
                        android:targetSdkVersion="36" />
                    <!-- A comment that mimics real app manifests. -->
                    <uses-permission android:name="android.permission.INTERNET" />

                    <queries>
                        <intent>
                            <action android:name="android.intent.action.PROCESS_TEXT" />

                            <data android:mimeType="text/plain" />
                        </intent>
                    </queries>

                    <application
                        android:debuggable="true"
                        android:extractNativeLibs="false"
                        android:hardwareAccelerated="true"
                        android:label="Host"
                        android:supportsRtl="true" >
                        <activity
                            android:name="com.example.host.MainActivity"
                            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
                            android:exported="true"
                            android:launchMode="singleTop"
                            android:windowSoftInputMode="adjustResize" >
                            <intent-filter>
                                <action android:name="android.intent.action.MAIN" />

                                <category android:name="android.intent.category.LAUNCHER" />
                            </intent-filter>
                        </activity>

                        <meta-data
                            android:name="flutterEmbedding"
                            android:value="2" />
                        <meta-data
                            android:name="io.flutter.embedding.android.EnableImpeller"
                            android:value="true" />
                        <meta-data
                            android:name="io.flutter.embedding.android.OldGenHeapSize"
                            android:value="519" />
                    </application>

                </manifest>
                """
            )
        val updatedManifest = createTempOutputFile()

        EnableHcppManifestTaskHelper.addEnableHcppMetadataIfAbsent(manifestFile, updatedManifest)

        assertEquals("true", findHcppMetadataValue(updatedManifest))

        // The rewritten manifest must preserve all elements and attributes.
        val manifest: Node =
            groovy.xml
                .XmlParser(false, false)
                .parse(updatedManifest)
        assertEquals("com.example.host", manifest.attribute("package"))
        assertEquals(
            "http://schemas.android.com/apk/res/android",
            manifest.attribute("xmlns:android"),
            "The android namespace declaration must be preserved"
        )
        val topLevel: List<Node> = manifest.children().filterIsInstance<Node>()
        assertEquals("24", topLevel.first { it.name() == "uses-sdk" }.attribute("android:minSdkVersion"))
        assertEquals(
            "android.permission.INTERNET",
            topLevel.first { it.name() == "uses-permission" }.attribute("android:name")
        )
        val queriesIntent: Node =
            topLevel
                .first { it.name() == "queries" }
                .children()
                .filterIsInstance<Node>()
                .first { it.name() == "intent" }
        assertEquals(
            "text/plain",
            queriesIntent.children().filterIsInstance<Node>().first { it.name() == "data" }.attribute("android:mimeType")
        )
        val applicationNode: Node = topLevel.first { it.name() == "application" }
        assertEquals("Host", applicationNode.attribute("android:label"))
        assertEquals("true", applicationNode.attribute("android:debuggable"))
        val activityNode: Node =
            applicationNode.children().filterIsInstance<Node>().first { it.name() == "activity" }
        assertEquals("com.example.host.MainActivity", activityNode.attribute("android:name"))
        assertEquals("singleTop", activityNode.attribute("android:launchMode"))
        val intentFilter: Node =
            activityNode.children().filterIsInstance<Node>().first { it.name() == "intent-filter" }
        assertEquals(
            "android.intent.action.MAIN",
            intentFilter.children().filterIsInstance<Node>().first { it.name() == "action" }.attribute("android:name")
        )
        val metadataValuesByName: Map<Any?, Any?> =
            applicationNode
                .children()
                .filterIsInstance<Node>()
                .filter { it.name() == "meta-data" }
                .associate { it.attribute("android:name") to it.attribute("android:value") }
        assertEquals("2", metadataValuesByName["flutterEmbedding"])
        assertEquals("true", metadataValuesByName["io.flutter.embedding.android.EnableImpeller"])
        assertEquals("519", metadataValuesByName["io.flutter.embedding.android.OldGenHeapSize"])
        assertEquals("true", metadataValuesByName[EnableHcppManifestTaskHelper.HCPP_METADATA_NAME])
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

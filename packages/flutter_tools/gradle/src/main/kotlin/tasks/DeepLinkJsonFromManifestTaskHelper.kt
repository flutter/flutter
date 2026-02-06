// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import androidx.annotation.VisibleForTesting
import com.flutter.gradle.AppLinkSettings
import com.flutter.gradle.Deeplink
import com.flutter.gradle.IntentFilterCheck
import groovy.util.Node
import org.gradle.api.file.RegularFileProperty
import java.io.File
import kotlin.collections.forEach
import kotlin.io.writeText

/**
 * Stateless object to contain the logic used in [FlutterTask]. Any required state should be stored
 * on [FlutterTask] instead, while any logic needed by [FlutterTask] should be added here.
 */
object DeepLinkJsonFromManifestTaskHelper {
    private const val MANIFEST_NAME_KEY = "android:name"
    private const val MANIFEST_VALUE_KEY = "android:value"
    private const val MANIFEST_VALUE_TRUE = "true"

    /**
     * Creates a jsonfile with deeplink information from the Android manifest file.
     *
     *
     * An example json:
     * {
     *     applicationId: "com.example.app",
     *         deeplinks: [
     *             {"scheme":"http", "host":"example.com", "path":".*"},
     *             {"scheme":"https","host":"example.com","path":".*"}
     *     ]
     * }
     */
    fun createAppLinkSettingsFile(
        applicationId: String,
        manifestFile: RegularFileProperty,
        deepLinkJson: RegularFileProperty
    ) {
        val appLinkSettings = createAppLinkSettings(applicationId, manifestFile.get().asFile)
        deepLinkJson.get().asFile.writeText(appLinkSettings.toJson().toString())
    }

    /**
     * Extracts app deeplink information from the Android manifest file then returns
     * an AppLinkSettings object.
     *
     * @param applicationId The application ID or the namespace of the variant.
     * @param manifestFile the Android manifest to be parsed.
     */
    @VisibleForTesting
    fun createAppLinkSettings(
        applicationId: String,
        manifestFile: File
    ): AppLinkSettings {
        val appLinkSettings = AppLinkSettings(applicationId)
        val manifest: Node =
            groovy.xml
                .XmlParser(false, false)
                .parse(manifestFile)
        val applicationNode: Node? =
            manifest.children().find { node ->
                node is Node && node.name() == "application"
            } as Node?
        if (applicationNode == null) {
            return appLinkSettings
        }
        val activities: List<Node> =
            applicationNode.children().filterIsInstance<Node>().filter { item ->
                item.name() == "activity"
            }

        activities.forEach { activity ->
            val metaDataItems: List<Node> =
                activity.children().filterIsInstance<Node>().filter { metaItem ->
                    metaItem.name() == "meta-data"
                }
            metaDataItems.forEach { metaDataItem ->
                val nameAttribute: Boolean =
                    metaDataItem.attribute(MANIFEST_NAME_KEY) == "flutter_deeplinking_enabled"
                val valueAttribute: Boolean =
                    metaDataItem.attribute(MANIFEST_VALUE_KEY) == MANIFEST_VALUE_TRUE
                if (nameAttribute && valueAttribute) {
                    appLinkSettings.deeplinkingFlagEnabled = true
                }
            }
            val intentFilterItems: List<Node> =
                activity.children().filterIsInstance<Node>().filter { filterItem ->
                    filterItem.name() == "intent-filter"
                }
            intentFilterItems.forEach { appLinkIntent ->
                // Print out the host attributes in data tags.
                val schemes: MutableSet<String?> = mutableSetOf()
                val hosts: MutableSet<String?> = mutableSetOf()
                val paths: MutableSet<String?> = mutableSetOf()
                val intentFilterCheck = IntentFilterCheck()
                if (appLinkIntent.attribute("android:autoVerify") == MANIFEST_VALUE_TRUE) {
                    intentFilterCheck.hasAutoVerify = true
                }

                val actionItems: List<Node> =
                    appLinkIntent.children().filterIsInstance<Node>().filter { item ->
                        item.name() == "action"
                    }
                intentFilterCheck.hasActionView =
                    actionItems.any { action ->
                        action.attribute(MANIFEST_NAME_KEY) == "android.intent.action.VIEW"
                    }
                val categoryItems: List<Node> =
                    appLinkIntent.children().filterIsInstance<Node>().filter { item ->
                        item.name() == "category"
                    }
                intentFilterCheck.hasDefaultCategory =
                    categoryItems.any { category -> category.attribute(MANIFEST_NAME_KEY) == "android.intent.category.DEFAULT" }
                intentFilterCheck.hasBrowsableCategory =
                    categoryItems.any { category -> category.attribute(MANIFEST_NAME_KEY) == "android.intent.category.BROWSABLE" }

                val dataItems: List<Node> =
                    appLinkIntent.children().filterIsInstance<Node>().filter { item ->
                        item.name() == "data"
                    }
                dataItems.forEach { data ->
                    data.attributes().forEach { entry ->
                        when (entry.key) {
                            "android:scheme" -> schemes.add(entry.value.toString())
                            "android:host" -> hosts.add(entry.value.toString())
                            // All path patterns add to paths.
                            "android:pathAdvancedPattern" ->
                                paths.add(
                                    entry.value.toString()
                                )

                            "android:pathPattern" -> paths.add(entry.value.toString())
                            "android:path" -> paths.add(entry.value.toString())
                            "android:pathPrefix" -> paths.add(entry.value.toString() + ".*")
                            "android:pathSuffix" -> paths.add(".*" + entry.value.toString())
                        }
                    }
                }
                if (hosts.isNotEmpty() || paths.isNotEmpty()) {
                    if (schemes.isEmpty()) {
                        schemes.add(null)
                    }
                    if (hosts.isEmpty()) {
                        hosts.add(null)
                    }
                    if (paths.isEmpty()) {
                        paths.add(".*")
                    }
                    // Sets are not ordered so the sortedBy gives them a predictable order.
                    schemes.sortedBy { it ?: "" }.forEach { scheme ->
                        hosts.sortedBy { it ?: "" }.forEach { host ->
                            paths.sortedBy { it ?: "" }.forEach { path ->
                                appLinkSettings.deeplinks.add(
                                    Deeplink(
                                        scheme,
                                        host,
                                        path,
                                        intentFilterCheck
                                    )
                                )
                            }
                        }
                    }
                }
            }
        }
        return appLinkSettings
    }
}

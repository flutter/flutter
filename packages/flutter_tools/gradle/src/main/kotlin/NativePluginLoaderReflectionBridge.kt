// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import org.gradle.api.plugins.ExtraPropertiesExtension
import java.io.File

// TODO(gmackall): Remove reflection after migrating to plugin style application in
//  https://github.com/flutter/flutter/issues/166461.
// New methods should not be added.

/**
 * Class to hide from Kotlin source the dangerous reflection being used to call methods defined
 * in script gradle plugins.
 */

object NativePluginLoaderReflectionBridge {
    /**
     * An abstraction to hide reflection from calling sites. See ../scripts/native_plugin_loader.gradle.kts.
     */
    fun getPlugins(
        extraProperties: ExtraPropertiesExtension,
        flutterProjectRoot: File
    ): List<Map<String?, Any?>> {
        val nativePluginLoader = extraProperties.get("nativePluginLoader")!!

        @Suppress("UNCHECKED_CAST")
        val pluginList: List<Map<String?, Any?>> =
            nativePluginLoader::class
                .members
                .firstOrNull { it.name == "getPlugins" }
                ?.call(nativePluginLoader, flutterProjectRoot) as List<Map<String?, Any?>>

        return pluginList
    }

    /**
     * An abstraction to hide reflection from calling sites. See ../scripts/native_plugin_loader.gradle.kts.
     */
    fun getDependenciesMetadata(
        extraProperties: ExtraPropertiesExtension,
        flutterProjectRoot: File
    ): Map<String, Any> {
        val nativePluginLoader = extraProperties.get("nativePluginLoader")!!

        @Suppress("UNCHECKED_CAST")
        val dependenciesMetadata: Map<String, Any> =
            nativePluginLoader::class
                .members
                .firstOrNull { it.name == "dependenciesMetadata" }
                ?.call(nativePluginLoader, flutterProjectRoot) as Map<String, Any>

        return dependenciesMetadata
    }
}

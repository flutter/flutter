// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import org.gradle.api.plugins.ExtraPropertiesExtension
import java.io.File
import java.lang.reflect.Method

/**
 * Reflection bridge used to call functions defined in the script-based
 * native plugin loader (../scripts/native_plugin_loader.gradle.kts).
 *
 * The original implementation used Kotlin reflection which can be fragile
 * across Gradle/Kotlin versions. This implementation uses defensive Java
 * reflection with clear error messages and runtime checks so failures are
 * easier to diagnose during Gradle configuration/initialization.
 *
 * NOTE: This class intentionally keeps reflection details out of the rest
 * of the Kotlin sources. When the native plugin loader is migrated away
 * from script-based reflection, this bridge can be removed.
 */
object NativePluginLoaderReflectionBridge {

  private fun requireNativeLoader(extraProperties: ExtraPropertiesExtension): Any {
    val key = "nativePluginLoader"
    if (!extraProperties.has(key)) {
      throw IllegalStateException("Expected extra property '$key' to be present (native_plugin_loader script must set it).")
    }
    return extraProperties.get(key) ?: throw IllegalStateException("Extra property '$key' was present but null.")
  }

  private fun findMethod(instance: Any, methodName: String): Method =
    instance.javaClass.methods.firstOrNull { it.name == methodName }
      ?: throw NoSuchMethodException("Method '$methodName' not found on ${instance.javaClass.name}")

  /**
   * Calls the script-provided `getPlugins` method and returns the plugin list.
   *
   * The script method may accept either zero parameters or a single File parameter
   * (the flutter project root). This function attempts to invoke the method with
   * the flutterProjectRoot if the method accepts one parameter; otherwise it
   * invokes it with no arguments.
   */
  @Suppress("UNCHECKED_CAST")
  fun getPlugins(
    extraProperties: ExtraPropertiesExtension,
    flutterProjectRoot: File
  ): List<Map<String?, Any?>> {
    val nativePluginLoader = requireNativeLoader(extraProperties)

    try {
      val method = findMethod(nativePluginLoader, "getPlugins")
      val result = when (method.parameterCount) {
        0 -> method.invoke(nativePluginLoader)
        1 -> method.invoke(nativePluginLoader, flutterProjectRoot)
        else -> throw IllegalStateException("Unexpected parameter count (${method.parameterCount}) for getPlugins on ${nativePluginLoader.javaClass.name}")
      }
      return result as? List<Map<String?, Any?>> ?: throw ClassCastException("getPlugins returned ${result?.javaClass?.name} instead of List<Map<String,Any?>>")
    } catch (e: Exception) {
      throw IllegalStateException("Failed to invoke getPlugins on nativePluginLoader: ${e.message}", e)
    }
  }

  /**
   * Calls the script-provided `dependenciesMetadata` method and returns the metadata map.
   *
   * Like getPlugins, the script method may accept zero or one parameter. We attempt
   * to call it with flutterProjectRoot if possible.
   */
  @Suppress("UNCHECKED_CAST")
  fun getDependenciesMetadata(
    extraProperties: ExtraPropertiesExtension,
    flutterProjectRoot: File
  ): Map<String, Any> {
    val nativePluginLoader = requireNativeLoader(extraProperties)

    try {
      val method = findMethod(nativePluginLoader, "dependenciesMetadata")
      val result = when (method.parameterCount) {
        0 -> method.invoke(nativePluginLoader)
        1 -> method.invoke(nativePluginLoader, flutterProjectRoot)
        else -> throw IllegalStateException("Unexpected parameter count (${method.parameterCount}) for dependenciesMetadata on ${nativePluginLoader.javaClass.name}")
      }
      return result as? Map<String, Any> ?: throw ClassCastException("dependenciesMetadata returned ${result?.javaClass?.name} instead of Map<String,Any>")
    } catch (e: Exception) {
      throw IllegalStateException("Failed to invoke dependenciesMetadata on nativePluginLoader: ${e.message}", e)
    }
  }
}

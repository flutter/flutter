// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.plugins

import com.android.builder.model.BuildType
import com.flutter.gradle.FlutterExtension
import com.flutter.gradle.FlutterPluginUtils
import com.flutter.gradle.FlutterPluginUtils.addApiDependencies
import com.flutter.gradle.FlutterPluginUtils.buildModeFor
import com.flutter.gradle.FlutterPluginUtils.getAndroidExtension
import com.flutter.gradle.FlutterPluginUtils.getCompileSdkFromProject
import com.flutter.gradle.FlutterPluginUtils.isBuiltAsApp
import com.flutter.gradle.FlutterPluginUtils.supportsBuildMode
import com.flutter.gradle.NativePluginLoaderReflectionBridge
import org.gradle.api.NamedDomainObjectContainer
import org.gradle.api.Project
import org.jetbrains.kotlin.gradle.plugin.extraProperties
import java.io.File
import com.android.build.gradle.internal.dsl.BuildType as dslBuildType

/**
 * Handles interactions with the flutter plugins (not Gradle plugins) used by the Flutter project,
 * such as retrieving them as a list and configuring them as Gradle dependencies of the main Gradle
 * project.
 */
class PluginHandler(
    val project: Project
) {
    private var pluginList: List<Map<String?, Any?>>? = null
    private var pluginDependencies: List<Map<String?, Any?>>? = null

    /**
     * Gets the list of plugins (as map) that support the Android platform.
     *
     * The map contains the following key - value pairs:
     *  `name` - the plugins name (String),
     *  `path` - it's path (String),
     *  `dependencies` - a list of its dependencies names (List<String>)
     *  `dev_dependency` - a boolean indicating whether the plugin is a dev dependency (Boolean)
     *  `native_build` - a boolean indicating whether the plugin has native code (Boolean)
     *
     * This format is defined in packages/flutter_tools/lib/src/flutter_plugins.dart, in the
     * _createPluginMapOfPlatform method.
     * See also [NativePluginLoader#getPlugins] in packages/flutter_tools/gradle/src/main/scripts/native_plugin_loader.gradle.kts
     */
    internal fun getPluginList(): List<Map<String?, Any?>> {
        if (pluginList == null) {
            pluginList =
                NativePluginLoaderReflectionBridge.getPlugins(
                    project.extraProperties,
                    FlutterPluginUtils.getFlutterSourceDirectory(project)
                )
        }
        return pluginList!!
    }

    // TODO(54566, 48918): Remove in favor of [getPluginList] only, see also
    //  https://github.com/flutter/flutter/blob/1c90ed8b64d9ed8ce2431afad8bc6e6d9acc4556/packages/flutter_tools/lib/src/flutter_plugins.dart#L212

    /** Gets the plugins dependencies from `.flutter-plugins-dependencies`. */
    private fun getPluginDependencies(): List<Map<String?, Any?>> {
        if (pluginDependencies == null) {
            val meta: Map<String, Any> =
                NativePluginLoaderReflectionBridge.getDependenciesMetadata(
                    project.extraProperties,
                    FlutterPluginUtils.getFlutterSourceDirectory(project)
                )
            check(meta["dependencyGraph"] is List<*>)
            @Suppress("UNCHECKED_CAST")
            pluginDependencies = meta["dependencyGraph"] as List<Map<String?, Any?>>
        }
        return pluginDependencies!!
    }

    internal fun configurePlugins(engineVersionValue: String) {
        val pluginList: List<Map<String?, Any?>> = getPluginList()
        pluginList.forEach { plugin: Map<String?, Any?> ->
            configurePluginProject(
                project,
                plugin,
                engineVersionValue
            )
        }
        pluginList.forEach { plugin: Map<String?, Any?> ->
            configurePluginDependencies(project, plugin)
        }
    }

    /**
     * Gets the list of plugins (as map) that support the Android platform and are dependencies of the
     * Android project excluding dev dependencies.
     *
     * The map value contains either the plugins `name` (String),
     * its `path` (String), or its `dependencies` (List<String>).
     * See [NativePluginLoader#getPlugins] in packages/flutter_tools/gradle/src/main/scripts/native_plugin_loader.gradle.kts
     */
    internal fun getPluginListWithoutDevDependencies(): List<Map<String?, Any?>> =
        getPluginList().filter { pluginObject -> pluginObject["dev_dependency"] == false }

    companion object {
        /**
         * Flutter Docs Website URLs for help messages.
         */
        private const val WEBSITE_DEPLOYMENT_ANDROID_BUILD_CONFIG = "https://flutter.dev/to/review-gradle-config"

        /**
         * Performs configuration related to the plugin's Gradle [Project], including
         * 1. Adding the plugin itself as a dependency to the main project.
         * 2. Adding the main project's build types to the plugin's build types.
         * 3. Adding a dependency on the Flutter embedding to the plugin.
         *
         * Should only be called on plugins that support the Android platform.
         */
        private fun configurePluginProject(
            project: Project,
            pluginObject: Map<String?, Any?>,
            engineVersion: String
        ) {
            val pluginName =
                requireNotNull(pluginObject["name"] as? String) { "Plugin name must be a string for plugin object: $pluginObject" }
            val pluginProject: Project = project.rootProject.findProject(":$pluginName") ?: return

            // Apply the "flutter" Gradle extension to plugins so that they can use it's vended
            // compile/target/min sdk values.
            pluginProject.extensions.create("flutter", FlutterExtension::class.java)

            // Add plugin dependency to the app project. We only want to add dependency
            // for dev dependencies in non-release builds.
            project.afterEvaluate {
                getAndroidExtension(project).buildTypes.forEach { buildType ->
                    if (!(pluginObject["dev_dependency"] as Boolean) || buildType.name != "release") {
                        project.dependencies.add("${buildType.name}Api", pluginProject)
                    }
                }
            }

            // Wait until the Android plugin loaded.
            pluginProject.afterEvaluate {
                // Checks if there is a mismatch between the plugin compileSdkVersion and the project compileSdkVersion.
                val projectCompileSdkVersion: String = getCompileSdkFromProject(project)
                val pluginCompileSdkVersion: String = getCompileSdkFromProject(pluginProject)
                // TODO(gmackall): This is doing a string comparison, which is odd and also can be wrong
                //                 when comparing preview versions (against non preview, and also in the
                //                 case of alphabet reset which happened with "Baklava".
                if (pluginCompileSdkVersion > projectCompileSdkVersion) {
                    project.logger.quiet(
                        "Warning: The plugin $pluginName requires Android SDK version $pluginCompileSdkVersion or higher."
                    )
                    project.logger.quiet(
                        "For more information about build configuration, see ${WEBSITE_DEPLOYMENT_ANDROID_BUILD_CONFIG}."
                    )
                }

                getAndroidExtension(project).buildTypes.forEach { buildType ->
                    addEmbeddingDependencyToPlugin(project, pluginProject, buildType, engineVersion)
                }
            }
        }

        private fun addEmbeddingDependencyToPlugin(
            project: Project,
            pluginProject: Project,
            buildType: BuildType,
            engineVersion: String
        ) {
            val flutterBuildMode: String = buildModeFor(buildType)
            // TODO(gmackall): this should be safe to remove, as the minimum required AGP is well above
            //                 3.5. We should try to remove it.
            // In AGP 3.5, the embedding must be added as an API implementation,
            // so java8 features are desugared against the runtime classpath.
            // For more, see https://github.com/flutter/flutter/issues/40126
            if (!supportsBuildMode(pluginProject, flutterBuildMode)) {
                return
            }
            if (!pluginProject.hasProperty("android")) {
                return
            }

            // Copy build types from the app to the plugin.
            // This allows to build apps with plugins and custom build types or flavors.
            // However, only copy if the plugin is also an app project, since library projects
            // cannot have applicationIdSuffix and other app-specific properties.
            if (isBuiltAsApp(pluginProject)) {
                (getAndroidExtension(pluginProject).buildTypes as NamedDomainObjectContainer<dslBuildType>)
                    .addAll(getAndroidExtension(project).buildTypes as NamedDomainObjectContainer<dslBuildType>)
            } else {
                // For library projects, create compatible build types without app-specific properties
                getAndroidExtension(project).buildTypes.forEach { appBuildType ->
                    if (getAndroidExtension(pluginProject).buildTypes.findByName(appBuildType.name) == null) {
                        getAndroidExtension(pluginProject).buildTypes.create(appBuildType.name) {
                            // Copy library-compatible properties only
                            isDebuggable = appBuildType.isDebuggable
                            isMinifyEnabled = appBuildType.isMinifyEnabled
                            // Note: applicationIdSuffix and other app-specific properties are intentionally not copied
                        }
                    }
                }
            }

            // The embedding is API dependency of the plugin, so the AGP is able to desugar
            // default method implementations when the interface is implemented by a plugin.
            //
            // See https://issuetracker.google.com/139821726, and
            // https://github.com/flutter/flutter/issues/72185 for more details.
            addApiDependencies(pluginProject, buildType.name, "io.flutter:flutter_embedding_$flutterBuildMode:$engineVersion")
        }

        /**
         * Returns `true` if the given project is a plugin project having an `android` directory
         * containing a `build.gradle` or `build.gradle.kts` file.
         */
        internal fun pluginSupportsAndroidPlatform(project: Project): Boolean {
            val buildGradle = File(File(project.projectDir.parentFile, "android"), "build.gradle")
            val buildGradleKts =
                File(File(project.projectDir.parentFile, "android"), "build.gradle.kts")
            return buildGradle.exists() || buildGradleKts.exists()
        }

        /**
         * Add the dependencies on other plugin projects to the plugin project.
         * A plugin A can depend on plugin B. As a result, this dependency must be surfaced by
         * making the Gradle plugin project A depend on the Gradle plugin project B.
         */
        private fun configurePluginDependencies(
            project: Project,
            pluginObject: Map<String?, Any?>
        ) {
            val pluginName: String =
                requireNotNull(pluginObject["name"] as? String) {
                    "Missing valid \"name\" property for plugin object: $pluginObject"
                }
            val pluginProject: Project = project.rootProject.findProject(":$pluginName") ?: return

            getAndroidExtension(project).buildTypes.forEach { buildType ->
                val flutterBuildMode: String = buildModeFor(buildType)
                if (flutterBuildMode == "release" && (pluginObject["dev_dependency"] as? Boolean == true)) {
                    // This plugin is a dev dependency will not be included in the
                    // release build, so no need to add its dependencies.
                    return@forEach
                }
                val dependencies = requireNotNull(pluginObject["dependencies"] as? List<*>)
                dependencies.forEach innerForEach@{ pluginDependencyName ->
                    check(pluginDependencyName is String)
                    if (pluginDependencyName.isEmpty()) {
                        return@innerForEach
                    }

                    val dependencyProject =
                        project.rootProject.findProject(":$pluginDependencyName") ?: return@innerForEach
                    pluginProject.afterEvaluate {
                        // this.dependencies.add("implementation", dependencyProject)
                        pluginProject.dependencies.add("implementation", dependencyProject)
                    }
                }
            }
        }
    }
}

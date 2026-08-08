// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import org.gradle.api.Plugin
import org.gradle.api.Project

/**
 * The Flutter Plugin Gradle Plugin (FPGP) applied by Flutter plugins
 * that have migrated to use composite builds.
 *
 * Unlike the legacy model - where the app reaches across projects to configure each plugin
 * subproject - a migrated plugin is a standalone Gradle build that configures *itself*:
 *  1. Vends the `flutter` extension (compile/target/min sdk values).
 *  2. Adds the Flutter engine Maven repository.
 *  3. Recreates the Flutter `profile` build type so the plugin publishes a variant an app building
 *     in profile mode can resolve across the composite-build boundary.
 *  4. Adds the Flutter embedding as an API dependency of each build type.
 */
class FlutterPluginGradlePlugin : Plugin<Project> {
    override fun apply(project: Project) {
        project.logger.info("Applying FlutterPluginGradlePlugin to project ${project.name}")

        // Apply the "flutter" Gradle extension to plugins so that they can use its vended
        // compile/target/min sdk values.
        project.extensions.create("flutter", FlutterExtension::class.java)

        val flutterRoot = FlutterPluginUtils.resolveFlutterRoot(project)
        if (flutterRoot == null) {
            project.logger.error(
                "Flutter SDK root not found. Set the FLUTTER_ROOT environment variable, the " +
                    "flutter.sdk Gradle property, or flutter.sdk in local.properties."
            )
            return
        }

        // Add the Flutter engine repository for resolving embedding dependencies. Shared with
        // FlutterPlugin so the realm / FLUTTER_STORAGE_BASE_URL / local engine are all honored.
        FlutterPluginUtils.addFlutterEngineMavenRepository(project, flutterRoot)

        val engineVersion: String = FlutterPluginUtils.getFlutterEngineVersion(project, flutterRoot)

        // Recreating the Flutter `profile` build type requires touching AGP's extension. In the
        // legacy subproject model the app copied its build types (including `profile`) into each
        // plugin; composite builds cannot, so the plugin must own a matching variant or an app
        // building in profile mode silently falls back to the release variant (which links the
        // wrong - release - embedding and collides on the classpath).
        //
        // Touching the Android extension is the one thing that may fail if AGP is loaded in an
        // isolated classloader for this included build (the original prototype avoided it for that
        // reason). So attempt it defensively: if it works we get a real profile variant and wire
        // every build type by mode; if it throws we fall back to the original classloader-safe
        // debug/release-by-name wiring, never regressing below the prototype's behavior.
        //
        // The profile build type must be registered synchronously here (before AGP locks the DSL
        // and creates variants); the embedding dependencies are added in afterEvaluate once the
        // per-build-type `*Api` configurations exist.
        val androidExtension =
            try {
                FlutterPluginUtils.getLegacyAndroidExtension(project)
            } catch (e: Throwable) {
                project.logger.warn(
                    "FlutterPluginGradlePlugin: could not access the Android extension for " +
                        "project ${project.name} ($e). Falling back to debug/release embedding " +
                        "wiring; profile builds of apps depending on this plugin may not resolve."
                )
                null
            }

        if (androidExtension != null) {
            if (androidExtension.buildTypes.findByName("profile") == null) {
                val debugBuildType = androidExtension.buildTypes.getByName("debug")
                androidExtension.buildTypes.create("profile") {
                    // Library-compatible subset only, matching the legacy library-plugin behavior
                    // (app-specific properties such as applicationIdSuffix are intentionally omitted).
                    isDebuggable = debugBuildType.isDebuggable
                    isMinifyEnabled = debugBuildType.isMinifyEnabled
                }
            }
            project.afterEvaluate {
                androidExtension.buildTypes.forEach { buildType ->
                    addEmbeddingDependency(project, "${buildType.name}Api", FlutterPluginUtils.buildModeFor(buildType), engineVersion)
                }
            }
        } else {
            project.afterEvaluate {
                addEmbeddingDependency(project, "debugApi", "debug", engineVersion)
                addEmbeddingDependency(project, "releaseApi", "release", engineVersion)
            }
        }
    }

    private fun addEmbeddingDependency(
        project: Project,
        configurationName: String,
        flutterBuildMode: String,
        engineVersion: String
    ) {
        if (project.configurations.findByName(configurationName) == null) {
            return
        }
        val dependency = "io.flutter:flutter_embedding_$flutterBuildMode:$engineVersion"
        project.dependencies.add(configurationName, dependency)
        project.logger.info("Added dependency $dependency to configuration $configurationName")
    }
}

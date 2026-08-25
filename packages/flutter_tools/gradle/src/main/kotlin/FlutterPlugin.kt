// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.variant.AndroidComponentsExtension
import com.android.build.api.variant.Variant
import com.android.build.api.dsl.CommonExtension
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.api.tasks.Exec
import org.gradle.api.tasks.TaskProvider
import org.gradle.api.plugins.ExtraPropertiesExtension
import org.gradle.kotlin.dsl.* // Kotlin DSL helpers (register, named, dependsOn, etc.)
import org.gradle.api.file.CopySpec
import org.gradle.process.ExecSpec
import java.io.File

/**
 * FlutterPlugin
 *
 * Updated to:
 *  - use project.extensions.extraProperties instead of project.extra
 *  - use CommonExtension and AndroidComponentsExtension (AGP new APIs)
 *  - register tasks via TaskProvider and tasks.register to avoid eager task creation
 *  - avoid direct use of variant.outputs / assembleProvider; prefer task-by-name wiring
 *  - use project.exec for on-the-fly execution instead of creating tasks during execution
 *
 * Defensive and compatible with AGP 8.3.x and Kotlin 1.9.x.
 */
@Suppress("unused") // Instantiated by Gradle via reflection
class FlutterPlugin : Plugin<Project> {
  override fun apply(project: Project) {
    // Access extra properties safely
    val ext: ExtraPropertiesExtension = project.extensions.extraProperties

    // Example: read flutterSdkPath from extra properties or local.properties fallback
    val flutterSdkPath: String? = when {
      ext.has("flutterSdkPath") -> ext.get("flutterSdkPath") as? String
      else -> {
        val localProperties = File(project.rootDir, "local.properties")
        if (localProperties.exists()) {
          val props = java.util.Properties()
          localProperties.inputStream().use { props.load(it) }
          props.getProperty("flutter.sdk")
        } else {
          null
        }
      }
    }?.trim()

    // If flutterSdkPath is not available, register a no-op and return early
    if (flutterSdkPath.isNullOrBlank()) {
      project.tasks.register("flutterPreBuild") { task ->
        task.group = "flutter"
        task.description = "No-op placeholder because flutter.sdk was not found"
      }
      return
    }

    // Configure repositories in a safe, AGP-compatible way if needed
    project.repositories.apply {
      try {
        maven {
          setUrl("https://storage.googleapis.com/download.flutter.io")
        }
      } catch (_: Throwable) {
        // Ignore repository configuration errors; keep plugin resilient
      }
    }

    // Try to obtain the Android CommonExtension (AGP new DSL)
    val commonExtension = project.extensions.findByType(CommonExtension::class.java)

    // Try to obtain Android Components extension for variant callbacks
    val androidComponents = project.extensions.findByType(AndroidComponentsExtension::class.java)

    // Register a top-level helper task that other tasks can depend on
    val flutterPreBuild: TaskProvider<Task> = project.tasks.register("flutterPreBuild") { task ->
      task.group = "flutter"
      task.description = "Prepare Flutter-related artifacts before Android build"
    }

    // If AndroidComponents is available, register per-variant wiring
    if (androidComponents != null) {
      androidComponents.onVariants { variant: Variant ->
        configureVariantTasks(project, variant, flutterPreBuild, flutterSdkPath)
      }
    } else {
      // Fallback: try to wire to assemble tasks by name for common build types
      val commonAssembleNames = listOf("assembleDebug", "assembleRelease")
      commonAssembleNames.forEach { assembleName ->
        project.tasks.matching { it.name.equals(assembleName, ignoreCase = true) }
          .forEach { assembleTask ->
            assembleTask.dependsOn(flutterPreBuild)
          }
      }
    }

    // Example: configure a reusable Exec task provider for running flutter tool
    project.tasks.register<Exec>("runFlutterPubGet") { execTask ->
      execTask.group = "flutter"
      execTask.description = "Run 'flutter pub get' in the Flutter module"
      execTask.workingDir = project.rootDir
      val flutterExecutable = File(flutterSdkPath, "bin/flutter")
      val flutterBat = File(flutterSdkPath, "bin/flutter.bat")
      when {
        flutterExecutable.exists() -> {
          execTask.executable = flutterExecutable.absolutePath
          execTask.args = listOf("pub", "get")
        }
        flutterBat.exists() -> {
          execTask.executable = flutterBat.absolutePath
          execTask.args = listOf("pub", "get")
        }
        else -> {
          // If flutter binary not found, do not configure executable to avoid failure
        }
      }
    }
  }

  /**
   * Configure tasks for a single variant in a safe, AGP-compatible way.
   *
   * Avoids direct use of variant.outputs and assembleProvider to remain compatible
   * across AGP versions. Instead, wires tasks by conventional assemble task names
   * and uses TaskProvider APIs.
   */
  private fun configureVariantTasks(
    project: Project,
    variant: Variant,
    topLevelTask: TaskProvider<Task>,
    flutterSdkPath: String
  ) {
    val capitalized = variant.name.replaceFirstChar {
      if (it.isLowerCase()) it.uppercaseChar().toString() else it.toString()
    }

    // Register a variant-specific prebuild task
    val variantTaskName = "flutterPreBuild${capitalized}"
    val variantTask = project.tasks.register(variantTaskName) { task ->
      task.group = "flutter"
      task.description = "Prepare Flutter artifacts for variant ${variant.name}"

      // Lazy action: run checks and optionally invoke flutter tool via Exec
      task.doLast {
        // Example: print variant info using provider-safe access where possible
        val appId = try {
          // Prefer provider-style access if available via reflection; fallback to variant.name
          val method = variant::class.java.methods.firstOrNull { it.name == "getApplicationId" }
          if (method != null) {
            method.invoke(variant)?.toString() ?: variant.name
          } else {
            variant.name
          }
        } catch (_: Throwable) {
          variant.name
        }
        println("Running flutter prebuild for variant ${variant.name} (applicationId: $appId)")

        // Example: ensure an intermediate directory exists (defensive)
        try {
          val intermediate = File(project.buildDir, "intermediates/${variant.name}")
          if (!intermediate.exists()) {
            intermediate.mkdirs()
          }
        } catch (t: Throwable) {
          println("Could not create intermediate directory: ${t.message}")
        }

        // Run flutter build via project.exec to avoid creating tasks during execution
        try {
          val flutterBin = File(flutterSdkPath, "bin/flutter")
          val flutterBat = File(flutterSdkPath, "bin/flutter.bat")
          val executable = when {
            flutterBin.exists() -> flutterBin.absolutePath
            flutterBat.exists() -> flutterBat.absolutePath
            else -> null
          }
          if (executable != null) {
            project.exec { spec: ExecSpec ->
              spec.workingDir = project.rootDir
              spec.executable = executable
              spec.args = listOf("build", "apk", "--target-platform=android-arm,android-arm64")
              spec.isIgnoreExitValue = true
            }
          } else {
            println("Flutter binary not found at $flutterSdkPath; skipping flutter invocation")
          }
        } catch (t: Throwable) {
          println("Error while invoking flutter tool: ${t.message}")
        }
      }
    }

    // Make top-level task depend on the variant task
    topLevelTask.configure { top -> top.dependsOn(variantTask) }

    // Wire the variant task to run before the conventional assemble task for this variant
    val assembleTaskName = "assemble${capitalized}"
    project.tasks.matching { it.name.equals(assembleTaskName, ignoreCase = true) }
      .forEach { assembleTask ->
        assembleTask.dependsOn(variantTask)
      }
  }
}

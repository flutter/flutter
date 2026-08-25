package com.flutter.gradle

import com.android.build.api.variant.AndroidComponentsExtension
import com.android.build.api.variant.Variant
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.api.tasks.TaskProvider
import org.gradle.api.plugins.ExtraPropertiesExtension
import org.gradle.kotlin.dsl.* // brings Kotlin-DSL helpers (dependsOn, named, register, etc.) into scope
import java.io.File

/**
 * DependencyVersionChecker
 *
 * Uses:
 *  - project.extensions.extraProperties instead of project.extra
 *  - Android Components API (AndroidComponentsExtension.onVariants)
 *  - TaskProvider / tasks.register to avoid eager task creation
 *  - Provider-friendly access patterns (avoid direct Variant.outputs / assembleProvider usage)
 *
 * Defensive and compatible with AGP 8.3.x and Kotlin 1.9.x.
 */
class DependencyVersionChecker : Plugin<Project> {
  override fun apply(project: Project) {
    // Access extra properties safely
    val ext: ExtraPropertiesExtension = project.extensions.extraProperties

    // Read a toggle property if present (safe lookup)
    val enabled = if (ext.has("flutterDependencyVersionCheckEnabled")) {
      (ext.get("flutterDependencyVersionCheckEnabled") as? Boolean) ?: true
    } else {
      true
    }

    if (!enabled) {
      // Register a no-op task so scripts that expect the task won't fail.
      project.tasks.register("checkDependencyVersions") { task ->
        task.group = "verification"
        task.description = "Dependency version check disabled via extra property"
      }
      return
    }

    // Try to find the Android Components extension (AGP new API)
    val androidComponents = project.extensions.findByType(AndroidComponentsExtension::class.java)

    if (androidComponents == null) {
      // Not an Android project or AGP not available; register a no-op task for consistency
      project.tasks.register("checkDependencyVersions") { task ->
        task.group = "verification"
        task.description = "No-op dependency version check (AndroidComponents not found)"
      }
      return
    }

    // Top-level task that aggregates variant checks
    val topLevelCheck: TaskProvider<Task> = project.tasks.register("checkDependencyVersions") { task ->
      task.group = "verification"
      task.description = "Check dependency versions for all variants"
    }

    // For each variant, register a variant-specific check task using Android Components API
    androidComponents.onVariants { variant: Variant ->
      registerVariantCheckTask(project, variant, topLevelCheck)
    }
  }

  /**
   * Register a variant-specific check task.
   *
   * Uses TaskProvider APIs and avoids direct use of variant.outputs / assembleProvider.
   */
  private fun registerVariantCheckTask(
    project: Project,
    variant: Variant,
    topLevelCheck: TaskProvider<Task>
  ) {
    // Build a safe, normalized task name (e.g., checkDependencyVersionsRelease)
    val capitalized = variant.name.replaceFirstChar {
      if (it.isLowerCase()) it.uppercaseChar().toString() else it.toString()
    }
    val taskName = "checkDependencyVersions${capitalized}"

    // Register the task as a TaskProvider to avoid eager task creation
    val checkTask = project.tasks.register(taskName) { task ->
      task.group = "verification"
      task.description = "Check dependency versions for variant ${variant.name}"

      // Configure the action lazily
      task.doLast {
        // 1) Check for missing dependency versions in the 'implementation' configuration
        try {
          val configuration = project.configurations.findByName("implementation")
          if (configuration != null) {
            val mismatches = mutableListOf<String>()
            configuration.dependencies.forEach { dep ->
              val group = dep.group ?: "<no-group>"
              val name = dep.name ?: "<no-name>"
              val version = dep.version ?: "<no-version>"
              if (dep.version == null || dep.version!!.isBlank()) {
                mismatches.add("$group:$name has no version specified")
              }
            }
            if (mismatches.isNotEmpty()) {
              println("Dependency version issues for variant ${variant.name}:")
              mismatches.forEach { println("  - $it") }
              // Optionally fail the build by throwing an exception:
              // throw GradleException("Dependency version mismatches found")
            } else {
              println("Dependency version check passed for variant ${variant.name}")
            }
          } else {
            println("No 'implementation' configuration found for project ${project.path}; skipping dependency checks for variant ${variant.name}")
          }
        } catch (t: Throwable) {
          println("Error while checking dependencies for variant ${variant.name}: ${t.message}")
          // Do not fail the entire build here unless you want to enforce strict checks.
        }

        // 2) Defensive check: existence of an intermediate directory
        try {
          val buildDir = project.buildDir
          val intermediate = File(buildDir, "intermediates/${variant.name}")
          if (!intermediate.exists()) {
            println("Note: intermediate directory does not exist for variant ${variant.name}: ${intermediate.path}")
          }
        } catch (t: Throwable) {
          println("Error while checking intermediate directories: ${t.message}")
        }
      }
    }

    // Wire the variant-specific task into the top-level check task
    topLevelCheck.configure { topTask -> topTask.dependsOn(checkTask) }

    // If an assemble task exists for this variant, prefer to run checks before assemble.
    // Use findByName to avoid accidental task realization or exceptions.
    val assembleTaskName = "assemble${capitalized}"
    val assembleTask = project.tasks.findByName(assembleTaskName)
    if (assembleTask != null) {
      // Configure the assemble task to depend on the check task
      project.tasks.named(assembleTaskName).configure { asm -> asm.dependsOn(checkTask) }
    }
  }
}

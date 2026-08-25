package com.flutter.gradle

import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.api.tasks.Exec
import org.gradle.api.tasks.TaskProvider
import org.gradle.api.logging.Logger
import org.gradle.api.plugins.PluginContainer
import org.gradle.api.plugins.PluginManager
import org.gradle.api.artifacts.Configuration
import org.gradle.api.plugins.ExtraPropertiesExtension
import org.gradle.api.provider.Provider
import org.gradle.process.ExecSpec
import java.io.File
import java.util.Properties

/**
 * Utility helpers used by the Flutter Gradle plugin code.
 *
 * This file is intentionally conservative and defensive:
 *  - Uses project.logger and project.pluginManager instead of relying on Kotlin DSL helpers.
 *  - Uses project.tasks.register and TaskProvider to avoid eager task realization.
 *  - Uses project.exec for running external commands instead of serviceOf/legacy APIs.
 *  - Avoids direct assumptions about AGP internals; callers should use AndroidComponentsExtension where possible.
 */

/** Safely get the project's logger. */
fun Project.flutterLogger(): Logger = this.logger

/** Safely get the project's plugin manager. */
fun Project.flutterPluginManager(): PluginManager = this.pluginManager

/** Safely get the project's plugin container (alias to pluginManager for callers that expect PluginContainer). */
fun Project.flutterPluginContainer(): PluginContainer = this.pluginManager as PluginContainer

/** Safely get the project's root directory. */
fun Project.flutterProjectDir(): File = this.projectDir

/** Read local.properties from the project root (if present) and return as Properties. */
fun Project.loadLocalProperties(): Properties {
  val props = Properties()
  val localPropsFile = File(this.rootDir, "local.properties")
  if (localPropsFile.exists()) {
    localPropsFile.inputStream().use { props.load(it) }
  }
  return props
}

/**
 * Register a task if it does not already exist.
 *
 * Example:
 *   registerTaskIfAbsent("flutterPreBuild") { group = "flutter"; description = "..." }
 */
fun Project.registerTaskIfAbsent(name: String, configure: (Task) -> Unit): TaskProvider<Task> {
  val existing = this.tasks.findByName(name)
  return if (existing != null) {
    // Wrap existing task in a TaskProvider-like object via named
    this.tasks.named(name)
  } else {
    this.tasks.register(name) { task ->
      configure(task)
    }
  }
}

/**
 * Run an external command using project.exec in a defensive way.
 *
 * Returns the exit value (0 indicates success). Exceptions are caught and logged.
 */
fun Project.runCommand(
  workingDir: File = this.rootDir,
  executable: String,
  args: List<String> = emptyList(),
  ignoreExitValue: Boolean = false
): Int {
  return try {
    val result = this.exec { spec: ExecSpec ->
      spec.workingDir = workingDir
      spec.executable = executable
      if (args.isNotEmpty()) {
        spec.args = args
      }
      spec.isIgnoreExitValue = ignoreExitValue
    }
    result.exitValue
  } catch (t: Throwable) {
    this.logger.warn("Error running command $executable ${args.joinToString(" ")}: ${t.message}")
    if (ignoreExitValue) {
      -1
    } else {
      throw t
    }
  }
}

/**
 * Create or register an Exec task to run a command. Returns the TaskProvider<Exec>.
 *
 * If a task with the same name already exists, returns the named provider.
 */
fun Project.registerExecTaskIfAbsent(
  taskName: String,
  workingDir: File = this.rootDir,
  executable: String,
  args: List<String> = emptyList(),
  ignoreExitValue: Boolean = true
): TaskProvider<Exec> {
  val existing = this.tasks.findByName(taskName)
  return if (existing != null) {
    @Suppress("UNCHECKED_CAST")
    this.tasks.named(taskName) as TaskProvider<Exec>
  } else {
    this.tasks.register(taskName, Exec::class.java) { execTask ->
      execTask.group = "flutter"
      execTask.description = "Exec task $taskName"
      execTask.workingDir = workingDir
      execTask.executable = executable
      execTask.args = args
      execTask.isIgnoreExitValue = ignoreExitValue
    }
  }
}

/**
 * Safely add a dependency between tasks using TaskProvider to avoid eager realization.
 *
 * Example:
 *   topLevelTask.dependsOnVariantTask(variantTaskProvider)
 */
fun TaskProvider<out Task>.dependsOnTaskProvider(other: TaskProvider<out Task>) {
  this.configure { it.dependsOn(other) }
}

/**
 * Safely add a dependency from a concrete task name to a TaskProvider.
 *
 * If the named task exists, configure it to depend on the provider.
 */
fun Project.configureNamedTaskDependsOn(namedTaskName: String, dependency: TaskProvider<out Task>) {
  val namedTask = this.tasks.findByName(namedTaskName)
  if (namedTask != null) {
    this.tasks.named(namedTaskName).configure { it.dependsOn(dependency) }
  }
}

/**
 * Helper to read a string extra property from project.extensions.extraProperties.
 * Returns null if not present or not a string.
 */
fun Project.getExtraString(name: String): String? {
  val ext: ExtraPropertiesExtension = this.extensions.extraProperties
  return if (ext.has(name)) {
    ext.get(name) as? String
  } else {
    null
  }
}

/**
 * Helper to set an extra property on the project.
 */
fun Project.setExtraProperty(name: String, value: Any?) {
  val ext: ExtraPropertiesExtension = this.extensions.extraProperties
  ext.set(name, value)
}

/**
 * Safely get a configuration by name. Returns null if not present.
 */
fun Project.findConfiguration(name: String): Configuration? = try {
  this.configurations.findByName(name)
} catch (_: Throwable) {
  null
}

/**
 * Utility to check whether a plugin is applied to the project.
 */
fun Project.isPluginApplied(pluginId: String): Boolean = try {
  this.pluginManager.hasPlugin(pluginId)
} catch (_: Throwable) {
  false
}

/**
 * Read compileSdk and ndkVersion from a project's Android extension if available.
 *
 * This function is intentionally defensive: it uses reflection to attempt to read
 * common properties from AGP's DSL without hard failing if the properties are absent.
 *
 * Returns a Pair(compileSdkVersionString?, ndkVersionString?)
 */
fun Project.readAndroidSdkAndNdkVersions(): Pair<String?, String?> {
  try {
    val androidExt = this.extensions.findByName("android") ?: return Pair(null, null)
    val androidClass = androidExt::class.java

    // Try common property names used by AGP DSL
    val compileSdk = try {
      // Some AGP versions expose compileSdk as an Int or String
      val method = androidClass.methods.firstOrNull { it.name == "getCompileSdk" || it.name == "getCompileSdkVersion" }
      val value = method?.invoke(androidExt)
      value?.toString()
    } catch (_: Throwable) {
      null
    }

    val ndkVersion = try {
      val method = androidClass.methods.firstOrNull { it.name == "getNdkVersion" }
      val value = method?.invoke(androidExt)
      value?.toString()
    } catch (_: Throwable) {
      null
    }

    return Pair(compileSdk, ndkVersion)
  } catch (_: Throwable) {
    return Pair(null, null)
  }
}

/**
 * Helper to safely print a message to the project's logger at lifecycle level.
 */
fun Project.logLifecycle(message: String) {
  try {
    this.logger.lifecycle(message)
  } catch (_: Throwable) {
    // ignore logging failures
  }
}

/**
 * Helper to safely print a warning to the project's logger.
 */
fun Project.logWarn(message: String) {
  try {
    this.logger.warn(message)
  } catch (_: Throwable) {
    // ignore logging failures
  }
}

/**
 * Helper to safely print an info message to the project's logger.
 */
fun Project.logInfo(message: String) {
  try {
    this.logger.info(message)
  } catch (_: Throwable) {
    // ignore logging failures
  }
}

/**
 * Safely create a directory if it does not exist.
 */
fun File.ensureExists(): Boolean {
  return try {
    if (!this.exists()) {
      this.mkdirs()
    } else {
      true
    }
  } catch (_: Throwable) {
    false
  }
}

/**
 * Utility: attempt to resolve the Flutter SDK path from extra properties or local.properties.
 *
 * Returns null if not found.
 */
fun Project.resolveFlutterSdkPath(): String? {
  // 1) Try extra properties
  val ext: ExtraPropertiesExtension = this.extensions.extraProperties
  if (ext.has("flutterSdkPath")) {
    val value = ext.get("flutterSdkPath") as? String
    if (!value.isNullOrBlank()) {
      return value.trim()
    }
  }

  // 2) Try local.properties in project root
  val props = loadLocalProperties()
  val sdk = props.getProperty("flutter.sdk")?.trim()
  if (!sdk.isNullOrBlank()) {
    return sdk
  }

  return null
}

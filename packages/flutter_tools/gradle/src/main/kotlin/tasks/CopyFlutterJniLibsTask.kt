package com.flutter.gradle.tasks

import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.file.CopySpec
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.InputDirectory
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.TaskAction
import org.gradle.kotlin.dsl.*
import java.io.File

/**
 * Copies native libraries (.so) from a Flutter module's build outputs into the Android project's
 * jniLibs destination. This implementation is defensive and avoids relying on Kotlin-DSL
 * extension inference by using explicitly typed lambdas where necessary.
 *
 * Configure the task in build scripts by setting [flutterModuleDir] and [destinationDir].
 */
abstract class CopyFlutterJniLibsTask : DefaultTask() {

  /**
   * Directory that contains the Flutter module (root of the Flutter project).
   * The task will look for native libs under common Flutter output locations.
   */
  @get:InputDirectory
  abstract val flutterModuleDir: DirectoryProperty

  /**
   * Destination directory where native libs should be copied (typically
   * src/main/jniLibs in the Android project).
   */
  @get:OutputDirectory
  abstract val destinationDir: DirectoryProperty

  init {
    group = "flutter"
    description = "Copy Flutter-generated native libraries into the Android project's jniLibs"
  }

  @TaskAction
  fun copyJniLibs() {
    val flutterDirFile: File = try {
      flutterModuleDir.asFile.get()
    } catch (t: Throwable) {
      throw GradleException("flutterModuleDir is not configured or not available", t)
    }

    val destDirFile: File = try {
      destinationDir.asFile.get()
    } catch (t: Throwable) {
      throw GradleException("destinationDir is not configured or not available", t)
    }

    if (!flutterDirFile.exists() || !flutterDirFile.isDirectory) {
      throw GradleException("Flutter module directory does not exist: ${flutterDirFile.absolutePath}")
    }

    // Common Flutter output locations that may contain native libs.
    // We check several plausible paths to be robust across AGP/Flutter versions.
    val candidatePaths = listOf(
      File(flutterDirFile, "build/flutter_infra/flutter_release"),
      File(flutterDirFile, "build/flutter_assets"),
      File(flutterDirFile, "build/host/outputs/flutter/release"),
      File(flutterDirFile, "build/app/intermediates/flutter/release"),
      File(flutterDirFile, "build/outputs/flutter/release"),
      File(flutterDirFile, "build/flutter/outputs"), // additional fallback
      File(flutterDirFile, "build/outputs") // generic fallback
    )

    // Collect all found lib directories that contain .so files under an 'jniLibs' or 'lib' tree.
    val foundLibRoots = mutableListOf<File>()
    candidatePaths.forEach { candidate ->
      if (candidate.exists()) {
        candidate.walkTopDown().forEach { f ->
          if (f.isDirectory && (f.name.equals("jniLibs", ignoreCase = true) || f.name.equals("lib", ignoreCase = true))) {
            val hasSo = f.walkTopDown().any { it.isFile && it.extension == "so" }
            if (hasSo) {
              foundLibRoots.add(f)
            }
          }
        }
      }
    }

    if (foundLibRoots.isEmpty()) {
      // Nothing to copy; log and exit gracefully.
      logger.lifecycle("No native libraries found in Flutter module at ${flutterDirFile.absolutePath}; skipping CopyFlutterJniLibsTask.")
      return
    }

    // Ensure destination exists
    if (!destDirFile.exists()) {
      if (!destDirFile.mkdirs()) {
        throw GradleException("Failed to create destination directory: ${destDirFile.absolutePath}")
      }
    }

    // Copy each discovered lib root into the destination using an explicitly typed CopySpec lambda.
    foundLibRoots.forEach { libRoot ->
      project.copy { copySpec: CopySpec ->
        copySpec.from(libRoot) { inner: CopySpec ->
          inner.include("**/*.so")
        }
        copySpec.into(destDirFile)
      }
      logger.lifecycle("Copied native libs from ${libRoot.absolutePath} to ${destDirFile.absolutePath}")
    }
  }
}

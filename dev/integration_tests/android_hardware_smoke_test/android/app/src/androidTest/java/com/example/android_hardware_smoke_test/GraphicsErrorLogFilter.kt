// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@file:Suppress("PackageName")

package com.example.android_hardware_smoke_test

/**
 * Filters process logcat lines for fatal, unrecoverable EGL or graphics pipeline errors.
 */
internal object GraphicsErrorLogFilter {
    // Keep in sync with hasFatalEglLogcatError in run_android_hardware_smoke_tests.dart.
    private val FATAL_PATTERNS =
        listOf(
            "EGL_NOT_INITIALIZED",
            "EGL_BAD_ALLOC",
            "EGL_BAD_CONFIG",
            "EGL_BAD_CONTEXT",
            "EGL_BAD_DISPLAY",
            "EGL_BAD_NATIVE_WINDOW",
            "EGL_BAD_SURFACE",
            "EGL_CONTEXT_LOST",
            "Failed to create EGLSurface",
            "Failed to initialize EGL",
            "Unable to initialize EGL",
            "Failed to establish connection with the host",
            "vulkan: Failed to get host connection",
            "Could not create Vulkan instance",
            "Could not create surface from invalid Android context"
        )

    /**
     * Collects fatal graphics pipeline error lines emitted at or after [marker].
     */
    fun extractErrorsAfterMarker(
        lines: Sequence<String>,
        marker: String
    ): List<String> {
        val errors = mutableListOf<String>()
        var seenMarker = false
        for (line in lines) {
            if (line.contains(marker)) {
                seenMarker = true
            }
            if (seenMarker && isFatalGraphicsPipelineError(line)) {
                errors.add(line)
            }
        }
        return errors
    }

    /**
     * Returns true if [line] indicates an unrecoverable process-level EGL or Vulkan error, ignoring
     * benign Android HWUI capability-probe warnings and frame-duration warnings on software emulators.
     */
    fun isFatalGraphicsPipelineError(line: String): Boolean {
        // Android HWUI logs EGL_SWAP_BEHAVIOR_PRESERVED and 101010-2 'error = EGL_SUCCESS' probe
        // warnings unconditionally during normal startup on SwiftShader and headless emulators.
        // Match 'error = EGL_SUCCESS' specifically so real libEGL 'eglInitialize(...) failed (EGL_SUCCESS)'
        // failures when the host GPU pipe disconnects are not masked.
        if (line.contains("EGL_SWAP_BEHAVIOR_PRESERVED") || line.contains("error = EGL_SUCCESS")) {
            return false
        }
        if (line.contains("eglInitialize(") && line.contains(") failed (")) {
            return true
        }
        return FATAL_PATTERNS.any { pattern -> line.contains(pattern) }
    }
}

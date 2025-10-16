// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine;

import android.content.Context;
import androidx.annotation.NonNull;
import java.util.*;

/**
 * Arguments that can be delivered to the Flutter shell when it is created via the command line.
 *
 * <p>The term "shell" refers to the native code that adapts Flutter to different platforms.
 * Flutter's Android Java code initializes a native "shell" and passes these arguments to that
 * native shell when it is initialized. See {@link
 * io.flutter.embedding.engine.loader.FlutterLoader#ensureInitializationComplete(Context, String[])}
 * for more information.
 *
 * <p>All of these flags map to flag listed in shell/common/switches.cc. Some of these flags can
 * also be set via manifest metadata in AndroidManifest.xml. See {@link FlutterEngineManifestFlags}
 * for the full list of such available flags.
 */
// @SuppressWarnings({"WeakerAccess", "unused"}) TODO(camsim99): See if we need these
public class FlutterEngineCommandLineFlags {

  public static final String TRACE_STARTUP = "--trace-startup";
  public static final String START_PAUSED = "--start-paused";
  public static final String DISABLE_SERVICE_AUTH_CODES = "--disable-service-auth-codes";
  public static final String ENDLESS_TRACE_BUFFER = "--endless-trace-buffer";
  public static final String ENABLE_DART_PROFILING = "--enable-dart-profiling";
  public static final String PROFILE_STARTUP = "--profile-startup";
  public static final String TRACE_SKIA = "--trace-skia";
  public static final String TRACE_SKIA_ALLOWLIST = "--trace-skia-allowlist=";
  public static final String TRACE_SYSTRACE = "--trace-systrace";
  public static final String TRACE_TO_FILE = "--trace-to-file=";
  public static final String PROFILE_MICROTASKS = "--profile-microtasks";
  public static final String DUMP_SHADER_SKP_ON_SHADER_COMPILATION =
      "--dump-skp-on-shader-compilation";
  public static final String CACHE_SKSL = "--cache-sksl";
  public static final String PURGE_PERSISTENT_CACHE = "--purge-persistent-cache";
  public static final String VERBOSE_LOGGING = "--verbose-logging";
  public static final String DART_FLAGS = "--dart-flags=";

  // Flags also configurable via manifest metadata in AndroidManifest.xml:

  public static final String ENABLE_SOFTWARE_RENDERING = "--enable-software-rendering";
  public static final String SKIA_DETERMINISTIC_RENDERING = "--skia-deterministic-rendering";
  public static final String AOT_SHARED_LIBRARY_NAME = "--aot-shared-library-name=";
  public static final String FLUTTER_ASSETS_DIR = "--flutter-assets-dir=";
  public static final String OLD_GEN_HEAP_SIZE = "--old-gen-heap-size=";
  public static final String ENABLE_IMPELLER = "--enable-impeller=";
  public static final String IMPELLER_BACKEND = "--impeller-backend=";
  public static final String DISABLE_MERGED_PLATFORM_UI_THREAD =
      "--disable-merged-platform-ui-thread";
  public static final String ENABLE_SURFACE_CONTROL = "--enable-surface-control";
  public static final String ENABLE_FLUTTER_GPU = "--enable-flutter-gpu";
  public static final String IMPELLER_LAZY_SHADER_MODE = "--impeller-lazy-shader-mode=";
  public static final String IMPELLER_ANTIALIAS_LINES = "--impeller-antialias-lines";
  public static final String VM_SNAPSHOT_DATA = "--vm-snapshot-data=";
  public static final String ISOLATE_SNAPSHOT_DATA = "--isolate-snapshot-data=";
  public static final String NETWORK_POLICY = "--network-policy=";
  public static final String USE_TEST_FONTS = "--use-test-fonts";
  public static final String VM_SERVICE_PORT = "--vm-service-port=";
  public static final String ENABLE_VULKAN_VALIDATION = "--enable-vulkan-validation";
  public static final String ENABLE_OPENGL_GPU_TRACING = "--enable-opengl-gpu-tracing";
  public static final String ENABLE_VULKAN_GPU_TRACING = "--enable-vulkan-gpu-tracing";

  /**
   * Set whether leave or clean up the VM after the last shell shuts down. It can be set from app's
   * meta-data in the application block in AndroidManifest.xml. Set it to true in to leave the Dart
   * VM, set it to false to destroy VM.
   *
   * <p>If your want to let your app destroy the last shell and re-create shells more quickly, set
   * it to true, otherwise if you want to clean up the memory of the leak VM, set it to false.
   *
   * <p>TODO(eggfly): Should it be set to false by default?
   * https://github.com/flutter/flutter/issues/96843
   */
  public static final String LEAK_VM = "--leak-vm=";

  public static final List<String> ALL_FLAGS =
      Collections.unmodifiableList(
          Arrays.asList(
              TRACE_STARTUP,
              START_PAUSED,
              DISABLE_SERVICE_AUTH_CODES,
              ENDLESS_TRACE_BUFFER,
              ENABLE_DART_PROFILING,
              PROFILE_STARTUP,
              TRACE_SKIA,
              TRACE_SKIA_ALLOWLIST,
              TRACE_SYSTRACE,
              TRACE_TO_FILE,
              PROFILE_MICROTASKS,
              DUMP_SHADER_SKP_ON_SHADER_COMPILATION,
              CACHE_SKSL,
              PURGE_PERSISTENT_CACHE,
              VERBOSE_LOGGING,
              DART_FLAGS,
              ENABLE_SOFTWARE_RENDERING,
              SKIA_DETERMINISTIC_RENDERING,
              AOT_SHARED_LIBRARY_NAME,
              FLUTTER_ASSETS_DIR,
              OLD_GEN_HEAP_SIZE,
              ENABLE_IMPELLER,
              IMPELLER_BACKEND,
              DISABLE_MERGED_PLATFORM_UI_THREAD,
              ENABLE_SURFACE_CONTROL,
              ENABLE_FLUTTER_GPU,
              IMPELLER_LAZY_SHADER_MODE,
              IMPELLER_ANTIALIAS_LINES,
              VM_SNAPSHOT_DATA,
              ISOLATE_SNAPSHOT_DATA,
              NETWORK_POLICY,
              USE_TEST_FONTS,
              VM_SERVICE_PORT,
              ENABLE_VULKAN_VALIDATION,
              ENABLE_OPENGL_GPU_TRACING,
              ENABLE_VULKAN_GPU_TRACING));

  /**
   * Converts a command line flag string to camel case that can be used as a manifest metadata name
   * if the flag is configurable by manifest. See {@link FlutterEngineManifestFlags} for the list of
   * flags for such available flags.
   *
   * @param flag the command line flag (e.g., "--trace-startup")
   * @return the camel case version (e.g., "traceStartup")
   */
  @NonNull
  public static String toManifestMetadataName(@NonNull String flag) {
    // Remove leading dashes.
    String withoutDashes = flag.replaceFirst("^-+", "");

    // Remove trailing '=' if present.
    if (withoutDashes.endsWith("=")) {
      withoutDashes = withoutDashes.substring(0, withoutDashes.length() - 1);
    }

    // Convert the rest of the flag name to camel case without dashes.
    String[] parts = withoutDashes.split("[-_]");

    StringBuilder result = new StringBuilder();
    for (int i = 0; i < parts.length; i++) {
      String part = parts[i];
      if (part.isEmpty()) {
        continue;
      }

      if (i == 0) {
        // First part stays lowercase
        result.append(part.toLowerCase());
      } else {
        // Subsequent parts are capitalized
        result.append(Character.toUpperCase(part.charAt(0)));
        if (part.length() > 1) {
          result.append(part.substring(1).toLowerCase());
        }
      }
    }

    return result.toString();
  }
}

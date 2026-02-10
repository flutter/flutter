// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine;

import android.content.Intent;
import androidx.annotation.NonNull;
import java.util.*;

/**
 * Arguments that can be delivered to the Flutter shell on Android as Intent extras.
 *
 * <p>The term "shell" refers to the native code that adapts Flutter to different platforms.
 * Flutter's Android Java code initializes a native "shell" and passes these arguments to that
 * native "shell" when it is initialized. See {@link
 * io.flutter.embedding.engine.loader.FlutterLoader#ensureInitializationComplete(Context, String[])}
 * for more information.
 *
 * <p>All of these flags map to a flag listed in shell/common/switches.cc, which contains the full
 * list of flags that can be set across all platforms.
 *
 * <p>These flags are preferably set via the manifest metadata in a Flutter component's
 * AndroidManifest.xml or via the command line for security purposes as Intent extras may expose
 * sensitive information to malicious actors. See {@link FlutterShellArgs} for the specification of
 * how to set each flag via the command line and manifest metadata.
 */
// TODO(camsim99): Delete this class when support for setting engine shell arguments via Intent
// is no longer supported. See https://github.com/flutter/flutter/issues/180686.
public final class FlutterShellArgsIntentUtils {

  private FlutterShellArgsIntentUtils() {}

  public static final String ARG_KEY_TRACE_STARTUP = "trace-startup";
  public static final String ARG_TRACE_STARTUP = "--trace-startup";
  public static final String ARG_KEY_START_PAUSED = "start-paused";
  public static final String ARG_START_PAUSED = "--start-paused";
  public static final String ARG_KEY_DISABLE_SERVICE_AUTH_CODES = "disable-service-auth-codes";
  public static final String ARG_DISABLE_SERVICE_AUTH_CODES = "--disable-service-auth-codes";
  public static final String ARG_KEY_ENDLESS_TRACE_BUFFER = "endless-trace-buffer";
  public static final String ARG_ENDLESS_TRACE_BUFFER = "--endless-trace-buffer";
  public static final String ARG_KEY_USE_TEST_FONTS = "use-test-fonts";
  public static final String ARG_USE_TEST_FONTS = "--use-test-fonts";
  public static final String ARG_KEY_ENABLE_DART_PROFILING = "enable-dart-profiling";
  public static final String ARG_ENABLE_DART_PROFILING = "--enable-dart-profiling";
  public static final String ARG_KEY_PROFILE_STARTUP = "profile-startup";
  public static final String ARG_PROFILE_STARTUP = "--profile-startup";
  public static final String ARG_KEY_ENABLE_SOFTWARE_RENDERING = "enable-software-rendering";
  public static final String ARG_ENABLE_SOFTWARE_RENDERING = "--enable-software-rendering";
  public static final String ARG_KEY_SKIA_DETERMINISTIC_RENDERING = "skia-deterministic-rendering";
  public static final String ARG_SKIA_DETERMINISTIC_RENDERING = "--skia-deterministic-rendering";
  public static final String ARG_KEY_TRACE_SKIA = "trace-skia";
  public static final String ARG_TRACE_SKIA = "--trace-skia";
  public static final String ARG_KEY_TRACE_SKIA_ALLOWLIST = "trace-skia-allowlist";
  public static final String ARG_TRACE_SKIA_ALLOWLIST = "--trace-skia-allowlist=";
  public static final String ARG_KEY_TRACE_SYSTRACE = "trace-systrace";
  public static final String ARG_TRACE_SYSTRACE = "--trace-systrace";
  public static final String ARG_KEY_TRACE_TO_FILE = "trace-to-file";
  public static final String ARG_TRACE_TO_FILE = "--trace-to-file";
  public static final String ARG_KEY_PROFILE_MICROTASKS = "profile-microtasks";
  public static final String ARG_PROFILE_MICROTASKS = "--profile-microtasks";
  public static final String ARG_KEY_TOGGLE_IMPELLER = "enable-impeller";
  public static final String ARG_ENABLE_IMPELLER = "--enable-impeller=true";
  public static final String ARG_DISABLE_IMPELLER = "--enable-impeller=false";
  public static final String ARG_KEY_ENABLE_VULKAN_VALIDATION = "enable-vulkan-validation";
  public static final String ARG_ENABLE_VULKAN_VALIDATION = "--enable-vulkan-validation";
  public static final String ARG_KEY_DUMP_SHADER_SKP_ON_SHADER_COMPILATION =
      "dump-skp-on-shader-compilation";
  public static final String ARG_DUMP_SHADER_SKP_ON_SHADER_COMPILATION =
      "--dump-skp-on-shader-compilation";
  public static final String ARG_KEY_CACHE_SKSL = "cache-sksl";
  public static final String ARG_CACHE_SKSL = "--cache-sksl";
  public static final String ARG_KEY_PURGE_PERSISTENT_CACHE = "purge-persistent-cache";
  public static final String ARG_PURGE_PERSISTENT_CACHE = "--purge-persistent-cache";
  public static final String ARG_KEY_VERBOSE_LOGGING = "verbose-logging";
  public static final String ARG_VERBOSE_LOGGING = "--verbose-logging";
  public static final String ARG_KEY_VM_SERVICE_PORT = "vm-service-port";
  public static final String ARG_VM_SERVICE_PORT = "--vm-service-port=";
  public static final String ARG_KEY_DART_FLAGS = "dart-flags";
  public static final String ARG_DART_FLAGS = "--dart-flags";

  @NonNull
  public static String[] getFlutterShellCommandLineArgs(@NonNull Intent intent) {
    // Before adding more entries to this list, consider that arbitrary
    // Android applications can generate intents with extra data and that
    // there are many security-sensitive args in the binary.
    ArrayList<String> args = new ArrayList<>();

    if (intent.getBooleanExtra(ARG_KEY_TRACE_STARTUP, false)) {
      args.add(ARG_TRACE_STARTUP);
    }
    if (intent.getBooleanExtra(ARG_KEY_START_PAUSED, false)) {
      args.add(ARG_START_PAUSED);
    }
    int vmServicePort = intent.getIntExtra(ARG_KEY_VM_SERVICE_PORT, 0);
    if (vmServicePort > 0) {
      args.add(ARG_VM_SERVICE_PORT + vmServicePort);
    }
    if (intent.getBooleanExtra(ARG_KEY_DISABLE_SERVICE_AUTH_CODES, false)) {
      args.add(ARG_DISABLE_SERVICE_AUTH_CODES);
    }
    if (intent.getBooleanExtra(ARG_KEY_ENDLESS_TRACE_BUFFER, false)) {
      args.add(ARG_ENDLESS_TRACE_BUFFER);
    }
    if (intent.getBooleanExtra(ARG_KEY_USE_TEST_FONTS, false)) {
      args.add(ARG_USE_TEST_FONTS);
    }
    if (intent.getBooleanExtra(ARG_KEY_ENABLE_DART_PROFILING, false)) {
      args.add(ARG_ENABLE_DART_PROFILING);
    }
    if (intent.getBooleanExtra(ARG_KEY_PROFILE_STARTUP, false)) {
      args.add(ARG_PROFILE_STARTUP);
    }
    if (intent.getBooleanExtra(ARG_KEY_ENABLE_SOFTWARE_RENDERING, false)) {
      args.add(ARG_ENABLE_SOFTWARE_RENDERING);
    }
    if (intent.getBooleanExtra(ARG_KEY_SKIA_DETERMINISTIC_RENDERING, false)) {
      args.add(ARG_SKIA_DETERMINISTIC_RENDERING);
    }
    if (intent.getBooleanExtra(ARG_KEY_TRACE_SKIA, false)) {
      args.add(ARG_TRACE_SKIA);
    }
    String traceSkiaAllowlist = intent.getStringExtra(ARG_KEY_TRACE_SKIA_ALLOWLIST);
    if (traceSkiaAllowlist != null) {
      args.add(ARG_TRACE_SKIA_ALLOWLIST + traceSkiaAllowlist);
    }
    if (intent.getBooleanExtra(ARG_KEY_TRACE_SYSTRACE, false)) {
      args.add(ARG_TRACE_SYSTRACE);
    }
    if (intent.hasExtra(ARG_KEY_TRACE_TO_FILE)) {
      args.add(ARG_TRACE_TO_FILE + "=" + intent.getStringExtra(ARG_KEY_TRACE_TO_FILE));
    }
    if (intent.hasExtra(ARG_KEY_PROFILE_MICROTASKS)) {
      args.add(ARG_PROFILE_MICROTASKS);
    }
    if (intent.hasExtra(ARG_KEY_TOGGLE_IMPELLER)) {
      if (intent.getBooleanExtra(ARG_KEY_TOGGLE_IMPELLER, false)) {
        args.add(ARG_ENABLE_IMPELLER);
      } else {
        args.add(ARG_DISABLE_IMPELLER);
      }
    }
    if (intent.getBooleanExtra(ARG_KEY_ENABLE_VULKAN_VALIDATION, false)) {
      args.add(ARG_ENABLE_VULKAN_VALIDATION);
    }
    if (intent.getBooleanExtra(ARG_KEY_DUMP_SHADER_SKP_ON_SHADER_COMPILATION, false)) {
      args.add(ARG_DUMP_SHADER_SKP_ON_SHADER_COMPILATION);
    }
    if (intent.getBooleanExtra(ARG_KEY_CACHE_SKSL, false)) {
      args.add(ARG_CACHE_SKSL);
    }
    if (intent.getBooleanExtra(ARG_KEY_PURGE_PERSISTENT_CACHE, false)) {
      args.add(ARG_PURGE_PERSISTENT_CACHE);
    }
    if (intent.getBooleanExtra(ARG_KEY_VERBOSE_LOGGING, false)) {
      args.add(ARG_VERBOSE_LOGGING);
    }

    // All flags provided with this argument are subject to filtering
    // based on a list of allowed flags in shell/common/switches.cc. If any
    // flag provided is not allowed, the process will immediately terminate.
    if (intent.hasExtra(ARG_KEY_DART_FLAGS)) {
      args.add(ARG_DART_FLAGS + "=" + intent.getStringExtra(ARG_KEY_DART_FLAGS));
    }

    String[] argsArray = new String[args.size()];
    return args.toArray(argsArray);
  }
}

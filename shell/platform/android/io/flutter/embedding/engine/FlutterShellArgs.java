// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine;

import android.content.Context;
import android.content.Intent;
import androidx.annotation.NonNull;
import java.util.*;

/**
 * Arguments that can be delivered to the Flutter shell when it is created.
 *
 * <p>The term "shell" refers to the native code that adapts Flutter to different platforms.
 * Flutter's Android Java code initializes a native "shell" and passes these arguments to that
 * native shell when it is initialized. See {@link
 * io.flutter.embedding.engine.loader.FlutterLoader#ensureInitializationComplete(Context, String[])}
 * for more information.
 */
@SuppressWarnings({"WeakerAccess", "unused"})
public class FlutterShellArgs {
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
  public static final String ARG_KEY_ENABLE_IMPELLER = "enable-impeller";
  public static final String ARG_ENABLE_IMPELLER = "--enable-impeller";
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
  public static final String ARG_KEY_OBSERVATORY_PORT = "observatory-port";
  public static final String ARG_OBSERVATORY_PORT = "--observatory-port=";
  public static final String ARG_KEY_DART_FLAGS = "dart-flags";
  public static final String ARG_DART_FLAGS = "--dart-flags";
  public static final String ARG_KEY_MSAA_SAMPLES = "msaa-samples";
  public static final String ARG_MSAA_SAMPLES = "--msaa-samples";

  @NonNull
  public static FlutterShellArgs fromIntent(@NonNull Intent intent) {
    // Before adding more entries to this list, consider that arbitrary
    // Android applications can generate intents with extra data and that
    // there are many security-sensitive args in the binary.
    // TODO(mattcarroll): I left this warning as-is, but we should clarify what exactly this warning
    // is warning against.
    ArrayList<String> args = new ArrayList<>();

    if (intent.getBooleanExtra(ARG_KEY_TRACE_STARTUP, false)) {
      args.add(ARG_TRACE_STARTUP);
    }
    if (intent.getBooleanExtra(ARG_KEY_START_PAUSED, false)) {
      args.add(ARG_START_PAUSED);
    }
    final int observatoryPort = intent.getIntExtra(ARG_KEY_OBSERVATORY_PORT, 0);
    if (observatoryPort > 0) {
      args.add(ARG_OBSERVATORY_PORT + Integer.toString(observatoryPort));
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
    if (intent.getBooleanExtra(ARG_KEY_ENABLE_IMPELLER, false)) {
      args.add(ARG_ENABLE_IMPELLER);
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
    final int msaaSamples = intent.getIntExtra("msaa-samples", 0);
    if (msaaSamples > 1) {
      args.add("--msaa-samples=" + Integer.toString(msaaSamples));
    }

    // NOTE: all flags provided with this argument are subject to filtering
    // based on a a list of allowed flags in shell/common/switches.cc. If any
    // flag provided is not allowed, the process will immediately terminate.
    if (intent.hasExtra(ARG_KEY_DART_FLAGS)) {
      args.add(ARG_DART_FLAGS + "=" + intent.getStringExtra(ARG_KEY_DART_FLAGS));
    }

    return new FlutterShellArgs(args);
  }

  @NonNull private Set<String> args;

  /**
   * Creates a set of Flutter shell arguments from a given {@code String[]} array. The given
   * arguments are automatically de-duplicated.
   */
  public FlutterShellArgs(@NonNull String[] args) {
    this.args = new HashSet<>(Arrays.asList(args));
  }

  /**
   * Creates a set of Flutter shell arguments from a given {@code List<String>}. The given arguments
   * are automatically de-duplicated.
   */
  public FlutterShellArgs(@NonNull List<String> args) {
    this.args = new HashSet<>(args);
  }

  /** Creates a set of Flutter shell arguments from a given {@code Set<String>}. */
  public FlutterShellArgs(@NonNull Set<String> args) {
    this.args = new HashSet<>(args);
  }

  /**
   * Adds the given {@code arg} to this set of arguments.
   *
   * @param arg argument to add
   */
  public void add(@NonNull String arg) {
    args.add(arg);
  }

  /**
   * Removes the given {@code arg} from this set of arguments.
   *
   * @param arg argument to remove
   */
  public void remove(@NonNull String arg) {
    args.remove(arg);
  }

  /**
   * Returns a new {@code String[]} array which contains each of the arguments within this {@code
   * FlutterShellArgs}.
   *
   * @return array of arguments
   */
  @NonNull
  public String[] toArray() {
    String[] argsArray = new String[args.size()];
    return args.toArray(argsArray);
  }
}

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
 */
@SuppressWarnings({"WeakerAccess", "unused"})
// TODO(camsim99): Do we even need these????
public class FlutterEngineCommandLineFlags {
  public static final String TRACE_STARTUP_FLAG = "--trace-startup";
  public static final String START_PAUSED_FLAG = "--start-paused";
  public static final String DISABLE_SERVICE_AUTH_CODES_FLAG = "--disable-service-auth-codes";
  public static final String ENDLESS_TRACE_BUFFER_FLAG = "--endless-trace-buffer";
  public static final String USE_TEST_FONTS_FLAG = "--use-test-fonts";
  public static final String ENABLE_DART_PROFILING_FLAG = "--enable-dart-profiling";
  public static final String PROFILE_STARTUP_FLAG = "--profile-startup";
  public static final String ENABLE_SOFTWARE_RENDERING_FLAG = "--enable-software-rendering";
  public static final String SKIA_DETERMINISTIC_RENDERING_FLAG = "--skia-deterministic-rendering";
  public static final String TRACE_SKIA_FLAG = "--trace-skia";
  public static final String TRACE_SKIA_ALLOWLIST_FLAG = "--trace-skia-allowlist=";
  public static final String TRACE_SYSTRACE_FLAG = "--trace-systrace";
  public static final String TRACE_TO_FILE_FLAG = "--trace-to-file";
  public static final String PROFILE_MICROTASKS_FLAG = "--profile-microtasks";
  public static final String ENABLE_IMPELLER_FLAG = "--enable-impeller=";
  public static final String ENABLE_VULKAN_VALIDATION_FLAG = "--enable-vulkan-validation";
  public static final String DUMP_SHADER_SKP_ON_SHADER_COMPILATION_FLAG =
      "--dump-skp-on-shader-compilation";
  public static final String CACHE_SKSL_FLAG = "--cache-sksl";
  public static final String PURGE_PERSISTENT_CACHE_FLAG = "--purge-persistent-cache";
  public static final String VERBOSE_LOGGING_FLAG = "--verbose-logging";
  public static final String VM_SERVICE_PORT_FLAG = "--vm-service-port=";
  public static final String DART_FLAGS_FLAG = "--dart-flags=";

  @NonNull private Set<String> args;

  /**
   * Creates a set of Flutter shell arguments from a given {@code String[]} array. The given
   * arguments are automatically de-duplicated.
   */
  public FlutterEngineCommandLineFlags(@NonNull String[] args) {
    this.args = new HashSet<>(Arrays.asList(args));
  }

  /**
   * Creates a set of Flutter shell arguments from a given {@code List<String>}. The given arguments
   * are automatically de-duplicated.
   */
  public FlutterEngineCommandLineFlags(@NonNull List<String> args) {
    this.args = new HashSet<>(args);
  }

  /** Creates a set of Flutter shell arguments from a given {@code Set<String>}. */
  public FlutterEngineCommandLineFlags(@NonNull Set<String> args) {
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
   * FlutterEngineCommandLineFlags}.
   *
   * @return array of arguments
   */
  @NonNull
  public String[] toArray() {
    String[] argsArray = new String[args.size()];
    return args.toArray(argsArray);
  }
}

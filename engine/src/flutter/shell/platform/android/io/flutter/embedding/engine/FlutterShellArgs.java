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
  public static final String ARG_TRACE_STARTUP = "--trace-startup";
  public static final String ARG_START_PAUSED = "--start-paused";
  public static final String ARG_DISABLE_SERVICE_AUTH_CODES = "--disable-service-auth-codes";
  public static final String ARG_ENDLESS_TRACE_BUFFER = "--endless-trace-buffer";
  public static final String ARG_USE_TEST_FONTS = "--use-test-fonts";
  public static final String ARG_ENABLE_DART_PROFILING = "--enable-dart-profiling";
  public static final String ARG_PROFILE_STARTUP = "--profile-startup";
  public static final String ARG_ENABLE_SOFTWARE_RENDERING = "--enable-software-rendering";
  public static final String ARG_SKIA_DETERMINISTIC_RENDERING = "--skia-deterministic-rendering";
  public static final String ARG_TRACE_SKIA = "--trace-skia";
  public static final String ARG_TRACE_SKIA_ALLOWLIST = "--trace-skia-allowlist=";
  public static final String ARG_TRACE_SYSTRACE = "--trace-systrace";
  public static final String ARG_TRACE_TO_FILE = "--trace-to-file";
  public static final String ARG_PROFILE_MICROTASKS = "--profile-microtasks";
  public static final String ARG_ENABLE_IMPELLER = "--enable-impeller=";
  public static final String ARG_ENABLE_VULKAN_VALIDATION = "--enable-vulkan-validation";
  public static final String ARG_DUMP_SHADER_SKP_ON_SHADER_COMPILATION =
      "--dump-skp-on-shader-compilation";
  public static final String ARG_CACHE_SKSL = "--cache-sksl";
  public static final String ARG_PURGE_PERSISTENT_CACHE = "--purge-persistent-cache";
  public static final String ARG_VERBOSE_LOGGING = "--verbose-logging";
  public static final String ARG_VM_SERVICE_PORT = "--vm-service-port=";
  public static final String ARG_DART_FLAGS = "--dart-flags=";

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

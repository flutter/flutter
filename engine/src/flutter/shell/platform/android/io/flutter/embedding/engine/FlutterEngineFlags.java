// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine;

import androidx.annotation.VisibleForTesting;
import java.util.*;

/**
 * Arguments that can be delivered to the Flutter shell on Android.
 *
 * <p>The term "shell" refers to the native code that adapts Flutter to different platforms.
 * Flutter's Android Java code initializes a native "shell" and passes these arguments to that
 * native shell when it is initialized. See {@link
 * io.flutter.embedding.engine.loader.FlutterLoader#ensureInitializationComplete(Context, String[])}
 * for more information.
 *
 * <p>All of these flags map to a flag listed in shell/common/switches.cc, which contains the full
 * list of flags that can be set across all platforms.
 *
 * <p>These flags can either be set via the manifest metadata in a Flutter component's
 * AndroidManifest.xml or via the command line. See the inner {@code Flag} class for the
 * specification of how to set each flag via the command line and manifest metadata.
 *
 * <p>If the same flag is provided both via command line arguments and via AndroidManifest.xml
 * metadata, the command line value will take precedence at runtime.
 */
public final class FlutterEngineFlags {

  private FlutterEngineFlags() {}

  /** Represents a Flutter shell flag that can be set via manifest metadata or command line. */
  public static class Flag {
    /** The actual argument used to specify the flag in the engine. */
    public final String engineArgument;

    /**
     * The metadata key name used to specify the flag in AndroidManifest.xml.
     *
     * <p>To specify a flag in a manifest, it should be prefixed with {@code
     * io.flutter.embedding.android.}. This is enforced to avoid potential naming collisions with
     * other metadata keys. The only exception are flags that have already been deprecated.
     */
    public final String metadataKey;

    /** Whether this flag is allowed to be set in release mode. */
    public final boolean allowedInRelease;

    /**
     * Creates a new Flutter shell flag that is not allowed in release mode with the default flag
     * prefix.
     */
    private Flag(String engineArgument, String metaDataName) {
      this(engineArgument, metaDataName, "io.flutter.embedding.android.", false);
    }

    /** Creates a new Flutter shell flag with the default flag prefix. */
    private Flag(String engineArgument, String metaDataName, boolean allowedInRelease) {
      this(engineArgument, metaDataName, "io.flutter.embedding.android.", allowedInRelease);
    }

    /**
     * Creates a new Flutter shell flag.
     *
     * <p>{@param allowedInRelease} determines whether or not this flag is allowed in release mode.
     * Whenever possible, it is recommended to NOT allow this flag in release mode. Many flags are
     * designed for debugging purposes and if enabled in production, could expose sensitive
     * application data or make the app vulnerable to malicious actors.
     *
     * <p>If creating a flag that will be allowed in release, please leave a comment in the Javadoc
     * explaining why it should be allowed in release.
     */
    private Flag(
        String engineArgument, String metaDataName, String flagPrefix, boolean allowedInRelease) {
      this.engineArgument = engineArgument;
      this.metadataKey = flagPrefix + metaDataName;
      this.allowedInRelease = allowedInRelease;
    }

    /** Returns true if the command line flag requires a value to be specified. */
    public boolean hasCommandLineValue() {
      return engineArgument.endsWith("=");
    }
  }

  // Manifest flags allowed in release mode:

  /**
   * Specifies the path to the AOT shared library containing compiled Dart code.
   *
   * <p>The AOT shared library that the engine uses will default to the library set by this flag,
   * but will fall back to the libraries set internally by the embedding if the path specified by
   * this argument is invalid.
   *
   * <p>Allowed in release to support the same AOT configuration regardless of build mode. Only
   * settable via the manifest.
   */
  public static final Flag AOT_SHARED_LIBRARY_NAME =
      new Flag("--aot-shared-library-name=", "AOTSharedLibraryName", true);

  /**
   * Deprecated flag that specifies the path to the AOT shared library containing compiled Dart
   * code.
   *
   * <p>Please use {@link AOT_SHARED_LIBRARY_NAME} instead.
   */
  @Deprecated
  public static final Flag DEPRECATED_AOT_SHARED_LIBRARY_NAME =
      new Flag(
          "--aot-shared-library-name=",
          "aot-shared-library-name",
          "io.flutter.embedding.engine.loader.FlutterLoader.",
          true);

  /**
   * Sets the directory containing Flutter assets.
   *
   * <p>Allowed in release to specify custom asset locations in production. Only settable via the
   * manifest.
   */
  public static final Flag FLUTTER_ASSETS_DIR =
      new Flag("--flutter-assets-dir=", "FlutterAssetsDir", true);

  /**
   * The deprecated flag that sets the directory containing Flutter assets.
   *
   * <p>Please use {@link FLUTTER_ASSETS_DIR} infstead.
   */
  @Deprecated
  public static final Flag DEPRECATED_FLUTTER_ASSETS_DIR =
      new Flag(
          "--flutter-assets-dir=",
          "flutter-assets-dir",
          "io.flutter.embedding.engine.loader.FlutterLoader.",
          true);

  /**
   * Sets the old generation heap size for the Dart VM in megabytes.
   *
   * <p>Allowed in release for performance tuning. Only settable via the manifest.
   */
  public static final Flag OLD_GEN_HEAP_SIZE =
      new Flag("--old-gen-heap-size=", "OldGenHeapSize", true);

  /**
   * Enables Impeller.
   *
   * <p>Allowed in release to control which rendering backend is used in production. Settable via
   * the command line and manifest.
   */
  private static final Flag ENABLE_IMPELLER =
      new Flag("--enable-impeller=", "EnableImpeller", true);

  /**
   * Specifies the backend to use for Impeller rendering.
   *
   * <p>Allowed in release to select a specific graphics backend for Impeller in production. Only
   * settable via the manifest.
   */
  private static final Flag IMPELLER_BACKEND =
      new Flag("--impeller-backend=", "ImpellerBackend", true);

  /**
   * Enables Dart profiling for use with DevTools.
   *
   * <p>Allowed in release mode for testing purposes. Settable via the command line and the
   * manifest.
   */
  private static final Flag ENABLE_DART_PROFILING =
      new Flag("--enable-dart-profiling", "EnableDartProfiling", true);

  /**
   * Discards new profiler samples once the buffer is full. Only meaningful when set in conjunction
   * with {@link ENABLE_DART_PROFILING}.
   *
   * <p>Allowed in release mode to allow the startup performance to be profiled by DevTools.
   * Settable via the command line and the manifest.
   */
  private static final Flag PROFILE_STARTUP = new Flag("--profile-startup", "ProfileStartup", true);

  /**
   * Measures startup time and switches to an endless trace buffer.
   *
   * <p>Allowed in release mode to allow the startup performance to be profiled by DevTools.
   * Settable via the command line and the manifest.
   */
  private static final Flag TRACE_STARTUP = new Flag("--trace-startup", "TraceStartup", true);

  /**
   * Sets whether the UI thread and platform thread should be merged.
   *
   * <p>Allowed in release mode for performance purposes. Only settable via the manifest.
   */
  private static final Flag MERGED_PLATFORM_UI_THREAD =
      new Flag("--merged-platform-ui-thread", "MergedPlatformUIThread", true);

  /**
   * Specifies the path to the VM snapshot data file.
   *
   * <p>Allowed in release to support different snapshot configurations. Only settable via the
   * manifest.
   */
  public static final Flag VM_SNAPSHOT_DATA =
      new Flag("--vm-snapshot-data=", "VmSnapshotData", true);

  /**
   * Specifies the path to the isolate snapshot data file.
   *
   * <p>Allowed in release to support different snapshot configurations. Only settable via the
   * manifest.
   */
  public static final Flag ISOLATE_SNAPSHOT_DATA =
      new Flag("--isolate-snapshot-data=", "IsolateSnapshotData", true);

  /**
   * Enables Hybrid Composition++.
   *
   * <p>Allowed in release to opt-in to this platform views implementation in production. Settable
   * via the manifest and the command line (via --enable-hcpp).
   */
  private static final Flag ENABLE_HCPP =
      new Flag("--enable-hcpp-and-surface-control", "EnableHcpp", true);

  /**
   * Enables the Flutter GPU backend.
   *
   * <p>Allowed in release for developers to use the Flutter GPU backend in production. Settable via
   * the command line and the manifest.
   */
  private static final Flag ENABLE_FLUTTER_GPU =
      new Flag("--enable-flutter-gpu", "EnableFlutterGPU", true);

  /**
   * Enables lazy initialization of Impeller shaders.
   *
   * <p>Allowed in release for performance tuning of the Impeller backend. Only settable via the
   * manifest.
   */
  private static final Flag IMPELLER_LAZY_SHADER_MODER =
      new Flag("--impeller-lazy-shader-mode", "ImpellerLazyShaderInitialization", true);

  /**
   * Enables antialiasing for lines in Impeller.
   *
   * <p>Allowed in release to control rendering quality in production. Only settable via the
   * manifest.
   */
  private static final Flag IMPELLER_ANTIALIAS_LINES =
      new Flag("--impeller-antialias-lines", "ImpellerAntialiasLines", true);

  // Manifest flags NOT allowed in release mode:

  /**
   * Enables GPU tracing for OpenGL.
   *
   * <p>Only settable via the manifest.
   */
  private static final Flag IMPELLER_OPENGL_GPU_TRACING =
      new Flag("--enable-opengl-gpu-tracing", "EnableOpenGLGPUTracing");

  /**
   * Enables GPU tracing for Vulkan.
   *
   * <p>Only settable via the manifest.
   */
  private static final Flag IMPELLER_VULKAN_GPU_TRACING =
      new Flag("--enable-vulkan-gpu-tracing", "EnableVulkanGPUTracing");

  /**
   * Ensures deterministic Skia rendering by skipping CPU feature swaps.
   *
   * <p>Settable via the command line and the manifest.
   */
  private static final Flag SKIA_DETERMINISTIC_RENDERING =
      new Flag("--skia-deterministic-rendering", "SkiaDeterministicRendering");

  /**
   * Use Skia software backend for rendering.
   *
   * <p>Settable via the command line and the manifest.
   */
  public static final Flag ENABLE_SOFTWARE_RENDERING =
      new Flag("--enable-software-rendering", "EnableSoftwareRendering");

  /**
   * Use the Ahem test font for font resolution.
   *
   * <p>Settable via the command line and the manifest.
   */
  private static final Flag USE_TEST_FONTS = new Flag("--use-test-fonts", "UseTestFonts");

  /**
   * Sets the port for the Dart VM Service.
   *
   * <p>Settable via the command line and the manifest.
   */
  private static final Flag VM_SERVICE_PORT = new Flag("--vm-service-port=", "VMServicePort");

  /**
   * Enables Vulkan validation layers if available.
   *
   * <p>Settable via the command line and the manifest.
   */
  private static final Flag ENABLE_VULKAN_VALIDATION =
      new Flag("--enable-vulkan-validation", "EnableVulkanValidation");

  /**
   * Fake flag used for integration testing of the Android embedding processing engine flags.
   *
   * <p>Only settable via the manifest.
   */
  @VisibleForTesting public static final Flag TEST_FLAG = new Flag("--test-flag", "TestFlag");

  /**
   * Set whether leave or clean up the VM after the last shell shuts down. It can be set from app's
   * metadata in the application block in AndroidManifest.xml. Set it to true in to leave the Dart
   * VM, set it to false to destroy VM.
   *
   * <p>If your want to let your app destroy the last shell and re-create shells more quickly, set
   * it to true, otherwise if you want to clean up the memory of the leak VM, set it to false.
   *
   * <p>Only settable via the manifest.
   *
   * <p>TODO(eggfly): Should it be set to false by default?
   * https://github.com/flutter/flutter/issues/96843
   */
  public static final Flag LEAK_VM = new Flag("--leak-vm=", "LeakVM");

  /**
   * Pauses Dart code execution at launch until a debugger is attached.
   *
   * <p>Settable via the command line and the manifest.
   */
  private static final Flag START_PAUSED = new Flag("--start-paused", "StartPaused");

  /**
   * Disables authentication codes for VM service communication.
   *
   * <p>Settable via the command line and the manifest.
   */
  private static final Flag DISABLE_SERVICE_AUTH_CODES =
      new Flag("--disable-service-auth-codes", "DisableServiceAuthCodes");

  /**
   * Enables an endless trace buffer for timeline events.
   *
   * <p>Settable via the command line and the manifest.
   */
  private static final Flag ENDLESS_TRACE_BUFFER =
      new Flag("--endless-trace-buffer", "EndlessTraceBuffer");

  /**
   * Enables tracing of Skia GPU calls.
   *
   * <p>Settable via the command line and the manifest.
   */
  private static final Flag TRACE_SKIA = new Flag("--trace-skia", "TraceSkia");

  /**
   * Only traces specified Skia event categories.
   *
   * <p>Settable via the command line and the manifest.
   */
  private static final Flag TRACE_SKIA_ALLOWLIST =
      new Flag("--trace-skia-allowlist=", "TraceSkiaAllowList");

  /**
   * Traces to the system tracer on supported platforms.
   *
   * <p>Settable via the command line and the manifest.
   */
  private static final Flag TRACE_SYSTRACE = new Flag("--trace-systrace", "TraceSystrace");

  /**
   * Writes timeline trace to a file in Perfetto format.
   *
   * <p>Settable via the command line and the manifest.
   */
  private static final Flag TRACE_TO_FILE = new Flag("--trace-to-file=", "TraceToFile");

  /**
   * Collects and logs information about microtasks.
   *
   * <p>Settable via the command line and the manifest.
   */
  private static final Flag PROFILE_MICROTASKS =
      new Flag("--profile-microtasks", "ProfileMicrotasks");

  /**
   * Dumps SKP files that trigger shader compilations.
   *
   * <p>Only settable via the manifest.
   */
  private static final Flag DUMP_SKP_ON_SHADER_COMPILATION =
      new Flag("--dump-skp-on-shader-compilation", "DumpSkpOnShaderCompilation");

  /**
   * Removes all persistent cache files for debugging.
   *
   * <p>Settable via the command line and the manifest.
   */
  private static final Flag PURGE_PERSISTENT_CACHE =
      new Flag("--purge-persistent-cache", "PurgePersistentCache");

  /**
   * Enables logging at all severity levels.
   *
   * <p>Settable via the command line (use `--verbose-system-logs`) and the manifest.
   */
  private static final Flag VERBOSE_LOGGING = new Flag("--verbose-logging", "VerboseLogging");

  /**
   * Passes additional flags to the Dart VM.
   *
   * <p>All flags provided with this argument are subject to filtering based on a list of allowed
   * flags in shell/common/switch_defs.h. If any flag provided is not allowed, the process will
   * immediately terminate.
   *
   * <p>Flags should be separated by a space, e.g. "--dart-flags=--flag-1 --flag-2=2".
   *
   * <p>Settable via the command line and the manifest.
   */
  private static final Flag DART_FLAGS = new Flag("--dart-flags=", "DartFlags");

  /**
   * Disables the merging of the UI and platform threads.
   *
   * <p>This flag is disabled and only exists for the purpose of throwing an exception when used.
   */
  @VisibleForTesting
  public static final Flag DISABLE_MERGED_PLATFORM_UI_THREAD =
      new Flag("--no-enable-merged-platform-ui-thread", "DisableMergedPlatformUIThread");

  @VisibleForTesting
  public static final List<Flag> ALL_FLAGS =
      Collections.unmodifiableList(
          Arrays.asList(
              VM_SERVICE_PORT,
              USE_TEST_FONTS,
              ENABLE_SOFTWARE_RENDERING,
              SKIA_DETERMINISTIC_RENDERING,
              AOT_SHARED_LIBRARY_NAME,
              FLUTTER_ASSETS_DIR,
              ENABLE_IMPELLER,
              IMPELLER_BACKEND,
              ENABLE_VULKAN_VALIDATION,
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
              DUMP_SKP_ON_SHADER_COMPILATION,
              VERBOSE_LOGGING,
              DART_FLAGS,
              MERGED_PLATFORM_UI_THREAD,
              DISABLE_MERGED_PLATFORM_UI_THREAD,
              DEPRECATED_AOT_SHARED_LIBRARY_NAME,
              DEPRECATED_FLUTTER_ASSETS_DIR,
              OLD_GEN_HEAP_SIZE,
              VM_SNAPSHOT_DATA,
              ISOLATE_SNAPSHOT_DATA,
              PURGE_PERSISTENT_CACHE,
              TRACE_STARTUP,
              LEAK_VM,
              TEST_FLAG,
              ENABLE_FLUTTER_GPU,
              IMPELLER_LAZY_SHADER_MODER,
              IMPELLER_ANTIALIAS_LINES,
              IMPELLER_OPENGL_GPU_TRACING,
              IMPELLER_VULKAN_GPU_TRACING,
              ENABLE_HCPP));

  // Flags that have been turned off.
  private static final List<Flag> DISABLED_FLAGS =
      Collections.unmodifiableList(Arrays.asList(DISABLE_MERGED_PLATFORM_UI_THREAD));

  // Lookup map for current flags that replace deprecated ones.
  private static final Map<Flag, Flag> DEPRECATED_FLAGS_BY_REPLACEMENT =
      new HashMap<Flag, Flag>() {
        {
          put(DEPRECATED_AOT_SHARED_LIBRARY_NAME, AOT_SHARED_LIBRARY_NAME);
          put(DEPRECATED_FLUTTER_ASSETS_DIR, FLUTTER_ASSETS_DIR);
        }
      };

  // Lookup map for retrieving the Flag corresponding to a specific command line argument.
  private static final Map<String, Flag> FLAG_BY_COMMAND_LINE_ARG;

  // Lookup map for retrieving the Flag corresponding to a specific metadata key.
  private static final Map<String, Flag> FLAG_BY_META_DATA_KEY;

  static {
    Map<String, Flag> map = new HashMap<String, Flag>(ALL_FLAGS.size());
    Map<String, Flag> metaMap = new HashMap<String, Flag>(ALL_FLAGS.size());
    for (Flag flag : ALL_FLAGS) {
      map.put(flag.engineArgument, flag);
      metaMap.put(flag.metadataKey, flag);
    }
    FLAG_BY_COMMAND_LINE_ARG = Collections.unmodifiableMap(map);
    FLAG_BY_META_DATA_KEY = Collections.unmodifiableMap(metaMap);
  }

  /** Looks up a {@link Flag} by its engineArgument. */
  public static Flag getFlagByEngineArgument(String arg) {
    int equalsIndex = arg.indexOf('=');
    Flag flag =
        FLAG_BY_COMMAND_LINE_ARG.get(equalsIndex == -1 ? arg : arg.substring(0, equalsIndex + 1));
    Flag replacementFlag = getReplacementFlagIfDeprecated(flag);
    return replacementFlag != null ? replacementFlag : flag;
  }

  /**
   * Looks up a {@link Flag} by its Intent key.
   *
   * <p>Previously, the Intent keys were used to set Flutter shell arguments via Intent. The Intent
   * keys typically match the command line argument without the "--" prefix and "=" suffix if the
   * argument takes a value.
   */
  public static Flag getFlagFromIntentKey(String intentKey) {
    Flag toReturn = getFlagByEngineArgument(intentKey);

    if (toReturn == null) {
      toReturn = getFlagByEngineArgument("--" + intentKey);
    }
    if (toReturn == null) {
      toReturn = getFlagByEngineArgument("--" + intentKey + "=");
    }

    return toReturn;
  }

  /** Returns whether or not a flag is disabled and should raise an exception if used. */
  public static boolean isDisabled(Flag flag) {
    return DISABLED_FLAGS.contains(flag);
  }

  /** Returns the replacement flag of that given if it is deprecated. */
  public static Flag getReplacementFlagIfDeprecated(Flag flag) {
    return DEPRECATED_FLAGS_BY_REPLACEMENT.get(flag);
  }
}

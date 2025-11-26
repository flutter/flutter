// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine;

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
 * list of flags that can potentially be set. They can either be set via the manifest metadata in a
 * Flutter component's AndroidManifest.xml or via the command line. See the inner {@code Flag} class
 * for the specification of how to set each flag via the command line and manifest metadata.
 *
 * <p>If the same flag is provided both via command line arguments and via AndroidManifest.xml
 * metadata, the command line value will take precedence at runtime.
 */
public final class FlutterShellArgs {

  private FlutterShellArgs() {}

  /** Represents a Flutter shell flag that can be set via manifest metadata or command line. */
  public static class Flag {
    /** The command line argument used to specify the flag. */
    public final String commandLineArgument;

    /**
     * The metadata key name used to specify the flag in AndroidManifest.xml.
     *
     * <p>To specify a flag in a manifest, it must be prefixed with {@code
     * io.flutter.embedding.android.}. This is done to avoid potential naming collisions with other
     * metadata keys.
     */
    public final String metadataKey;

    /** Whether this flag is allowed to be set in release mode. */
    public final boolean allowedInRelease;

    private String packageName = "io.flutter.embedding.android.";

    public Flag(String commandLineArgument, String metaDataName, boolean allowedInRelease) {
      this.commandLineArgument = commandLineArgument;
      this.metadataKey = packageName + metaDataName;
      this.allowedInRelease = allowedInRelease;
    }

    /** Returns true if this flag requires a value to be specified. */
    public boolean hasValue() {
      return commandLineArgument.endsWith("=");
    }
  }

  // Manifest flags allowed in release mode:

  /** Use Skia software backend for rendering. */
  public static final Flag ENABLE_SOFTWARE_RENDERING =
      new Flag("--enable-software-rendering", "EnableSoftwareRendering", true);

  /** Ensures deterministic Skia rendering by skipping CPU feature swaps. */
  public static final Flag SKIA_DETERMINISTIC_RENDERING =
      new Flag("--skia-deterministic-rendering", "SkiaDeterministicRendering", true);

  /**
   * Specifies the path to the AOT shared library containing compiled Dart code.
   *
   * <p>The AOT shared library that the engine uses will default to the library set by this flag,
   * but will fall back to the libraries set internally by the embedding if the path specified by
   * this argument is invalid.
   */
  public static final Flag AOT_SHARED_LIBRARY_NAME =
      new Flag("--aot-shared-library-name=", "AOTSharedLibraryName", true);

  /** Sets the directory containing Flutter assets. */
  public static final Flag FLUTTER_ASSETS_DIR =
      new Flag("--flutter-assets-dir=", "FlutterAssetsDir", true);

  /** Sets the old generation heap size for the Dart VM in megabytes. */
  public static final Flag OLD_GEN_HEAP_SIZE =
      new Flag("--old-gen-heap-size=", "OldGenHeapSize", true);

  /** Enables or disables the Impeller renderer. */
  public static final Flag ENABLE_IMPELLER = new Flag("--enable-impeller=", "EnableImpeller", true);

  /** Specifies the backend to use for Impeller rendering. */
  public static final Flag IMPELLER_BACKEND =
      new Flag("--impeller-backend=", "ImpellerBackend", true);

  /** Enables Android SurfaceControl for rendering. */
  public static final Flag ENABLE_SURFACE_CONTROL =
      new Flag("--enable-surface-control", "EnableSurfaceControl", true);

  /** Enables the Flutter GPU backend. */
  public static final Flag ENABLE_FLUTTER_GPU =
      new Flag("--enable-flutter-gpu", "EnableFlutterGPU", true);

  /** Enables lazy initialization of Impeller shaders. */
  public static final Flag IMPELLER_LAZY_SHADER_MODE =
      new Flag("--impeller-lazy-shader-mode=", "ImpellerLazyShaderInitialization", true);

  /** Enables antialiasing for lines in Impeller. */
  public static final Flag IMPELLER_ANTIALIAS_LINES =
      new Flag("--impeller-antialias-lines", "ImpellerAntialiasLines", true);

  /** Specifies the path to the VM snapshot data file. */
  public static final Flag VM_SNAPSHOT_DATA =
      new Flag("--vm-snapshot-data=", "VmSnapshotData", true);

  /** Specifies the path to the isolate snapshot data file. */
  public static final Flag ISOLATE_SNAPSHOT_DATA =
      new Flag("--isolate-snapshot-data=", "IsolateSnapshotData", true);

  // Manifest flags NOT allowed in release mode:

  /** Use the Ahem test font for font resolution. */
  public static final Flag USE_TEST_FONTS = new Flag("--use-test-fonts", "UseTestFonts", false);

  /** Sets the port for the Dart VM Service. */
  public static final Flag VM_SERVICE_PORT = new Flag("--vm-service-port=", "VMServicePort", false);

  /** Enables Vulkan validation layers if available. */
  public static final Flag ENABLE_VULKAN_VALIDATION =
      new Flag("--enable-vulkan-validation", "EnableVulkanValidation", false);

  /** Enables GPU tracing for OpenGL. */
  public static final Flag ENABLE_OPENGL_GPU_TRACING =
      new Flag("--enable-opengl-gpu-tracing", "EnableOpenGLGPUTracing", false);

  /** Enables GPU tracing for Vulkan. */
  public static final Flag ENABLE_VULKAN_GPU_TRACING =
      new Flag("--enable-vulkan-gpu-tracing", "EnableVulkanGPUTracing", false);

  /**
   * Set whether leave or clean up the VM after the last shell shuts down. It can be set from app's
   * metadata in the application block in AndroidManifest.xml. Set it to true in to leave the Dart
   * VM, set it to false to destroy VM.
   *
   * <p>If your want to let your app destroy the last shell and re-create shells more quickly, set
   * it to true, otherwise if you want to clean up the memory of the leak VM, set it to false.
   *
   * <p>TODO(eggfly): Should it be set to false by default?
   * https://github.com/flutter/flutter/issues/96843
   */
  public static final Flag LEAK_VM = new Flag("--leak-vm=", "LeakVM", false);

  /** Measures startup time and switches to an endless trace buffer. */
  public static final Flag TRACE_STARTUP = new Flag("--trace-startup", "TraceStartup", false);

  /** Pauses Dart code execution at launch until a debugger is attached. */
  public static final Flag START_PAUSED = new Flag("--start-paused", "StartPaused", false);

  /** Disables authentication codes for VM service communication. */
  public static final Flag DISABLE_SERVICE_AUTH_CODES =
      new Flag("--disable-service-auth-codes", "DisableServiceAuthCodes", false);

  /** Enables an endless trace buffer for timeline events. */
  public static final Flag ENDLESS_TRACE_BUFFER =
      new Flag("--endless-trace-buffer", "EndlessTraceBuffer", false);

  /** Enables Dart profiling for use with DevTools. */
  public static final Flag ENABLE_DART_PROFILING =
      new Flag("--enable-dart-profiling", "EnableDartProfiling", false);

  /** Discards new profiler samples once the buffer is full. */
  public static final Flag PROFILE_STARTUP = new Flag("--profile-startup", "ProfileStartup", false);

  /** Enables tracing of Skia GPU calls. */
  public static final Flag TRACE_SKIA = new Flag("--trace-skia", "TraceSkia", false);

  /** Only traces specified Skia event categories. */
  public static final Flag TRACE_SKIA_ALLOWLIST =
      new Flag("--trace-skia-allowlist=", "TraceSkiaAllowList", false);

  /** Traces to the system tracer on supported platforms. */
  public static final Flag TRACE_SYSTRACE = new Flag("--trace-systrace", "TraceSystrace", false);

  /** Writes timeline trace to a file in Perfetto format. */
  public static final Flag TRACE_TO_FILE = new Flag("--trace-to-file=", "TraceToFile", false);

  /** Collects and logs information about microtasks. */
  public static final Flag PROFILE_MICROTASKS =
      new Flag("--profile-microtasks", "ProfileMicrotasks", false);

  /** Dumps SKP files that trigger shader compilations. */
  public static final Flag DUMP_SKP_ON_SHADER_COMPILATION =
      new Flag("--dump-skp-on-shader-compilation", "DumpSkpOnShaderCompilation", false);

  /** Removes all persistent cache files for debugging. */
  public static final Flag PURGE_PERSISTENT_CACHE =
      new Flag("--purge-persistent-cache", "PurgePersistentCache", false);

  /** Enables logging at all severity levels. */
  public static final Flag VERBOSE_LOGGING = new Flag("--verbose-logging", "VerboseLogging", false);

  /**
   * Passes additional flags to the Dart VM.
   *
   * <p>All flags provided with this argument are subject to filtering based on a list of allowed
   * flags in shell/common/switches.cc. If any flag provided is not allowed, the process will
   * immediately terminate.
   */
  public static final Flag DART_FLAGS = new Flag("--dart-flags=", "DartFlags", false);

  public static final List<Flag> ALL_FLAGS =
      Collections.unmodifiableList(
          Arrays.asList(
              VM_SERVICE_PORT,
              USE_TEST_FONTS,
              ENABLE_SOFTWARE_RENDERING,
              SKIA_DETERMINISTIC_RENDERING,
              AOT_SHARED_LIBRARY_NAME,
              FLUTTER_ASSETS_DIR,
              OLD_GEN_HEAP_SIZE,
              ENABLE_IMPELLER,
              IMPELLER_BACKEND,
              ENABLE_SURFACE_CONTROL,
              ENABLE_FLUTTER_GPU,
              IMPELLER_LAZY_SHADER_MODE,
              IMPELLER_ANTIALIAS_LINES,
              VM_SNAPSHOT_DATA,
              ISOLATE_SNAPSHOT_DATA,
              ENABLE_VULKAN_VALIDATION,
              ENABLE_OPENGL_GPU_TRACING,
              ENABLE_VULKAN_GPU_TRACING,
              LEAK_VM,
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
              DUMP_SKP_ON_SHADER_COMPILATION,
              PURGE_PERSISTENT_CACHE,
              VERBOSE_LOGGING,
              DART_FLAGS));

  // Lookup map for retrieving the Flag corresponding to a specific command line argument.
  private static final Map<String, Flag> FLAG_BY_COMMAND_LINE_ARG;

  // Lookup map for retrieving the Flag corresponding to a specific metadata key.
  private static final Map<String, Flag> FLAG_BY_META_DATA_KEY;

  static {
    Map<String, Flag> map = new HashMap<String, Flag>(ALL_FLAGS.size());
    Map<String, Flag> metaMap = new HashMap<String, Flag>(ALL_FLAGS.size());
    for (Flag flag : ALL_FLAGS) {
      map.put(flag.commandLineArgument, flag);
      metaMap.put(flag.metadataKey, flag);
    }
    FLAG_BY_COMMAND_LINE_ARG = Collections.unmodifiableMap(map);
    FLAG_BY_META_DATA_KEY = Collections.unmodifiableMap(metaMap);
  }

  /** Returns true if a manifest flag with the given command line argument exists. */
  public static boolean containsCommandLineArgument(String arg) {
    return FLAG_BY_COMMAND_LINE_ARG.containsKey(arg);
  }

  /** Looks up a {@link Flag} by its metadataKey. */
  public static Flag getFlagByMetadataKey(String key) {
    return FLAG_BY_META_DATA_KEY.get(key);
  }
}

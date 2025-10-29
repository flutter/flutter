// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine;

import java.util.*;

/**
 * Arguments that can be delivered to the Flutter shell when it is created via the app manifest.
 *
 * <p>The term "shell" refers to the native code that adapts Flutter to different platforms.
 * Flutter's Android Java code initializes a native "shell" and passes these arguments to that
 * native shell when it is initialized. See {@link
 * io.flutter.embedding.engine.loader.FlutterLoader#ensureInitializationComplete(Context, String[])}
 * for more information.
 *
 * <p>If the same flag is provided both via command line arguments and via AndroidManifest.xml
 * meta-data, the command line value takes precedence at runtime.
 */
public final class FlutterEngineManifestFlags {

  private FlutterEngineManifestFlags() {}

  /** Represents a manifest flag and whether it is allowed in release mode. */
  public static class Flag {
    public final String commandLineArgument;
    public final String metaDataKey;
    public final boolean allowedInRelease;

    private String packageName = "io.flutter.embedding.android.";

    public Flag(String commandLineArgument, String metaDataKey, boolean allowedInRelease) {
      this.commandLineArgument = commandLineArgument;
      this.metaDataKey = packageName + metaDataKey;
      this.allowedInRelease = allowedInRelease;
    }

    public boolean hasValue() {
      return commandLineArgument.endsWith("=");
    }
  }

  // Manifest flags allowed in release mode:

  public static final Flag ENABLE_SOFTWARE_RENDERING =
      new Flag(
          FlutterEngineCommandLineFlags.ENABLE_SOFTWARE_RENDERING, "EnableSoftwareRendering", true);
  public static final Flag SKIA_DETERMINISTIC_RENDERING =
      new Flag(
          FlutterEngineCommandLineFlags.SKIA_DETERMINISTIC_RENDERING,
          "SkiaDeterministicRendering",
          true);
  public static final Flag AOT_SHARED_LIBRARY_NAME =
      new Flag(FlutterEngineCommandLineFlags.AOT_SHARED_LIBRARY_NAME, "AotSharedLibraryName", true);
  public static final Flag FLUTTER_ASSETS_DIR =
      new Flag(FlutterEngineCommandLineFlags.FLUTTER_ASSETS_DIR, "FlutterAssetsDir", true);
  public static final Flag OLD_GEN_HEAP_SIZE =
      new Flag(FlutterEngineCommandLineFlags.OLD_GEN_HEAP_SIZE, "OldGenHeapSize", true);
  public static final Flag ENABLE_IMPELLER =
      new Flag(FlutterEngineCommandLineFlags.ENABLE_IMPELLER, "EnableImpeller", true);
  public static final Flag IMPELLER_BACKEND =
      new Flag(FlutterEngineCommandLineFlags.IMPELLER_BACKEND, "ImpellerBackend", true);
  public static final Flag DISABLE_MERGED_PLATFORM_UI_THREAD =
      new Flag(
          FlutterEngineCommandLineFlags.DISABLE_MERGED_PLATFORM_UI_THREAD,
          "DisableMergedPlatformUIThread",
          true);
  public static final Flag ENABLE_SURFACE_CONTROL =
      new Flag(FlutterEngineCommandLineFlags.ENABLE_SURFACE_CONTROL, "EnableSurfaceControl", true);
  public static final Flag ENABLE_FLUTTER_GPU =
      new Flag(FlutterEngineCommandLineFlags.ENABLE_FLUTTER_GPU, "EnableFlutterGPU", true);
  public static final Flag IMPELLER_LAZY_SHADER_MODE =
      new Flag(
          FlutterEngineCommandLineFlags.IMPELLER_LAZY_SHADER_MODE, "ImpellerLazyShaderMode", true);
  public static final Flag IMPELLER_ANTIALIAS_LINES =
      new Flag(
          FlutterEngineCommandLineFlags.IMPELLER_ANTIALIAS_LINES, "ImpellerAntialiasLines", true);
  public static final Flag VM_SNAPSHOT_DATA =
      new Flag(FlutterEngineCommandLineFlags.VM_SNAPSHOT_DATA, "VmSnapshotData", true);
  public static final Flag ISOLATE_SNAPSHOT_DATA =
      new Flag(FlutterEngineCommandLineFlags.ISOLATE_SNAPSHOT_DATA, "IsolateSnapshotData", true);

  // Manifest flags NOT allowed in release mode:

  public static final Flag USE_TEST_FONTS =
      new Flag(FlutterEngineCommandLineFlags.USE_TEST_FONTS, "UseTestFonts", false);
  public static final Flag VM_SERVICE_PORT =
      new Flag(FlutterEngineCommandLineFlags.VM_SERVICE_PORT, "VMServicePort", false);
  public static final Flag ENABLE_VULKAN_VALIDATION =
      new Flag(
          FlutterEngineCommandLineFlags.ENABLE_VULKAN_VALIDATION, "EnableVulkanValidation", false);
  public static final Flag ENABLE_OPENGL_GPU_TRACING =
      new Flag(
          FlutterEngineCommandLineFlags.ENABLE_OPENGL_GPU_TRACING, "EnableOpenGLGPUTracing", false);
  public static final Flag ENABLE_VULKAN_GPU_TRACING =
      new Flag(
          FlutterEngineCommandLineFlags.ENABLE_VULKAN_GPU_TRACING, "EnableVulkanGPUTracing", false);
  public static final Flag LEAK_VM =
      new Flag(FlutterEngineCommandLineFlags.LEAK_VM, "LeakVM", false);

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
              ENABLE_VULKAN_VALIDATION,
              IMPELLER_BACKEND,
              ENABLE_OPENGL_GPU_TRACING,
              ENABLE_VULKAN_GPU_TRACING,
              DISABLE_MERGED_PLATFORM_UI_THREAD,
              ENABLE_SURFACE_CONTROL,
              ENABLE_FLUTTER_GPU,
              IMPELLER_LAZY_SHADER_MODE,
              IMPELLER_ANTIALIAS_LINES,
              VM_SNAPSHOT_DATA,
              ISOLATE_SNAPSHOT_DATA,
              LEAK_VM));

  /**
   * Looks up a Flag by its metaDataKey.
   *
   * @param key The manifest meta-data key.
   * @return The {@link Flag}, or null if not found.
   */
  public static Flag getFlagByMetaDataKey(String key) {
    for (Flag flag : ALL_FLAGS) {
      if (flag.metaDataKey.equals(key)) {
        return flag;
      }
    }
    return null;
  }
}

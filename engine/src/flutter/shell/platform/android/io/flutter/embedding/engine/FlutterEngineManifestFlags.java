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
 */
public final class FlutterEngineManifestFlags {

  private FlutterEngineManifestFlags() {}

  /** Represents a manifest flag and whether it is allowed in release mode. */
  public static class Flag {
    public final String metaDataName;
    public final String metaDataKey;
    public final boolean allowedInRelease;

    private String packageName = "io.flutter.embedding.android.";

    public Flag(String metaDataName, boolean allowedInRelease) {
      this.metaDataName = metaDataName;
      metaDataKey = packageName + metaDataName;
      this.allowedInRelease = allowedInRelease;
    }

    /**
     * Converts this flag to its command-line argument form. If value is provided:
     * "--flag-name=value" If value is null/empty: "--flag-name"
     */
    public String toCommandLineFlag(String value) {
      String flag = "--" + metaDataName.replaceAll("([a-z])([A-Z])", "$1-$2").toLowerCase();
      if (value != null && !value.isEmpty()) {
        return flag + "=" + value;
      } else {
        return flag;
      }
    }
  }

  // Can also be set by command line. Command line takes precendence IMO
  // TODO(camsim99): note this in my manifest file.
  public static final Flag VM_SERVICE_PORT = new Flag("VmServicePort", false);
  public static final Flag USE_TEST_FONTS = new Flag("UseTestFonts", false);
  public static final Flag ENABLE_SOFTWARE_RENDERING = new Flag("EnableSoftwareRendering", true);
  public static final Flag SKIA_DETERMINISTIC_RENDERING =
      new Flag("SkiaDeterministicRendering", true);
  public static final Flag AOT_SHARED_LIBRARY_NAME =
      new Flag("AotSharedLibraryName", true); // set internally too -- note
  public static final Flag FLUTTER_ASSETS_DIR = new Flag("FlutterAssetsDir", true);
  public static final Flag AUTOMATICALLY_REGISTER_PLUGINS =
      new Flag("AutomaticallyRegisterPlugins", true);
  public static final Flag OLD_GEN_HEAP_SIZE = new Flag("OldGenHeapSize", true);
  public static final Flag ENABLE_IMPELLER = new Flag("EnableImpeller", true);
  public static final Flag ENABLE_VULKAN_VALIDATION = new Flag("EnableVulkanValidation", false);
  public static final Flag IMPELLER_BACKEND = new Flag("ImpellerBackend", true);
  public static final Flag ENABLE_OPENGL_GPU_TRACING = new Flag("EnableOpenGLGPUTracing", false);
  public static final Flag ENABLE_VULKAN_GPU_TRACING = new Flag("EnableVulkanGPUTracing", false);
  public static final Flag DISABLE_MERGED_PLATFORM_UI_THREAD =
      new Flag("DisableMergedPlatformUIThread", true);
  public static final Flag ENABLE_SURFACE_CONTROL = new Flag("EnableSurfaceControl", true);
  public static final Flag ENABLE_FLUTTER_GPU = new Flag("EnableFlutterGPU", true);
  public static final Flag IMPELLER_LAZY_SHADER_MODE = new Flag("ImpellerLazyShaderMode", true);
  public static final Flag IMPELLER_LAZY_SHADER_INITIALIZATION =
      new Flag("ImpellerLazyShaderInitialization", true);
  public static final Flag IMPELLER_ANTIALIAS_LINES = new Flag("ImpellerAntialiasLines", true);
  public static final Flag VM_SNAPSHOT_DATA = new Flag("VmSnapshotData", true);
  public static final Flag ISOLATE_SNAPSHOT_DATA = new Flag("IsolateSnapshotData", true);
  public static final Flag NETWORK_POLICY = new Flag("NetworkPolicy", true);

  /**
   * Set whether leave or clean up the VM after the last shell shuts down. It can be set from app's
   * meta-data in the application block in AndroidManifest.xml. Set it to true in to leave the Dart VM,
   * set it to false to destroy VM.
   *
   * <p>If your want to let your app destroy the last shell and re-create shells more quickly, set
   * it to true, otherwise if you want to clean up the memory of the leak VM, set it to false.
   *
   * <p>TODO(eggfly): Should it be set to false by default?
   * https://github.com/flutter/flutter/issues/96843
   */
  public static final Flag LEAK_VM = new Flag("LeakVM", false);

  /**
   * Looks up a Flag by its metaDataKey.
   *
   * @param key The manifest meta-data key.
   * @return The Flag, or null if not found.
   */
  // TODO(camsim99): optimize this with a Map if this becomes a performance issue.
  public static Flag getFlagByMetaDataKey(String key) {
    for (Flag flag : ALL_FLAGS) {
      if (flag.metaDataKey.equals(key)) {
        return flag;
      }
    }
    return null;
  }
}

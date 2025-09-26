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

  public enum FlagType {
    VALUE,
    BOOLEAN
  }

  /** Represents a manifest flag and whether it is allowed in release mode. */
  public static class Flag {
    public final String metaDataName;
    public final String metaDataKey;
    public final boolean allowedInRelease;
    public final FlagType type;

    private String packageName = "io.flutter.embedding.android.";

    public Flag(String metaDataName, boolean allowedInRelease, FlagType type) {
      this.metaDataName = metaDataName;
      metaDataKey = packageName + metaDataName;
      this.allowedInRelease = allowedInRelease;
      this.type = type;
    }

    /**
     * Converts this flag to its command-line argument form. For BOOLEAN flags: "--flag-name" For
     * VALUE flags: "--flag-name=value"
     */
    public String toCommandLineFlag(String value) {
      String flag = "--" + metaDataName.replaceAll("([a-z])([A-Z])", "$1-$2").toLowerCase();
      if (type == FlagType.VALUE) {
        return flag + "=" + value;
      } else {
        return flag;
      }
    }
  }

  // Can also be set by command line. Command line takes precendence IMO
  // TODO(camsim99): note this in my manifest file.
  public static final Flag VM_SERVICE_PORT = new Flag("VmServicePort", false, FlagType.VALUE);
  public static final Flag USE_TEST_FONTS = new Flag("UseTestFonts", false, FlagType.BOOLEAN);
  public static final Flag ENABLE_SOFTWARE_RENDERING =
      new Flag("EnableSoftwareRendering", true, FlagType.BOOLEAN);
  public static final Flag SKIA_DETERMINISTIC_RENDERING =
      new Flag("SkiaDeterministicRendering", true, FlagType.BOOLEAN);
  public static final Flag AOT_SHARED_LIBRARY_NAME = // set internally too
      new Flag("AotSharedLibraryName", true, FlagType.VALUE);
  public static final Flag FLUTTER_ASSETS_DIR = new Flag("FlutterAssetsDir", true, FlagType.VALUE);
  public static final Flag AUTOMATICALLY_REGISTER_PLUGINS =
      new Flag("AutomaticallyRegisterPlugins", true, FlagType.BOOLEAN);
  public static final Flag OLD_GEN_HEAP_SIZE = new Flag("OldGenHeapSize", true, FlagType.VALUE);
  public static final Flag ENABLE_IMPELLER = new Flag("EnableImpeller", true, FlagType.VALUE);
  public static final Flag ENABLE_VULKAN_VALIDATION =
      new Flag("EnableVulkanValidation", false, FlagType.BOOLEAN);
  public static final Flag IMPELLER_BACKEND = new Flag("ImpellerBackend", true, FlagType.VALUE);
  // TODO(camsim99): this one only in flutter loader before weirdly. Also make sure this converts correctly.
  public static final Flag ENABLE_OPENGL_GPU_TRACING =
      new Flag("EnableOpenGLGPUTracing", false, FlagType.BOOLEAN);
  public static final Flag ENABLE_VULKAN_GPU_TRACING =
      new Flag("EnableVulkanGPUTracing", false, FlagType.BOOLEAN);
  public static final Flag DISABLE_MERGED_PLATFORM_UI_THREAD =
      new Flag("DisableMergedPlatformUIThread", true, FlagType.BOOLEAN);
  public static final Flag ENABLE_SURFACE_CONTROL =
      new Flag("EnableSurfaceControl", true, FlagType.BOOLEAN);
  public static final Flag ENABLE_FLUTTER_GPU =
      new Flag("EnableFlutterGPU", true, FlagType.BOOLEAN);
  public static final Flag IMPELLER_LAZY_SHADER_MODE =
      new Flag("ImpellerLazyShaderMode", true, FlagType.BOOLEAN);
  public static final Flag IMPELLER_LAZY_SHADER_INITIALIZATION =
      new Flag("ImpellerLazyShaderInitialization", true, FlagType.BOOLEAN);
  public static final Flag IMPELLER_ANTIALIAS_LINES =
      new Flag("ImpellerAntialiasLines", true, FlagType.BOOLEAN);
  public static final Flag LEAK_VM = new Flag("LeakVM", false, FlagType.BOOLEAN);

  // public static final List<Flag> ALL_FLAGS = Collections.unmodifiableList(Arrays.asList(
  //     VM_SERVICE_PORT,
  //     USE_TEST_FONTS,
  //     ENABLE_SOFTWARE_RENDERING,
  //     SKIA_DETERMINISTIC_RENDERING,
  //     AOT_SHARED_LIBRARY_NAME,
  //     ISOLATE_SNAPSHOT_DATA,
  //     FLUTTER_ASSETS_DIR,
  //     AUTOMATICALLY_REGISTER_PLUGINS,
  //     OLD_GEN_HEAP_SIZE,
  //     ENABLE_IMPELLER,
  //     ENABLE_VULKAN_VALIDATION,
  //     IMPELLER_BACKEND,
  //     ENABLE_OPENGL_GPU_TRACING,
  //     ENABLE_VULKAN_GPU_TRACING,
  //     DISABLE_MERGED_PLATFORM_UI_THREAD,
  //     ENABLE_SURFACE_CONTROL,
  //     ENABLE_FLUTTER_GPU,
  //     IMPELLER_LAZY_SHADER_INITIALIZATION,
  //     IMPELLER_ANTIALIAS_LINES,
  //     LEAK_VM
  // ));

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

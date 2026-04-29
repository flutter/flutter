// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.loader;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.os.Build;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import io.flutter.Log;
import io.flutter.embedding.engine.FlutterJNI;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Enumeration;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

/**
 * Robust native library loader with multiple fallback strategies.
 *
 * <p>Loads {@code libflutter.so} using a cascading sequence of strategies. Each strategy is tried
 * in order; on success, loading completes. If all strategies fail, an {@link UnsatisfiedLinkError}
 * is thrown that lists every path searched, every error encountered, and the relevant device/APK
 * state — so the developer can diagnose why the library could not be located.
 *
 * <p>Strategies, in order:
 *
 * <ol>
 *   <li>{@link FlutterJNI#loadLibrary(Context)} — the existing ReLinker-based path. This invokes
 *       {@code ReLinker.loadLibrary(context, "flutter")} which itself first tries {@code
 *       System.loadLibrary} and then a workaround that extracts the library from the base APK and
 *       calls {@code System.load} on the extracted file. Calling FlutterJNI ensures the {@code
 *       FlutterJNI.loadLibraryCalled} state flag is set on success.
 *   <li>Direct {@code System.loadLibrary("flutter")} — bypasses ReLinker. ReLinker can fail in
 *       cases where {@code System.loadLibrary} succeeds (rare but observed in practice when
 *       ReLinker's APK-scanning logic is confused by app-bundle splits).
 *   <li>Manual extraction from the device-installed native library directory ({@code
 *       ApplicationInfo.nativeLibraryDir}). The OS normally extracts native libraries here at
 *       install time; if the file exists, we attempt {@code System.load} on it directly.
 *   <li>Manual extraction from the base APK ({@code ApplicationInfo.sourceDir}) for every supported
 *       ABI on the device.
 *   <li>Manual extraction from each split APK ({@code ApplicationInfo.splitSourceDirs}) — this is
 *       the case that fails for app-bundle distributions where the native library lives in a split
 *       rather than the base APK. See https://github.com/flutter/flutter/issues/151638.
 *   <li>Scan all APKs (base + splits) for any ABI directory present, even ABIs not in {@link
 *       Build#SUPPORTED_ABIS}, and try them. Catches mis-built APKs and devices reporting
 *       unexpected ABI names.
 * </ol>
 *
 * <p>Extracted libraries are written to the application's code cache directory, not the regular
 * cache directory: the OS may evict regular cache entries at any time, but code cache is intended
 * for executable artifacts and is more durable.
 *
 * <p>This class is package-private and used only by {@link FlutterLoader}.
 */
final class RobustLibraryLoader {
  private static final String TAG = "RobustLibraryLoader";

  /** The library name as passed to {@code System.loadLibrary} (no {@code lib} prefix, no suffix). */
  private static final String LIBRARY_NAME = "flutter";

  /** The library file name as it appears on disk and inside APKs ({@code libflutter.so}). */
  private static final String LIBRARY_FILE_NAME = "lib" + LIBRARY_NAME + ".so";

  /** ZIP entries always use forward slashes regardless of host OS. */
  private static final char ZIP_SEPARATOR = '/';

  @NonNull private final Context context;
  @NonNull private final FlutterJNI flutterJNI;
  @NonNull private final FlutterApplicationInfo flutterApplicationInfo;

  RobustLibraryLoader(
      @NonNull Context context,
      @NonNull FlutterJNI flutterJNI,
      @NonNull FlutterApplicationInfo flutterApplicationInfo) {
    this.context = context;
    this.flutterJNI = flutterJNI;
    this.flutterApplicationInfo = flutterApplicationInfo;
  }

  /**
   * Load {@code libflutter.so} using all available strategies.
   *
   * @throws UnsatisfiedLinkError if every strategy fails. The error message details every path
   *     attempted and the contents of the relevant directories so the failure can be diagnosed
   *     from a single crash report.
   */
  void loadLibrary() {
    final List<LoadAttempt> attempts = new ArrayList<>();
    final ApplicationInfo appInfo = context.getApplicationInfo();

    // --- Strategy 1: existing FlutterJNI path (ReLinker) ---
    try {
      Log.d(TAG, "Strategy 1: FlutterJNI.loadLibrary (ReLinker)");
      flutterJNI.loadLibrary(context);
      Log.i(TAG, "Loaded libflutter.so via FlutterJNI/ReLinker");
      return;
    } catch (UnsatisfiedLinkError e) {
      Log.w(TAG, "FlutterJNI/ReLinker failed: " + e.getMessage());
      attempts.add(new LoadAttempt("FlutterJNI/ReLinker", null, e));
    } catch (Throwable e) {
      // ReLinker can throw MissingLibraryException (a RuntimeException) — catch broadly.
      Log.w(TAG, "FlutterJNI/ReLinker threw: " + e);
      attempts.add(new LoadAttempt("FlutterJNI/ReLinker", null, e));
    }

    // --- Strategy 2: plain System.loadLibrary, bypassing ReLinker ---
    try {
      Log.d(TAG, "Strategy 2: System.loadLibrary(\"" + LIBRARY_NAME + "\")");
      System.loadLibrary(LIBRARY_NAME);
      // Mark as loaded so subsequent FlutterJNI calls don't try to load again.
      markLoaded();
      Log.i(TAG, "Loaded libflutter.so via System.loadLibrary");
      return;
    } catch (UnsatisfiedLinkError e) {
      Log.w(TAG, "System.loadLibrary failed: " + e.getMessage());
      attempts.add(new LoadAttempt("System.loadLibrary", null, e));
    }

    // --- Strategy 3: load directly from nativeLibraryDir, if the file is there ---
    final String nativeLibraryDir = flutterApplicationInfo.nativeLibraryDir;
    if (nativeLibraryDir != null) {
      final File installed = new File(nativeLibraryDir, LIBRARY_FILE_NAME);
      try {
        Log.d(TAG, "Strategy 3: System.load(\"" + installed.getAbsolutePath() + "\")");
        if (!installed.exists()) {
          throw new UnsatisfiedLinkError("File does not exist: " + installed.getAbsolutePath());
        }
        if (!installed.canRead()) {
          throw new UnsatisfiedLinkError(
              "File is not readable (length=" + installed.length() + "): "
                  + installed.getAbsolutePath());
        }
        System.load(installed.getAbsolutePath());
        markLoaded();
        Log.i(TAG, "Loaded libflutter.so from nativeLibraryDir");
        return;
      } catch (Throwable e) {
        Log.w(TAG, "Loading from nativeLibraryDir failed: " + e.getMessage());
        attempts.add(
            new LoadAttempt("System.load(nativeLibraryDir)", installed.getAbsolutePath(), e));
      }
    }

    // --- Strategy 4: extract from base APK for each supported ABI ---
    final String baseApk = appInfo.sourceDir;
    final String[] supportedAbis = (Build.SUPPORTED_ABIS != null) ? Build.SUPPORTED_ABIS : new String[0];

    if (baseApk != null) {
      for (String abi : supportedAbis) {
        tryExtractAndLoad(baseApk, abi, "base APK", attempts);
        if (loaded()) return;
      }
    }

    // --- Strategy 5: extract from each split APK for each supported ABI ---
    final String[] splits = appInfo.splitSourceDirs;
    if (splits != null) {
      for (String splitPath : splits) {
        if (splitPath == null) continue;
        for (String abi : supportedAbis) {
          tryExtractAndLoad(splitPath, abi, "split APK", attempts);
          if (loaded()) return;
        }
      }
    }

    // --- Strategy 6: scan every APK for any ABI dir present (even unexpected ones) ---
    final List<String> allApks = new ArrayList<>();
    if (baseApk != null) allApks.add(baseApk);
    if (splits != null) {
      for (String s : splits) {
        if (s != null) allApks.add(s);
      }
    }
    final Set<String> alreadyTried = new LinkedHashSet<>(Arrays.asList(supportedAbis));
    for (String apk : allApks) {
      for (String abi : scanApkForAbis(apk)) {
        if (alreadyTried.contains(abi)) continue;
        Log.d(TAG, "Strategy 6: trying unexpected ABI " + abi + " in " + apk);
        tryExtractAndLoad(apk, abi, "ABI scan", attempts);
        if (loaded()) return;
        alreadyTried.add(abi);
      }
    }

    // All strategies exhausted.
    throw buildDiagnosticError(attempts, appInfo);
  }

  /**
   * Try to extract and load the library from {@code apkPath} for the given {@code abi}. On
   * success, {@link #loaded()} returns true. On failure, an entry is appended to {@code attempts}.
   */
  private void tryExtractAndLoad(
      @NonNull String apkPath,
      @NonNull String abi,
      @NonNull String label,
      @NonNull List<LoadAttempt> attempts) {
    final String entryName = "lib" + ZIP_SEPARATOR + abi + ZIP_SEPARATOR + LIBRARY_FILE_NAME;
    final String description = label + " " + apkPath + "!" + entryName;
    File extracted = null;
    try {
      extracted = extractFromApk(apkPath, abi, entryName);
      System.load(extracted.getAbsolutePath());
      markLoaded();
      Log.i(TAG, "Loaded libflutter.so from " + description);
    } catch (Throwable e) {
      Log.w(TAG, "Failed to load from " + description + ": " + e.getMessage());
      attempts.add(
          new LoadAttempt(
              "extract+load",
              description + (extracted != null ? " -> " + extracted.getAbsolutePath() : ""),
              e));
    }
  }

  /**
   * Extract a single ZIP entry from an APK to a uniquely-named file in the code cache. Throws if
   * the APK does not exist, is not readable, the entry is missing, or extraction fails.
   *
   * @return the extracted file, with execute permission set
   */
  @NonNull
  private File extractFromApk(@NonNull String apkPath, @NonNull String abi, @NonNull String entryName)
      throws IOException {
    final File apkFile = new File(apkPath);
    if (!apkFile.exists()) {
      throw new IOException("APK does not exist: " + apkPath);
    }
    if (!apkFile.canRead()) {
      throw new IOException("APK is not readable: " + apkPath);
    }

    try (ZipFile zip = new ZipFile(apkFile)) {
      final ZipEntry entry = zip.getEntry(entryName);
      if (entry == null) {
        throw new IOException(
            "Entry not found: " + entryName + " in " + apkPath
                + " (entries with prefix lib/: " + listLibEntries(zip) + ")");
      }

      final File outDir = getExtractionDir();
      if (!outDir.exists() && !outDir.mkdirs()) {
        throw new IOException("Could not create extraction dir: " + outDir.getAbsolutePath());
      }
      // Encode APK identity in filename to prevent collisions between base/split for the same ABI
      // and to invalidate stale extractions when the APK is updated.
      final File out =
          new File(
              outDir,
              LIBRARY_FILE_NAME + "." + abi + "." + apkFile.getName() + "." + apkFile.lastModified());

      // Reuse cached extraction if it matches in size; otherwise re-extract.
      if (!out.exists() || out.length() != entry.getSize()) {
        final File tmp = new File(out.getAbsolutePath() + ".tmp");
        try (InputStream in = zip.getInputStream(entry);
            FileOutputStream os = new FileOutputStream(tmp)) {
          final byte[] buf = new byte[64 * 1024];
          int n;
          while ((n = in.read(buf)) > 0) {
            os.write(buf, 0, n);
          }
        }
        if (!tmp.renameTo(out)) {
          // renameTo can fail across some filesystems; fall back to delete+rename
          if (out.exists()) out.delete();
          if (!tmp.renameTo(out)) {
            throw new IOException(
                "Could not move extracted file " + tmp.getAbsolutePath() + " -> "
                    + out.getAbsolutePath());
          }
        }
      }

      // dlopen requires the file to be readable; some filesystems also require execute.
      //noinspection ResultOfMethodCallIgnored
      out.setReadable(true, /*ownerOnly=*/ false);
      //noinspection ResultOfMethodCallIgnored
      out.setExecutable(true, /*ownerOnly=*/ false);

      if (!out.canRead()) {
        throw new IOException("Extracted file is not readable: " + out.getAbsolutePath());
      }
      return out;
    }
  }

  /**
   * @return the directory in which extracted libraries are placed. Uses code cache (more durable
   *     than regular cache) on API 21+, falling back to regular cache otherwise.
   */
  @NonNull
  private File getExtractionDir() {
    if (Build.VERSION.SDK_INT >= 21) {
      final File codeCache = context.getCodeCacheDir();
      if (codeCache != null) {
        return new File(codeCache, "flutter-jni");
      }
    }
    return new File(context.getCacheDir(), "flutter-jni");
  }

  /** Scan an APK and return every ABI directory that contains {@code libflutter.so}. */
  @NonNull
  private Set<String> scanApkForAbis(@NonNull String apkPath) {
    final Set<String> abis = new LinkedHashSet<>();
    final File apkFile = new File(apkPath);
    if (!apkFile.exists() || !apkFile.canRead()) return abis;
    try (ZipFile zip = new ZipFile(apkFile)) {
      final Enumeration<? extends ZipEntry> entries = zip.entries();
      while (entries.hasMoreElements()) {
        final String name = entries.nextElement().getName();
        // Match exactly: lib/<abi>/libflutter.so (no nested directories).
        if (name.startsWith("lib/") && name.endsWith("/" + LIBRARY_FILE_NAME)) {
          final int abiStart = "lib/".length();
          final int abiEnd = name.length() - ("/" + LIBRARY_FILE_NAME).length();
          if (abiEnd > abiStart) {
            final String abi = name.substring(abiStart, abiEnd);
            // Reject if the "abi" itself contains a slash (nested dir).
            if (abi.indexOf('/') < 0) abis.add(abi);
          }
        }
      }
    } catch (IOException e) {
      Log.d(TAG, "Could not scan APK " + apkPath + ": " + e.getMessage());
    }
    return abis;
  }

  /** Best-effort listing of all {@code lib/...} entries in an APK for diagnostic output. */
  @NonNull
  private List<String> listLibEntries(@NonNull ZipFile zip) {
    final List<String> result = new ArrayList<>();
    final Enumeration<? extends ZipEntry> entries = zip.entries();
    while (entries.hasMoreElements()) {
      final String name = entries.nextElement().getName();
      if (name.startsWith("lib/")) result.add(name);
    }
    return result;
  }

  private void markLoaded() {
    flutterJNI.setLoaded();
  }

  private boolean loaded() {
    return flutterJNI.loadLibraryCalled();
  }

  /**
   * Build a comprehensive {@link UnsatisfiedLinkError} describing every search path that was
   * tried, every error encountered, and the relevant device/APK state.
   */
  @NonNull
  private UnsatisfiedLinkError buildDiagnosticError(
      @NonNull List<LoadAttempt> attempts, @NonNull ApplicationInfo appInfo) {
    final StringBuilder sb = new StringBuilder();
    sb.append("Could not load libflutter.so. All loading strategies failed.\n\n");

    // --- Device ---
    sb.append("=== DEVICE ===\n");
    sb.append("  os.arch=").append(System.getProperty("os.arch")).append("\n");
    sb.append("  Build.SUPPORTED_ABIS=").append(Arrays.toString(Build.SUPPORTED_ABIS)).append("\n");
    sb.append("  Build.CPU_ABI=").append(Build.CPU_ABI).append("\n");
    sb.append("  Build.CPU_ABI2=").append(Build.CPU_ABI2).append("\n");
    sb.append("  Build.VERSION.SDK_INT=").append(Build.VERSION.SDK_INT).append("\n");
    sb.append("  Build.MANUFACTURER=").append(Build.MANUFACTURER).append("\n");
    sb.append("  Build.MODEL=").append(Build.MODEL).append("\n");

    // --- nativeLibraryDir ---
    sb.append("\n=== nativeLibraryDir ===\n");
    final String nativeLibraryDir = flutterApplicationInfo.nativeLibraryDir;
    sb.append("  path=").append(nativeLibraryDir).append("\n");
    if (nativeLibraryDir != null) {
      final File dir = new File(nativeLibraryDir);
      sb.append("  exists=").append(dir.exists()).append("\n");
      if (dir.exists()) {
        sb.append("  isDirectory=").append(dir.isDirectory()).append("\n");
        sb.append("  canRead=").append(dir.canRead()).append("\n");
        final File[] files = dir.listFiles();
        if (files == null) {
          sb.append("  listFiles=null\n");
        } else if (files.length == 0) {
          sb.append("  contents=(empty)\n");
        } else {
          sb.append("  contents:\n");
          for (File f : files) {
            sb.append("    - ")
                .append(f.getName())
                .append(" (")
                .append(f.length())
                .append(" bytes, readable=")
                .append(f.canRead())
                .append(")\n");
          }
        }
      }
    }

    // --- APKs ---
    sb.append("\n=== APKs ===\n");
    appendApkInfo(sb, "base", appInfo.sourceDir);
    if (appInfo.splitSourceDirs != null) {
      for (int i = 0; i < appInfo.splitSourceDirs.length; i++) {
        appendApkInfo(sb, "split[" + i + "]", appInfo.splitSourceDirs[i]);
      }
    } else {
      sb.append("  (no split APKs)\n");
    }

    // --- Attempts ---
    sb.append("\n=== ATTEMPTS (").append(attempts.size()).append(") ===\n");
    for (int i = 0; i < attempts.size(); i++) {
      final LoadAttempt a = attempts.get(i);
      sb.append("  [").append(i + 1).append("] strategy=").append(a.strategy);
      if (a.target != null) sb.append(" target=").append(a.target);
      sb.append("\n      error=")
          .append(a.error.getClass().getName())
          .append(": ")
          .append(a.error.getMessage())
          .append("\n");
    }

    sb.append(
        "\nSee https://docs.flutter.dev/deployment/android#what-are-the-supported-target-architectures"
            + " — the most common cause is an APK that does not contain libflutter.so for this device's ABI.\n");
    sb.append("Tracking issue: https://github.com/flutter/flutter/issues/151638\n");

    final UnsatisfiedLinkError err = new UnsatisfiedLinkError(sb.toString());
    if (!attempts.isEmpty()) {
      err.initCause(attempts.get(0).error);
    }
    return err;
  }

  private void appendApkInfo(@NonNull StringBuilder sb, @NonNull String label, @Nullable String path) {
    sb.append("  ").append(label).append("=").append(path).append("\n");
    if (path == null) return;
    final File apk = new File(path);
    sb.append("      exists=").append(apk.exists());
    if (apk.exists()) {
      sb.append(" size=").append(apk.length()).append(" canRead=").append(apk.canRead());
    }
    sb.append("\n");
    if (apk.exists() && apk.canRead()) {
      try (ZipFile zip = new ZipFile(apk)) {
        final List<String> libs = listLibEntries(zip);
        if (libs.isEmpty()) {
          sb.append("      lib/ entries: (none)\n");
        } else {
          sb.append("      lib/ entries (").append(libs.size()).append("):\n");
          for (String s : libs) sb.append("        - ").append(s).append("\n");
        }
      } catch (IOException e) {
        sb.append("      (could not read APK: ").append(e.getMessage()).append(")\n");
      }
    }
  }

  /** A single load attempt, recorded for the eventual diagnostic error. */
  @VisibleForTesting
  static final class LoadAttempt {
    @NonNull final String strategy;
    @Nullable final String target;
    @NonNull final Throwable error;

    LoadAttempt(@NonNull String strategy, @Nullable String target, @NonNull Throwable error) {
      this.strategy = strategy;
      this.target = target;
      this.error = error;
    }
  }
}

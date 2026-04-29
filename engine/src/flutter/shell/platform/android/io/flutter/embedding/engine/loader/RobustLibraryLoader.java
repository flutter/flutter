// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.loader;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.os.Build;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.getkeepsafe.relinker.ReLinker;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

/**
 * Robust native library loader with multiple fallback strategies.
 *
 * Attempts to load libflutter.so using cascading fallbacks:
 * 1. ReLinker (optimized path for standard APKs)
 * 2. Manual extraction from main APK
 * 3. Search split APK directories
 * 4. Scan APK for all available ABIs (not just Build.SUPPORTED_ABIS)
 * 5. Comprehensive failure with diagnostic information
 */
public class RobustLibraryLoader {
  private static final String TAG = "RobustLibraryLoader";
  private static final String LIBRARY_NAME = "flutter";

  private final Context context;
  private final FlutterApplicationInfo flutterApplicationInfo;

  public RobustLibraryLoader(
      @NonNull Context context, @NonNull FlutterApplicationInfo flutterApplicationInfo) {
    this.context = context;
    this.flutterApplicationInfo = flutterApplicationInfo;
  }

  /**
   * Load libflutter.so with multiple fallback strategies.
   *
   * @throws UnsatisfiedLinkError if all loading strategies fail
   */
  public void loadLibrary() throws UnsatisfiedLinkError {
    List<LoadAttempt> attempts = new ArrayList<>();

    // Attempt 1: Standard ReLinker loading
    try {
      Log.d(TAG, "Attempt 1: Loading via ReLinker");
      ReLinker.log(msg -> Log.d(TAG, msg)).loadLibrary(context, LIBRARY_NAME);
      Log.i(TAG, "Successfully loaded libflutter.so via ReLinker");
      return;
    } catch (UnsatisfiedLinkError e) {
      Log.w(TAG, "ReLinker loading failed: " + e.getMessage());
      attempts.add(new LoadAttempt("ReLinker", e));
    }

    // Attempt 2: Manual extraction from main APK
    try {
      Log.d(TAG, "Attempt 2: Manual extraction from main APK");
      loadFromAPK(context.getApplicationInfo().sourceDir);
      Log.i(TAG, "Successfully loaded libflutter.so from main APK");
      return;
    } catch (Throwable e) {
      Log.w(TAG, "Main APK loading failed: " + e.getMessage());
      attempts.add(new LoadAttempt("Main APK extraction", e));
    }

    // Attempt 3: Search split APKs explicitly
    ApplicationInfo appInfo = context.getApplicationInfo();
    if (appInfo.splitSourceDirs != null && appInfo.splitSourceDirs.length > 0) {
      for (String splitDir : appInfo.splitSourceDirs) {
        try {
          Log.d(TAG, "Attempt 3: Searching split APK: " + splitDir);
          loadFromAPK(splitDir);
          Log.i(TAG, "Successfully loaded libflutter.so from split APK: " + splitDir);
          return;
        } catch (Throwable e) {
          Log.w(TAG, "Split APK loading failed (" + splitDir + "): " + e.getMessage());
          attempts.add(new LoadAttempt("Split APK: " + splitDir, e));
        }
      }
    }

    // Attempt 4: Scan APK for all available ABIs (not just Build.SUPPORTED_ABIS)
    Set<String> availableABIs = scanAPKForABIs(context.getApplicationInfo().sourceDir);
    for (String abi : availableABIs) {
      // Skip ABIs already tried in previous attempts
      if (Build.SUPPORTED_ABIS != null && contains(Build.SUPPORTED_ABIS, abi)) {
        continue;
      }
      try {
        Log.d(TAG, "Attempt 4: Trying available ABI not in Build.SUPPORTED_ABIS: " + abi);
        loadFromAPKWithABI(context.getApplicationInfo().sourceDir, abi);
        Log.i(TAG, "Successfully loaded libflutter.so using ABI: " + abi);
        return;
      } catch (Throwable e) {
        Log.w(TAG, "ABI loading failed (" + abi + "): " + e.getMessage());
        attempts.add(new LoadAttempt("ABI " + abi, e));
      }
    }

    // All attempts failed - throw comprehensive error
    throw createComprehensiveError(attempts, appInfo);
  }

  /**
   * Attempt to load library from a specific APK file.
   * Tries all supported ABIs.
   */
  private void loadFromAPK(@NonNull String apkPath) throws IOException, UnsatisfiedLinkError {
    String[] abis = Build.SUPPORTED_ABIS;
    if (abis == null || abis.length == 0) {
      throw new UnsatisfiedLinkError("No supported ABIs available");
    }

    for (String abi : abis) {
      try {
        loadFromAPKWithABI(apkPath, abi);
        return;
      } catch (Throwable e) {
        Log.d(TAG, "Failed to load from " + apkPath + " with ABI " + abi + ": " + e.getMessage());
      }
    }

    throw new UnsatisfiedLinkError(
        "Could not find libflutter.so in " + apkPath + " for any supported ABI");
  }

  /**
   * Attempt to load library from a specific APK with a specific ABI.
   */
  private void loadFromAPKWithABI(@NonNull String apkPath, @NonNull String abi)
      throws IOException, UnsatisfiedLinkError {
    try (ZipFile zipFile = new ZipFile(apkPath)) {
      String libPath = "lib" + File.separator + abi + File.separator + "lib" + LIBRARY_NAME + ".so";
      ZipEntry entry = zipFile.getEntry(libPath);

      if (entry == null) {
        throw new UnsatisfiedLinkError("Library entry not found in APK: " + libPath);
      }

      // Extract to app's cache directory
      File cacheDir = context.getCacheDir();
      File libFile = new File(cacheDir, "lib" + LIBRARY_NAME + "_" + abi + ".so");

      // Extract and load
      extractZipEntry(zipFile, entry, libFile);
      System.load(libFile.getAbsolutePath());

      Log.d(TAG, "Successfully loaded " + libFile.getAbsolutePath());
    }
  }

  /**
   * Extract a ZipEntry to a file and verify it's valid.
   */
  private void extractZipEntry(
      @NonNull ZipFile zipFile, @NonNull ZipEntry entry, @NonNull File outputFile)
      throws IOException {
    // Remove old version if it exists
    if (outputFile.exists()) {
      outputFile.delete();
    }

    byte[] buffer = new byte[8192];
    try (java.io.InputStream input = zipFile.getInputStream(entry);
        java.io.FileOutputStream output = new java.io.FileOutputStream(outputFile)) {
      int len;
      while ((len = input.read(buffer)) > 0) {
        output.write(buffer, 0, len);
      }
    }

    // Verify file exists and is readable
    if (!outputFile.exists() || !outputFile.canRead()) {
      throw new IOException("Extracted file is not readable: " + outputFile.getAbsolutePath());
    }
  }

  /**
   * Scan an APK file for all available ABIs (not just Build.SUPPORTED_ABIS).
   * This catches cases where APK has architectures not reported by the device.
   */
  @NonNull
  private Set<String> scanAPKForABIs(@NonNull String apkPath) {
    Set<String> abis = new HashSet<>();
    try (ZipFile zipFile = new ZipFile(apkPath)) {
      Enumeration<? extends ZipEntry> entries = zipFile.entries();
      while (entries.hasMoreElements()) {
        ZipEntry entry = entries.nextElement();
        String name = entry.getName();
        // Look for entries like "lib/arm64-v8a/libflutter.so"
        if (name.startsWith("lib/") && name.endsWith("/lib" + LIBRARY_NAME + ".so")) {
          String abi = name.substring(4, name.length() - ("lib" + LIBRARY_NAME + ".so").length() - 1);
          abis.add(abi);
          Log.d(TAG, "Found available ABI in APK: " + abi);
        }
      }
    } catch (IOException e) {
      Log.w(TAG, "Error scanning APK for ABIs: " + e.getMessage());
    }
    return abis;
  }

  /**
   * Create a comprehensive error message with all attempted paths and diagnostic info.
   */
  private UnsatisfiedLinkError createComprehensiveError(
      @NonNull List<LoadAttempt> attempts, @NonNull ApplicationInfo appInfo) {
    StringBuilder sb = new StringBuilder();
    sb.append("Could not load libflutter.so. All loading strategies failed:\n\n");

    // Device info
    sb.append("=== DEVICE INFO ===\n");
    sb.append("Supported ABIs: ");
    if (Build.SUPPORTED_ABIS != null) {
      for (String abi : Build.SUPPORTED_ABIS) {
        sb.append(abi).append(" ");
      }
    }
    sb.append("\nCPU Architecture: ").append(System.getProperty("os.arch")).append("\n");
    sb.append("API Level: ").append(Build.VERSION.SDK_INT).append("\n\n");

    // APK info
    sb.append("=== APK INFO ===\n");
    sb.append("Main APK: ").append(appInfo.sourceDir).append("\n");
    File mainApkFile = new File(appInfo.sourceDir);
    sb.append("Main APK exists: ").append(mainApkFile.exists()).append("\n");

    if (appInfo.splitSourceDirs != null && appInfo.splitSourceDirs.length > 0) {
      sb.append("Split APKs:\n");
      for (String split : appInfo.splitSourceDirs) {
        sb.append("  - ").append(split);
        sb.append(" (exists: ").append(new File(split).exists()).append(")\n");
      }
    } else {
      sb.append("No split APKs\n");
    }

    // Native library directory
    sb.append("\n=== NATIVE LIBRARY DIR ===\n");
    sb.append("Path: ").append(flutterApplicationInfo.nativeLibraryDir).append("\n");
    File nativeLibDir = new File(flutterApplicationInfo.nativeLibraryDir);
    sb.append("Exists: ").append(nativeLibDir.exists()).append("\n");
    if (nativeLibDir.exists() && nativeLibDir.isDirectory()) {
      File[] files = nativeLibDir.listFiles();
      if (files != null && files.length > 0) {
        sb.append("Contents:\n");
        for (File f : files) {
          sb.append("  - ").append(f.getName()).append("\n");
        }
      } else {
        sb.append("Directory is empty\n");
      }
    }

    // Scan for ABIs actually in APK
    sb.append("\n=== AVAILABLE ABIs IN APK ===\n");
    Set<String> availableABIs = scanAPKForABIs(appInfo.sourceDir);
    if (availableABIs.isEmpty()) {
      sb.append("No native libraries found in APK\n");
    } else {
      for (String abi : availableABIs) {
        sb.append("  - ").append(abi).append("\n");
      }
    }

    // Load attempts
    sb.append("\n=== LOAD ATTEMPTS ===\n");
    for (LoadAttempt attempt : attempts) {
      sb.append(attempt.strategy).append(": ").append(attempt.error.getMessage()).append("\n");
    }

    sb.append("\n=== RECOMMENDATION ===\n");
    sb.append(
        "Check that your app is built for the correct architecture(s) "
            + "and that the AAB includes native libraries for the device's ABI.\n");
    sb.append("See: https://docs.flutter.dev/deployment/android#what-are-the-supported-target-architectures\n");

    return new UnsatisfiedLinkError(sb.toString());
  }

  /**
   * Helper to check if array contains value.
   */
  private boolean contains(@NonNull String[] array, @NonNull String value) {
    for (String item : array) {
      if (item.equals(value)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Record of a single load attempt for error reporting.
   */
  private static class LoadAttempt {
    final String strategy;
    final Throwable error;

    LoadAttempt(@NonNull String strategy, @NonNull Throwable error) {
      this.strategy = strategy;
      this.error = error;
    }
  }
}

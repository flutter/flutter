// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.content.Context;
import android.os.Handler;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import io.flutter.embedding.engine.loader.FlutterLoader;

/**
 * A legacy class to initialize the Flutter engine.
 *
 * <p>Replaced by {@link io.flutter.embedding.engine.loader.FlutterLoader}.
 */
public class FlutterMain {

  public static class Settings {
    private String logTag;

    @Nullable
    public String getLogTag() {
      return logTag;
    }

    /**
     * Set the tag associated with Flutter app log messages.
     *
     * @param tag Log tag.
     */
    public void setLogTag(String tag) {
      logTag = tag;
    }
  }

  /**
   * Starts initialization of the native system.
   *
   * @param applicationContext The Android application context.
   */
  public static void startInitialization(@NonNull Context applicationContext) {
    if (isRunningInRobolectricTest) {
      return;
    }
    FlutterLoader.getInstance().startInitialization(applicationContext);
  }

  /**
   * Starts initialization of the native system.
   *
   * <p>This loads the Flutter engine's native library to enable subsequent JNI calls. This also
   * starts locating and unpacking Dart resources packaged in the app's APK.
   *
   * <p>Calling this method multiple times has no effect.
   *
   * @param applicationContext The Android application context.
   * @param settings Configuration settings.
   */
  public static void startInitialization(
      @NonNull Context applicationContext, @NonNull Settings settings) {
    if (isRunningInRobolectricTest) {
      return;
    }
    FlutterLoader.Settings newSettings = new FlutterLoader.Settings();
    newSettings.setLogTag(settings.getLogTag());
    FlutterLoader.getInstance().startInitialization(applicationContext, newSettings);
  }

  /**
   * Blocks until initialization of the native system has completed.
   *
   * <p>Calling this method multiple times has no effect.
   *
   * @param applicationContext The Android application context.
   * @param args Flags sent to the Flutter runtime.
   */
  public static void ensureInitializationComplete(
      @NonNull Context applicationContext, @Nullable String[] args) {
    if (isRunningInRobolectricTest) {
      return;
    }
    FlutterLoader.getInstance().ensureInitializationComplete(applicationContext, args);
  }

  /**
   * Same as {@link #ensureInitializationComplete(Context, String[])} but waiting on a background
   * thread, then invoking {@code callback} on the {@code callbackHandler}.
   */
  public static void ensureInitializationCompleteAsync(
      @NonNull Context applicationContext,
      @Nullable String[] args,
      @NonNull Handler callbackHandler,
      @NonNull Runnable callback) {
    if (isRunningInRobolectricTest) {
      return;
    }
    FlutterLoader.getInstance()
        .ensureInitializationCompleteAsync(applicationContext, args, callbackHandler, callback);
  }

  @NonNull
  public static String findAppBundlePath() {
    return FlutterLoader.getInstance().findAppBundlePath();
  }

  @Deprecated
  @Nullable
  public static String findAppBundlePath(@NonNull Context applicationContext) {
    return FlutterLoader.getInstance().findAppBundlePath();
  }

  /**
   * Returns the file name for the given asset. The returned file name can be used to access the
   * asset in the APK through the {@link android.content.res.AssetManager} API.
   *
   * @param asset the name of the asset. The name can be hierarchical
   * @return the filename to be used with {@link android.content.res.AssetManager}
   */
  @NonNull
  public static String getLookupKeyForAsset(@NonNull String asset) {
    return FlutterLoader.getInstance().getLookupKeyForAsset(asset);
  }

  /**
   * Returns the file name for the given asset which originates from the specified packageName. The
   * returned file name can be used to access the asset in the APK through the {@link
   * android.content.res.AssetManager} API.
   *
   * @param asset the name of the asset. The name can be hierarchical
   * @param packageName the name of the package from which the asset originates
   * @return the file name to be used with {@link android.content.res.AssetManager}
   */
  @NonNull
  public static String getLookupKeyForAsset(@NonNull String asset, @NonNull String packageName) {
    return FlutterLoader.getInstance().getLookupKeyForAsset(asset, packageName);
  }

  private static boolean isRunningInRobolectricTest = false;

  /*
   * Indicates whether we are currently running in a Robolectric Test.
   *
   * <p> Flutter cannot be initialized inside a Robolectric environment since it cannot load
   * native libraries.
   *
   * @deprecated Use the new embedding (io.flutter.embedding) instead which provides better
   *     modularity for testing.
   */
  @Deprecated
  @VisibleForTesting
  public static void setIsRunningInRobolectricTest(boolean isRunningInRobolectricTest) {
    FlutterMain.isRunningInRobolectricTest = isRunningInRobolectricTest;
  }
}

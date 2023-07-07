// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.content.res.AssetManager;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.PluginRegistry;
import java.io.IOException;

/** Provides access to the assets registered as part of the App bundle. */
@SuppressWarnings({"deprecation", "DeprecatedIsStillUsed"})
abstract class FlutterAssetManager {
  final AssetManager assetManager;

  /**
   * Constructs a new instance of the {@link FlutterAssetManager}.
   *
   * @param assetManager Instance of Android's {@link AssetManager} used to access assets within the
   *     App bundle.
   */
  public FlutterAssetManager(AssetManager assetManager) {
    this.assetManager = assetManager;
  }

  /**
   * Gets the relative file path to the Flutter asset with the given name, including the file's
   * extension, e.g., "myImage.jpg".
   *
   * <p>The returned file path is relative to the Android app's standard asset's directory.
   * Therefore, the returned path is appropriate to pass to Android's AssetManager, but the path is
   * not appropriate to load as an absolute path.
   */
  abstract String getAssetFilePathByName(String name);

  /**
   * Returns a String array of all the assets at the given path.
   *
   * @param path A relative path within the assets, i.e., "docs/home.html". This value cannot be
   *     null.
   * @return String[] Array of strings, one for each asset. These file names are relative to 'path'.
   *     This value may be null.
   * @throws IOException Throws an IOException in case I/O operations were interrupted.
   */
  public String[] list(@NonNull String path) throws IOException {
    return assetManager.list(path);
  }

  /**
   * Provides access to assets using the {@link PluginRegistry.Registrar} for looking up file paths
   * to Flutter assets.
   *
   * @deprecated The {@link RegistrarFlutterAssetManager} is for Flutter's v1 embedding. For
   *     instructions on migrating a plugin from Flutter's v1 Android embedding to v2, visit
   *     http://flutter.dev/go/android-plugin-migration
   */
  @Deprecated
  static class RegistrarFlutterAssetManager extends FlutterAssetManager {
    final PluginRegistry.Registrar registrar;

    /**
     * Constructs a new instance of the {@link RegistrarFlutterAssetManager}.
     *
     * @param assetManager Instance of Android's {@link AssetManager} used to access assets within
     *     the App bundle.
     * @param registrar Instance of {@link io.flutter.plugin.common.PluginRegistry.Registrar} used
     *     to look up file paths to assets registered by Flutter.
     */
    RegistrarFlutterAssetManager(AssetManager assetManager, PluginRegistry.Registrar registrar) {
      super(assetManager);
      this.registrar = registrar;
    }

    @Override
    public String getAssetFilePathByName(String name) {
      return registrar.lookupKeyForAsset(name);
    }
  }

  /**
   * Provides access to assets using the {@link FlutterPlugin.FlutterAssets} for looking up file
   * paths to Flutter assets.
   */
  static class PluginBindingFlutterAssetManager extends FlutterAssetManager {
    final FlutterPlugin.FlutterAssets flutterAssets;

    /**
     * Constructs a new instance of the {@link PluginBindingFlutterAssetManager}.
     *
     * @param assetManager Instance of Android's {@link AssetManager} used to access assets within
     *     the App bundle.
     * @param flutterAssets Instance of {@link
     *     io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterAssets} used to look up file
     *     paths to assets registered by Flutter.
     */
    PluginBindingFlutterAssetManager(
        AssetManager assetManager, FlutterPlugin.FlutterAssets flutterAssets) {
      super(assetManager);
      this.flutterAssets = flutterAssets;
    }

    @Override
    public String getAssetFilePathByName(String name) {
      return flutterAssets.getAssetFilePathByName(name);
    }
  }
}

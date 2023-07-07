// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.webkit.WebView;
import androidx.annotation.NonNull;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.FlutterAssetManagerHostApi;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * Host api implementation for {@link WebView}.
 *
 * <p>Handles creating {@link WebView}s that intercommunicate with a paired Dart object.
 */
public class FlutterAssetManagerHostApiImpl implements FlutterAssetManagerHostApi {
  final FlutterAssetManager flutterAssetManager;

  /** Constructs a new instance of {@link FlutterAssetManagerHostApiImpl}. */
  public FlutterAssetManagerHostApiImpl(@NonNull FlutterAssetManager flutterAssetManager) {
    this.flutterAssetManager = flutterAssetManager;
  }

  @NonNull
  @Override
  public List<String> list(@NonNull String path) {
    try {
      String[] paths = flutterAssetManager.list(path);

      if (paths == null) {
        return new ArrayList<>();
      }

      return Arrays.asList(paths);
    } catch (IOException ex) {
      throw new RuntimeException(ex.getMessage());
    }
  }

  @NonNull
  @Override
  public String getAssetFilePathByName(@NonNull String name) {
    return flutterAssetManager.getAssetFilePathByName(name);
  }
}

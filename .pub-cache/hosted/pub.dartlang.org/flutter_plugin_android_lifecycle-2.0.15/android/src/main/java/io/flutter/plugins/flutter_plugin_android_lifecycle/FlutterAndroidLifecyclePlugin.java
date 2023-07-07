// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
package io.flutter.plugins.flutter_plugin_android_lifecycle;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;

/**
 * Plugin class that exists because the Flutter tool expects such a class to exist for every Android
 * plugin.
 *
 * <p><strong>DO NOT USE THIS CLASS.</strong>
 */
public class FlutterAndroidLifecyclePlugin implements FlutterPlugin {
  @SuppressWarnings("deprecation")
  public static void registerWith(
      @NonNull io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
    // no-op
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    // no-op
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    // no-op
  }
}

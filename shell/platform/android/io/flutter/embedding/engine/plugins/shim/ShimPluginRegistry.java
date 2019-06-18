// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.plugins.shim;

import android.app.Activity;
import android.support.annotation.NonNull;

import java.util.HashMap;
import java.util.Map;

import io.flutter.Log;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.platform.PlatformViewsController;
import io.flutter.view.FlutterView;

/**
 * A {@link PluginRegistry} that is shimmed to use the new Android embedding and plugin API behind
 * the scenes.
 * <p>
 * The following is an example usage of {@code ShimPluginRegistry} within a {@code FlutterActivity}:
 * {@code
 *   // Create the FlutterEngine that will back the Flutter UI.
 *   FlutterEngine flutterEngine = new FlutterEngine(context);
 *
 *   // Create a ShimPluginRegistry and wrap the FlutterEngine with the shim.
 *   ShimPluginRegistry shimPluginRegistry = new ShimPluginRegistry(flutterEngine, platformViewsController);
 *
 *   // Use the GeneratedPluginRegistrant to add every plugin that's in the pubspec.
 *   GeneratedPluginRegistrant.registerWith(shimPluginRegistry);
 * }
 */
public class ShimPluginRegistry implements PluginRegistry {
  private static final String TAG = "ShimPluginRegistry";

  private final FlutterEngine flutterEngine;
  private final PlatformViewsController platformViewsController;
  private final Map<String, Object> pluginMap = new HashMap<>();
  private final FlutterEngine.EngineLifecycleListener engineLifecycleListener = new FlutterEngine.EngineLifecycleListener() {
    @Override
    public void onPreEngineRestart() {
      Log.v(TAG, "onPreEngineRestart()");
      ShimPluginRegistry.this.onPreEngineRestart();
    }
  };

  public ShimPluginRegistry(
      @NonNull FlutterEngine flutterEngine,
      @NonNull PlatformViewsController platformViewsController
  ) {
    this.flutterEngine = flutterEngine;
    this.flutterEngine.addEngineLifecycleListener(engineLifecycleListener);
    this.platformViewsController = platformViewsController;
  }

  @Override
  public Registrar registrarFor(String pluginKey) {
    Log.v(TAG, "Creating plugin Registrar for '" + pluginKey + "'");
    if (pluginMap.containsKey(pluginKey)) {
      throw new IllegalStateException("Plugin key " + pluginKey + " is already in use");
    }
    pluginMap.put(pluginKey, null);
    ShimRegistrar registrar = new ShimRegistrar(pluginKey, pluginMap);
    flutterEngine.getPlugins().add(registrar);
    return registrar;
  }

  @Override
  public boolean hasPlugin(String pluginKey) {
    return pluginMap.containsKey(pluginKey);
  }

  @Override
  @SuppressWarnings("unchecked")
  public <T> T valuePublishedByPlugin(String pluginKey) {
    return (T) pluginMap.get(pluginKey);
  }

  //----- From FlutterPluginRegistry that aren't in the PluginRegistry interface ----//
  public void attach(FlutterView flutterView, Activity activity) {
    Log.v(TAG, "Attaching to a FlutterView and an Activity.");
    platformViewsController.attach(activity, flutterEngine.getRenderer(), flutterEngine.getDartExecutor());
  }

  public void detach() {
    Log.v(TAG, "Detaching from a FlutterView and an Activity.");
    platformViewsController.detach();
    platformViewsController.onFlutterViewDestroyed();
  }

  private void onPreEngineRestart() {
    platformViewsController.onPreEngineRestart();
  }

  public PlatformViewsController getPlatformViewsController() {
    return platformViewsController;
  }
}

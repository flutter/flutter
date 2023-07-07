// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.connectivity;

import android.content.Context;
import android.net.ConnectivityManager;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

/** ConnectivityPlugin */
public class ConnectivityPlugin implements FlutterPlugin {

  private MethodChannel methodChannel;
  private EventChannel eventChannel;

  /** Plugin registration. */
  @SuppressWarnings("deprecation")
  public static void registerWith(io.flutter.plugin.common.PluginRegistry.Registrar registrar) {

    ConnectivityPlugin plugin = new ConnectivityPlugin();
    plugin.setupChannels(registrar.messenger(), registrar.context());
  }

  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    setupChannels(binding.getBinaryMessenger(), binding.getApplicationContext());
  }

  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {
    teardownChannels();
  }

  private void setupChannels(BinaryMessenger messenger, Context context) {
    methodChannel = new MethodChannel(messenger, "plugins.flutter.io/connectivity");
    eventChannel = new EventChannel(messenger, "plugins.flutter.io/connectivity_status");
    ConnectivityManager connectivityManager =
        (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);

    Connectivity connectivity = new Connectivity(connectivityManager);

    ConnectivityMethodChannelHandler methodChannelHandler =
        new ConnectivityMethodChannelHandler(connectivity);
    ConnectivityBroadcastReceiver receiver =
        new ConnectivityBroadcastReceiver(context, connectivity);

    methodChannel.setMethodCallHandler(methodChannelHandler);
    eventChannel.setStreamHandler(receiver);
  }

  private void teardownChannels() {
    methodChannel.setMethodCallHandler(null);
    eventChannel.setStreamHandler(null);
    methodChannel = null;
    eventChannel = null;
  }
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.deviceinfo;

import android.content.Context;
import android.util.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodCodec;
import io.flutter.plugin.common.StandardMethodCodec;
import java.lang.reflect.Constructor;
import java.lang.reflect.Method;

/** DeviceInfoPlugin */
public class DeviceInfoPlugin implements FlutterPlugin {
  static final String TAG = "DeviceInfoPlugin";
  MethodChannel channel;

  /** Plugin registration. */
  @SuppressWarnings("deprecation")
  public static void registerWith(io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
    DeviceInfoPlugin plugin = new DeviceInfoPlugin();
    plugin.setupMethodChannel(registrar.messenger(), registrar.context());
  }

  @Override
  public void onAttachedToEngine(FlutterPlugin.FlutterPluginBinding binding) {
    setupMethodChannel(binding.getBinaryMessenger(), binding.getApplicationContext());
  }

  @Override
  public void onDetachedFromEngine(FlutterPlugin.FlutterPluginBinding binding) {
    tearDownChannel();
  }

  private void setupMethodChannel(BinaryMessenger messenger, Context context) {
    String channelName = "plugins.flutter.io/device_info";
    // TODO(gaaclarke): Remove reflection guard when https://github.com/flutter/engine/pull/29147
    // becomes available on the stable branch.
    try {
      Class methodChannelClass = Class.forName("io.flutter.plugin.common.MethodChannel");
      Class taskQueueClass = Class.forName("io.flutter.plugin.common.BinaryMessenger$TaskQueue");
      Method makeBackgroundTaskQueue = messenger.getClass().getMethod("makeBackgroundTaskQueue");
      Object taskQueue = makeBackgroundTaskQueue.invoke(messenger);
      Constructor<MethodChannel> constructor =
          methodChannelClass.getConstructor(
              BinaryMessenger.class, String.class, MethodCodec.class, taskQueueClass);
      channel =
          constructor.newInstance(messenger, channelName, StandardMethodCodec.INSTANCE, taskQueue);
      Log.d(TAG, "Use TaskQueues.");
    } catch (Exception ex) {
      channel = new MethodChannel(messenger, channelName);
      Log.d(TAG, "Don't use TaskQueues.");
    }
    final MethodCallHandlerImpl handler =
        new MethodCallHandlerImpl(context.getContentResolver(), context.getPackageManager());
    channel.setMethodCallHandler(handler);
  }

  private void tearDownChannel() {
    channel.setMethodCallHandler(null);
    channel = null;
  }
}

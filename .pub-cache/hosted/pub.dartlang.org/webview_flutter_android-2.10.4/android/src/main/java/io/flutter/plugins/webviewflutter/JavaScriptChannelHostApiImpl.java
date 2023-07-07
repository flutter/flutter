// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.os.Handler;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.JavaScriptChannelHostApi;

/**
 * Host api implementation for {@link JavaScriptChannel}.
 *
 * <p>Handles creating {@link JavaScriptChannel}s that intercommunicate with a paired Dart object.
 */
public class JavaScriptChannelHostApiImpl implements JavaScriptChannelHostApi {
  private final InstanceManager instanceManager;
  private final JavaScriptChannelCreator javaScriptChannelCreator;
  private final JavaScriptChannelFlutterApiImpl flutterApi;

  private Handler platformThreadHandler;

  /** Handles creating {@link JavaScriptChannel}s for a {@link JavaScriptChannelHostApiImpl}. */
  public static class JavaScriptChannelCreator {
    /**
     * Creates a {@link JavaScriptChannel}.
     *
     * @param flutterApi handles sending messages to Dart
     * @param channelName JavaScript channel the message should be sent through
     * @param platformThreadHandler handles making callbacks on the desired thread
     * @return the created {@link JavaScriptChannel}
     */
    public JavaScriptChannel createJavaScriptChannel(
        JavaScriptChannelFlutterApiImpl flutterApi,
        String channelName,
        Handler platformThreadHandler) {
      return new JavaScriptChannel(flutterApi, channelName, platformThreadHandler);
    }
  }

  /**
   * Creates a host API that handles creating {@link JavaScriptChannel}s.
   *
   * @param instanceManager maintains instances stored to communicate with Dart objects
   * @param javaScriptChannelCreator handles creating {@link JavaScriptChannel}s
   * @param flutterApi handles sending messages to Dart
   * @param platformThreadHandler handles making callbacks on the desired thread
   */
  public JavaScriptChannelHostApiImpl(
      InstanceManager instanceManager,
      JavaScriptChannelCreator javaScriptChannelCreator,
      JavaScriptChannelFlutterApiImpl flutterApi,
      Handler platformThreadHandler) {
    this.instanceManager = instanceManager;
    this.javaScriptChannelCreator = javaScriptChannelCreator;
    this.flutterApi = flutterApi;
    this.platformThreadHandler = platformThreadHandler;
  }

  /**
   * Sets the platformThreadHandler to make callbacks
   *
   * @param platformThreadHandler the new thread handler
   */
  public void setPlatformThreadHandler(Handler platformThreadHandler) {
    this.platformThreadHandler = platformThreadHandler;
  }

  @Override
  public void create(Long instanceId, String channelName) {
    final JavaScriptChannel javaScriptChannel =
        javaScriptChannelCreator.createJavaScriptChannel(
            flutterApi, channelName, platformThreadHandler);
    instanceManager.addDartCreatedInstance(javaScriptChannel, instanceId);
  }
}

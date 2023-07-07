// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import androidx.annotation.NonNull;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.JavaScriptChannelFlutterApi;

/**
 * Flutter Api implementation for {@link JavaScriptChannel}.
 *
 * <p>Passes arguments of callbacks methods from a {@link JavaScriptChannel} to Dart.
 */
public class JavaScriptChannelFlutterApiImpl extends JavaScriptChannelFlutterApi {
  private final InstanceManager instanceManager;

  /**
   * Creates a Flutter api that sends messages to Dart.
   *
   * @param binaryMessenger Handles sending messages to Dart.
   * @param instanceManager Maintains instances stored to communicate with Dart objects.
   */
  public JavaScriptChannelFlutterApiImpl(
      @NonNull BinaryMessenger binaryMessenger, @NonNull InstanceManager instanceManager) {
    super(binaryMessenger);
    this.instanceManager = instanceManager;
  }

  /** Passes arguments from {@link JavaScriptChannel#postMessage} to Dart. */
  public void postMessage(
      @NonNull JavaScriptChannel javaScriptChannel,
      @NonNull String messageArg,
      @NonNull Reply<Void> callback) {
    super.postMessage(getIdentifierForJavaScriptChannel(javaScriptChannel), messageArg, callback);
  }

  private long getIdentifierForJavaScriptChannel(JavaScriptChannel javaScriptChannel) {
    final Long identifier = instanceManager.getIdentifierForStrongReference(javaScriptChannel);
    if (identifier == null) {
      throw new IllegalStateException("Could not find identifier for JavaScriptChannel.");
    }
    return identifier;
  }
}

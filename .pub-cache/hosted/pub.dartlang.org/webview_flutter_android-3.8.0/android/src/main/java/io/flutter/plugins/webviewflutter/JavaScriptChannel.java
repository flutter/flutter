// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.os.Handler;
import android.os.Looper;
import android.webkit.JavascriptInterface;
import androidx.annotation.NonNull;

/**
 * Added as a JavaScript interface to the WebView for any JavaScript channel that the Dart code sets
 * up.
 *
 * <p>Exposes a single method named `postMessage` to JavaScript, which sends a message to the Dart
 * code.
 */
public class JavaScriptChannel {
  private final Handler platformThreadHandler;
  final String javaScriptChannelName;
  private final JavaScriptChannelFlutterApiImpl flutterApi;

  /**
   * Creates a {@link JavaScriptChannel} that passes arguments of callback methods to Dart.
   *
   * @param flutterApi the Flutter Api to which JS messages are sent
   * @param channelName JavaScript channel the message was sent through
   * @param platformThreadHandler handles making callbacks on the desired thread
   */
  public JavaScriptChannel(
      @NonNull JavaScriptChannelFlutterApiImpl flutterApi,
      @NonNull String channelName,
      @NonNull Handler platformThreadHandler) {
    this.flutterApi = flutterApi;
    this.javaScriptChannelName = channelName;
    this.platformThreadHandler = platformThreadHandler;
  }

  // Suppressing unused warning as this is invoked from JavaScript.
  @SuppressWarnings("unused")
  @JavascriptInterface
  public void postMessage(@NonNull final String message) {
    final Runnable postMessageRunnable =
        () -> flutterApi.postMessage(JavaScriptChannel.this, message, reply -> {});

    if (platformThreadHandler.getLooper() == Looper.myLooper()) {
      postMessageRunnable.run();
    } else {
      platformThreadHandler.post(postMessageRunnable);
    }
  }
}

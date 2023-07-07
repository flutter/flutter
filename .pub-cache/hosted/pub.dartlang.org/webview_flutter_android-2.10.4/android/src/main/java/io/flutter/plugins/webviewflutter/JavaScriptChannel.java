// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.os.Handler;
import android.os.Looper;
import android.webkit.JavascriptInterface;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

/**
 * Added as a JavaScript interface to the WebView for any JavaScript channel that the Dart code sets
 * up.
 *
 * <p>Exposes a single method named `postMessage` to JavaScript, which sends a message to the Dart
 * code.
 *
 * <p>No messages are sent to Dart after {@link JavaScriptChannel#release} is called.
 */
public class JavaScriptChannel implements Releasable {
  private final Handler platformThreadHandler;
  final String javaScriptChannelName;
  @Nullable private JavaScriptChannelFlutterApiImpl flutterApi;

  /**
   * Creates a {@link JavaScriptChannel} that passes arguments of callback methods to Dart.
   *
   * @param flutterApi the Flutter Api to which JS messages are sent
   * @param channelName JavaScript channel the message was sent through
   * @param platformThreadHandler handles making callbacks on the desired thread
   */
  public JavaScriptChannel(
      @NonNull JavaScriptChannelFlutterApiImpl flutterApi,
      String channelName,
      Handler platformThreadHandler) {
    this.flutterApi = flutterApi;
    this.javaScriptChannelName = channelName;
    this.platformThreadHandler = platformThreadHandler;
  }

  // Suppressing unused warning as this is invoked from JavaScript.
  @SuppressWarnings("unused")
  @JavascriptInterface
  public void postMessage(final String message) {
    final Runnable postMessageRunnable =
        () -> {
          if (flutterApi != null) {
            flutterApi.postMessage(JavaScriptChannel.this, message, reply -> {});
          }
        };

    if (platformThreadHandler.getLooper() == Looper.myLooper()) {
      postMessageRunnable.run();
    } else {
      platformThreadHandler.post(postMessageRunnable);
    }
  }

  @Override
  public void release() {
    if (flutterApi != null) {
      flutterApi.dispose(this, reply -> {});
    }
    flutterApi = null;
  }
}

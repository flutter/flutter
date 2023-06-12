// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.urllauncher;

import android.os.Bundle;
import android.util.Log;
import androidx.annotation.Nullable;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugins.urllauncher.UrlLauncher.LaunchStatus;
import java.util.Map;

/**
 * Translates incoming UrlLauncher MethodCalls into well formed Java function calls for {@link
 * UrlLauncher}.
 */
final class MethodCallHandlerImpl implements MethodCallHandler {
  private static final String TAG = "MethodCallHandlerImpl";
  private final UrlLauncher urlLauncher;
  @Nullable private MethodChannel channel;

  /** Forwards all incoming MethodChannel calls to the given {@code urlLauncher}. */
  MethodCallHandlerImpl(UrlLauncher urlLauncher) {
    this.urlLauncher = urlLauncher;
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    final String url = call.argument("url");
    switch (call.method) {
      case "canLaunch":
        onCanLaunch(result, url);
        break;
      case "launch":
        onLaunch(call, result, url);
        break;
      case "closeWebView":
        onCloseWebView(result);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  /**
   * Registers this instance as a method call handler on the given {@code messenger}.
   *
   * <p>Stops any previously started and unstopped calls.
   *
   * <p>This should be cleaned with {@link #stopListening} once the messenger is disposed of.
   */
  void startListening(BinaryMessenger messenger) {
    if (channel != null) {
      Log.wtf(TAG, "Setting a method call handler before the last was disposed.");
      stopListening();
    }

    channel = new MethodChannel(messenger, "plugins.flutter.io/url_launcher_android");
    channel.setMethodCallHandler(this);
  }

  /**
   * Clears this instance from listening to method calls.
   *
   * <p>Does nothing if {@link #startListening} hasn't been called, or if we're already stopped.
   */
  void stopListening() {
    if (channel == null) {
      Log.d(TAG, "Tried to stop listening when no MethodChannel had been initialized.");
      return;
    }

    channel.setMethodCallHandler(null);
    channel = null;
  }

  private void onCanLaunch(Result result, String url) {
    result.success(urlLauncher.canLaunch(url));
  }

  private void onLaunch(MethodCall call, Result result, String url) {
    final boolean useWebView = call.argument("useWebView");
    final boolean enableJavaScript = call.argument("enableJavaScript");
    final boolean enableDomStorage = call.argument("enableDomStorage");
    final Map<String, String> headersMap = call.argument("headers");
    final Bundle headersBundle = extractBundle(headersMap);

    LaunchStatus launchStatus =
        urlLauncher.launch(url, headersBundle, useWebView, enableJavaScript, enableDomStorage);

    if (launchStatus == LaunchStatus.NO_ACTIVITY) {
      result.error("NO_ACTIVITY", "Launching a URL requires a foreground activity.", null);
    } else if (launchStatus == LaunchStatus.ACTIVITY_NOT_FOUND) {
      result.error(
          "ACTIVITY_NOT_FOUND",
          String.format("No Activity found to handle intent { %s }", url),
          null);
    } else {
      result.success(true);
    }
  }

  private void onCloseWebView(Result result) {
    urlLauncher.closeWebView();
    result.success(null);
  }

  private static Bundle extractBundle(Map<String, String> headersMap) {
    final Bundle headersBundle = new Bundle();
    for (String key : headersMap.keySet()) {
      final String value = headersMap.get(key);
      headersBundle.putString(key, value);
    }
    return headersBundle;
  }
}

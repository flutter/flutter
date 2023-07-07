// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.webkit.WebChromeClient;
import android.webkit.WebView;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.WebChromeClientFlutterApi;

/**
 * Flutter Api implementation for {@link WebChromeClient}.
 *
 * <p>Passes arguments of callbacks methods from a {@link WebChromeClient} to Dart.
 */
public class WebChromeClientFlutterApiImpl extends WebChromeClientFlutterApi {
  private final InstanceManager instanceManager;

  /**
   * Creates a Flutter api that sends messages to Dart.
   *
   * @param binaryMessenger handles sending messages to Dart
   * @param instanceManager maintains instances stored to communicate with Dart objects
   */
  public WebChromeClientFlutterApiImpl(
      BinaryMessenger binaryMessenger, InstanceManager instanceManager) {
    super(binaryMessenger);
    this.instanceManager = instanceManager;
  }

  /** Passes arguments from {@link WebChromeClient#onProgressChanged} to Dart. */
  public void onProgressChanged(
      WebChromeClient webChromeClient, WebView webView, Long progress, Reply<Void> callback) {
    final Long webViewIdentifier = instanceManager.getIdentifierForStrongReference(webView);
    if (webViewIdentifier == null) {
      throw new IllegalStateException("Could not find identifier for WebView.");
    }
    super.onProgressChanged(
        getIdentifierForClient(webChromeClient), webViewIdentifier, progress, callback);
  }

  /**
   * Communicates to Dart that the reference to a {@link WebChromeClient}} was removed.
   *
   * @param webChromeClient the instance whose reference will be removed
   * @param callback reply callback with return value from Dart
   */
  public void dispose(WebChromeClient webChromeClient, Reply<Void> callback) {
    if (instanceManager.containsInstance(webChromeClient)) {
      dispose(getIdentifierForClient(webChromeClient), callback);
    } else {
      callback.reply(null);
    }
  }

  private long getIdentifierForClient(WebChromeClient webChromeClient) {
    final Long identifier = instanceManager.getIdentifierForStrongReference(webChromeClient);
    if (identifier == null) {
      throw new IllegalStateException("Could not find identifier for WebChromeClient.");
    }
    return identifier;
  }
}

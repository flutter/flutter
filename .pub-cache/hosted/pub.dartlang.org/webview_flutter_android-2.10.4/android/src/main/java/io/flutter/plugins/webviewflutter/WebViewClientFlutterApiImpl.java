// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.annotation.SuppressLint;
import android.os.Build;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import androidx.annotation.RequiresApi;
import androidx.webkit.WebResourceErrorCompat;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.WebViewClientFlutterApi;
import java.util.HashMap;

/**
 * Flutter Api implementation for {@link WebViewClient}.
 *
 * <p>Passes arguments of callbacks methods from a {@link WebViewClient} to Dart.
 */
public class WebViewClientFlutterApiImpl extends WebViewClientFlutterApi {
  private final InstanceManager instanceManager;

  @RequiresApi(api = Build.VERSION_CODES.M)
  static GeneratedAndroidWebView.WebResourceErrorData createWebResourceErrorData(
      WebResourceError error) {
    return new GeneratedAndroidWebView.WebResourceErrorData.Builder()
        .setErrorCode((long) error.getErrorCode())
        .setDescription(error.getDescription().toString())
        .build();
  }

  @SuppressLint("RequiresFeature")
  static GeneratedAndroidWebView.WebResourceErrorData createWebResourceErrorData(
      WebResourceErrorCompat error) {
    return new GeneratedAndroidWebView.WebResourceErrorData.Builder()
        .setErrorCode((long) error.getErrorCode())
        .setDescription(error.getDescription().toString())
        .build();
  }

  @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
  static GeneratedAndroidWebView.WebResourceRequestData createWebResourceRequestData(
      WebResourceRequest request) {
    final GeneratedAndroidWebView.WebResourceRequestData.Builder requestData =
        new GeneratedAndroidWebView.WebResourceRequestData.Builder()
            .setUrl(request.getUrl().toString())
            .setIsForMainFrame(request.isForMainFrame())
            .setHasGesture(request.hasGesture())
            .setMethod(request.getMethod())
            .setRequestHeaders(
                request.getRequestHeaders() != null
                    ? request.getRequestHeaders()
                    : new HashMap<>());
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
      requestData.setIsRedirect(request.isRedirect());
    }

    return requestData.build();
  }

  /**
   * Creates a Flutter api that sends messages to Dart.
   *
   * @param binaryMessenger handles sending messages to Dart
   * @param instanceManager maintains instances stored to communicate with Dart objects
   */
  public WebViewClientFlutterApiImpl(
      BinaryMessenger binaryMessenger, InstanceManager instanceManager) {
    super(binaryMessenger);
    this.instanceManager = instanceManager;
  }

  /** Passes arguments from {@link WebViewClient#onPageStarted} to Dart. */
  public void onPageStarted(
      WebViewClient webViewClient, WebView webView, String urlArg, Reply<Void> callback) {
    final Long webViewIdentifier = instanceManager.getIdentifierForStrongReference(webView);
    if (webViewIdentifier == null) {
      throw new IllegalStateException("Could not find identifier for WebView.");
    }
    onPageStarted(getIdentifierForClient(webViewClient), webViewIdentifier, urlArg, callback);
  }

  /** Passes arguments from {@link WebViewClient#onPageFinished} to Dart. */
  public void onPageFinished(
      WebViewClient webViewClient, WebView webView, String urlArg, Reply<Void> callback) {
    final Long webViewIdentifier = instanceManager.getIdentifierForStrongReference(webView);
    if (webViewIdentifier == null) {
      throw new IllegalStateException("Could not find identifier for WebView.");
    }
    onPageFinished(getIdentifierForClient(webViewClient), webViewIdentifier, urlArg, callback);
  }

  /**
   * Passes arguments from {@link WebViewClient#onReceivedError(WebView, WebResourceRequest,
   * WebResourceError)} to Dart.
   */
  @RequiresApi(api = Build.VERSION_CODES.M)
  public void onReceivedRequestError(
      WebViewClient webViewClient,
      WebView webView,
      WebResourceRequest request,
      WebResourceError error,
      Reply<Void> callback) {
    final Long webViewIdentifier = instanceManager.getIdentifierForStrongReference(webView);
    if (webViewIdentifier == null) {
      throw new IllegalStateException("Could not find identifier for WebView.");
    }
    onReceivedRequestError(
        getIdentifierForClient(webViewClient),
        webViewIdentifier,
        createWebResourceRequestData(request),
        createWebResourceErrorData(error),
        callback);
  }

  /**
   * Passes arguments from {@link androidx.webkit.WebViewClientCompat#onReceivedError(WebView,
   * WebResourceRequest, WebResourceError)} to Dart.
   */
  @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
  public void onReceivedRequestError(
      WebViewClient webViewClient,
      WebView webView,
      WebResourceRequest request,
      WebResourceErrorCompat error,
      Reply<Void> callback) {
    final Long webViewIdentifier = instanceManager.getIdentifierForStrongReference(webView);
    if (webViewIdentifier == null) {
      throw new IllegalStateException("Could not find identifier for WebView.");
    }
    onReceivedRequestError(
        getIdentifierForClient(webViewClient),
        webViewIdentifier,
        createWebResourceRequestData(request),
        createWebResourceErrorData(error),
        callback);
  }

  /**
   * Passes arguments from {@link WebViewClient#onReceivedError(WebView, int, String, String)} to
   * Dart.
   */
  public void onReceivedError(
      WebViewClient webViewClient,
      WebView webView,
      Long errorCodeArg,
      String descriptionArg,
      String failingUrlArg,
      Reply<Void> callback) {
    final Long webViewIdentifier = instanceManager.getIdentifierForStrongReference(webView);
    if (webViewIdentifier == null) {
      throw new IllegalStateException("Could not find identifier for WebView.");
    }
    onReceivedError(
        getIdentifierForClient(webViewClient),
        webViewIdentifier,
        errorCodeArg,
        descriptionArg,
        failingUrlArg,
        callback);
  }

  /**
   * Passes arguments from {@link WebViewClient#shouldOverrideUrlLoading(WebView,
   * WebResourceRequest)} to Dart.
   */
  @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
  public void requestLoading(
      WebViewClient webViewClient,
      WebView webView,
      WebResourceRequest request,
      Reply<Void> callback) {
    final Long webViewIdentifier = instanceManager.getIdentifierForStrongReference(webView);
    if (webViewIdentifier == null) {
      throw new IllegalStateException("Could not find identifier for WebView.");
    }
    requestLoading(
        getIdentifierForClient(webViewClient),
        webViewIdentifier,
        createWebResourceRequestData(request),
        callback);
  }

  /**
   * Passes arguments from {@link WebViewClient#shouldOverrideUrlLoading(WebView, String)} to Dart.
   */
  public void urlLoading(
      WebViewClient webViewClient, WebView webView, String urlArg, Reply<Void> callback) {
    final Long webViewIdentifier = instanceManager.getIdentifierForStrongReference(webView);
    if (webViewIdentifier == null) {
      throw new IllegalStateException("Could not find identifier for WebView.");
    }
    urlLoading(getIdentifierForClient(webViewClient), webViewIdentifier, urlArg, callback);
  }

  /**
   * Communicates to Dart that the reference to a {@link WebViewClient} was removed.
   *
   * @param webViewClient the instance whose reference will be removed
   * @param callback reply callback with return value from Dart
   */
  public void dispose(WebViewClient webViewClient, Reply<Void> callback) {
    if (instanceManager.containsInstance(webViewClient)) {
      dispose(getIdentifierForClient(webViewClient), callback);
    } else {
      callback.reply(null);
    }
  }

  private long getIdentifierForClient(WebViewClient webViewClient) {
    final Long identifier = instanceManager.getIdentifierForStrongReference(webViewClient);
    if (identifier == null) {
      throw new IllegalStateException("Could not find identifier for WebViewClient.");
    }
    return identifier;
  }
}

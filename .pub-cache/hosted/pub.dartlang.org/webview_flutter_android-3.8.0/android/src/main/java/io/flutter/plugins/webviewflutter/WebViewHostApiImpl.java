// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.annotation.SuppressLint;
import android.content.Context;
import android.hardware.display.DisplayManager;
import android.os.Build;
import android.view.View;
import android.view.ViewParent;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import io.flutter.embedding.android.FlutterView;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.WebViewHostApi;
import java.util.Map;
import java.util.Objects;

/**
 * Host api implementation for {@link WebView}.
 *
 * <p>Handles creating {@link WebView}s that intercommunicate with a paired Dart object.
 */
public class WebViewHostApiImpl implements WebViewHostApi {
  private final InstanceManager instanceManager;
  private final WebViewProxy webViewProxy;
  private final BinaryMessenger binaryMessenger;

  private Context context;

  /** Handles creating and calling static methods for {@link WebView}s. */
  public static class WebViewProxy {
    /**
     * Creates a {@link WebViewPlatformView}.
     *
     * @param context an Activity Context to access application assets
     * @param binaryMessenger used to communicate with Dart over asynchronous messages
     * @param instanceManager mangages instances used to communicate with the corresponding objects
     *     in Dart
     * @return the created {@link WebViewPlatformView}
     */
    @NonNull
    public WebViewPlatformView createWebView(
        @NonNull Context context,
        @NonNull BinaryMessenger binaryMessenger,
        @NonNull InstanceManager instanceManager) {
      return new WebViewPlatformView(context, binaryMessenger, instanceManager);
    }

    /**
     * Forwards call to {@link WebView#setWebContentsDebuggingEnabled}.
     *
     * @param enabled whether debugging should be enabled
     */
    public void setWebContentsDebuggingEnabled(boolean enabled) {
      WebView.setWebContentsDebuggingEnabled(enabled);
    }
  }

  /** Implementation of {@link WebView} that can be used as a Flutter {@link PlatformView}s. */
  @SuppressLint("ViewConstructor")
  public static class WebViewPlatformView extends WebView implements PlatformView {
    // To ease adding callback methods, this value is added prematurely.
    @SuppressWarnings("unused")
    private WebViewFlutterApiImpl api;

    private WebViewClient currentWebViewClient;
    private WebChromeClientHostApiImpl.SecureWebChromeClient currentWebChromeClient;

    /**
     * Creates a {@link WebViewPlatformView}.
     *
     * @param context an Activity Context to access application assets. This value cannot be null.
     */
    public WebViewPlatformView(
        @NonNull Context context,
        @NonNull BinaryMessenger binaryMessenger,
        @NonNull InstanceManager instanceManager) {
      super(context);
      currentWebViewClient = new WebViewClient();
      currentWebChromeClient = new WebChromeClientHostApiImpl.SecureWebChromeClient();
      api = new WebViewFlutterApiImpl(binaryMessenger, instanceManager);

      setWebViewClient(currentWebViewClient);
      setWebChromeClient(currentWebChromeClient);
    }

    @Nullable
    @Override
    public View getView() {
      return this;
    }

    @Override
    public void dispose() {}

    // TODO(bparrishMines): This should be removed once https://github.com/flutter/engine/pull/40771 makes it to stable.
    // Temporary fix for https://github.com/flutter/flutter/issues/92165. The FlutterView is setting
    // setImportantForAutofill(IMPORTANT_FOR_AUTOFILL_YES_EXCLUDE_DESCENDANTS) which prevents this
    // view from automatically being traversed for autofill.
    @Override
    protected void onAttachedToWindow() {
      super.onAttachedToWindow();
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        final FlutterView flutterView = tryFindFlutterView();
        if (flutterView != null) {
          flutterView.setImportantForAutofill(IMPORTANT_FOR_AUTOFILL_YES);
        }
      }
    }

    // Attempt to traverse the parents of this view until a FlutterView is found.
    private FlutterView tryFindFlutterView() {
      ViewParent currentView = this;

      while (currentView.getParent() != null) {
        currentView = currentView.getParent();
        if (currentView instanceof FlutterView) {
          return (FlutterView) currentView;
        }
      }

      return null;
    }

    @Override
    public void setWebViewClient(@NonNull WebViewClient webViewClient) {
      super.setWebViewClient(webViewClient);
      currentWebViewClient = webViewClient;
      currentWebChromeClient.setWebViewClient(webViewClient);
    }

    @Override
    public void setWebChromeClient(@Nullable WebChromeClient client) {
      super.setWebChromeClient(client);
      if (!(client instanceof WebChromeClientHostApiImpl.SecureWebChromeClient)) {
        throw new AssertionError("Client must be a SecureWebChromeClient.");
      }
      currentWebChromeClient = (WebChromeClientHostApiImpl.SecureWebChromeClient) client;
      currentWebChromeClient.setWebViewClient(currentWebViewClient);
    }

    // When running unit tests, the parent `WebView` class is replaced by a stub that returns null
    // for every method. This is overridden so that this returns the current WebChromeClient during
    // unit tests. This should only remain overridden as long as `setWebChromeClient` is overridden.
    @Nullable
    @Override
    public WebChromeClient getWebChromeClient() {
      return currentWebChromeClient;
    }

    /**
     * Flutter API used to send messages back to Dart.
     *
     * <p>This is only visible for testing.
     */
    @SuppressWarnings("unused")
    @VisibleForTesting
    void setApi(WebViewFlutterApiImpl api) {
      this.api = api;
    }
  }

  /**
   * Creates a host API that handles creating {@link WebView}s and invoking its methods.
   *
   * @param instanceManager maintains instances stored to communicate with Dart objects
   * @param binaryMessenger used to communicate with Dart over asynchronous messages
   * @param webViewProxy handles creating {@link WebView}s and calling its static methods
   * @param context an Activity Context to access application assets. This value cannot be null.
   */
  public WebViewHostApiImpl(
      @NonNull InstanceManager instanceManager,
      @NonNull BinaryMessenger binaryMessenger,
      @NonNull WebViewProxy webViewProxy,
      @Nullable Context context) {
    this.instanceManager = instanceManager;
    this.binaryMessenger = binaryMessenger;
    this.webViewProxy = webViewProxy;
    this.context = context;
  }

  /**
   * Sets the context to construct {@link WebView}s.
   *
   * @param context the new context.
   */
  public void setContext(@Nullable Context context) {
    this.context = context;
  }

  @Override
  public void create(@NonNull Long instanceId) {
    DisplayListenerProxy displayListenerProxy = new DisplayListenerProxy();
    DisplayManager displayManager =
        (DisplayManager) context.getSystemService(Context.DISPLAY_SERVICE);
    displayListenerProxy.onPreWebViewInitialization(displayManager);

    final WebView webView = webViewProxy.createWebView(context, binaryMessenger, instanceManager);

    displayListenerProxy.onPostWebViewInitialization(displayManager);
    instanceManager.addDartCreatedInstance(webView, instanceId);
  }

  @Override
  public void loadData(
      @NonNull Long instanceId,
      @NonNull String data,
      @Nullable String mimeType,
      @Nullable String encoding) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webView.loadData(data, mimeType, encoding);
  }

  @Override
  public void loadDataWithBaseUrl(
      @NonNull Long instanceId,
      @Nullable String baseUrl,
      @NonNull String data,
      @Nullable String mimeType,
      @Nullable String encoding,
      @Nullable String historyUrl) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webView.loadDataWithBaseURL(baseUrl, data, mimeType, encoding, historyUrl);
  }

  @Override
  public void loadUrl(
      @NonNull Long instanceId, @NonNull String url, @NonNull Map<String, String> headers) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webView.loadUrl(url, headers);
  }

  @Override
  public void postUrl(@NonNull Long instanceId, @NonNull String url, @NonNull byte[] data) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webView.postUrl(url, data);
  }

  @Nullable
  @Override
  public String getUrl(@NonNull Long instanceId) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    return webView.getUrl();
  }

  @NonNull
  @Override
  public Boolean canGoBack(@NonNull Long instanceId) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    return webView.canGoBack();
  }

  @NonNull
  @Override
  public Boolean canGoForward(@NonNull Long instanceId) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    return webView.canGoForward();
  }

  @Override
  public void goBack(@NonNull Long instanceId) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webView.goBack();
  }

  @Override
  public void goForward(@NonNull Long instanceId) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webView.goForward();
  }

  @Override
  public void reload(@NonNull Long instanceId) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webView.reload();
  }

  @Override
  public void clearCache(@NonNull Long instanceId, @NonNull Boolean includeDiskFiles) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webView.clearCache(includeDiskFiles);
  }

  @Override
  public void evaluateJavascript(
      @NonNull Long instanceId,
      @NonNull String javascriptString,
      @NonNull GeneratedAndroidWebView.Result<String> result) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webView.evaluateJavascript(javascriptString, result::success);
  }

  @Nullable
  @Override
  public String getTitle(@NonNull Long instanceId) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    return webView.getTitle();
  }

  @Override
  public void scrollTo(@NonNull Long instanceId, @NonNull Long x, @NonNull Long y) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webView.scrollTo(x.intValue(), y.intValue());
  }

  @Override
  public void scrollBy(@NonNull Long instanceId, @NonNull Long x, @NonNull Long y) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webView.scrollBy(x.intValue(), y.intValue());
  }

  @NonNull
  @Override
  public Long getScrollX(@NonNull Long instanceId) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    return (long) webView.getScrollX();
  }

  @NonNull
  @Override
  public Long getScrollY(@NonNull Long instanceId) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    return (long) webView.getScrollY();
  }

  @NonNull
  @Override
  public GeneratedAndroidWebView.WebViewPoint getScrollPosition(@NonNull Long instanceId) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    return new GeneratedAndroidWebView.WebViewPoint.Builder()
        .setX((long) webView.getScrollX())
        .setY((long) webView.getScrollY())
        .build();
  }

  @Override
  public void setWebContentsDebuggingEnabled(@NonNull Boolean enabled) {
    webViewProxy.setWebContentsDebuggingEnabled(enabled);
  }

  @Override
  public void setWebViewClient(@NonNull Long instanceId, @NonNull Long webViewClientInstanceId) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webView.setWebViewClient(instanceManager.getInstance(webViewClientInstanceId));
  }

  @SuppressLint("JavascriptInterface")
  @Override
  public void addJavaScriptChannel(
      @NonNull Long instanceId, @NonNull Long javaScriptChannelInstanceId) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    final JavaScriptChannel javaScriptChannel =
        Objects.requireNonNull(instanceManager.getInstance(javaScriptChannelInstanceId));
    webView.addJavascriptInterface(javaScriptChannel, javaScriptChannel.javaScriptChannelName);
  }

  @Override
  public void removeJavaScriptChannel(
      @NonNull Long instanceId, @NonNull Long javaScriptChannelInstanceId) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    final JavaScriptChannel javaScriptChannel =
        Objects.requireNonNull((instanceManager.getInstance(javaScriptChannelInstanceId)));
    webView.removeJavascriptInterface(javaScriptChannel.javaScriptChannelName);
  }

  @Override
  public void setDownloadListener(@NonNull Long instanceId, @Nullable Long listenerInstanceId) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webView.setDownloadListener(
        instanceManager.getInstance(Objects.requireNonNull(listenerInstanceId)));
  }

  @Override
  public void setWebChromeClient(@NonNull Long instanceId, @Nullable Long clientInstanceId) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webView.setWebChromeClient(
        instanceManager.getInstance(Objects.requireNonNull(clientInstanceId)));
  }

  @Override
  public void setBackgroundColor(@NonNull Long instanceId, @NonNull Long color) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webView.setBackgroundColor(color.intValue());
  }

  /** Maintains instances used to communicate with the corresponding WebView Dart object. */
  @NonNull
  public InstanceManager getInstanceManager() {
    return instanceManager;
  }
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.graphics.Bitmap;
import android.os.Build;
import android.view.KeyEvent;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.webkit.WebResourceErrorCompat;
import androidx.webkit.WebViewClientCompat;

/**
 * Host api implementation for {@link WebViewClient}.
 *
 * <p>Handles creating {@link WebViewClient}s that intercommunicate with a paired Dart object.
 */
public class WebViewClientHostApiImpl implements GeneratedAndroidWebView.WebViewClientHostApi {
  private final InstanceManager instanceManager;
  private final WebViewClientCreator webViewClientCreator;
  private final WebViewClientFlutterApiImpl flutterApi;

  /**
   * An interface implemented by a class that extends {@link WebViewClient} and {@link Releasable}.
   */
  public interface ReleasableWebViewClient extends Releasable {}

  /** Implementation of {@link WebViewClient} that passes arguments of callback methods to Dart. */
  @RequiresApi(Build.VERSION_CODES.N)
  public static class WebViewClientImpl extends WebViewClient implements ReleasableWebViewClient {
    @Nullable private WebViewClientFlutterApiImpl flutterApi;
    private final boolean shouldOverrideUrlLoading;

    /**
     * Creates a {@link WebViewClient} that passes arguments of callbacks methods to Dart.
     *
     * @param flutterApi handles sending messages to Dart
     * @param shouldOverrideUrlLoading whether loading a url should be overridden
     */
    public WebViewClientImpl(
        @NonNull WebViewClientFlutterApiImpl flutterApi, boolean shouldOverrideUrlLoading) {
      this.shouldOverrideUrlLoading = shouldOverrideUrlLoading;
      this.flutterApi = flutterApi;
    }

    @Override
    public void onPageStarted(WebView view, String url, Bitmap favicon) {
      if (flutterApi != null) {
        flutterApi.onPageStarted(this, view, url, reply -> {});
      }
    }

    @Override
    public void onPageFinished(WebView view, String url) {
      if (flutterApi != null) {
        flutterApi.onPageFinished(this, view, url, reply -> {});
      }
    }

    @Override
    public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
      if (flutterApi != null) {
        flutterApi.onReceivedRequestError(this, view, request, error, reply -> {});
      }
    }

    @Override
    public void onReceivedError(
        WebView view, int errorCode, String description, String failingUrl) {
      if (flutterApi != null) {
        flutterApi.onReceivedError(
            this, view, (long) errorCode, description, failingUrl, reply -> {});
      }
    }

    @Override
    public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
      if (flutterApi != null) {
        flutterApi.requestLoading(this, view, request, reply -> {});
      }
      return shouldOverrideUrlLoading;
    }

    @Override
    public boolean shouldOverrideUrlLoading(WebView view, String url) {
      if (flutterApi != null) {
        flutterApi.urlLoading(this, view, url, reply -> {});
      }
      return shouldOverrideUrlLoading;
    }

    @Override
    public void onUnhandledKeyEvent(WebView view, KeyEvent event) {
      // Deliberately empty. Occasionally the webview will mark events as having failed to be
      // handled even though they were handled. We don't want to propagate those as they're not
      // truly lost.
    }

    public void release() {
      if (flutterApi != null) {
        flutterApi.dispose(this, reply -> {});
      }
      flutterApi = null;
    }
  }

  /**
   * Implementation of {@link WebViewClientCompat} that passes arguments of callback methods to
   * Dart.
   */
  public static class WebViewClientCompatImpl extends WebViewClientCompat
      implements ReleasableWebViewClient {
    private @Nullable WebViewClientFlutterApiImpl flutterApi;
    private final boolean shouldOverrideUrlLoading;

    public WebViewClientCompatImpl(
        @NonNull WebViewClientFlutterApiImpl flutterApi, boolean shouldOverrideUrlLoading) {
      this.shouldOverrideUrlLoading = shouldOverrideUrlLoading;
      this.flutterApi = flutterApi;
    }

    @Override
    public void onPageStarted(WebView view, String url, Bitmap favicon) {
      if (flutterApi != null) {
        flutterApi.onPageStarted(this, view, url, reply -> {});
      }
    }

    @Override
    public void onPageFinished(WebView view, String url) {
      if (flutterApi != null) {
        flutterApi.onPageFinished(this, view, url, reply -> {});
      }
    }

    // This method is only called when the WebViewFeature.RECEIVE_WEB_RESOURCE_ERROR feature is
    // enabled. The deprecated method is called when a device doesn't support this.
    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    @SuppressLint("RequiresFeature")
    @Override
    public void onReceivedError(
        @NonNull WebView view,
        @NonNull WebResourceRequest request,
        @NonNull WebResourceErrorCompat error) {
      if (flutterApi != null) {
        flutterApi.onReceivedRequestError(this, view, request, error, reply -> {});
      }
    }

    @Override
    public void onReceivedError(
        WebView view, int errorCode, String description, String failingUrl) {
      if (flutterApi != null) {
        flutterApi.onReceivedError(
            this, view, (long) errorCode, description, failingUrl, reply -> {});
      }
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    @Override
    public boolean shouldOverrideUrlLoading(
        @NonNull WebView view, @NonNull WebResourceRequest request) {
      if (flutterApi != null) {
        flutterApi.requestLoading(this, view, request, reply -> {});
      }
      return shouldOverrideUrlLoading;
    }

    @Override
    public boolean shouldOverrideUrlLoading(WebView view, String url) {
      if (flutterApi != null) {
        flutterApi.urlLoading(this, view, url, reply -> {});
      }
      return shouldOverrideUrlLoading;
    }

    @Override
    public void onUnhandledKeyEvent(WebView view, KeyEvent event) {
      // Deliberately empty. Occasionally the webview will mark events as having failed to be
      // handled even though they were handled. We don't want to propagate those as they're not
      // truly lost.
    }

    public void release() {
      if (flutterApi != null) {
        flutterApi.dispose(this, reply -> {});
      }
      flutterApi = null;
    }
  }

  /** Handles creating {@link WebViewClient}s for a {@link WebViewClientHostApiImpl}. */
  public static class WebViewClientCreator {
    /**
     * Creates a {@link WebViewClient}.
     *
     * @param flutterApi handles sending messages to Dart
     * @return the created {@link WebViewClient}
     */
    public WebViewClient createWebViewClient(
        WebViewClientFlutterApiImpl flutterApi, boolean shouldOverrideUrlLoading) {
      // WebViewClientCompat is used to get
      // shouldOverrideUrlLoading(WebView view, WebResourceRequest request)
      // invoked by the webview on older Android devices, without it pages that use iframes will
      // be broken when a navigationDelegate is set on Android version earlier than N.
      //
      // However, this if statement attempts to avoid using WebViewClientCompat on versions >= N due
      // to bug https://bugs.chromium.org/p/chromium/issues/detail?id=925887. Also, see
      // https://github.com/flutter/flutter/issues/29446.
      if (android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
        return new WebViewClientImpl(flutterApi, shouldOverrideUrlLoading);
      } else {
        return new WebViewClientCompatImpl(flutterApi, shouldOverrideUrlLoading);
      }
    }
  }

  /**
   * Creates a host API that handles creating {@link WebViewClient}s.
   *
   * @param instanceManager maintains instances stored to communicate with Dart objects
   * @param webViewClientCreator handles creating {@link WebViewClient}s
   * @param flutterApi handles sending messages to Dart
   */
  public WebViewClientHostApiImpl(
      InstanceManager instanceManager,
      WebViewClientCreator webViewClientCreator,
      WebViewClientFlutterApiImpl flutterApi) {
    this.instanceManager = instanceManager;
    this.webViewClientCreator = webViewClientCreator;
    this.flutterApi = flutterApi;
  }

  @Override
  public void create(Long instanceId, Boolean shouldOverrideUrlLoading) {
    final WebViewClient webViewClient =
        webViewClientCreator.createWebViewClient(flutterApi, shouldOverrideUrlLoading);
    instanceManager.addDartCreatedInstance(webViewClient, instanceId);
  }
}

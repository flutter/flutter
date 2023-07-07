// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.net.Uri;
import android.os.Build;
import android.os.Message;
import android.webkit.GeolocationPermissions;
import android.webkit.PermissionRequest;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.annotation.VisibleForTesting;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.WebChromeClientHostApi;
import java.util.Objects;

/**
 * Host api implementation for {@link WebChromeClient}.
 *
 * <p>Handles creating {@link WebChromeClient}s that intercommunicate with a paired Dart object.
 */
public class WebChromeClientHostApiImpl implements WebChromeClientHostApi {
  private final InstanceManager instanceManager;
  private final WebChromeClientCreator webChromeClientCreator;
  private final WebChromeClientFlutterApiImpl flutterApi;

  /**
   * Implementation of {@link WebChromeClient} that passes arguments of callback methods to Dart.
   */
  public static class WebChromeClientImpl extends SecureWebChromeClient {
    private final WebChromeClientFlutterApiImpl flutterApi;
    private boolean returnValueForOnShowFileChooser = false;

    /**
     * Creates a {@link WebChromeClient} that passes arguments of callbacks methods to Dart.
     *
     * @param flutterApi handles sending messages to Dart
     */
    public WebChromeClientImpl(@NonNull WebChromeClientFlutterApiImpl flutterApi) {
      this.flutterApi = flutterApi;
    }

    @Override
    public void onProgressChanged(@NonNull WebView view, int progress) {
      flutterApi.onProgressChanged(this, view, (long) progress, reply -> {});
    }

    @Override
    public void onGeolocationPermissionsShowPrompt(
        @NonNull String origin, @NonNull GeolocationPermissions.Callback callback) {
      flutterApi.onGeolocationPermissionsShowPrompt(this, origin, callback, reply -> {});
    }

    @Override
    public void onGeolocationPermissionsHidePrompt() {
      flutterApi.onGeolocationPermissionsHidePrompt(this, reply -> {});
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    @SuppressWarnings("LambdaLast")
    @Override
    public boolean onShowFileChooser(
        @NonNull WebView webView,
        @NonNull ValueCallback<Uri[]> filePathCallback,
        @NonNull FileChooserParams fileChooserParams) {
      final boolean currentReturnValueForOnShowFileChooser = returnValueForOnShowFileChooser;
      flutterApi.onShowFileChooser(
          this,
          webView,
          fileChooserParams,
          reply -> {
            // The returned list of file paths can only be passed to `filePathCallback` if the
            // `onShowFileChooser` method returned true.
            if (currentReturnValueForOnShowFileChooser) {
              final Uri[] filePaths = new Uri[reply.size()];
              for (int i = 0; i < reply.size(); i++) {
                filePaths[i] = Uri.parse(reply.get(i));
              }
              filePathCallback.onReceiveValue(filePaths);
            }
          });
      return currentReturnValueForOnShowFileChooser;
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    @Override
    public void onPermissionRequest(@NonNull PermissionRequest request) {
      flutterApi.onPermissionRequest(this, request, reply -> {});
    }

    /** Sets return value for {@link #onShowFileChooser}. */
    public void setReturnValueForOnShowFileChooser(boolean value) {
      returnValueForOnShowFileChooser = value;
    }
  }

  /**
   * Implementation of {@link WebChromeClient} that only allows secure urls when opening a new
   * window.
   */
  public static class SecureWebChromeClient extends WebChromeClient {
    @Nullable WebViewClient webViewClient;

    @Override
    public boolean onCreateWindow(
        @NonNull final WebView view,
        boolean isDialog,
        boolean isUserGesture,
        @NonNull Message resultMsg) {
      return onCreateWindow(view, resultMsg, new WebView(view.getContext()));
    }

    /**
     * Verifies that a url opened by `Window.open` has a secure url.
     *
     * @param view the WebView from which the request for a new window originated.
     * @param resultMsg the message to send when once a new WebView has been created. resultMsg.obj
     *     is a {@link WebView.WebViewTransport} object. This should be used to transport the new
     *     WebView, by calling WebView.WebViewTransport.setWebView(WebView)
     * @param onCreateWindowWebView the temporary WebView used to verify the url is secure
     * @return this method should return true if the host application will create a new window, in
     *     which case resultMsg should be sent to its target. Otherwise, this method should return
     *     false. Returning false from this method but also sending resultMsg will result in
     *     undefined behavior
     */
    @VisibleForTesting
    boolean onCreateWindow(
        @NonNull final WebView view,
        @NonNull Message resultMsg,
        @Nullable WebView onCreateWindowWebView) {
      // WebChromeClient requires a WebViewClient because of a bug fix that makes
      // calls to WebViewClient.requestLoading/WebViewClient.urlLoading when a new
      // window is opened. This is to make sure a url opened by `Window.open` has
      // a secure url.
      if (webViewClient == null) {
        return false;
      }

      final WebViewClient windowWebViewClient =
          new WebViewClient() {
            @RequiresApi(api = Build.VERSION_CODES.N)
            @Override
            public boolean shouldOverrideUrlLoading(
                @NonNull WebView windowWebView, @NonNull WebResourceRequest request) {
              if (!webViewClient.shouldOverrideUrlLoading(view, request)) {
                view.loadUrl(request.getUrl().toString());
              }
              return true;
            }

            // Legacy codepath for < N.
            @Override
            @SuppressWarnings({"deprecation", "RedundantSuppression"})
            public boolean shouldOverrideUrlLoading(WebView windowWebView, String url) {
              if (!webViewClient.shouldOverrideUrlLoading(view, url)) {
                view.loadUrl(url);
              }
              return true;
            }
          };

      if (onCreateWindowWebView == null) {
        onCreateWindowWebView = new WebView(view.getContext());
      }
      onCreateWindowWebView.setWebViewClient(windowWebViewClient);

      final WebView.WebViewTransport transport = (WebView.WebViewTransport) resultMsg.obj;
      transport.setWebView(onCreateWindowWebView);
      resultMsg.sendToTarget();

      return true;
    }

    /**
     * Set the {@link WebViewClient} that calls to {@link WebChromeClient#onCreateWindow} are passed
     * to.
     *
     * @param webViewClient the forwarding {@link WebViewClient}
     */
    public void setWebViewClient(@NonNull WebViewClient webViewClient) {
      this.webViewClient = webViewClient;
    }
  }

  /** Handles creating {@link WebChromeClient}s for a {@link WebChromeClientHostApiImpl}. */
  public static class WebChromeClientCreator {
    /**
     * Creates a {@link WebChromeClientHostApiImpl.WebChromeClientImpl}.
     *
     * @param flutterApi handles sending messages to Dart
     * @return the created {@link WebChromeClientHostApiImpl.WebChromeClientImpl}
     */
    @NonNull
    public WebChromeClientImpl createWebChromeClient(
        @NonNull WebChromeClientFlutterApiImpl flutterApi) {
      return new WebChromeClientImpl(flutterApi);
    }
  }

  /**
   * Creates a host API that handles creating {@link WebChromeClient}s.
   *
   * @param instanceManager maintains instances stored to communicate with Dart objects
   * @param webChromeClientCreator handles creating {@link WebChromeClient}s
   * @param flutterApi handles sending messages to Dart
   */
  public WebChromeClientHostApiImpl(
      @NonNull InstanceManager instanceManager,
      @NonNull WebChromeClientCreator webChromeClientCreator,
      @NonNull WebChromeClientFlutterApiImpl flutterApi) {
    this.instanceManager = instanceManager;
    this.webChromeClientCreator = webChromeClientCreator;
    this.flutterApi = flutterApi;
  }

  @Override
  public void create(@NonNull Long instanceId) {
    final WebChromeClient webChromeClient =
        webChromeClientCreator.createWebChromeClient(flutterApi);
    instanceManager.addDartCreatedInstance(webChromeClient, instanceId);
  }

  @Override
  public void setSynchronousReturnValueForOnShowFileChooser(
      @NonNull Long instanceId, @NonNull Boolean value) {
    final WebChromeClientImpl webChromeClient =
        Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webChromeClient.setReturnValueForOnShowFileChooser(value);
  }
}

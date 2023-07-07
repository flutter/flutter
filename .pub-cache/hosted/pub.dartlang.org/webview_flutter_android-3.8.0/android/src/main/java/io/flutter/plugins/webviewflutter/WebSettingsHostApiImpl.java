// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.webkit.WebSettings;
import android.webkit.WebView;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.WebSettingsHostApi;
import java.util.Objects;

/**
 * Host api implementation for {@link WebSettings}.
 *
 * <p>Handles creating {@link WebSettings}s that intercommunicate with a paired Dart object.
 */
public class WebSettingsHostApiImpl implements WebSettingsHostApi {
  private final InstanceManager instanceManager;
  private final WebSettingsCreator webSettingsCreator;

  /** Handles creating {@link WebSettings} for a {@link WebSettingsHostApiImpl}. */
  public static class WebSettingsCreator {
    /**
     * Creates a {@link WebSettings}.
     *
     * @param webView the {@link WebView} which the settings affect
     * @return the created {@link WebSettings}
     */
    @NonNull
    public WebSettings createWebSettings(@NonNull WebView webView) {
      return webView.getSettings();
    }
  }

  /**
   * Creates a host API that handles creating {@link WebSettings} and invoke its methods.
   *
   * @param instanceManager maintains instances stored to communicate with Dart objects
   * @param webSettingsCreator handles creating {@link WebSettings}s
   */
  public WebSettingsHostApiImpl(
      @NonNull InstanceManager instanceManager, @NonNull WebSettingsCreator webSettingsCreator) {
    this.instanceManager = instanceManager;
    this.webSettingsCreator = webSettingsCreator;
  }

  @Override
  public void create(@NonNull Long instanceId, @NonNull Long webViewInstanceId) {
    final WebView webView = Objects.requireNonNull(instanceManager.getInstance(webViewInstanceId));
    instanceManager.addDartCreatedInstance(
        webSettingsCreator.createWebSettings(webView), instanceId);
  }

  @Override
  public void setDomStorageEnabled(@NonNull Long instanceId, @NonNull Boolean flag) {
    final WebSettings webSettings = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webSettings.setDomStorageEnabled(flag);
  }

  @Override
  public void setJavaScriptCanOpenWindowsAutomatically(
      @NonNull Long instanceId, @NonNull Boolean flag) {
    final WebSettings webSettings = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webSettings.setJavaScriptCanOpenWindowsAutomatically(flag);
  }

  @Override
  public void setSupportMultipleWindows(@NonNull Long instanceId, @NonNull Boolean support) {
    final WebSettings webSettings = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webSettings.setSupportMultipleWindows(support);
  }

  @Override
  public void setJavaScriptEnabled(@NonNull Long instanceId, @NonNull Boolean flag) {
    final WebSettings webSettings = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webSettings.setJavaScriptEnabled(flag);
  }

  @Override
  public void setUserAgentString(@NonNull Long instanceId, @Nullable String userAgentString) {
    final WebSettings webSettings = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webSettings.setUserAgentString(userAgentString);
  }

  @Override
  public void setMediaPlaybackRequiresUserGesture(
      @NonNull Long instanceId, @NonNull Boolean require) {
    final WebSettings webSettings = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webSettings.setMediaPlaybackRequiresUserGesture(require);
  }

  @Override
  public void setSupportZoom(@NonNull Long instanceId, @NonNull Boolean support) {
    final WebSettings webSettings = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webSettings.setSupportZoom(support);
  }

  @Override
  public void setLoadWithOverviewMode(@NonNull Long instanceId, @NonNull Boolean overview) {
    final WebSettings webSettings = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webSettings.setLoadWithOverviewMode(overview);
  }

  @Override
  public void setUseWideViewPort(@NonNull Long instanceId, @NonNull Boolean use) {
    final WebSettings webSettings = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webSettings.setUseWideViewPort(use);
  }

  @Override
  public void setDisplayZoomControls(@NonNull Long instanceId, @NonNull Boolean enabled) {
    final WebSettings webSettings = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webSettings.setDisplayZoomControls(enabled);
  }

  @Override
  public void setBuiltInZoomControls(@NonNull Long instanceId, @NonNull Boolean enabled) {
    final WebSettings webSettings = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webSettings.setBuiltInZoomControls(enabled);
  }

  @Override
  public void setAllowFileAccess(@NonNull Long instanceId, @NonNull Boolean enabled) {
    final WebSettings webSettings = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webSettings.setAllowFileAccess(enabled);
  }

  @Override
  public void setTextZoom(@NonNull Long instanceId, @NonNull Long textZoom) {
    final WebSettings webSettings = Objects.requireNonNull(instanceManager.getInstance(instanceId));
    webSettings.setTextZoom(textZoom.intValue());
  }
}

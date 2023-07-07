// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.webkit.WebSettings;
import android.webkit.WebView;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.WebSettingsHostApi;

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
    public WebSettings createWebSettings(WebView webView) {
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
      InstanceManager instanceManager, WebSettingsCreator webSettingsCreator) {
    this.instanceManager = instanceManager;
    this.webSettingsCreator = webSettingsCreator;
  }

  @Override
  public void create(Long instanceId, Long webViewInstanceId) {
    final WebView webView = (WebView) instanceManager.getInstance(webViewInstanceId);
    instanceManager.addDartCreatedInstance(
        webSettingsCreator.createWebSettings(webView), instanceId);
  }

  @Override
  public void dispose(Long instanceId) {
    instanceManager.remove(instanceId);
  }

  @Override
  public void setDomStorageEnabled(Long instanceId, Boolean flag) {
    final WebSettings webSettings = (WebSettings) instanceManager.getInstance(instanceId);
    webSettings.setDomStorageEnabled(flag);
  }

  @Override
  public void setJavaScriptCanOpenWindowsAutomatically(Long instanceId, Boolean flag) {
    final WebSettings webSettings = (WebSettings) instanceManager.getInstance(instanceId);
    webSettings.setJavaScriptCanOpenWindowsAutomatically(flag);
  }

  @Override
  public void setSupportMultipleWindows(Long instanceId, Boolean support) {
    final WebSettings webSettings = (WebSettings) instanceManager.getInstance(instanceId);
    webSettings.setSupportMultipleWindows(support);
  }

  @Override
  public void setJavaScriptEnabled(Long instanceId, Boolean flag) {
    final WebSettings webSettings = (WebSettings) instanceManager.getInstance(instanceId);
    webSettings.setJavaScriptEnabled(flag);
  }

  @Override
  public void setUserAgentString(Long instanceId, String userAgentString) {
    final WebSettings webSettings = (WebSettings) instanceManager.getInstance(instanceId);
    webSettings.setUserAgentString(userAgentString);
  }

  @Override
  public void setMediaPlaybackRequiresUserGesture(Long instanceId, Boolean require) {
    final WebSettings webSettings = (WebSettings) instanceManager.getInstance(instanceId);
    webSettings.setMediaPlaybackRequiresUserGesture(require);
  }

  @Override
  public void setSupportZoom(Long instanceId, Boolean support) {
    final WebSettings webSettings = (WebSettings) instanceManager.getInstance(instanceId);
    webSettings.setSupportZoom(support);
  }

  @Override
  public void setLoadWithOverviewMode(Long instanceId, Boolean overview) {
    final WebSettings webSettings = (WebSettings) instanceManager.getInstance(instanceId);
    webSettings.setLoadWithOverviewMode(overview);
  }

  @Override
  public void setUseWideViewPort(Long instanceId, Boolean use) {
    final WebSettings webSettings = (WebSettings) instanceManager.getInstance(instanceId);
    webSettings.setUseWideViewPort(use);
  }

  @Override
  public void setDisplayZoomControls(Long instanceId, Boolean enabled) {
    final WebSettings webSettings = (WebSettings) instanceManager.getInstance(instanceId);
    webSettings.setDisplayZoomControls(enabled);
  }

  @Override
  public void setBuiltInZoomControls(Long instanceId, Boolean enabled) {
    final WebSettings webSettings = (WebSettings) instanceManager.getInstance(instanceId);
    webSettings.setBuiltInZoomControls(enabled);
  }

  @Override
  public void setAllowFileAccess(Long instanceId, Boolean enabled) {
    final WebSettings webSettings = (WebSettings) instanceManager.getInstance(instanceId);
    webSettings.setAllowFileAccess(enabled);
  }
}

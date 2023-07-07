// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.net.Uri;
import android.os.Message;
import android.webkit.GeolocationPermissions;
import android.webkit.PermissionRequest;
import android.webkit.WebResourceRequest;
import android.webkit.WebView;
import android.webkit.WebView.WebViewTransport;
import android.webkit.WebViewClient;
import androidx.annotation.NonNull;
import io.flutter.plugins.webviewflutter.WebChromeClientHostApiImpl.WebChromeClientCreator;
import io.flutter.plugins.webviewflutter.WebChromeClientHostApiImpl.WebChromeClientImpl;
import org.junit.After;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnit;
import org.mockito.junit.MockitoRule;

public class WebChromeClientTest {
  @Rule public MockitoRule mockitoRule = MockitoJUnit.rule();

  @Mock public WebChromeClientFlutterApiImpl mockFlutterApi;

  @Mock public WebView mockWebView;

  @Mock public WebViewClient mockWebViewClient;

  InstanceManager instanceManager;
  WebChromeClientHostApiImpl hostApiImpl;
  WebChromeClientImpl webChromeClient;

  @Before
  public void setUp() {
    instanceManager = InstanceManager.create(identifier -> {});

    final WebChromeClientCreator webChromeClientCreator =
        new WebChromeClientCreator() {
          @Override
          @NonNull
          public WebChromeClientImpl createWebChromeClient(
              @NonNull WebChromeClientFlutterApiImpl flutterApi) {
            webChromeClient = super.createWebChromeClient(flutterApi);
            return webChromeClient;
          }
        };

    hostApiImpl =
        new WebChromeClientHostApiImpl(instanceManager, webChromeClientCreator, mockFlutterApi);
    hostApiImpl.create(2L);
  }

  @After
  public void tearDown() {
    instanceManager.stopFinalizationListener();
  }

  @Test
  public void onProgressChanged() {
    webChromeClient.onProgressChanged(mockWebView, 23);
    verify(mockFlutterApi).onProgressChanged(eq(webChromeClient), eq(mockWebView), eq(23L), any());
  }

  @Test
  public void onCreateWindow() {
    final WebView mockOnCreateWindowWebView = mock(WebView.class);

    // Create a fake message to transport requests to onCreateWindowWebView.
    final Message message = new Message();
    message.obj = mock(WebViewTransport.class);

    webChromeClient.setWebViewClient(mockWebViewClient);
    assertTrue(webChromeClient.onCreateWindow(mockWebView, message, mockOnCreateWindowWebView));

    /// Capture the WebViewClient used with onCreateWindow WebView.
    final ArgumentCaptor<WebViewClient> webViewClientCaptor =
        ArgumentCaptor.forClass(WebViewClient.class);
    verify(mockOnCreateWindowWebView).setWebViewClient(webViewClientCaptor.capture());
    final WebViewClient onCreateWindowWebViewClient = webViewClientCaptor.getValue();
    assertNotNull(onCreateWindowWebViewClient);

    /// Create a WebResourceRequest with a Uri.
    final WebResourceRequest mockRequest = mock(WebResourceRequest.class);
    when(mockRequest.getUrl()).thenReturn(mock(Uri.class));
    when(mockRequest.getUrl().toString()).thenReturn("https://www.google.com");

    // Test when the forwarding WebViewClient is overriding all url loading.
    when(mockWebViewClient.shouldOverrideUrlLoading(any(), any(WebResourceRequest.class)))
        .thenReturn(true);
    assertTrue(
        onCreateWindowWebViewClient.shouldOverrideUrlLoading(
            mockOnCreateWindowWebView, mockRequest));
    verify(mockWebView, never()).loadUrl(any());

    // Test when the forwarding WebViewClient is NOT overriding all url loading.
    when(mockWebViewClient.shouldOverrideUrlLoading(any(), any(WebResourceRequest.class)))
        .thenReturn(false);
    assertTrue(
        onCreateWindowWebViewClient.shouldOverrideUrlLoading(
            mockOnCreateWindowWebView, mockRequest));
    verify(mockWebView).loadUrl("https://www.google.com");
  }

  @Test
  public void onPermissionRequest() {
    final PermissionRequest mockRequest = mock(PermissionRequest.class);
    instanceManager.addDartCreatedInstance(mockRequest, 10);
    webChromeClient.onPermissionRequest(mockRequest);
    verify(mockFlutterApi).onPermissionRequest(eq(webChromeClient), eq(mockRequest), any());
  }

  @Test
  public void onGeolocationPermissionsShowPrompt() {
    final GeolocationPermissions.Callback mockCallback =
        mock(GeolocationPermissions.Callback.class);
    webChromeClient.onGeolocationPermissionsShowPrompt("https://flutter.dev", mockCallback);

    verify(mockFlutterApi)
        .onGeolocationPermissionsShowPrompt(
            eq(webChromeClient), eq("https://flutter.dev"), eq(mockCallback), any());
  }

  @Test
  public void onGeolocationPermissionsHidePrompt() {
    webChromeClient.onGeolocationPermissionsHidePrompt();
    verify(mockFlutterApi).onGeolocationPermissionsHidePrompt(eq(webChromeClient), any());
  }
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import static org.junit.Assert.assertEquals;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.content.Context;
import android.webkit.DownloadListener;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebViewClient;
import io.flutter.plugins.webviewflutter.DownloadListenerHostApiImpl.DownloadListenerImpl;
import io.flutter.plugins.webviewflutter.WebChromeClientHostApiImpl.WebChromeClientImpl;
import io.flutter.plugins.webviewflutter.WebViewClientHostApiImpl.WebViewClientImpl;
import io.flutter.plugins.webviewflutter.WebViewHostApiImpl.InputAwareWebViewPlatformView;
import io.flutter.plugins.webviewflutter.WebViewHostApiImpl.WebViewPlatformView;
import java.util.HashMap;
import org.junit.After;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnit;
import org.mockito.junit.MockitoRule;

public class WebViewTest {
  @Rule public MockitoRule mockitoRule = MockitoJUnit.rule();

  @Mock public WebViewPlatformView mockWebView;

  @Mock WebViewHostApiImpl.WebViewProxy mockWebViewProxy;

  @Mock Context mockContext;

  InstanceManager testInstanceManager;
  WebViewHostApiImpl testHostApiImpl;

  @Before
  public void setUp() {
    testInstanceManager = InstanceManager.open(identifier -> {});

    when(mockWebViewProxy.createWebView(mockContext)).thenReturn(mockWebView);
    testHostApiImpl =
        new WebViewHostApiImpl(testInstanceManager, mockWebViewProxy, mockContext, null);
    testHostApiImpl.create(0L, true);
  }

  @After
  public void tearDown() {
    testInstanceManager.close();
  }

  @Test
  public void releaseWebView() {
    final WebViewPlatformView webView = new WebViewPlatformView(mockContext);

    final WebViewClientImpl mockWebViewClient = mock(WebViewClientImpl.class);
    final WebChromeClientImpl mockWebChromeClient = mock(WebChromeClientImpl.class);
    final DownloadListenerImpl mockDownloadListener = mock(DownloadListenerImpl.class);
    final JavaScriptChannel mockJavaScriptChannel = mock(JavaScriptChannel.class);

    webView.setWebViewClient(mockWebViewClient);
    webView.setWebChromeClient(mockWebChromeClient);
    webView.setDownloadListener(mockDownloadListener);
    webView.addJavascriptInterface(mockJavaScriptChannel, "jchannel");

    webView.release();

    verify(mockWebViewClient).release();
    verify(mockWebChromeClient).release();
    verify(mockDownloadListener).release();
    verify(mockJavaScriptChannel).release();
  }

  @Test
  public void releaseWebViewDependents() {
    final WebViewPlatformView webView = new WebViewPlatformView(mockContext);

    final WebViewClientImpl mockWebViewClient = mock(WebViewClientImpl.class);
    final WebChromeClientImpl mockWebChromeClient = mock(WebChromeClientImpl.class);
    final DownloadListenerImpl mockDownloadListener = mock(DownloadListenerImpl.class);
    final JavaScriptChannel mockJavaScriptChannel = mock(JavaScriptChannel.class);
    final JavaScriptChannel mockJavaScriptChannel2 = mock(JavaScriptChannel.class);

    webView.setWebViewClient(mockWebViewClient);
    webView.setWebChromeClient(mockWebChromeClient);
    webView.setDownloadListener(mockDownloadListener);
    webView.addJavascriptInterface(mockJavaScriptChannel, "jchannel");

    // Release should be called on the object added above.
    webView.addJavascriptInterface(mockJavaScriptChannel2, "jchannel");
    verify(mockJavaScriptChannel).release();

    webView.setWebViewClient(null);
    webView.setWebChromeClient(null);
    webView.setDownloadListener(null);
    webView.removeJavascriptInterface("jchannel");

    verify(mockWebViewClient).release();
    verify(mockWebChromeClient).release();
    verify(mockDownloadListener).release();
    verify(mockJavaScriptChannel2).release();
  }

  @Test
  public void releaseInputAwareWebView() {
    final InputAwareWebViewPlatformView webView =
        new InputAwareWebViewPlatformView(mockContext, null);

    final WebViewClientImpl mockWebViewClient = mock(WebViewClientImpl.class);
    final WebChromeClientImpl mockWebChromeClient = mock(WebChromeClientImpl.class);
    final DownloadListenerImpl mockDownloadListener = mock(DownloadListenerImpl.class);
    final JavaScriptChannel mockJavaScriptChannel = mock(JavaScriptChannel.class);

    webView.setWebViewClient(mockWebViewClient);
    webView.setWebChromeClient(mockWebChromeClient);
    webView.setDownloadListener(mockDownloadListener);
    webView.addJavascriptInterface(mockJavaScriptChannel, "jchannel");

    webView.release();

    verify(mockWebViewClient).release();
    verify(mockWebChromeClient).release();
    verify(mockDownloadListener).release();
    verify(mockJavaScriptChannel).release();
  }

  @Test
  public void releaseInputAwareWebViewDependents() {
    final InputAwareWebViewPlatformView webView =
        new InputAwareWebViewPlatformView(mockContext, null);

    final WebViewClientImpl mockWebViewClient = mock(WebViewClientImpl.class);
    final WebChromeClientImpl mockWebChromeClient = mock(WebChromeClientImpl.class);
    final DownloadListenerImpl mockDownloadListener = mock(DownloadListenerImpl.class);
    final JavaScriptChannel mockJavaScriptChannel = mock(JavaScriptChannel.class);
    final JavaScriptChannel mockJavaScriptChannel2 = mock(JavaScriptChannel.class);

    webView.setWebViewClient(mockWebViewClient);
    webView.setWebChromeClient(mockWebChromeClient);
    webView.setDownloadListener(mockDownloadListener);
    webView.addJavascriptInterface(mockJavaScriptChannel, "jchannel");

    // Release should be called on the object added above.
    webView.addJavascriptInterface(mockJavaScriptChannel2, "jchannel");
    verify(mockJavaScriptChannel).release();

    webView.setWebViewClient(null);
    webView.setWebChromeClient(null);
    webView.setDownloadListener(null);
    webView.removeJavascriptInterface("jchannel");

    verify(mockWebViewClient).release();
    verify(mockWebChromeClient).release();
    verify(mockDownloadListener).release();
    verify(mockJavaScriptChannel2).release();
  }

  @Test
  public void loadData() {
    testHostApiImpl.loadData(
        0L, "VGhpcyBkYXRhIGlzIGJhc2U2NCBlbmNvZGVkLg==", "text/plain", "base64");
    verify(mockWebView)
        .loadData("VGhpcyBkYXRhIGlzIGJhc2U2NCBlbmNvZGVkLg==", "text/plain", "base64");
  }

  @Test
  public void loadDataWithNullValues() {
    testHostApiImpl.loadData(0L, "VGhpcyBkYXRhIGlzIGJhc2U2NCBlbmNvZGVkLg==", null, null);
    verify(mockWebView).loadData("VGhpcyBkYXRhIGlzIGJhc2U2NCBlbmNvZGVkLg==", null, null);
  }

  @Test
  public void loadDataWithBaseUrl() {
    testHostApiImpl.loadDataWithBaseUrl(
        0L,
        "https://flutter.dev",
        "VGhpcyBkYXRhIGlzIGJhc2U2NCBlbmNvZGVkLg==",
        "text/plain",
        "base64",
        "about:blank");
    verify(mockWebView)
        .loadDataWithBaseURL(
            "https://flutter.dev",
            "VGhpcyBkYXRhIGlzIGJhc2U2NCBlbmNvZGVkLg==",
            "text/plain",
            "base64",
            "about:blank");
  }

  @Test
  public void loadDataWithBaseUrlAndNullValues() {
    testHostApiImpl.loadDataWithBaseUrl(
        0L, null, "VGhpcyBkYXRhIGlzIGJhc2U2NCBlbmNvZGVkLg==", null, null, null);
    verify(mockWebView)
        .loadDataWithBaseURL(null, "VGhpcyBkYXRhIGlzIGJhc2U2NCBlbmNvZGVkLg==", null, null, null);
  }

  @Test
  public void loadUrl() {
    testHostApiImpl.loadUrl(0L, "https://www.google.com", new HashMap<>());
    verify(mockWebView).loadUrl("https://www.google.com", new HashMap<>());
  }

  @Test
  public void postUrl() {
    testHostApiImpl.postUrl(0L, "https://www.google.com", new byte[] {0x01, 0x02});
    verify(mockWebView).postUrl("https://www.google.com", new byte[] {0x01, 0x02});
  }

  @Test
  public void getUrl() {
    when(mockWebView.getUrl()).thenReturn("https://www.google.com");
    assertEquals(testHostApiImpl.getUrl(0L), "https://www.google.com");
  }

  @Test
  public void canGoBack() {
    when(mockWebView.canGoBack()).thenReturn(true);
    assertEquals(testHostApiImpl.canGoBack(0L), true);
  }

  @Test
  public void canGoForward() {
    when(mockWebView.canGoForward()).thenReturn(false);
    assertEquals(testHostApiImpl.canGoForward(0L), false);
  }

  @Test
  public void goBack() {
    testHostApiImpl.goBack(0L);
    verify(mockWebView).goBack();
  }

  @Test
  public void goForward() {
    testHostApiImpl.goForward(0L);
    verify(mockWebView).goForward();
  }

  @Test
  public void reload() {
    testHostApiImpl.reload(0L);
    verify(mockWebView).reload();
  }

  @Test
  public void clearCache() {
    testHostApiImpl.clearCache(0L, false);
    verify(mockWebView).clearCache(false);
  }

  @Test
  public void evaluateJavaScript() {
    final String[] successValue = new String[1];
    testHostApiImpl.evaluateJavascript(
        0L,
        "2 + 2",
        new GeneratedAndroidWebView.Result<String>() {
          @Override
          public void success(String result) {
            successValue[0] = result;
          }

          @Override
          public void error(Throwable error) {}
        });

    @SuppressWarnings("unchecked")
    final ArgumentCaptor<ValueCallback<String>> callbackCaptor =
        ArgumentCaptor.forClass(ValueCallback.class);
    verify(mockWebView).evaluateJavascript(eq("2 + 2"), callbackCaptor.capture());

    callbackCaptor.getValue().onReceiveValue("da result");
    assertEquals(successValue[0], "da result");
  }

  @Test
  public void getTitle() {
    when(mockWebView.getTitle()).thenReturn("My title");
    assertEquals(testHostApiImpl.getTitle(0L), "My title");
  }

  @Test
  public void scrollTo() {
    testHostApiImpl.scrollTo(0L, 12L, 13L);
    verify(mockWebView).scrollTo(12, 13);
  }

  @Test
  public void scrollBy() {
    testHostApiImpl.scrollBy(0L, 15L, 23L);
    verify(mockWebView).scrollBy(15, 23);
  }

  @Test
  public void getScrollX() {
    when(mockWebView.getScrollX()).thenReturn(55);
    assertEquals((long) testHostApiImpl.getScrollX(0L), 55);
  }

  @Test
  public void getScrollY() {
    when(mockWebView.getScrollY()).thenReturn(23);
    assertEquals((long) testHostApiImpl.getScrollY(0L), 23);
  }

  @Test
  public void getScrollPosition() {
    when(mockWebView.getScrollX()).thenReturn(1);
    when(mockWebView.getScrollY()).thenReturn(2);
    final GeneratedAndroidWebView.WebViewPoint position = testHostApiImpl.getScrollPosition(0L);
    assertEquals((long) position.getX(), 1L);
    assertEquals((long) position.getY(), 2L);
  }

  @Test
  public void setWebViewClient() {
    final WebViewClient mockWebViewClient = mock(WebViewClient.class);
    testInstanceManager.addDartCreatedInstance(mockWebViewClient, 1L);

    testHostApiImpl.setWebViewClient(0L, 1L);
    verify(mockWebView).setWebViewClient(mockWebViewClient);
  }

  @Test
  public void addJavaScriptChannel() {
    final JavaScriptChannel javaScriptChannel =
        new JavaScriptChannel(mock(JavaScriptChannelFlutterApiImpl.class), "aName", null);
    testInstanceManager.addDartCreatedInstance(javaScriptChannel, 1L);

    testHostApiImpl.addJavaScriptChannel(0L, 1L);
    verify(mockWebView).addJavascriptInterface(javaScriptChannel, "aName");
  }

  @Test
  public void removeJavaScriptChannel() {
    final JavaScriptChannel javaScriptChannel =
        new JavaScriptChannel(mock(JavaScriptChannelFlutterApiImpl.class), "aName", null);
    testInstanceManager.addDartCreatedInstance(javaScriptChannel, 1L);

    testHostApiImpl.removeJavaScriptChannel(0L, 1L);
    verify(mockWebView).removeJavascriptInterface("aName");
  }

  @Test
  public void setDownloadListener() {
    final DownloadListener mockDownloadListener = mock(DownloadListener.class);
    testInstanceManager.addDartCreatedInstance(mockDownloadListener, 1L);

    testHostApiImpl.setDownloadListener(0L, 1L);
    verify(mockWebView).setDownloadListener(mockDownloadListener);
  }

  @Test
  public void setWebChromeClient() {
    final WebChromeClient mockWebChromeClient = mock(WebChromeClient.class);
    testInstanceManager.addDartCreatedInstance(mockWebChromeClient, 1L);

    testHostApiImpl.setWebChromeClient(0L, 1L);
    verify(mockWebView).setWebChromeClient(mockWebChromeClient);
  }
}

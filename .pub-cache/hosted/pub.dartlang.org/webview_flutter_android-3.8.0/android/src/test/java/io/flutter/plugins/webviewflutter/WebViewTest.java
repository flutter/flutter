// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.content.Context;
import android.os.Build;
import android.view.View;
import android.webkit.DownloadListener;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebViewClient;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterView;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.WebViewFlutterApi;
import io.flutter.plugins.webviewflutter.WebViewHostApiImpl.WebViewPlatformView;
import io.flutter.plugins.webviewflutter.utils.TestUtils;
import java.util.HashMap;
import java.util.Objects;
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

  @Mock BinaryMessenger mockBinaryMessenger;

  InstanceManager testInstanceManager;
  WebViewHostApiImpl testHostApiImpl;

  @Before
  public void setUp() {
    testInstanceManager = InstanceManager.create(identifier -> {});

    when(mockWebViewProxy.createWebView(mockContext, mockBinaryMessenger, testInstanceManager))
        .thenReturn(mockWebView);
    testHostApiImpl =
        new WebViewHostApiImpl(
            testInstanceManager, mockBinaryMessenger, mockWebViewProxy, mockContext);
    testHostApiImpl.create(0L);
  }

  @After
  public void tearDown() {
    testInstanceManager.stopFinalizationListener();
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
          public void error(@NonNull Throwable error) {}
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

  @Test
  public void defaultWebChromeClientIsSecureWebChromeClient() {
    final WebViewPlatformView webView = new WebViewPlatformView(mockContext, null, null);
    assertTrue(
        webView.getWebChromeClient() instanceof WebChromeClientHostApiImpl.SecureWebChromeClient);
    assertFalse(
        webView.getWebChromeClient() instanceof WebChromeClientHostApiImpl.WebChromeClientImpl);
  }

  @Test
  public void defaultWebChromeClientDoesNotAttemptToCommunicateWithDart() {
    final WebViewPlatformView webView = new WebViewPlatformView(mockContext, null, null);
    // This shouldn't throw an Exception.
    Objects.requireNonNull(webView.getWebChromeClient()).onProgressChanged(webView, 0);
  }

  @Test
  public void disposeDoesNotCallDestroy() {
    final boolean[] destroyCalled = {false};
    final WebViewPlatformView webView =
        new WebViewPlatformView(mockContext, null, null) {
          @Override
          public void destroy() {
            destroyCalled[0] = true;
          }
        };
    webView.dispose();

    assertFalse(destroyCalled[0]);
  }

  @Test
  public void destroyWebViewWhenDisposedFromJavaObjectHostApi() {
    final boolean[] destroyCalled = {false};
    final WebViewPlatformView webView =
        new WebViewPlatformView(mockContext, null, null) {
          @Override
          public void destroy() {
            destroyCalled[0] = true;
          }
        };

    testInstanceManager.addDartCreatedInstance(webView, 1);
    final JavaObjectHostApiImpl javaObjectHostApi = new JavaObjectHostApiImpl(testInstanceManager);
    javaObjectHostApi.dispose(1L);

    assertTrue(destroyCalled[0]);
  }

  @Test
  public void flutterApiCreate() {
    final InstanceManager instanceManager = InstanceManager.create(identifier -> {});

    final WebViewFlutterApiImpl flutterApiImpl =
        new WebViewFlutterApiImpl(mockBinaryMessenger, instanceManager);

    final WebViewFlutterApi mockFlutterApi = mock(WebViewFlutterApi.class);
    flutterApiImpl.setApi(mockFlutterApi);

    flutterApiImpl.create(mockWebView, reply -> {});

    final long instanceIdentifier =
        Objects.requireNonNull(instanceManager.getIdentifierForStrongReference(mockWebView));
    verify(mockFlutterApi).create(eq(instanceIdentifier), any());

    instanceManager.stopFinalizationListener();
  }

  @Test
  public void setImportantForAutofillForParentFlutterView() {
    final WebViewPlatformView webView =
        new WebViewPlatformView(mockContext, mockBinaryMessenger, testInstanceManager);

    final WebViewPlatformView webViewSpy = spy(webView);
    final FlutterView mockFlutterView = mock(FlutterView.class);
    when(webViewSpy.getParent()).thenReturn(mockFlutterView);

    TestUtils.setFinalStatic(Build.VERSION.class, "SDK_INT", Build.VERSION_CODES.O);
    webViewSpy.onAttachedToWindow();

    verify(mockFlutterView).setImportantForAutofill(View.IMPORTANT_FOR_AUTOFILL_YES);
  }
}

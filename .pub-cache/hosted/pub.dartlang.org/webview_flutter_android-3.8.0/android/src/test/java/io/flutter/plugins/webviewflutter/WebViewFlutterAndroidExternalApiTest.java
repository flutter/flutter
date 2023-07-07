// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import android.content.Context;
import android.webkit.WebView;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.PluginRegistry;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.platform.PlatformViewRegistry;
import org.junit.Rule;
import org.junit.Test;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnit;
import org.mockito.junit.MockitoRule;

public class WebViewFlutterAndroidExternalApiTest {
  @Rule public MockitoRule mockitoRule = MockitoJUnit.rule();

  @Mock Context mockContext;

  @Mock BinaryMessenger mockBinaryMessenger;

  @Mock PlatformViewRegistry mockViewRegistry;

  @Mock FlutterPlugin.FlutterPluginBinding mockPluginBinding;

  @Test
  public void getWebView() {
    final WebViewFlutterPlugin webViewFlutterPlugin = new WebViewFlutterPlugin();

    when(mockPluginBinding.getApplicationContext()).thenReturn(mockContext);
    when(mockPluginBinding.getPlatformViewRegistry()).thenReturn(mockViewRegistry);
    when(mockPluginBinding.getBinaryMessenger()).thenReturn(mockBinaryMessenger);

    webViewFlutterPlugin.onAttachedToEngine(mockPluginBinding);

    final InstanceManager instanceManager = webViewFlutterPlugin.getInstanceManager();
    assertNotNull(instanceManager);

    final WebView mockWebView = mock(WebView.class);
    instanceManager.addDartCreatedInstance(mockWebView, 0);

    final PluginRegistry mockPluginRegistry = mock(PluginRegistry.class);
    when(mockPluginRegistry.get(WebViewFlutterPlugin.class)).thenReturn(webViewFlutterPlugin);

    final FlutterEngine mockFlutterEngine = mock(FlutterEngine.class);
    when(mockFlutterEngine.getPlugins()).thenReturn(mockPluginRegistry);

    assertEquals(WebViewFlutterAndroidExternalApi.getWebView(mockFlutterEngine, 0), mockWebView);

    webViewFlutterPlugin.onDetachedFromEngine(mockPluginBinding);
  }
}

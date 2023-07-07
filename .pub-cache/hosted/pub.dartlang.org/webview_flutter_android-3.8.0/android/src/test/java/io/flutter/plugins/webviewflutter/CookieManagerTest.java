// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.os.Build;
import android.webkit.CookieManager;
import android.webkit.ValueCallback;
import android.webkit.WebView;
import androidx.annotation.NonNull;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugins.webviewflutter.utils.TestUtils;
import org.junit.After;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnit;
import org.mockito.junit.MockitoRule;

public class CookieManagerTest {
  @Rule public MockitoRule mockitoRule = MockitoJUnit.rule();
  @Mock public CookieManager mockCookieManager;
  @Mock public BinaryMessenger mockBinaryMessenger;
  @Mock public CookieManagerHostApiImpl.CookieManagerProxy mockProxy;
  InstanceManager instanceManager;

  @Before
  public void setUp() {
    instanceManager = InstanceManager.create(identifier -> {});
  }

  @After
  public void tearDown() {
    instanceManager.stopFinalizationListener();
  }

  @Test
  public void getInstance() {
    final CookieManager mockCookieManager = mock(CookieManager.class);
    final long instanceIdentifier = 1;

    when(mockProxy.getInstance()).thenReturn(mockCookieManager);

    final CookieManagerHostApiImpl hostApi =
        new CookieManagerHostApiImpl(mockBinaryMessenger, instanceManager, mockProxy);
    hostApi.attachInstance(instanceIdentifier);

    assertEquals(instanceManager.getInstance(instanceIdentifier), mockCookieManager);
  }

  @Test
  public void setCookie() {
    final String url = "testString";
    final String value = "testString2";

    final long instanceIdentifier = 0;
    instanceManager.addDartCreatedInstance(mockCookieManager, instanceIdentifier);

    final CookieManagerHostApiImpl hostApi =
        new CookieManagerHostApiImpl(mockBinaryMessenger, instanceManager);

    hostApi.setCookie(instanceIdentifier, url, value);

    verify(mockCookieManager).setCookie(url, value);
  }

  @SuppressWarnings({"rawtypes", "unchecked"})
  @Test
  public void clearCookies() {
    TestUtils.setFinalStatic(Build.VERSION.class, "SDK_INT", Build.VERSION_CODES.LOLLIPOP);

    final long instanceIdentifier = 0;
    instanceManager.addDartCreatedInstance(mockCookieManager, instanceIdentifier);

    final CookieManagerHostApiImpl hostApi =
        new CookieManagerHostApiImpl(mockBinaryMessenger, instanceManager);

    final Boolean[] successResult = new Boolean[1];
    hostApi.removeAllCookies(
        instanceIdentifier,
        new GeneratedAndroidWebView.Result<Boolean>() {
          @Override
          public void success(Boolean result) {
            successResult[0] = result;
          }

          @Override
          public void error(@NonNull Throwable error) {}
        });

    final ArgumentCaptor<ValueCallback> valueCallbackArgumentCaptor =
        ArgumentCaptor.forClass(ValueCallback.class);
    verify(mockCookieManager).removeAllCookies(valueCallbackArgumentCaptor.capture());

    final Boolean returnValue = true;
    valueCallbackArgumentCaptor.getValue().onReceiveValue(returnValue);

    assertEquals(successResult[0], returnValue);
  }

  @Test
  public void setAcceptThirdPartyCookies() {
    TestUtils.setFinalStatic(Build.VERSION.class, "SDK_INT", Build.VERSION_CODES.LOLLIPOP);

    final WebView mockWebView = mock(WebView.class);
    final long webViewIdentifier = 4;
    instanceManager.addDartCreatedInstance(mockWebView, webViewIdentifier);

    final boolean accept = true;

    final long instanceIdentifier = 0;
    instanceManager.addDartCreatedInstance(mockCookieManager, instanceIdentifier);

    final CookieManagerHostApiImpl hostApi =
        new CookieManagerHostApiImpl(mockBinaryMessenger, instanceManager);

    hostApi.setAcceptThirdPartyCookies(instanceIdentifier, webViewIdentifier, accept);

    verify(mockCookieManager).setAcceptThirdPartyCookies(mockWebView, accept);
  }
}

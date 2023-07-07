// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.os.Build;
import android.webkit.CookieManager;
import android.webkit.ValueCallback;
import io.flutter.plugins.webviewflutter.utils.TestUtils;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.mockito.MockedStatic;

public class CookieManagerHostApiImplTest {

  private CookieManager cookieManager;
  private MockedStatic<CookieManager> staticMockCookieManager;

  @Before
  public void setup() {
    staticMockCookieManager = mockStatic(CookieManager.class);
    cookieManager = mock(CookieManager.class);
    when(CookieManager.getInstance()).thenReturn(cookieManager);
    when(cookieManager.hasCookies()).thenReturn(true);
    doAnswer(
            answer -> {
              ((ValueCallback<Boolean>) answer.getArgument(0)).onReceiveValue(true);
              return null;
            })
        .when(cookieManager)
        .removeAllCookies(any());
  }

  @After
  public void tearDown() {
    staticMockCookieManager.close();
  }

  @Test
  public void setCookieShouldCallSetCookie() {
    // Setup
    CookieManagerHostApiImpl impl = new CookieManagerHostApiImpl();
    // Run
    impl.setCookie("flutter.dev", "foo=bar; path=/");
    // Verify
    verify(cookieManager).setCookie("flutter.dev", "foo=bar; path=/");
  }

  @Test
  public void clearCookiesShouldCallRemoveAllCookiesOnAndroidLAbove() {
    // Setup
    TestUtils.setFinalStatic(Build.VERSION.class, "SDK_INT", Build.VERSION_CODES.LOLLIPOP);
    GeneratedAndroidWebView.Result<Boolean> result = mock(GeneratedAndroidWebView.Result.class);
    CookieManagerHostApiImpl impl = new CookieManagerHostApiImpl();
    // Run
    impl.clearCookies(result);
    // Verify
    verify(cookieManager).removeAllCookies(any());
    verify(result).success(true);
  }

  @Test
  public void clearCookiesShouldCallRemoveAllCookieBelowAndroidL() {
    // Setup
    TestUtils.setFinalStatic(Build.VERSION.class, "SDK_INT", Build.VERSION_CODES.KITKAT_WATCH);
    GeneratedAndroidWebView.Result<Boolean> result = mock(GeneratedAndroidWebView.Result.class);
    CookieManagerHostApiImpl impl = new CookieManagerHostApiImpl();
    // Run
    impl.clearCookies(result);
    // Verify
    verify(cookieManager).removeAllCookie();
    verify(result).success(true);
  }
}

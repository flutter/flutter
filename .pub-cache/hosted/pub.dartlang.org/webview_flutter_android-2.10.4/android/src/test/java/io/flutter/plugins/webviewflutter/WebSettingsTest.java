// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.webkit.WebSettings;
import io.flutter.plugins.webviewflutter.WebSettingsHostApiImpl.WebSettingsCreator;
import org.junit.After;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnit;
import org.mockito.junit.MockitoRule;

public class WebSettingsTest {
  @Rule public MockitoRule mockitoRule = MockitoJUnit.rule();

  @Mock public WebSettings mockWebSettings;

  @Mock WebSettingsCreator mockWebSettingsCreator;

  InstanceManager testInstanceManager;
  WebSettingsHostApiImpl testHostApiImpl;

  @Before
  public void setUp() {
    testInstanceManager = InstanceManager.open(identifier -> {});

    when(mockWebSettingsCreator.createWebSettings(any())).thenReturn(mockWebSettings);
    testHostApiImpl = new WebSettingsHostApiImpl(testInstanceManager, mockWebSettingsCreator);
    testHostApiImpl.create(0L, 0L);
  }

  @After
  public void tearDown() {
    testInstanceManager.close();
  }

  @Test
  public void setDomStorageEnabled() {
    testHostApiImpl.setDomStorageEnabled(0L, true);
    verify(mockWebSettings).setDomStorageEnabled(true);
  }

  @Test
  public void setJavaScriptCanOpenWindowsAutomatically() {
    testHostApiImpl.setJavaScriptCanOpenWindowsAutomatically(0L, false);
    verify(mockWebSettings).setJavaScriptCanOpenWindowsAutomatically(false);
  }

  @Test
  public void setSupportMultipleWindows() {
    testHostApiImpl.setSupportMultipleWindows(0L, true);
    verify(mockWebSettings).setSupportMultipleWindows(true);
  }

  @Test
  public void setJavaScriptEnabled() {
    testHostApiImpl.setJavaScriptEnabled(0L, false);
    verify(mockWebSettings).setJavaScriptEnabled(false);
  }

  @Test
  public void setUserAgentString() {
    testHostApiImpl.setUserAgentString(0L, "hello");
    verify(mockWebSettings).setUserAgentString("hello");
  }

  @Test
  public void setMediaPlaybackRequiresUserGesture() {
    testHostApiImpl.setMediaPlaybackRequiresUserGesture(0L, false);
    verify(mockWebSettings).setMediaPlaybackRequiresUserGesture(false);
  }

  @Test
  public void setSupportZoom() {
    testHostApiImpl.setSupportZoom(0L, true);
    verify(mockWebSettings).setSupportZoom(true);
  }

  @Test
  public void setLoadWithOverviewMode() {
    testHostApiImpl.setLoadWithOverviewMode(0L, false);
    verify(mockWebSettings).setLoadWithOverviewMode(false);
  }

  @Test
  public void setUseWideViewPort() {
    testHostApiImpl.setUseWideViewPort(0L, true);
    verify(mockWebSettings).setUseWideViewPort(true);
  }

  @Test
  public void setDisplayZoomControls() {
    testHostApiImpl.setDisplayZoomControls(0L, false);
    verify(mockWebSettings).setDisplayZoomControls(false);
  }

  @Test
  public void setBuiltInZoomControls() {
    testHostApiImpl.setBuiltInZoomControls(0L, true);
    verify(mockWebSettings).setBuiltInZoomControls(true);
  }
}

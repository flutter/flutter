// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;

import android.os.Handler;
import io.flutter.plugins.webviewflutter.JavaScriptChannelHostApiImpl.JavaScriptChannelCreator;
import org.junit.After;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnit;
import org.mockito.junit.MockitoRule;

public class JavaScriptChannelTest {
  @Rule public MockitoRule mockitoRule = MockitoJUnit.rule();

  @Mock public JavaScriptChannelFlutterApiImpl mockFlutterApi;

  InstanceManager instanceManager;
  JavaScriptChannelHostApiImpl hostApiImpl;
  JavaScriptChannel javaScriptChannel;

  @Before
  public void setUp() {
    instanceManager = InstanceManager.open(identifier -> {});

    final JavaScriptChannelCreator javaScriptChannelCreator =
        new JavaScriptChannelCreator() {
          @Override
          public JavaScriptChannel createJavaScriptChannel(
              JavaScriptChannelFlutterApiImpl javaScriptChannelFlutterApi,
              String channelName,
              Handler platformThreadHandler) {
            javaScriptChannel =
                super.createJavaScriptChannel(
                    javaScriptChannelFlutterApi, channelName, platformThreadHandler);
            return javaScriptChannel;
          }
        };

    hostApiImpl =
        new JavaScriptChannelHostApiImpl(
            instanceManager, javaScriptChannelCreator, mockFlutterApi, new Handler());
    hostApiImpl.create(0L, "aChannelName");
  }

  @After
  public void tearDown() {
    instanceManager.close();
  }

  @Test
  public void postMessage() {
    javaScriptChannel.postMessage("A message post.");
    verify(mockFlutterApi).postMessage(eq(javaScriptChannel), eq("A message post."), any());

    reset(mockFlutterApi);
    javaScriptChannel.release();
    javaScriptChannel.postMessage("a message");
    verify(mockFlutterApi, never()).postMessage((JavaScriptChannel) any(), any(), any());
  }
}

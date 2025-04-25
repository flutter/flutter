// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.view;

import static org.mockito.Mockito.any;
import static org.mockito.Mockito.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;

import org.mockito.ArgumentCaptor;
import android.app.Activity;
import android.view.View;
import android.view.ViewStructure;
import android.view.inputmethod.InputConnection;
import android.view.inputmethod.InputMethodManager;
import android.view.inputmethod.InputMethodSubtype;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodCall;
import java.nio.ByteBuffer;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.robolectric.Robolectric;
import org.robolectric.annotation.Config;
import org.robolectric.annotation.Implementation;
import org.robolectric.annotation.Implements;
import org.robolectric.shadow.api.Shadow;
import org.robolectric.shadows.ShadowAutofillManager;
import org.robolectric.shadows.ShadowBuild;
import org.robolectric.shadows.ShadowInputMethodManager;
import org.robolectric.Robolectric;
import android.os.Build;
import io.flutter.embedding.engine.systemchannels.SensitiveContentChannel;
import io.flutter.plugin.common.MethodChannel;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.junit.Test;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMethodCodec;

@RunWith(AndroidJUnit4.class)
public class SensitiveContentPluginTest {

  private static void sendToBinaryMessageHandler(
      BinaryMessenger.BinaryMessageHandler binaryMessageHandler, String method, Object args) {
    MethodCall methodCall = new MethodCall(method, args);
    ByteBuffer encodedMethodCall = StandardMethodCodec.INSTANCE.encodeMethodCall(methodCall);
    binaryMessageHandler.onMessage(
        (ByteBuffer) encodedMethodCall.flip(), mock(BinaryMessenger.BinaryReply.class));
  }

  @SuppressWarnings("deprecation")
  // setMessageHandler is deprecated.
  @Test
  public void respondsToSensitiveContentChannelMessage() {
    ArgumentCaptor<BinaryMessenger.BinaryMessageHandler> binaryMessageHandlerCaptor =
        ArgumentCaptor.forClass(BinaryMessenger.BinaryMessageHandler.class);
    DartExecutor mockBinaryMessenger = mock(DartExecutor.class);
    SensitiveContentChannel.SensitiveContentMethodHandler mockHandler =
        mock(SensitiveContentChannel.SensitiveContentMethodHandler.class);
    SensitiveContentChannel sensitiveContentChannel = new SensitiveContentChannel(mockBinaryMessenger);

    sensitiveContentChannel.setSensitiveContentMethodHandler(mockHandler);

    verify(mockBinaryMessenger, times(1))
        .setMessageHandler(any(String.class), binaryMessageHandlerCaptor.capture());

    BinaryMessenger.BinaryMessageHandler binaryMessageHandler =
        binaryMessageHandlerCaptor.getValue();
    final int contentSensitivityLevel = 2;

    sendToBinaryMessageHandler(
        binaryMessageHandler,
        "SensitiveContent.setContentSensitivity",
        contentSensitivityLevel);

    verify(mockHandler)
        .setContentSensitivity(eq(contentSensitivityLevel), any(MethodChannel.Result.class));
  }

  @Test
  @Config(maxSdk = 34)
  public void setContentSensitivty_doesNotSetContentSensitivityWhenRunningBelowApi35() {
    final int fakeFlutterViewId = 56;
    final Activity mockFlutterActivity = mock(Activity.class);
    final SensitiveContentChannel mockSensitiveContentChannel = mock(SensitiveContentChannel.class);
    final SensitiveContentPlugin sensitiveContentPlugin =
        spy(new SensitiveContentPlugin(fakeFlutterViewId, mockFlutterActivity, mockSensitiveContentChannel));
    final MethodChannel.Result mockResult = mock(MethodChannel.Result.class);

    sensitiveContentPlugin.setContentSensitivity(1, mockResult);

    verifyNoMoreInteractions(mockFlutterActivity);
    verify(mockResult).success(null);
  }

  @Test
  @Config(minSdk = 35)
  public void setContentSensitivty_setsContentSensitivityWhenRunningAboveApi35WhenSettingDifferentStateAsCurrent() {
    final int fakeFlutterViewId = 51;
    final Activity mockFlutterActivity = mock(Activity.class);
    final SensitiveContentChannel mockSensitiveContentChannel = mock(SensitiveContentChannel.class);
    final SensitiveContentPlugin sensitiveContentPlugin =
        spy(new SensitiveContentPlugin(fakeFlutterViewId, mockFlutterActivity, mockSensitiveContentChannel));
    final View mockFlutterView = mock(View.class);
    final MethodChannel.Result mockResult = mock(MethodChannel.Result.class);
    final int testCurrentContentSensitivityValue = 0;
    final int testContentSensitivityValueToSet = 2;

    when(mockFlutterActivity.findViewById(fakeFlutterViewId)).thenReturn(mockFlutterView);
    when(mockFlutterView.getContentSensitivity()).thenReturn(testCurrentContentSensitivityValue);

    sensitiveContentPlugin.setContentSensitivity(testContentSensitivityValueToSet, mockResult);

    verify(mockFlutterView).setContentSensitivity(testContentSensitivityValueToSet);
    verify(mockFlutterView).invalidate();
    verify(mockResult).success(null);
  }

  @Test
  @Config(minSdk = 35)
  public void setContentSensitivty_doesNotSetContentSensitivityWhenRunningAboveApi35WhenSettingSameStateAsCurrent() {
    final int fakeFlutterViewId = 13;
    final Activity mockFlutterActivity = mock(Activity.class);
    final SensitiveContentChannel mockSensitiveContentChannel = mock(SensitiveContentChannel.class);
    final SensitiveContentPlugin sensitiveContentPlugin =
        spy(new SensitiveContentPlugin(fakeFlutterViewId, mockFlutterActivity, mockSensitiveContentChannel));
    final View mockFlutterView = mock(View.class);
    final MethodChannel.Result mockResult = mock(MethodChannel.Result.class);
    final int testCurrentContentSensitivityValue = 1;
    final int testContentSensitivityValueToSet = 1;

    when(mockFlutterActivity.findViewById(fakeFlutterViewId)).thenReturn(mockFlutterView);
    when(mockFlutterView.getContentSensitivity()).thenReturn(testCurrentContentSensitivityValue);

    sensitiveContentPlugin.setContentSensitivity(testContentSensitivityValueToSet, mockResult);

    verify(mockFlutterView, never()).setContentSensitivity(testContentSensitivityValueToSet);
    verify(mockFlutterView, never()).invalidate();
    verify(mockResult).success(null);
  }

  @Test
  @Config(maxSdk = 34)
  public void getContentSensitivity_doesNotGetContentSensitivityWhenRunningBelowApi35() {
    final int fakeFlutterViewId = 33;
    final Activity mockFlutterActivity = mock(Activity.class);
    final SensitiveContentChannel mockSensitiveContentChannel = mock(SensitiveContentChannel.class);
    final SensitiveContentPlugin sensitiveContentPlugin =
        spy(new SensitiveContentPlugin(fakeFlutterViewId, mockFlutterActivity, mockSensitiveContentChannel));
    final MethodChannel.Result mockResult = mock(MethodChannel.Result.class);

    sensitiveContentPlugin.getContentSensitivity(mockResult);

    verifyNoMoreInteractions(mockFlutterActivity);
    verify(mockResult).success(null);
  }

@Test
  @Config(minSdk = 35)
  public void getContentSensitivity_getsContentSensitivityWhenRunningAboveApi35() {
    final int fakeFlutterViewId = 80;
    final Activity mockFlutterActivity = mock(Activity.class);
    final SensitiveContentChannel mockSensitiveContentChannel = mock(SensitiveContentChannel.class);
    final SensitiveContentPlugin sensitiveContentPlugin =
        spy(new SensitiveContentPlugin(fakeFlutterViewId, mockFlutterActivity, mockSensitiveContentChannel));
    final View mockFlutterView = mock(View.class);
    final MethodChannel.Result mockResult = mock(MethodChannel.Result.class);
    final int testCurrentContentSensitivityValue = 2;

    when(mockFlutterActivity.findViewById(fakeFlutterViewId)).thenReturn(mockFlutterView);
    when(mockFlutterView.getContentSensitivity()).thenReturn(testCurrentContentSensitivityValue);

    sensitiveContentPlugin.getContentSensitivity(mockResult);

    verify(mockResult).success(testCurrentContentSensitivityValue);
  }

}
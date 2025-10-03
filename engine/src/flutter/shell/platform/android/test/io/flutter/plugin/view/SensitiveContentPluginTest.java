// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.view;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertThrows;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.anyString;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.eq;
import static org.mockito.Mockito.isNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;
import static org.mockito.Mockito.when;

import android.app.Activity;
import android.view.View;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.systemchannels.SensitiveContentChannel;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StandardMethodCodec;
import java.nio.ByteBuffer;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.robolectric.annotation.Config;

@RunWith(AndroidJUnit4.class)
public class SensitiveContentPluginTest {

  private String setContentSensitivityMethodName = "SensitiveContent.setContentSensitivity";
  private String getContentSensitivityMethodName = "SensitiveContent.getContentSensitivity";

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
  public void respondsToSensitiveContentChannelSetContentSensitivityMessageAsExpected() {
    ArgumentCaptor<BinaryMessenger.BinaryMessageHandler> binaryMessageHandlerCaptor =
        ArgumentCaptor.forClass(BinaryMessenger.BinaryMessageHandler.class);
    DartExecutor mockBinaryMessenger = mock(DartExecutor.class);
    SensitiveContentChannel.SensitiveContentMethodHandler mockHandler =
        mock(SensitiveContentChannel.SensitiveContentMethodHandler.class);
    SensitiveContentChannel sensitiveContentChannel =
        new SensitiveContentChannel(mockBinaryMessenger);

    sensitiveContentChannel.setSensitiveContentMethodHandler(mockHandler);

    verify(mockBinaryMessenger, times(1))
        .setMessageHandler(any(String.class), binaryMessageHandlerCaptor.capture());

    BinaryMessenger.BinaryMessageHandler binaryMessageHandler =
        binaryMessageHandlerCaptor.getValue();

    // Test each possible content sensitivity value:
    sendToBinaryMessageHandler(
        binaryMessageHandler,
        setContentSensitivityMethodName,
        SensitiveContentChannel.AUTO_SENSITIVE_CONTENT_SENSITIVITY);
    verify(mockHandler).setContentSensitivity(eq(View.CONTENT_SENSITIVITY_AUTO));

    sendToBinaryMessageHandler(
        binaryMessageHandler,
        setContentSensitivityMethodName,
        SensitiveContentChannel.SENSITIVE_CONTENT_SENSITIVITY);
    verify(mockHandler).setContentSensitivity(eq(View.CONTENT_SENSITIVITY_SENSITIVE));

    sendToBinaryMessageHandler(
        binaryMessageHandler,
        setContentSensitivityMethodName,
        SensitiveContentChannel.NOT_SENSITIVE_CONTENT_SENSITIVITY);
    verify(mockHandler).setContentSensitivity(eq(View.CONTENT_SENSITIVITY_NOT_SENSITIVE));
  }

  @Test
  public void
      respondsToSensitiveContentChannelSetContentSensitivityWithErrorWhenIsSupportedNotCalledFirst() {
    DartExecutor mockBinaryMessenger = mock(DartExecutor.class);
    SensitiveContentChannel.SensitiveContentMethodHandler mockHandler =
        mock(SensitiveContentChannel.SensitiveContentMethodHandler.class);
    SensitiveContentChannel sensitiveContentChannel =
        new SensitiveContentChannel(mockBinaryMessenger);
    MethodCall methodCall =
        new MethodCall(
            "SensitiveContent.setContentSensitivity",
            SensitiveContentChannel.AUTO_SENSITIVE_CONTENT_SENSITIVITY);
    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);

    sensitiveContentChannel.setSensitiveContentMethodHandler(mockHandler);
    doThrow(new IllegalStateException("when isSupported is not first called, we throw this"))
        .when(mockHandler)
        .setContentSensitivity(View.CONTENT_SENSITIVITY_AUTO);

    sensitiveContentChannel.parsingMethodHandler.onMethodCall(methodCall, mockResult);

    verify(mockResult).error(eq("error"), anyString(), isNull());
  }

  @Test
  public void
      respondsToSensitiveContentChannelSetContentSensitivityWithErrorWhenFlutterViewNotFound() {
    DartExecutor mockBinaryMessenger = mock(DartExecutor.class);
    SensitiveContentChannel.SensitiveContentMethodHandler mockHandler =
        mock(SensitiveContentChannel.SensitiveContentMethodHandler.class);
    SensitiveContentChannel sensitiveContentChannel =
        new SensitiveContentChannel(mockBinaryMessenger);
    MethodCall methodCall =
        new MethodCall(
            "SensitiveContent.setContentSensitivity",
            SensitiveContentChannel.AUTO_SENSITIVE_CONTENT_SENSITIVITY);
    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);

    sensitiveContentChannel.setSensitiveContentMethodHandler(mockHandler);
    doThrow(new IllegalArgumentException("when FlutterView is not found, we throw this"))
        .when(mockHandler)
        .setContentSensitivity(View.CONTENT_SENSITIVITY_AUTO);

    sensitiveContentChannel.parsingMethodHandler.onMethodCall(methodCall, mockResult);

    verify(mockResult).error(eq("error"), anyString(), isNull());
  }

  @Test
  public void
      respondsToSensitiveContentChannelGetContentSensitivityWithExpectedContentSensitivity() {
    DartExecutor mockBinaryMessenger = mock(DartExecutor.class);
    SensitiveContentChannel.SensitiveContentMethodHandler mockHandler =
        mock(SensitiveContentChannel.SensitiveContentMethodHandler.class);
    SensitiveContentChannel sensitiveContentChannel =
        new SensitiveContentChannel(mockBinaryMessenger);
    MethodCall methodCall = new MethodCall(getContentSensitivityMethodName, null);

    sensitiveContentChannel.setSensitiveContentMethodHandler(mockHandler);

    // Test each possible content sensitivity value:
    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);
    when(mockHandler.getContentSensitivity()).thenReturn(View.CONTENT_SENSITIVITY_AUTO);
    sensitiveContentChannel.parsingMethodHandler.onMethodCall(methodCall, mockResult);
    verify(mockResult).success(SensitiveContentChannel.AUTO_SENSITIVE_CONTENT_SENSITIVITY);

    mockResult = mock(MethodChannel.Result.class);
    when(mockHandler.getContentSensitivity()).thenReturn(View.CONTENT_SENSITIVITY_SENSITIVE);
    sensitiveContentChannel.parsingMethodHandler.onMethodCall(methodCall, mockResult);
    verify(mockResult).success(SensitiveContentChannel.SENSITIVE_CONTENT_SENSITIVITY);

    mockResult = mock(MethodChannel.Result.class);
    when(mockHandler.getContentSensitivity()).thenReturn(View.CONTENT_SENSITIVITY_NOT_SENSITIVE);
    sensitiveContentChannel.parsingMethodHandler.onMethodCall(methodCall, mockResult);
    verify(mockResult).success(SensitiveContentChannel.NOT_SENSITIVE_CONTENT_SENSITIVITY);

    // Test an unknown value:
    mockResult = mock(MethodChannel.Result.class);
    when(mockHandler.getContentSensitivity()).thenReturn(94502);
    sensitiveContentChannel.parsingMethodHandler.onMethodCall(methodCall, mockResult);
    verify(mockResult).success(SensitiveContentChannel.UNKNOWN_CONTENT_SENSITIVITY);
  }

  @Test
  public void
      respondsToSensitiveContentChannelGetContentSensitivityWithErrorWhenIsSupportedNotCalledFirst() {
    DartExecutor mockBinaryMessenger = mock(DartExecutor.class);
    SensitiveContentChannel.SensitiveContentMethodHandler mockHandler =
        mock(SensitiveContentChannel.SensitiveContentMethodHandler.class);
    SensitiveContentChannel sensitiveContentChannel =
        new SensitiveContentChannel(mockBinaryMessenger);
    MethodCall methodCall = new MethodCall(getContentSensitivityMethodName, null);
    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);

    sensitiveContentChannel.setSensitiveContentMethodHandler(mockHandler);

    when(mockHandler.getContentSensitivity())
        .thenThrow(
            new IllegalStateException("when isSupported is not first called, we throw this"));
    sensitiveContentChannel.parsingMethodHandler.onMethodCall(methodCall, mockResult);
    verify(mockResult).error(eq("error"), anyString(), isNull());
  }

  @Test
  public void
      respondsToSensitiveContentChannelGetContentSensitivityWithErrorWhenFlutterViewNotFound() {
    DartExecutor mockBinaryMessenger = mock(DartExecutor.class);
    SensitiveContentChannel.SensitiveContentMethodHandler mockHandler =
        mock(SensitiveContentChannel.SensitiveContentMethodHandler.class);
    SensitiveContentChannel sensitiveContentChannel =
        new SensitiveContentChannel(mockBinaryMessenger);
    MethodCall methodCall = new MethodCall(getContentSensitivityMethodName, null);
    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);

    sensitiveContentChannel.setSensitiveContentMethodHandler(mockHandler);

    when(mockHandler.getContentSensitivity())
        .thenThrow(new IllegalArgumentException("when FlutterView is not found, we throw this"));
    sensitiveContentChannel.parsingMethodHandler.onMethodCall(methodCall, mockResult);
    verify(mockResult).error(eq("error"), anyString(), isNull());
  }

  @Test
  @Config(maxSdk = 34)
  public void
      setContentSensitivity_doesNotSetContentSensitivityAndThrowsExceptionWhenRunningBelowApi35() {
    final int fakeFlutterViewId = 56;
    final Activity mockFlutterActivity = mock(Activity.class);
    final SensitiveContentChannel mockSensitiveContentChannel = mock(SensitiveContentChannel.class);
    final SensitiveContentPlugin sensitiveContentPlugin =
        new SensitiveContentPlugin(
            fakeFlutterViewId, mockFlutterActivity, mockSensitiveContentChannel);

    assertThrows(
        IllegalStateException.class, () -> sensitiveContentPlugin.setContentSensitivity(1));
    verifyNoMoreInteractions(mockFlutterActivity);
  }

  @Test
  @Config(minSdk = 35)
  public void setContentSensitivity_throwsExceptionWhenRunningAboveApi35AndFlutterViewNotFound() {
    final int fakeFlutterViewId = 52;
    final Activity mockFlutterActivity = mock(Activity.class);
    final SensitiveContentChannel mockSensitiveContentChannel = mock(SensitiveContentChannel.class);
    final SensitiveContentPlugin sensitiveContentPlugin =
        new SensitiveContentPlugin(
            fakeFlutterViewId, mockFlutterActivity, mockSensitiveContentChannel);
    final int testCurrentContentSensitivityValue = 0;
    final int testContentSensitivityValueToSet = 2;

    when(mockFlutterActivity.findViewById(fakeFlutterViewId)).thenReturn(null);

    assertThrows(
        IllegalArgumentException.class,
        () -> sensitiveContentPlugin.setContentSensitivity(testContentSensitivityValueToSet));
  }

  @Test
  @Config(minSdk = 35)
  public void
      setContentSensitivity_setsContentSensitivityWhenRunningAboveApi35WhenSettingDifferentStateAsCurrent() {
    final int fakeFlutterViewId = 51;
    final Activity mockFlutterActivity = mock(Activity.class);
    final SensitiveContentChannel mockSensitiveContentChannel = mock(SensitiveContentChannel.class);
    final SensitiveContentPlugin sensitiveContentPlugin =
        new SensitiveContentPlugin(
            fakeFlutterViewId, mockFlutterActivity, mockSensitiveContentChannel);
    final View mockFlutterView = mock(View.class);
    final int testCurrentContentSensitivityValue = 0;
    final int testContentSensitivityValueToSet = 2;

    when(mockFlutterActivity.findViewById(fakeFlutterViewId)).thenReturn(mockFlutterView);
    when(mockFlutterView.getContentSensitivity()).thenReturn(testCurrentContentSensitivityValue);

    sensitiveContentPlugin.setContentSensitivity(testContentSensitivityValueToSet);

    verify(mockFlutterView).setContentSensitivity(testContentSensitivityValueToSet);
    verify(mockFlutterView).invalidate();
  }

  @Test
  @Config(minSdk = 35)
  public void
      setContentSensitivity_doesNotSetContentSensitivityWhenRunningAboveApi35WhenSettingSameStateAsCurrent() {
    final int fakeFlutterViewId = 13;
    final Activity mockFlutterActivity = mock(Activity.class);
    final SensitiveContentChannel mockSensitiveContentChannel = mock(SensitiveContentChannel.class);
    final SensitiveContentPlugin sensitiveContentPlugin =
        new SensitiveContentPlugin(
            fakeFlutterViewId, mockFlutterActivity, mockSensitiveContentChannel);
    final View mockFlutterView = mock(View.class);
    final int testCurrentContentSensitivityValue = 1;
    final int testContentSensitivityValueToSet = 1;

    when(mockFlutterActivity.findViewById(fakeFlutterViewId)).thenReturn(mockFlutterView);
    when(mockFlutterView.getContentSensitivity()).thenReturn(testCurrentContentSensitivityValue);

    sensitiveContentPlugin.setContentSensitivity(testContentSensitivityValueToSet);

    verify(mockFlutterView, never()).setContentSensitivity(testContentSensitivityValueToSet);
    verify(mockFlutterView, never()).invalidate();
  }

  @Test
  @Config(maxSdk = 34)
  public void getContentSensitivity_returnsNotSensitiveRunningBelowApi35() {
    final int fakeFlutterViewId = 33;
    final Activity mockFlutterActivity = mock(Activity.class);
    final SensitiveContentChannel mockSensitiveContentChannel = mock(SensitiveContentChannel.class);
    final SensitiveContentPlugin sensitiveContentPlugin =
        new SensitiveContentPlugin(
            fakeFlutterViewId, mockFlutterActivity, mockSensitiveContentChannel);
    final View mockFlutterView = mock(View.class);

    when(mockFlutterActivity.findViewById(fakeFlutterViewId)).thenReturn(mockFlutterView);

    assertEquals(
        View.CONTENT_SENSITIVITY_NOT_SENSITIVE, sensitiveContentPlugin.getContentSensitivity());
  }

  @Test
  @Config(minSdk = 35)
  public void getContentSensitivity_throwsExceptionWhenRunningAboveApi35AndFlutterViewNotFound() {
    final int fakeFlutterViewId = 80;
    final Activity mockFlutterActivity = mock(Activity.class);
    final SensitiveContentChannel mockSensitiveContentChannel = mock(SensitiveContentChannel.class);
    final SensitiveContentPlugin sensitiveContentPlugin =
        new SensitiveContentPlugin(
            fakeFlutterViewId, mockFlutterActivity, mockSensitiveContentChannel);

    when(mockFlutterActivity.findViewById(fakeFlutterViewId)).thenReturn(null);

    assertThrows(IllegalArgumentException.class, sensitiveContentPlugin::getContentSensitivity);
  }

  @Test
  @Config(minSdk = 35)
  public void getContentSensitivity_getsContentSensitivityWhenRunningAboveApi35() {
    final int fakeFlutterViewId = 81;
    final Activity mockFlutterActivity = mock(Activity.class);
    final SensitiveContentChannel mockSensitiveContentChannel = mock(SensitiveContentChannel.class);
    final SensitiveContentPlugin sensitiveContentPlugin =
        new SensitiveContentPlugin(
            fakeFlutterViewId, mockFlutterActivity, mockSensitiveContentChannel);
    final View mockFlutterView = mock(View.class);
    final int testCurrentContentSensitivityValue = 2;

    when(mockFlutterActivity.findViewById(fakeFlutterViewId)).thenReturn(mockFlutterView);
    when(mockFlutterView.getContentSensitivity()).thenReturn(testCurrentContentSensitivityValue);

    assertEquals(
        testCurrentContentSensitivityValue, sensitiveContentPlugin.getContentSensitivity());
  }

  @Test
  @Config(maxSdk = 34)
  public void isSupported_returnsFalseWhenRunningBelowApi35() {
    final int fakeFlutterViewId = 19;
    final Activity mockFlutterActivity = mock(Activity.class);
    final SensitiveContentChannel mockSensitiveContentChannel = mock(SensitiveContentChannel.class);
    final SensitiveContentPlugin sensitiveContentPlugin =
        new SensitiveContentPlugin(
            fakeFlutterViewId, mockFlutterActivity, mockSensitiveContentChannel);

    assertFalse(sensitiveContentPlugin.isSupported());
  }

  @Test
  @Config(minSdk = 35)
  public void isSupported_returnsTrueWhenRunningAboveApi35() {
    final int fakeFlutterViewId = 14;
    final Activity mockFlutterActivity = mock(Activity.class);
    final SensitiveContentChannel mockSensitiveContentChannel = mock(SensitiveContentChannel.class);
    final SensitiveContentPlugin sensitiveContentPlugin =
        new SensitiveContentPlugin(
            fakeFlutterViewId, mockFlutterActivity, mockSensitiveContentChannel);

    assertTrue(sensitiveContentPlugin.isSupported());
  }
}

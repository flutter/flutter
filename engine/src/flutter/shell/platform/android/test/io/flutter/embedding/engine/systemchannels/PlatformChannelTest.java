// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import static org.junit.Assert.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.refEq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;
import static org.mockito.Mockito.when;

import android.content.res.AssetManager;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.util.Arrays;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;

@RunWith(AndroidJUnit4.class)
public class PlatformChannelTest {
  @Test
  public void platformChannel_hasStringsMessage() {
    MethodChannel rawChannel = mock(MethodChannel.class);
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = new DartExecutor(mockFlutterJNI, mock(AssetManager.class));
    PlatformChannel fakePlatformChannel = new PlatformChannel(dartExecutor);
    PlatformChannel.PlatformMessageHandler mockMessageHandler =
        mock(PlatformChannel.PlatformMessageHandler.class);
    fakePlatformChannel.setPlatformMessageHandler(mockMessageHandler);
    Boolean returnValue = true;
    when(mockMessageHandler.clipboardHasStrings()).thenReturn(returnValue);
    MethodCall methodCall = new MethodCall("Clipboard.hasStrings", null);
    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);
    fakePlatformChannel.parsingMethodCallHandler.onMethodCall(methodCall, mockResult);

    JSONObject expected = new JSONObject();
    try {
      expected.put("value", returnValue);
    } catch (JSONException e) {
    }
    verify(mockResult).success(refEq(expected));
  }

  @Test
  public void platformChannel_shareInvokeMessage() {
    MethodChannel rawChannel = mock(MethodChannel.class);
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = new DartExecutor(mockFlutterJNI, mock(AssetManager.class));
    PlatformChannel fakePlatformChannel = new PlatformChannel(dartExecutor);
    PlatformChannel.PlatformMessageHandler mockMessageHandler =
        mock(PlatformChannel.PlatformMessageHandler.class);
    fakePlatformChannel.setPlatformMessageHandler(mockMessageHandler);

    ArgumentCaptor<String> valueCapture = ArgumentCaptor.forClass(String.class);
    doNothing().when(mockMessageHandler).share(valueCapture.capture());

    final String expectedContent = "Flutter";
    MethodCall methodCall = new MethodCall("Share.invoke", expectedContent);
    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);
    fakePlatformChannel.parsingMethodCallHandler.onMethodCall(methodCall, mockResult);

    assertEquals(expectedContent, valueCapture.getValue());
    verify(mockResult).success(null);
  }

  @Test
  public void platformChannel_replaysFrameworkHandlesBackForNewHandler() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = new DartExecutor(mockFlutterJNI, mock(AssetManager.class));
    PlatformChannel fakePlatformChannel = new PlatformChannel(dartExecutor);
    PlatformChannel.PlatformMessageHandler firstMessageHandler =
        mock(PlatformChannel.PlatformMessageHandler.class);
    fakePlatformChannel.setPlatformMessageHandler(firstMessageHandler);

    MethodCall methodCall = new MethodCall("SystemNavigator.setFrameworkHandlesBack", true);
    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);
    fakePlatformChannel.parsingMethodCallHandler.onMethodCall(methodCall, mockResult);
    fakePlatformChannel.setPlatformMessageHandler(null);

    PlatformChannel.PlatformMessageHandler replacementMessageHandler =
        mock(PlatformChannel.PlatformMessageHandler.class);
    fakePlatformChannel.setPlatformMessageHandler(replacementMessageHandler);

    verify(mockResult).success(null);
    verify(replacementMessageHandler).setFrameworkHandlesBack(true);
  }

  @Test
  public void platformChannel_remembersFrameworkHandlesBackWithoutHandler() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = new DartExecutor(mockFlutterJNI, mock(AssetManager.class));
    PlatformChannel fakePlatformChannel = new PlatformChannel(dartExecutor);

    MethodCall methodCall = new MethodCall("SystemNavigator.setFrameworkHandlesBack", true);
    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);
    fakePlatformChannel.parsingMethodCallHandler.onMethodCall(methodCall, mockResult);

    PlatformChannel.PlatformMessageHandler messageHandler =
        mock(PlatformChannel.PlatformMessageHandler.class);
    fakePlatformChannel.setPlatformMessageHandler(messageHandler);

    verify(mockResult).success(null);
    verify(messageHandler).setFrameworkHandlesBack(true);
  }

  private static MethodChannel.Result invokeMethod(
      PlatformChannel platformChannel, String method, Object arguments) {
    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);
    platformChannel.parsingMethodCallHandler.onMethodCall(
        new MethodCall(method, arguments), mockResult);
    return mockResult;
  }

  private static PlatformChannel newPlatformChannel() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = new DartExecutor(mockFlutterJNI, mock(AssetManager.class));
    return new PlatformChannel(dartExecutor);
  }

  @Test
  public void platformChannel_completesSetPreferredOrientationsWithoutHandler() {
    MethodChannel.Result mockResult =
        invokeMethod(
            newPlatformChannel(),
            "SystemChrome.setPreferredOrientations",
            new JSONArray(Arrays.asList("DeviceOrientation.portraitUp")));

    verify(mockResult).success(null);
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void platformChannel_completesSetEnabledSystemUIModeWithoutHandler() {
    MethodChannel.Result mockResult =
        invokeMethod(
            newPlatformChannel(),
            "SystemChrome.setEnabledSystemUIMode",
            "SystemUiMode.immersiveSticky");

    verify(mockResult).success(null);
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void platformChannel_completesHapticFeedbackWithoutHandler() {
    MethodChannel.Result mockResult =
        invokeMethod(
            newPlatformChannel(), "HapticFeedback.vibrate", "HapticFeedbackType.lightImpact");

    verify(mockResult).success(null);
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void platformChannel_completesShareInvokeWithoutHandler() {
    MethodChannel.Result mockResult = invokeMethod(newPlatformChannel(), "Share.invoke", "Flutter");

    verify(mockResult).success(null);
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void platformChannel_reportsNoClipboardDataWithoutHandler() {
    MethodChannel.Result mockResult =
        invokeMethod(newPlatformChannel(), "Clipboard.getData", "text/plain");

    verify(mockResult).success(null);
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void platformChannel_reportsNoStringsWithoutHandler() throws JSONException {
    MethodChannel.Result mockResult =
        invokeMethod(newPlatformChannel(), "Clipboard.hasStrings", "text/plain");

    JSONObject expected = new JSONObject();
    expected.put("value", false);
    verify(mockResult).success(refEq(expected));
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void platformChannel_reportsUnknownMethodWithoutHandler() {
    // An iOS-only method, so it has no case in this channel.
    MethodChannel.Result mockResult =
        invokeMethod(newPlatformChannel(), "SearchWeb.invoke", "Flutter");

    verify(mockResult).notImplemented();
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void platformChannel_reportsInvalidArgumentsWithoutHandler() {
    MethodChannel.Result mockResult =
        invokeMethod(newPlatformChannel(), "HapticFeedback.vibrate", "HapticFeedbackType.unknown");

    verify(mockResult).error(eq("error"), any(), any());
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void platformChannel_answersCallsAfterHandlerIsRemoved() {
    PlatformChannel fakePlatformChannel = newPlatformChannel();
    PlatformChannel.PlatformMessageHandler mockMessageHandler =
        mock(PlatformChannel.PlatformMessageHandler.class);
    fakePlatformChannel.setPlatformMessageHandler(mockMessageHandler);
    fakePlatformChannel.setPlatformMessageHandler(null);

    MethodChannel.Result mockResult =
        invokeMethod(
            fakePlatformChannel,
            "SystemChrome.setPreferredOrientations",
            new JSONArray(Arrays.asList("DeviceOrientation.portraitUp")));

    verify(mockResult).success(null);
    verifyNoMoreInteractions(mockResult);
    verify(mockMessageHandler, never()).setPreferredOrientations(anyInt());
  }

  @Test
  public void platformChannel_repliesOnceToUnsupportedClipboardFormat() {
    PlatformChannel fakePlatformChannel = newPlatformChannel();
    PlatformChannel.PlatformMessageHandler mockMessageHandler =
        mock(PlatformChannel.PlatformMessageHandler.class);
    fakePlatformChannel.setPlatformMessageHandler(mockMessageHandler);

    MethodChannel.Result mockResult =
        invokeMethod(fakePlatformChannel, "Clipboard.getData", "text/html");

    verify(mockResult).error(eq("error"), any(), any());
    verifyNoMoreInteractions(mockResult);
    verify(mockMessageHandler, never()).getClipboardData(any());
  }
}

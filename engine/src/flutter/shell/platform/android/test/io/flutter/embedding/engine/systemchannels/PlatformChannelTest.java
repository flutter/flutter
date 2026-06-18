// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.mockito.ArgumentMatchers.refEq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.content.res.AssetManager;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
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

    assertEquals(valueCapture.getValue(), expectedContent);
    verify(mockResult).success(null);
  }

  @Test
  public void platformChannel_setPreferredOrientations_completesWhenNoHandler()
      throws JSONException {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = new DartExecutor(mockFlutterJNI, mock(AssetManager.class));
    PlatformChannel fakePlatformChannel = new PlatformChannel(dartExecutor);

    JSONArray orientations = new JSONArray();
    orientations.put("DeviceOrientation.portraitUp");
    MethodCall methodCall = new MethodCall("SystemChrome.setPreferredOrientations", orientations);
    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);
    fakePlatformChannel.parsingMethodCallHandler.onMethodCall(methodCall, mockResult);

    verify(mockResult).success(null);
  }

  @Test
  public void platformChannel_cachesAndReplaysConfigurationState() throws JSONException {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = new DartExecutor(mockFlutterJNI, mock(AssetManager.class));
    PlatformChannel fakePlatformChannel = new PlatformChannel(dartExecutor);

    // 1. Call setPreferredOrientations when no handler is registered.
    JSONArray orientations = new JSONArray();
    orientations.put("DeviceOrientation.portraitUp");
    MethodCall methodCall = new MethodCall("SystemChrome.setPreferredOrientations", orientations);
    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);
    fakePlatformChannel.parsingMethodCallHandler.onMethodCall(methodCall, mockResult);

    // Verify it succeeded and cached the value.
    verify(mockResult).success(null);
    assertEquals(Integer.valueOf(1), fakePlatformChannel.pendingAndroidOrientation);

    // 2. Set a handler and verify it immediately replays the cached state.
    PlatformChannel.PlatformMessageHandler mockMessageHandler =
        mock(PlatformChannel.PlatformMessageHandler.class);
    fakePlatformChannel.setPlatformMessageHandler(mockMessageHandler);
    verify(mockMessageHandler).setPreferredOrientations(1);
  }

  @Test
  public void platformChannel_systemUiModeAndOverlaysAreMutuallyExclusive() throws JSONException {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = new DartExecutor(mockFlutterJNI, mock(AssetManager.class));
    PlatformChannel fakePlatformChannel = new PlatformChannel(dartExecutor);

    // 1. Set overlays.
    JSONArray overlays = new JSONArray();
    overlays.put("SystemUiOverlay.top");
    MethodCall overlaysCall = new MethodCall("SystemChrome.setEnabledSystemUIOverlays", overlays);
    fakePlatformChannel.parsingMethodCallHandler.onMethodCall(
        overlaysCall, mock(MethodChannel.Result.class));

    assertEquals(1, fakePlatformChannel.pendingOverlays.size());
    assertEquals(
        PlatformChannel.SystemUiOverlay.TOP_OVERLAYS, fakePlatformChannel.pendingOverlays.get(0));
    assertNull(fakePlatformChannel.pendingSystemUiMode);

    // 2. Set system UI mode, verifying it clears overlays.
    MethodCall modeCall =
        new MethodCall("SystemChrome.setEnabledSystemUIMode", "SystemUiMode.immersive");
    fakePlatformChannel.parsingMethodCallHandler.onMethodCall(
        modeCall, mock(MethodChannel.Result.class));

    assertEquals(PlatformChannel.SystemUiMode.IMMERSIVE, fakePlatformChannel.pendingSystemUiMode);
    assertNull(fakePlatformChannel.pendingOverlays);

    // 3. Set overlays again, verifying it clears mode.
    fakePlatformChannel.parsingMethodCallHandler.onMethodCall(
        overlaysCall, mock(MethodChannel.Result.class));
    assertEquals(1, fakePlatformChannel.pendingOverlays.size());
    assertNull(fakePlatformChannel.pendingSystemUiMode);
  }

  @Test
  public void platformChannel_clearDataResetsCache() throws JSONException {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = new DartExecutor(mockFlutterJNI, mock(AssetManager.class));
    PlatformChannel fakePlatformChannel = new PlatformChannel(dartExecutor);

    // Set configuration.
    JSONArray orientations = new JSONArray();
    orientations.put("DeviceOrientation.portraitUp");
    MethodCall methodCall = new MethodCall("SystemChrome.setPreferredOrientations", orientations);
    fakePlatformChannel.parsingMethodCallHandler.onMethodCall(
        methodCall, mock(MethodChannel.Result.class));
    assertEquals(Integer.valueOf(1), fakePlatformChannel.pendingAndroidOrientation);

    // Clear data.
    fakePlatformChannel.clearData();
    assertNull(fakePlatformChannel.pendingAndroidOrientation);
  }

  @Test
  public void platformChannel_nonConfigurationMethodsCompleteWhenNoHandler() throws JSONException {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = new DartExecutor(mockFlutterJNI, mock(AssetManager.class));
    PlatformChannel fakePlatformChannel = new PlatformChannel(dartExecutor);

    // Clipboard.getData completes with null.
    MethodCall getDataCall = new MethodCall("Clipboard.getData", "text/plain");
    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);
    fakePlatformChannel.parsingMethodCallHandler.onMethodCall(getDataCall, mockResult);
    verify(mockResult).success(null);

    // Clipboard.hasStrings completes with null.
    MethodCall hasStringsCall = new MethodCall("Clipboard.hasStrings", "text/plain");
    MethodChannel.Result mockResult2 = mock(MethodChannel.Result.class);
    fakePlatformChannel.parsingMethodCallHandler.onMethodCall(hasStringsCall, mockResult2);
    verify(mockResult2).success(null);

    // SystemNavigator.pop completes with null.
    MethodCall popCall = new MethodCall("SystemNavigator.pop", null);
    MethodChannel.Result mockResult3 = mock(MethodChannel.Result.class);
    fakePlatformChannel.parsingMethodCallHandler.onMethodCall(popCall, mockResult3);
    verify(mockResult3).success(null);
  }
}

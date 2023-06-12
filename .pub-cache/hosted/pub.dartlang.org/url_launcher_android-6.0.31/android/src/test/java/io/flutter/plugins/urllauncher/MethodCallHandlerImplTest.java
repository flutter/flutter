// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.urllauncher;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.os.Bundle;
import androidx.test.core.app.ApplicationProvider;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.BinaryMessenger.BinaryMessageHandler;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.Result;
import java.util.HashMap;
import java.util.Map;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;

@RunWith(RobolectricTestRunner.class)
public class MethodCallHandlerImplTest {
  private static final String CHANNEL_NAME = "plugins.flutter.io/url_launcher_android";
  private UrlLauncher urlLauncher;
  private MethodCallHandlerImpl methodCallHandler;

  @Before
  public void setUp() {
    urlLauncher = new UrlLauncher(ApplicationProvider.getApplicationContext(), /*activity=*/ null);
    methodCallHandler = new MethodCallHandlerImpl(urlLauncher);
  }

  @Test
  public void startListening_registersChannel() {
    BinaryMessenger messenger = mock(BinaryMessenger.class);

    methodCallHandler.startListening(messenger);

    verify(messenger, times(1))
        .setMessageHandler(eq(CHANNEL_NAME), any(BinaryMessageHandler.class));
  }

  @Test
  public void startListening_unregistersExistingChannel() {
    BinaryMessenger firstMessenger = mock(BinaryMessenger.class);
    BinaryMessenger secondMessenger = mock(BinaryMessenger.class);
    methodCallHandler.startListening(firstMessenger);

    methodCallHandler.startListening(secondMessenger);

    // Unregisters the first and then registers the second.
    verify(firstMessenger, times(1)).setMessageHandler(CHANNEL_NAME, null);
    verify(secondMessenger, times(1))
        .setMessageHandler(eq(CHANNEL_NAME), any(BinaryMessageHandler.class));
  }

  @Test
  public void stopListening_unregistersExistingChannel() {
    BinaryMessenger messenger = mock(BinaryMessenger.class);
    methodCallHandler.startListening(messenger);

    methodCallHandler.stopListening();

    verify(messenger, times(1)).setMessageHandler(CHANNEL_NAME, null);
  }

  @Test
  public void stopListening_doesNothingWhenUnset() {
    BinaryMessenger messenger = mock(BinaryMessenger.class);

    methodCallHandler.stopListening();

    verify(messenger, never()).setMessageHandler(CHANNEL_NAME, null);
  }

  @Test
  public void onMethodCall_canLaunchReturnsTrue() {
    urlLauncher = mock(UrlLauncher.class);
    methodCallHandler = new MethodCallHandlerImpl(urlLauncher);
    String url = "foo";
    when(urlLauncher.canLaunch(url)).thenReturn(true);
    Result result = mock(Result.class);
    Map<String, Object> args = new HashMap<>();
    args.put("url", url);

    methodCallHandler.onMethodCall(new MethodCall("canLaunch", args), result);

    verify(result, times(1)).success(true);
  }

  @Test
  public void onMethodCall_canLaunchReturnsFalse() {
    urlLauncher = mock(UrlLauncher.class);
    methodCallHandler = new MethodCallHandlerImpl(urlLauncher);
    String url = "foo";
    when(urlLauncher.canLaunch(url)).thenReturn(false);
    Result result = mock(Result.class);
    Map<String, Object> args = new HashMap<>();
    args.put("url", url);

    methodCallHandler.onMethodCall(new MethodCall("canLaunch", args), result);

    verify(result, times(1)).success(false);
  }

  @Test
  public void onMethodCall_launchReturnsNoActivityError() {
    // Setup mock objects
    urlLauncher = mock(UrlLauncher.class);
    Result result = mock(Result.class);
    // Setup expected values
    String url = "foo";
    boolean useWebView = false;
    boolean enableJavaScript = false;
    boolean enableDomStorage = false;
    // Setup arguments map send on the method channel
    Map<String, Object> args = new HashMap<>();
    args.put("url", url);
    args.put("useWebView", useWebView);
    args.put("enableJavaScript", enableJavaScript);
    args.put("enableDomStorage", enableDomStorage);
    args.put("headers", new HashMap<>());
    // Mock the launch method on the urlLauncher class
    when(urlLauncher.launch(
            eq(url), any(Bundle.class), eq(useWebView), eq(enableJavaScript), eq(enableDomStorage)))
        .thenReturn(UrlLauncher.LaunchStatus.NO_ACTIVITY);
    // Act by calling the "launch" method on the method channel
    methodCallHandler = new MethodCallHandlerImpl(urlLauncher);
    methodCallHandler.onMethodCall(new MethodCall("launch", args), result);
    // Verify the results and assert
    verify(result, times(1))
        .error("NO_ACTIVITY", "Launching a URL requires a foreground activity.", null);
  }

  @Test
  public void onMethodCall_launchReturnsActivityNotFoundError() {
    // Setup mock objects
    urlLauncher = mock(UrlLauncher.class);
    Result result = mock(Result.class);
    // Setup expected values
    String url = "foo";
    boolean useWebView = false;
    boolean enableJavaScript = false;
    boolean enableDomStorage = false;
    // Setup arguments map send on the method channel
    Map<String, Object> args = new HashMap<>();
    args.put("url", url);
    args.put("useWebView", useWebView);
    args.put("enableJavaScript", enableJavaScript);
    args.put("enableDomStorage", enableDomStorage);
    args.put("headers", new HashMap<>());
    // Mock the launch method on the urlLauncher class
    when(urlLauncher.launch(
            eq(url), any(Bundle.class), eq(useWebView), eq(enableJavaScript), eq(enableDomStorage)))
        .thenReturn(UrlLauncher.LaunchStatus.ACTIVITY_NOT_FOUND);
    // Act by calling the "launch" method on the method channel
    methodCallHandler = new MethodCallHandlerImpl(urlLauncher);
    methodCallHandler.onMethodCall(new MethodCall("launch", args), result);
    // Verify the results and assert
    verify(result, times(1))
        .error(
            "ACTIVITY_NOT_FOUND",
            String.format("No Activity found to handle intent { %s }", url),
            null);
  }

  @Test
  public void onMethodCall_launchReturnsTrue() {
    // Setup mock objects
    urlLauncher = mock(UrlLauncher.class);
    Result result = mock(Result.class);
    // Setup expected values
    String url = "foo";
    boolean useWebView = false;
    boolean enableJavaScript = false;
    boolean enableDomStorage = false;
    // Setup arguments map send on the method channel
    Map<String, Object> args = new HashMap<>();
    args.put("url", url);
    args.put("useWebView", useWebView);
    args.put("enableJavaScript", enableJavaScript);
    args.put("enableDomStorage", enableDomStorage);
    args.put("headers", new HashMap<>());
    // Mock the launch method on the urlLauncher class
    when(urlLauncher.launch(
            eq(url), any(Bundle.class), eq(useWebView), eq(enableJavaScript), eq(enableDomStorage)))
        .thenReturn(UrlLauncher.LaunchStatus.OK);
    // Act by calling the "launch" method on the method channel
    methodCallHandler = new MethodCallHandlerImpl(urlLauncher);
    methodCallHandler.onMethodCall(new MethodCall("launch", args), result);
    // Verify the results and assert
    verify(result, times(1)).success(true);
  }

  @Test
  public void onMethodCall_closeWebView() {
    urlLauncher = mock(UrlLauncher.class);
    methodCallHandler = new MethodCallHandlerImpl(urlLauncher);
    String url = "foo";
    when(urlLauncher.canLaunch(url)).thenReturn(true);
    Result result = mock(Result.class);
    Map<String, Object> args = new HashMap<>();
    args.put("url", url);

    methodCallHandler.onMethodCall(new MethodCall("closeWebView", args), result);

    verify(urlLauncher, times(1)).closeWebView();
    verify(result, times(1)).success(null);
  }
}

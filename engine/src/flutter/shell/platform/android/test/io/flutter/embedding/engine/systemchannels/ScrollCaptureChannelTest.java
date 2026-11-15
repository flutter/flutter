// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import android.graphics.Rect;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.plugin.common.MethodChannel;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;
import org.json.JSONObject;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;

@RunWith(AndroidJUnit4.class)
public class ScrollCaptureChannelTest {
  private MethodChannel mockMethodChannel;
  private ScrollCaptureChannel scrollCaptureChannel;

  @Before
  public void setUp() {
    mockMethodChannel = mock(MethodChannel.class);
    scrollCaptureChannel = new ScrollCaptureChannel(mockMethodChannel);
  }

  private MethodChannel.Result captureResult(String method) {
    ArgumentCaptor<MethodChannel.Result> resultCaptor =
        ArgumentCaptor.forClass(MethodChannel.Result.class);
    verify(mockMethodChannel).invokeMethod(eq(method), any(), resultCaptor.capture());
    return resultCaptor.getValue();
  }

  @Test
  public void searchParsesBounds() throws Exception {
    AtomicReference<Rect> bounds = new AtomicReference<>();
    scrollCaptureChannel.search(bounds::set);

    verify(mockMethodChannel).invokeMethod(eq("ScrollCapture.search"), isNull(), any());
    captureResult("ScrollCapture.search")
        .success(new JSONObject("{\"left\":1,\"top\":2,\"right\":3,\"bottom\":4}"));
    assertEquals(new Rect(1, 2, 3, 4), bounds.get());
  }

  @Test
  public void searchReportsNullWhenThereIsNothingToCapture() {
    AtomicReference<Rect> bounds = new AtomicReference<>(new Rect());
    scrollCaptureChannel.search(bounds::set);

    captureResult("ScrollCapture.search").success(JSONObject.NULL);
    assertNull(bounds.get());
  }

  @Test
  public void searchReportsNullWhenNotImplemented() {
    AtomicReference<Rect> bounds = new AtomicReference<>(new Rect());
    scrollCaptureChannel.search(bounds::set);

    captureResult("ScrollCapture.search").notImplemented();
    assertNull(bounds.get());
  }

  @Test
  public void startParsesBounds() throws Exception {
    AtomicReference<Rect> bounds = new AtomicReference<>();
    scrollCaptureChannel.start(bounds::set);

    captureResult("ScrollCapture.start")
        .success(new JSONObject("{\"left\":0,\"top\":10,\"right\":100,\"bottom\":200}"));
    assertEquals(new Rect(0, 10, 100, 200), bounds.get());
  }

  @Test
  @SuppressWarnings("unchecked")
  public void scrollToSendsRangeAndParsesDelta() throws Exception {
    AtomicReference<Integer> delta = new AtomicReference<>();
    scrollCaptureChannel.scrollTo(-50, 150, delta::set);

    ArgumentCaptor<Object> argumentsCaptor = ArgumentCaptor.forClass(Object.class);
    ArgumentCaptor<MethodChannel.Result> resultCaptor =
        ArgumentCaptor.forClass(MethodChannel.Result.class);
    verify(mockMethodChannel)
        .invokeMethod(
            eq("ScrollCapture.scrollTo"), argumentsCaptor.capture(), resultCaptor.capture());
    Map<String, Object> arguments = (Map<String, Object>) argumentsCaptor.getValue();
    assertEquals(-50, arguments.get("top"));
    assertEquals(150, arguments.get("bottom"));

    resultCaptor.getValue().success(new JSONObject("{\"scrollDelta\":-42}"));
    assertEquals(Integer.valueOf(-42), delta.get());
  }

  @Test
  public void scrollToReportsNullOnError() {
    AtomicReference<Integer> delta = new AtomicReference<>(0);
    scrollCaptureChannel.scrollTo(0, 100, delta::set);

    captureResult("ScrollCapture.scrollTo").error("error", "message", null);
    assertNull(delta.get());
  }

  @Test
  public void endRunsCallbackOnSuccessAndFailure() {
    AtomicBoolean done = new AtomicBoolean(false);
    scrollCaptureChannel.end(() -> done.set(true));
    captureResult("ScrollCapture.end").success(null);
    assertTrue(done.get());

    MethodChannel otherChannel = mock(MethodChannel.class);
    AtomicBoolean doneAfterError = new AtomicBoolean(false);
    new ScrollCaptureChannel(otherChannel).end(() -> doneAfterError.set(true));
    ArgumentCaptor<MethodChannel.Result> resultCaptor =
        ArgumentCaptor.forClass(MethodChannel.Result.class);
    verify(otherChannel).invokeMethod(eq("ScrollCapture.end"), any(), resultCaptor.capture());
    resultCaptor.getValue().notImplemented();
    assertTrue(doneAfterError.get());
  }
}

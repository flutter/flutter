// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import android.graphics.Bitmap;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.plugin.common.MethodChannel;
import java.nio.ByteBuffer;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;

@RunWith(AndroidJUnit4.class)
public class ScreenshotChannelTest {
  @Test
  public void captureView_decodesValidRgbaPayloadIntoBitmap() {
    MethodChannel mockChannel = mock(MethodChannel.class);
    ScreenshotChannel screenshotChannel = new ScreenshotChannel(mockChannel);

    AtomicReference<Bitmap> capturedBitmap = new AtomicReference<>();
    screenshotChannel.captureView(0L, capturedBitmap::set);

    ArgumentCaptor<MethodChannel.Result> resultCaptor =
        ArgumentCaptor.forClass(MethodChannel.Result.class);
    verify(mockChannel).invokeMethod(eq("Screenshot.captureView"), eq(0L), resultCaptor.capture());

    // 2x1 RGBA_8888 buffer: pixel (0,0) = Red, pixel (1,0) = Green.
    byte[] rgbaBytes =
        new byte[] {(byte) 0xFF, 0x00, 0x00, (byte) 0xFF, 0x00, (byte) 0xFF, 0x00, (byte) 0xFF};
    Map<String, Object> payload = new HashMap<>();
    payload.put("width", 2);
    payload.put("height", 1);
    payload.put("bytes", rgbaBytes);

    resultCaptor.getValue().success(payload);

    Bitmap bitmap = capturedBitmap.get();
    assertNotNull(bitmap);
    assertEquals(2, bitmap.getWidth());
    assertEquals(1, bitmap.getHeight());
    assertEquals(Bitmap.Config.ARGB_8888, bitmap.getConfig());

    byte[] outBytes = new byte[rgbaBytes.length];
    bitmap.copyPixelsToBuffer(ByteBuffer.wrap(outBytes));
    assertArrayEquals(rgbaBytes, outBytes);
  }

  @Test
  public void captureView_returnsNullWhenPayloadInvalid() {
    MethodChannel mockChannel = mock(MethodChannel.class);
    ScreenshotChannel screenshotChannel = new ScreenshotChannel(mockChannel);

    // 1. Null result.
    AtomicBoolean called = new AtomicBoolean(false);
    AtomicReference<Bitmap> capturedBitmap = new AtomicReference<>();
    screenshotChannel.captureView(
        0L,
        bitmap -> {
          called.set(true);
          capturedBitmap.set(bitmap);
        });

    ArgumentCaptor<MethodChannel.Result> resultCaptor =
        ArgumentCaptor.forClass(MethodChannel.Result.class);
    verify(mockChannel).invokeMethod(eq("Screenshot.captureView"), eq(0L), resultCaptor.capture());
    resultCaptor.getValue().success(null);
    assertTrue(called.get());
    assertNull(capturedBitmap.get());

    // 2. Truncated byte array.
    called.set(false);
    Map<String, Object> truncatedPayload = new HashMap<>();
    truncatedPayload.put("width", 2);
    truncatedPayload.put("height", 2);
    truncatedPayload.put("bytes", new byte[] {1, 2, 3, 4});
    resultCaptor.getValue().success(truncatedPayload);
    assertTrue(called.get());
    assertNull(capturedBitmap.get());
  }

  @Test
  public void captureView_returnsNullOnChannelErrorOrNotImplemented() {
    MethodChannel mockChannel = mock(MethodChannel.class);
    ScreenshotChannel screenshotChannel = new ScreenshotChannel(mockChannel);

    AtomicBoolean called = new AtomicBoolean(false);
    AtomicReference<Bitmap> capturedBitmap = new AtomicReference<>();
    screenshotChannel.captureView(
        0L,
        bitmap -> {
          called.set(true);
          capturedBitmap.set(bitmap);
        });

    ArgumentCaptor<MethodChannel.Result> resultCaptor =
        ArgumentCaptor.forClass(MethodChannel.Result.class);
    verify(mockChannel).invokeMethod(eq("Screenshot.captureView"), eq(0L), resultCaptor.capture());

    resultCaptor.getValue().error("ERROR", "Capture failed", null);
    assertTrue(called.get());
    assertNull(capturedBitmap.get());

    called.set(false);
    resultCaptor.getValue().notImplemented();
    assertTrue(called.get());
    assertNull(capturedBitmap.get());
  }
}

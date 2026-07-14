// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import static org.junit.Assert.*;
import static org.mockito.Mockito.*;

import android.content.Context;
import android.graphics.Canvas;
import android.hardware.HardwareBuffer;
import android.media.Image;
import android.media.ImageReader;
import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(AndroidJUnit4.class)
public class FlutterImageViewTest {
  private final Context ctx = ApplicationProvider.getApplicationContext();

  @Test
  public void testOnDrawPerformsOptimization() {
    ImageReader mockReader = mock(ImageReader.class);
    FlutterImageView imageView =
        new FlutterImageView(ctx, mockReader, FlutterImageView.SurfaceKind.overlay);
    imageView.attachToRenderer(mock(FlutterRenderer.class));

    // Image 1
    Image mockImage1 = mock(Image.class);
    HardwareBuffer mockBuffer1 = mock(HardwareBuffer.class);
    when(mockBuffer1.getUsage()).thenReturn(HardwareBuffer.USAGE_GPU_SAMPLED_IMAGE);
    when(mockBuffer1.getFormat()).thenReturn(HardwareBuffer.RGBA_8888);
    when(mockBuffer1.getWidth()).thenReturn(100);
    when(mockBuffer1.getHeight()).thenReturn(100);
    when(mockImage1.getHardwareBuffer()).thenReturn(mockBuffer1);

    // Image 2
    Image mockImage2 = mock(Image.class);
    HardwareBuffer mockBuffer2 = mock(HardwareBuffer.class);
    when(mockBuffer2.getUsage()).thenReturn(HardwareBuffer.USAGE_GPU_SAMPLED_IMAGE);
    when(mockBuffer2.getFormat()).thenReturn(HardwareBuffer.RGBA_8888);
    when(mockBuffer2.getWidth()).thenReturn(100);
    when(mockBuffer2.getHeight()).thenReturn(100);
    when(mockImage2.getHardwareBuffer()).thenReturn(mockBuffer2);

    // Setup reader to return image 1 first, then image 2
    when(mockReader.acquireLatestImage()).thenReturn(mockImage1).thenReturn(mockImage2);

    // Acquire image 1
    assertTrue(imageView.acquireLatestImage());

    // First draw should update bitmap (calls getHardwareBuffer on image 1)
    Canvas mockCanvas = mock(Canvas.class);
    imageView.onDraw(mockCanvas);
    verify(mockImage1, times(1)).getHardwareBuffer();

    // Second draw should NOT update bitmap (no calls to getHardwareBuffer on image 1)
    imageView.onDraw(mockCanvas);
    verify(mockImage1, times(1)).getHardwareBuffer(); // Still 1

    // Acquire image 2
    assertTrue(imageView.acquireLatestImage());

    // Third draw should update bitmap (calls getHardwareBuffer on image 2)
    imageView.onDraw(mockCanvas);
    verify(mockImage1, times(1)).getHardwareBuffer(); // Still 1
    verify(mockImage2, times(1)).getHardwareBuffer(); // Called 1 time
  }
}

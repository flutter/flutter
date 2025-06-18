// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.renderer;

import static io.flutter.Build.API_LEVELS;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotEquals;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.when;
import static org.robolectric.Shadows.shadowOf;

import android.annotation.TargetApi;
import android.graphics.Canvas;
import android.graphics.SurfaceTexture;
import android.os.Handler;
import android.os.Looper;
import android.view.Surface;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.view.TextureRegistry;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(AndroidJUnit4.class)
@TargetApi(API_LEVELS.API_26)
public final class SurfaceTextureSurfaceProducerTest {
  private final FlutterJNI fakeJNI = mock(FlutterJNI.class);

  @Test
  public void createsSurfaceTextureOfGivenSizeAndResizesWhenRequested() {
    final FlutterRenderer flutterRenderer = new FlutterRenderer(fakeJNI);

    // Create a surface and set the initial size.
    final Handler handler = new Handler(Looper.getMainLooper());
    final SurfaceTextureSurfaceProducer producer =
        new SurfaceTextureSurfaceProducer(
            0, handler, fakeJNI, flutterRenderer.registerSurfaceTexture(new SurfaceTexture(0)));
    final Surface surface = producer.getSurface();
    AtomicInteger frames = new AtomicInteger();
    producer
        .getSurfaceTexture()
        .setOnFrameAvailableListener(
            (texture) -> {
              if (texture.isReleased()) {
                return;
              }
              frames.getAndIncrement();
            });
    producer.setSize(100, 200);

    // Draw.
    Canvas canvas = surface.lockHardwareCanvas();
    canvas.drawARGB(255, 255, 0, 0);
    surface.unlockCanvasAndPost(canvas);
    shadowOf(Looper.getMainLooper()).idle();
    assertEquals(frames.get(), 1);

    // Resize and redraw.
    producer.setSize(400, 800);
    canvas = surface.lockHardwareCanvas();
    canvas.drawARGB(255, 255, 0, 0);
    surface.unlockCanvasAndPost(canvas);
    shadowOf(Looper.getMainLooper()).idle();
    assertEquals(frames.get(), 2);

    // Done.
    fakeJNI.detachFromNativeAndReleaseResources();
    producer.release();
  }

  @Test
  public void releaseWillReleaseSurface() {
    final FlutterRenderer flutterRenderer = new FlutterRenderer(fakeJNI);

    // Create a surface and set the initial size.
    final Handler handler = new Handler(Looper.getMainLooper());
    final SurfaceTextureSurfaceProducer producer =
        new SurfaceTextureSurfaceProducer(
            0, handler, fakeJNI, flutterRenderer.registerSurfaceTexture(new SurfaceTexture(0)));
    final Surface surface = producer.getSurface();
    assertTrue(surface.isValid());
    producer.release();
    assertFalse(surface.isValid());
  }

  @Test
  public void getSurface_doesNotReturnInvalidSurface() {
    final FlutterRenderer flutterRenderer = new FlutterRenderer(fakeJNI);
    final Handler handler = new Handler(Looper.getMainLooper());
    final SurfaceTexture mockSurfaceTexture = mock(SurfaceTexture.class);
    final TextureRegistry.SurfaceTextureEntry spyTexture =
        spy(flutterRenderer.registerSurfaceTexture(mockSurfaceTexture));
    final SurfaceTextureSurfaceProducer producerSpy =
        spy(new SurfaceTextureSurfaceProducer(0, handler, fakeJNI, spyTexture));
    final Surface firstMockSurface = mock(Surface.class);
    final Surface secondMockSurface = mock(Surface.class);

    when(spyTexture.surfaceTexture()).thenReturn(mockSurfaceTexture);
    when(firstMockSurface.isValid()).thenReturn(false);
    when(producerSpy.createSurface(mockSurfaceTexture))
        .thenReturn(firstMockSurface)
        .thenReturn(secondMockSurface);

    final Surface firstSurface = producerSpy.getSurface();
    final Surface secondSurface = producerSpy.getSurface();

    assertNotEquals(firstSurface, secondSurface);
  }

  @Test
  public void getSurface_consecutiveCallsReturnSameSurfaceIfStillValid() {
    final FlutterRenderer flutterRenderer = new FlutterRenderer(fakeJNI);
    final Handler handler = new Handler(Looper.getMainLooper());
    final SurfaceTexture mockSurfaceTexture = mock(SurfaceTexture.class);
    final TextureRegistry.SurfaceTextureEntry spyTexture =
        spy(flutterRenderer.registerSurfaceTexture(mockSurfaceTexture));
    final SurfaceTextureSurfaceProducer producerSpy =
        spy(new SurfaceTextureSurfaceProducer(0, handler, fakeJNI, spyTexture));
    final Surface mockSurface = mock(Surface.class);

    when(spyTexture.surfaceTexture()).thenReturn(mockSurfaceTexture);
    when(mockSurface.isValid()).thenReturn(true);
    when(producerSpy.createSurface(mockSurfaceTexture)).thenReturn(mockSurface);

    final Surface firstSurface = producerSpy.getSurface();
    final Surface secondSurface = producerSpy.getSurface();

    assertEquals(firstSurface, secondSurface);
  }

  @Test
  public void getForcedNewSurface_returnsNewSurface() {
    final FlutterRenderer flutterRenderer = new FlutterRenderer(fakeJNI);
    final Handler handler = new Handler(Looper.getMainLooper());
    final SurfaceTextureSurfaceProducer producer =
        new SurfaceTextureSurfaceProducer(
            0, handler, fakeJNI, flutterRenderer.registerSurfaceTexture(new SurfaceTexture(0)));

    final Surface firstSurface = producer.getSurface();
    final Surface secondSurface = producer.getForcedNewSurface();

    assertNotEquals(firstSurface, secondSurface);
  }

  @Test
  public void getSurface_doesNotReturnNewSurface() {
    final FlutterRenderer flutterRenderer = new FlutterRenderer(fakeJNI);
    final Handler handler = new Handler(Looper.getMainLooper());
    final SurfaceTextureSurfaceProducer producer =
        new SurfaceTextureSurfaceProducer(
            0, handler, fakeJNI, flutterRenderer.registerSurfaceTexture(new SurfaceTexture(0)));

    Surface firstSurface = producer.getSurface();
    Surface secondSurface = producer.getSurface();

    assertEquals(firstSurface, secondSurface);
  }
}

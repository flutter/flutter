// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import static io.flutter.Build.API_LEVELS;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.annotation.TargetApi;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Point;
import android.graphics.Rect;
import android.os.CancellationSignal;
import android.view.ScrollCaptureSession;
import android.view.Surface;
import android.view.View;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.engine.systemchannels.ScrollCaptureChannel;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;
import java.util.function.Consumer;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.robolectric.annotation.Config;

@Config(minSdk = API_LEVELS.API_31)
@TargetApi(API_LEVELS.API_31)
@RunWith(AndroidJUnit4.class)
public class FlutterScrollCaptureCallbackTest {
  private static final Rect SCROLL_BOUNDS = new Rect(0, 100, 1000, 1100);

  private View mockView;
  private ScrollCaptureChannel mockChannel;
  private FlutterScrollCaptureCallback.PixelCopier mockPixelCopier;
  private Surface mockSurface;
  private Canvas mockCanvas;
  private ScrollCaptureSession session;
  private FlutterScrollCaptureCallback callback;

  @Before
  public void setUp() {
    mockView = mock(View.class);
    when(mockView.isShown()).thenReturn(true);
    when(mockView.getWidth()).thenReturn(1000);
    when(mockView.getHeight()).thenReturn(2000);
    // Run delayed work immediately.
    doAnswer(
            invocation -> {
              ((Runnable) invocation.getArgument(0)).run();
              return true;
            })
        .when(mockView)
        .postDelayed(any(Runnable.class), anyLong());

    mockChannel = mock(ScrollCaptureChannel.class);
    mockPixelCopier = mock(FlutterScrollCaptureCallback.PixelCopier.class);
    mockSurface = mock(Surface.class);
    mockCanvas = mock(Canvas.class);
    when(mockSurface.lockHardwareCanvas()).thenReturn(mockCanvas);
    session = new ScrollCaptureSession(mockSurface, SCROLL_BOUNDS, new Point(0, 0));
    callback = new FlutterScrollCaptureCallback(mockView, mockChannel, mockPixelCopier);
  }

  @SuppressWarnings("unchecked")
  private ScrollCaptureChannel.Callback<Rect> captureRectCallback(boolean isStart) {
    ArgumentCaptor<ScrollCaptureChannel.Callback<Rect>> captor =
        ArgumentCaptor.forClass(ScrollCaptureChannel.Callback.class);
    if (isStart) {
      verify(mockChannel).start(captor.capture());
    } else {
      verify(mockChannel).search(captor.capture());
    }
    return captor.getValue();
  }

  @SuppressWarnings("unchecked")
  private ScrollCaptureChannel.Callback<Integer> captureScrollToCallback(int top, int bottom) {
    ArgumentCaptor<ScrollCaptureChannel.Callback<Integer>> captor =
        ArgumentCaptor.forClass(ScrollCaptureChannel.Callback.class);
    verify(mockChannel).scrollTo(eq(top), eq(bottom), captor.capture());
    return captor.getValue();
  }

  @Test
  public void searchRejectsHiddenView() {
    when(mockView.isShown()).thenReturn(false);
    AtomicReference<Rect> result = new AtomicReference<>();
    callback.onScrollCaptureSearch(new CancellationSignal(), result::set);

    verify(mockChannel, never()).search(any());
    assertTrue(result.get().isEmpty());
  }

  @Test
  public void searchReportsBoundsClippedToTheView() {
    AtomicReference<Rect> result = new AtomicReference<>();
    callback.onScrollCaptureSearch(new CancellationSignal(), result::set);

    captureRectCallback(false).onResult(new Rect(-10, 100, 1000, 2500));
    assertEquals(new Rect(0, 100, 1000, 2000), result.get());
  }

  @Test
  public void searchReportsEmptyBoundsWhenThereIsNothingToCapture() {
    AtomicReference<Rect> result = new AtomicReference<>();
    callback.onScrollCaptureSearch(new CancellationSignal(), result::set);

    captureRectCallback(false).onResult(null);
    assertTrue(result.get().isEmpty());
  }

  @Test
  public void searchDoesNotReportWhenCancelled() {
    CancellationSignal signal = new CancellationSignal();
    AtomicReference<Rect> result = new AtomicReference<>();
    callback.onScrollCaptureSearch(signal, result::set);

    signal.cancel();
    captureRectCallback(false).onResult(new Rect(0, 0, 10, 10));
    assertNull(result.get());
  }

  @Test
  public void startRunsOnReadyOnceTheFrameworkIsReady() {
    AtomicBoolean ready = new AtomicBoolean(false);
    callback.onScrollCaptureStart(session, new CancellationSignal(), () -> ready.set(true));

    assertFalse(ready.get());
    captureRectCallback(true).onResult(SCROLL_BOUNDS);
    assertTrue(ready.get());
  }

  @Test
  @SuppressWarnings("unchecked")
  public void imageRequestCopiesTheVisiblePartOfTheRequestedArea() {
    doAnswer(
            invocation -> {
              ((Consumer<Boolean>) invocation.getArgument(2)).accept(true);
              return null;
            })
        .when(mockPixelCopier)
        .copyPixels(any(Rect.class), any(Bitmap.class), any());

    AtomicReference<Rect> result = new AtomicReference<>();
    // Request the area just below the initially visible area.
    callback.onScrollCaptureImageRequest(
        session, new CancellationSignal(), new Rect(0, 1000, 1000, 1500), result::set);

    // The framework could only scroll by 300 pixels before reaching the end of the content.
    captureScrollToCallback(1000, 1500).onResult(300);

    // The visible part of the requested area is 1000-1300, which is at 700-1000 in the scroll
    // bounds, which start at 100 in the view.
    ArgumentCaptor<Rect> sourceCaptor = ArgumentCaptor.forClass(Rect.class);
    ArgumentCaptor<Bitmap> bitmapCaptor = ArgumentCaptor.forClass(Bitmap.class);
    verify(mockPixelCopier).copyPixels(sourceCaptor.capture(), bitmapCaptor.capture(), any());
    assertEquals(new Rect(0, 800, 1000, 1100), sourceCaptor.getValue());
    assertEquals(1000, bitmapCaptor.getValue().getWidth());
    assertEquals(300, bitmapCaptor.getValue().getHeight());

    verify(mockCanvas).drawBitmap(eq(bitmapCaptor.getValue()), eq(0f), eq(0f), any());
    verify(mockSurface).unlockCanvasAndPost(mockCanvas);
    assertEquals(new Rect(0, 1000, 1000, 1300), result.get());
  }

  @Test
  public void imageRequestBeyondTheContentReportsEmptyArea() {
    AtomicReference<Rect> result = new AtomicReference<>();
    callback.onScrollCaptureImageRequest(
        session, new CancellationSignal(), new Rect(0, 3000, 1000, 3500), result::set);

    // Already at the end of the content.
    captureScrollToCallback(3000, 3500).onResult(1000);

    verify(mockPixelCopier, never()).copyPixels(any(), any(), any());
    assertTrue(result.get().isEmpty());
  }

  @Test
  public void imageRequestReportsEmptyAreaWhenTheFrameworkFails() {
    AtomicReference<Rect> result = new AtomicReference<>();
    callback.onScrollCaptureImageRequest(
        session, new CancellationSignal(), new Rect(0, 0, 1000, 500), result::set);

    captureScrollToCallback(0, 500).onResult(null);

    verify(mockPixelCopier, never()).copyPixels(any(), any(), any());
    assertTrue(result.get().isEmpty());
  }

  @Test
  @SuppressWarnings("unchecked")
  public void imageRequestReportsEmptyAreaWhenTheCopyFails() {
    doAnswer(
            invocation -> {
              ((Consumer<Boolean>) invocation.getArgument(2)).accept(false);
              return null;
            })
        .when(mockPixelCopier)
        .copyPixels(any(Rect.class), any(Bitmap.class), any());

    AtomicReference<Rect> result = new AtomicReference<>();
    callback.onScrollCaptureImageRequest(
        session, new CancellationSignal(), new Rect(0, 0, 1000, 500), result::set);
    captureScrollToCallback(0, 500).onResult(0);

    verify(mockSurface, never()).lockHardwareCanvas();
    assertTrue(result.get().isEmpty());
  }

  @Test
  public void imageRequestDoesNotReportWhenCancelled() {
    CancellationSignal signal = new CancellationSignal();
    AtomicReference<Rect> result = new AtomicReference<>();
    callback.onScrollCaptureImageRequest(session, signal, new Rect(0, 0, 1000, 500), result::set);

    signal.cancel();
    captureScrollToCallback(0, 500).onResult(0);

    verify(mockView, never()).postDelayed(any(Runnable.class), anyLong());
    assertNull(result.get());
  }

  @Test
  public void endRestoresTheFrameworkOnlyAfterStart() {
    AtomicBoolean ready = new AtomicBoolean(false);
    callback.onScrollCaptureEnd(() -> ready.set(true));
    verify(mockChannel, never()).end(any());
    assertTrue(ready.get());

    callback.onScrollCaptureStart(session, new CancellationSignal(), () -> {});
    Runnable onReady = () -> {};
    callback.onScrollCaptureEnd(onReady);
    verify(mockChannel).end(onReady);
  }
}

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
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.atLeastOnce;
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
  private FlutterScrollCaptureCallback.FrameCapturer mockFrameCapturer;
  private Bitmap frame;
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

    mockChannel = mock(ScrollCaptureChannel.class);
    frame = Bitmap.createBitmap(1000, 2000, Bitmap.Config.ARGB_8888);
    mockFrameCapturer = mock(FlutterScrollCaptureCallback.FrameCapturer.class);
    when(mockFrameCapturer.captureFrame()).thenReturn(frame);
    mockSurface = mock(Surface.class);
    mockCanvas = mock(Canvas.class);
    when(mockSurface.lockHardwareCanvas()).thenReturn(mockCanvas);
    session = new ScrollCaptureSession(mockSurface, SCROLL_BOUNDS, new Point(0, 0));
    callback = new FlutterScrollCaptureCallback(mockView, mockChannel, mockFrameCapturer);
  }

  @SuppressWarnings("unchecked")
  private ScrollCaptureChannel.Callback<Rect> captureSearchCallback() {
    ArgumentCaptor<ScrollCaptureChannel.Callback<Rect>> captor =
        ArgumentCaptor.forClass(ScrollCaptureChannel.Callback.class);
    verify(mockChannel).search(captor.capture());
    return captor.getValue();
  }

  @SuppressWarnings("unchecked")
  private ScrollCaptureChannel.Callback<Rect> captureLastStartCallback() {
    ArgumentCaptor<ScrollCaptureChannel.Callback<Rect>> captor =
        ArgumentCaptor.forClass(ScrollCaptureChannel.Callback.class);
    verify(mockChannel, atLeastOnce()).start(captor.capture());
    return captor.getValue();
  }

  @SuppressWarnings("unchecked")
  private ScrollCaptureChannel.Callback<Integer> captureScrollToCallback(int top, int bottom) {
    ArgumentCaptor<ScrollCaptureChannel.Callback<Integer>> captor =
        ArgumentCaptor.forClass(ScrollCaptureChannel.Callback.class);
    verify(mockChannel).scrollTo(eq(top), eq(bottom), captor.capture());
    return captor.getValue();
  }

  /** Starts a session in which the framework reports {@code bounds}. */
  private void startSession(Rect bounds) {
    callback.onScrollCaptureStart(session, new CancellationSignal(), () -> {});
    captureLastStartCallback().onResult(bounds);
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

    captureSearchCallback().onResult(new Rect(-10, 100, 1000, 2500));
    assertEquals(new Rect(0, 100, 1000, 2000), result.get());
  }

  @Test
  public void searchReportsEmptyBoundsWhenThereIsNothingToCapture() {
    AtomicReference<Rect> result = new AtomicReference<>();
    callback.onScrollCaptureSearch(new CancellationSignal(), result::set);

    captureSearchCallback().onResult(null);
    assertTrue(result.get().isEmpty());
  }

  @Test
  public void searchDoesNotReportWhenCancelled() {
    CancellationSignal signal = new CancellationSignal();
    AtomicReference<Rect> result = new AtomicReference<>();
    callback.onScrollCaptureSearch(signal, result::set);

    signal.cancel();
    captureSearchCallback().onResult(new Rect(0, 0, 10, 10));
    assertNull(result.get());
  }

  @Test
  public void startRunsOnReadyOnceTheFrameworkIsReady() {
    AtomicBoolean ready = new AtomicBoolean(false);
    callback.onScrollCaptureStart(session, new CancellationSignal(), () -> ready.set(true));

    assertFalse(ready.get());
    captureLastStartCallback().onResult(new Rect(SCROLL_BOUNDS));
    assertTrue(ready.get());
  }

  @Test
  public void imageRequestCopiesTheVisiblePartOfTheRequestedArea() {
    startSession(new Rect(SCROLL_BOUNDS));
    AtomicReference<Rect> result = new AtomicReference<>();
    // Request the area just below the initially visible area.
    callback.onScrollCaptureImageRequest(
        session, new CancellationSignal(), new Rect(0, 1000, 1000, 1500), result::set);

    // The framework could only scroll by 300 pixels before reaching the end of the content.
    captureScrollToCallback(1000, 1500).onResult(300);

    // The visible part of the requested area is 1000-1300, which is at 700-1000 in the scroll
    // bounds, which start at 100 in the view. It is drawn at the origin of the surface.
    verify(mockCanvas)
        .drawBitmap(
            eq(frame), eq(new Rect(0, 800, 1000, 1100)), eq(new Rect(0, 0, 1000, 300)), isNull());
    verify(mockSurface).unlockCanvasAndPost(mockCanvas);
    assertTrue(frame.isRecycled());
    assertEquals(new Rect(0, 1000, 1000, 1300), result.get());
  }

  @Test
  public void imageRequestBeyondTheContentReportsEmptyArea() {
    startSession(new Rect(SCROLL_BOUNDS));
    AtomicReference<Rect> result = new AtomicReference<>();
    callback.onScrollCaptureImageRequest(
        session, new CancellationSignal(), new Rect(0, 3000, 1000, 3500), result::set);

    // Already at the end of the content.
    captureScrollToCallback(3000, 3500).onResult(1000);

    verify(mockFrameCapturer, never()).captureFrame();
    assertTrue(result.get().isEmpty());
  }

  @Test
  public void imageRequestReportsEmptyAreaWhenTheFrameworkFails() {
    startSession(new Rect(SCROLL_BOUNDS));
    AtomicReference<Rect> result = new AtomicReference<>();
    callback.onScrollCaptureImageRequest(
        session, new CancellationSignal(), new Rect(0, 0, 1000, 500), result::set);

    captureScrollToCallback(0, 500).onResult(null);

    verify(mockFrameCapturer, never()).captureFrame();
    assertTrue(result.get().isEmpty());
  }

  @Test
  public void imageRequestReportsEmptyAreaWhenTheFrameIsUnavailable() {
    when(mockFrameCapturer.captureFrame()).thenReturn(null);
    startSession(new Rect(SCROLL_BOUNDS));
    AtomicReference<Rect> result = new AtomicReference<>();
    callback.onScrollCaptureImageRequest(
        session, new CancellationSignal(), new Rect(0, 0, 1000, 500), result::set);
    captureScrollToCallback(0, 500).onResult(0);

    verify(mockSurface, never()).lockHardwareCanvas();
    assertTrue(result.get().isEmpty());
  }

  @Test
  public void imageRequestReportsEmptyAreaWhenTheFrameDoesNotMatchTheView() {
    Bitmap smallFrame = Bitmap.createBitmap(500, 1000, Bitmap.Config.ARGB_8888);
    when(mockFrameCapturer.captureFrame()).thenReturn(smallFrame);
    startSession(new Rect(SCROLL_BOUNDS));
    AtomicReference<Rect> result = new AtomicReference<>();
    callback.onScrollCaptureImageRequest(
        session, new CancellationSignal(), new Rect(0, 0, 1000, 500), result::set);
    captureScrollToCallback(0, 500).onResult(0);

    verify(mockSurface, never()).lockHardwareCanvas();
    assertTrue(smallFrame.isRecycled());
    assertTrue(result.get().isEmpty());
  }

  @Test
  public void imageRequestDoesNotReportWhenCancelled() {
    startSession(new Rect(SCROLL_BOUNDS));
    CancellationSignal signal = new CancellationSignal();
    AtomicReference<Rect> result = new AtomicReference<>();
    callback.onScrollCaptureImageRequest(session, signal, new Rect(0, 0, 1000, 500), result::set);

    signal.cancel();
    captureScrollToCallback(0, 500).onResult(0);

    verify(mockFrameCapturer, never()).captureFrame();
    assertNull(result.get());
  }

  @Test
  public void imageRequestFailsWhenTheBoundsChangedSinceTheSearch() {
    startSession(new Rect(0, 200, 1000, 1100));
    AtomicReference<Rect> result = new AtomicReference<>();
    callback.onScrollCaptureImageRequest(
        session, new CancellationSignal(), new Rect(0, 0, 1000, 500), result::set);

    verify(mockChannel, never()).scrollTo(anyInt(), anyInt(), any());
    assertTrue(result.get().isEmpty());
  }

  @Test
  public void imageRequestIgnoresRepliesAfterTheSessionEnded() {
    startSession(new Rect(SCROLL_BOUNDS));
    AtomicReference<Rect> result = new AtomicReference<>();
    callback.onScrollCaptureImageRequest(
        session, new CancellationSignal(), new Rect(0, 0, 1000, 500), result::set);
    callback.onScrollCaptureEnd(() -> {});

    captureScrollToCallback(0, 500).onResult(0);

    verify(mockFrameCapturer, never()).captureFrame();
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

  @Test
  public void disposeEndsTheSessionAndIgnoresPendingReplies() {
    startSession(new Rect(SCROLL_BOUNDS));
    AtomicReference<Rect> result = new AtomicReference<>();
    callback.onScrollCaptureImageRequest(
        session, new CancellationSignal(), new Rect(0, 0, 1000, 500), result::set);

    callback.dispose();
    verify(mockChannel).end(any());

    captureScrollToCallback(0, 500).onResult(0);
    verify(mockFrameCapturer, never()).captureFrame();
    assertNull(result.get());

    // The system ending the session afterwards does not end it again.
    callback.onScrollCaptureEnd(() -> {});
    verify(mockChannel).end(any());
  }
}

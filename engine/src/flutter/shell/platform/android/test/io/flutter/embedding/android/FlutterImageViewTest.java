// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import static io.flutter.Build.API_LEVELS;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Canvas;
import android.hardware.HardwareBuffer;
import android.media.Image;
import android.media.ImageReader;
import android.os.Handler;
import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import java.nio.ByteBuffer;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.robolectric.annotation.Config;

@RunWith(AndroidJUnit4.class)
public class FlutterImageViewTest {
  private static final int TEST_DIMENSION_PX = 8;
  private static final int RGBA_BYTES_PER_PIXEL = 4;
  private static final int SCREEN_OFF_BURST_FRAME_COUNT = 100;
  private static final int MAX_CONCURRENT_VIEW_HELD_IMAGES = 3;

  private final Context ctx = ApplicationProvider.getApplicationContext();

  private static Image createMockApi29Image() {
    final Image image = mock(Image.class);
    final HardwareBuffer buffer = mock(HardwareBuffer.class);
    when(buffer.getUsage()).thenReturn(HardwareBuffer.USAGE_GPU_SAMPLED_IMAGE);
    when(image.getHardwareBuffer()).thenReturn(buffer);
    return image;
  }

  private static Image createMockApi28Image() {
    final Image image = mock(Image.class);
    final Image.Plane plane = mock(Image.Plane.class);
    final ByteBuffer byteBuffer =
        ByteBuffer.allocateDirect(TEST_DIMENSION_PX * TEST_DIMENSION_PX * RGBA_BYTES_PER_PIXEL);
    when(plane.getPixelStride()).thenReturn(RGBA_BYTES_PER_PIXEL);
    when(plane.getRowStride()).thenReturn(TEST_DIMENSION_PX * RGBA_BYTES_PER_PIXEL);
    when(plane.getBuffer()).thenReturn(byteBuffer);
    when(image.getWidth()).thenReturn(TEST_DIMENSION_PX);
    when(image.getHeight()).thenReturn(TEST_DIMENSION_PX);
    when(image.getPlanes()).thenReturn(new Image.Plane[] {plane});
    return image;
  }

  @Test
  @SuppressLint("WrongCall")
  @Config(sdk = API_LEVELS.API_33)
  public void setImage_capturedRetiringImageSurvivesNextSetImageBeforeFrameCommitCallbackFires() {
    final Deque<Runnable> pendingCommitCallbacks = new ArrayDeque<>();
    final FlutterImageView view =
        spy(new FlutterImageView(ctx, FlutterImageView.SurfaceKind.background));
    doAnswer(
            invocation -> {
              pendingCommitCallbacks.addLast(invocation.getArgument(0));
              return true;
            })
        .when(view)
        .registerFrameCommitCallback(any());

    final AtomicInteger img1Releases = new AtomicInteger(0);
    final AtomicInteger img2Releases = new AtomicInteger(0);
    final AtomicInteger img3Releases = new AtomicInteger(0);
    final Image img1 = createMockApi29Image();
    final Image img2 = createMockApi29Image();
    final Image img3 = createMockApi29Image();
    final Canvas canvas = mock(Canvas.class);

    // T1: setImage(img1) -> onDraw records img1.
    view.setImage(img1, img1Releases::incrementAndGet);
    assertEquals(1.0f, view.getAlpha(), 0.0f);
    view.onDraw(canvas);
    assertEquals(0, pendingCommitCallbacks.size());
    assertEquals(0, img1Releases.get());

    // setImage(img2) -> T2 onDraw records img2 and arms CB_T2 for img1.
    view.setImage(img2, img2Releases::incrementAndGet);
    assertEquals(0, img1Releases.get());
    view.onDraw(canvas);
    assertEquals(1, pendingCommitCallbacks.size());
    assertEquals(0, img1Releases.get());
    assertEquals(0, img2Releases.get());

    // Before CB_T2 fires, setImage(img3) arrives on main, moving img2 into retiringDisplayedImage.
    view.setImage(img3, img3Releases::incrementAndGet);
    assertEquals(0, img1Releases.get());
    assertEquals(0, img2Releases.get());
    assertEquals(0, img3Releases.get());

    // CB_T2 fires before T3 onDraw: must release img1 ONLY and preserve img2 in retiring slot!
    pendingCommitCallbacks.removeFirst().run();
    assertEquals(1, img1Releases.get());
    assertEquals(0, img2Releases.get());
    assertEquals(0, img3Releases.get());
    assertTrue(view.hasRetiringDisplayedImageForTest());
    assertTrue(view.hasCurrentDisplayedImageForTest());

    // T3 onDraw arms CB_T3 for img2; firing CB_T3 releases img2 while keeping img3 displayed.
    view.onDraw(canvas);
    assertEquals(1, pendingCommitCallbacks.size());
    assertEquals(0, img2Releases.get());
    pendingCommitCallbacks.removeFirst().run();
    assertEquals(1, img1Releases.get());
    assertEquals(1, img2Releases.get());
    assertEquals(0, img3Releases.get());
    assertFalse(view.hasRetiringDisplayedImageForTest());

    // Detaching from window releases img3 once.
    view.onDetachedFromWindow();
    assertEquals(1, img3Releases.get());
    assertFalse(view.hasCurrentDisplayedImageForTest());
  }

  @Test
  @SuppressLint("WrongCall")
  @Config(sdk = API_LEVELS.API_33)
  public void setImage_hundredScreenOffUpdatesReleaseUndrawnImagesImmediately() {
    final Deque<Runnable> pendingCommitCallbacks = new ArrayDeque<>();
    final FlutterImageView view =
        spy(new FlutterImageView(ctx, FlutterImageView.SurfaceKind.background));
    doAnswer(
            invocation -> {
              pendingCommitCallbacks.addLast(invocation.getArgument(0));
              return true;
            })
        .when(view)
        .registerFrameCommitCallback(any());

    final AtomicInteger liveImages = new AtomicInteger(0);
    final Image initialDrawnImage = createMockApi29Image();
    liveImages.incrementAndGet();
    view.setImage(initialDrawnImage, liveImages::decrementAndGet);
    view.onDraw(mock(Canvas.class));
    assertEquals(1, liveImages.get());

    // Simulate 100 frames arriving while the screen is off (no further onDraw traversals).
    for (int i = 0; i < SCREEN_OFF_BURST_FRAME_COUNT; i++) {
      final Image frameImage = createMockApi29Image();
      liveImages.incrementAndGet();
      view.setImage(frameImage, liveImages::decrementAndGet);
      assertTrue(
          "Live view-held images exceeded budget: " + liveImages.get(),
          liveImages.get() <= MAX_CONCURRENT_VIEW_HELD_IMAGES);
    }

    // Only the drawn image (retiring) + the most recent undrawn image (current) remain held.
    assertEquals(2, liveImages.get());

    view.releaseDisplayedImages();
    assertEquals(0, liveImages.get());
  }

  @Test
  @SuppressLint("WrongCall")
  @Config(sdk = API_LEVELS.API_28)
  public void onDraw_belowApi29CopiesPixelsAndImmediatelyReleasesImagesWhileKeepingBitmap() {
    final FlutterImageView view =
        new FlutterImageView(ctx, FlutterImageView.SurfaceKind.background);
    final AtomicInteger img1Releases = new AtomicInteger(0);
    final AtomicInteger img2Releases = new AtomicInteger(0);

    view.setImage(createMockApi28Image(), img1Releases::incrementAndGet);
    view.onDraw(mock(Canvas.class));

    // On API 28, copyPixelsFromBuffer copied into currentBitmap, so currentDisplayedImage is
    // immediately released and nulled while currentBitmap stays alive for redraws.
    assertEquals(1, img1Releases.get());
    assertFalse(view.hasCurrentDisplayedImageForTest());
    assertFalse(view.hasRetiringDisplayedImageForTest());
    assertNotNull(view.getCurrentBitmapForTest());

    // Subsequent redraws still draw currentBitmap without touching closed Image planes.
    final Canvas redrawCanvas = mock(Canvas.class);
    view.onDraw(redrawCanvas);
    verify(redrawCanvas, times(1)).drawBitmap(view.getCurrentBitmapForTest(), 0, 0, null);

    view.setImage(createMockApi28Image(), img2Releases::incrementAndGet);
    view.onDraw(mock(Canvas.class));
    assertEquals(1, img2Releases.get());

    view.releaseDisplayedImages();
    assertNull(view.getCurrentBitmapForTest());
  }

  @Test
  public void readerBackedView_usesSixSlotReaderAndTracksAutoAcquiredFramesForPolling() {
    final FlutterImageView sixSlotView =
        new FlutterImageView(
            ctx, TEST_DIMENSION_PX, TEST_DIMENSION_PX, FlutterImageView.SurfaceKind.background);
    assertNotNull(sixSlotView.getImageReader());
    assertEquals(FlutterImageView.MAX_IMAGES, sixSlotView.getImageReader().getMaxImages());
    sixSlotView.closeImageReader();

    final ImageReader mockReader = mock(ImageReader.class);
    final Image autoImage = mock(Image.class);
    when(mockReader.acquireLatestImage()).thenReturn(autoImage, (Image) null);

    final FlutterImageView view =
        new FlutterImageView(ctx, mockReader, FlutterImageView.SurfaceKind.background);
    final FlutterRenderer renderer = new FlutterRenderer(mock(FlutterJNI.class));
    view.attachToRenderer(renderer);

    final ArgumentCaptor<ImageReader.OnImageAvailableListener> listenerCaptor =
        ArgumentCaptor.forClass(ImageReader.OnImageAvailableListener.class);
    verify(mockReader, times(1))
        .setOnImageAvailableListener(listenerCaptor.capture(), any(Handler.class));

    // Simulate main-Looper OnImageAvailableListener draining the latest image before screenshot
    // poll.
    listenerCaptor.getValue().onImageAvailable(mockReader);
    assertFalse(view.acquireLatestImage());
    assertTrue(view.pollLatestImageViewFrame());
    assertFalse(view.pollLatestImageViewFrame());

    view.detachFromRenderer();
    verify(mockReader, times(1)).setOnImageAvailableListener(null, null);
  }

  @Test
  public void displayOnlyConstructors_haveNoInternalImageReaderAndGuardReaderMethods() {
    final FlutterImageView bgView =
        new FlutterImageView(ctx, FlutterImageView.SurfaceKind.background);
    final FlutterImageView overlayView =
        new FlutterImageView(ctx, FlutterImageView.SurfaceKind.overlay);

    assertNull(bgView.getImageReader());
    assertNull(bgView.getSurface());
    assertFalse(bgView.acquireLatestImage());
    assertFalse(bgView.pollLatestImageViewFrame());
    bgView.resizeIfNeeded(TEST_DIMENSION_PX, TEST_DIMENSION_PX);
    bgView.onSizeChanged(TEST_DIMENSION_PX, TEST_DIMENSION_PX, 0, 0);
    bgView.closeImageReader();

    assertNull(overlayView.getImageReader());
    assertNull(overlayView.getSurface());
    assertFalse(overlayView.acquireLatestImage());
  }
}

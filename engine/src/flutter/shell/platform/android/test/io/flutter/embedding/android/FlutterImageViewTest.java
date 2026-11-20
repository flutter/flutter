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
import static org.mockito.Mockito.mock;
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

  private static Canvas createHardwareCanvasMock() {
    final Canvas canvas = mock(Canvas.class);
    when(canvas.isHardwareAccelerated()).thenReturn(true);
    return canvas;
  }

  @Test
  @SuppressLint("WrongCall")
  @Config(sdk = API_LEVELS.API_33)
  public void setImage_preDrawCapturedCommitCallbackAndClippedOutRearmAndThreeFramePipeline() {
    // Models AOSP ViewRootImpl.performDraw(): captureFrameCommitCallbacks() drains
    // mOnFrameCommitListeners into inFlightRenderThreadCallbacks BEFORE View.onDraw(Canvas) runs.
    final Deque<Runnable> vtoPendingListeners = new ArrayDeque<>();
    final Deque<Runnable> inFlightRenderThreadCallbacks = new ArrayDeque<>();
    final FlutterImageView view =
        new FlutterImageView(ctx, FlutterImageView.SurfaceKind.background) {
          @Override
          boolean registerFrameCommitCallback(Runnable callback) {
            vtoPendingListeners.addLast(callback);
            return true;
          }
        };
    final Runnable captureFrameCommitCallbacks =
        () -> {
          while (!vtoPendingListeners.isEmpty()) {
            inFlightRenderThreadCallbacks.addLast(vtoPendingListeners.removeFirst());
          }
        };

    final AtomicInteger img1Releases = new AtomicInteger(0);
    final AtomicInteger img2Releases = new AtomicInteger(0);
    final AtomicInteger img3Releases = new AtomicInteger(0);
    final Image img1 = createMockApi29Image();
    final Image img2 = createMockApi29Image();
    final Image img3 = createMockApi29Image();
    final Canvas hwCanvas = createHardwareCanvasMock();

    // T1: setImage(img1) -> captureFrameCommitCallbacks() -> onDraw(hwCanvas).
    view.setImage(img1, img1Releases::incrementAndGet);
    assertEquals(1.0f, view.getAlpha(), 0.0f);
    assertEquals(0, vtoPendingListeners.size());
    captureFrameCommitCallbacks.run();
    view.onDraw(hwCanvas);
    assertEquals(0, inFlightRenderThreadCallbacks.size());
    assertEquals(0, img1Releases.get());

    // setImage(img2) MUST arm CB for img1 BEFORE T2 begins so captureFrameCommitCallbacks()
    // captures it ahead of onDraw.
    view.setImage(img2, img2Releases::incrementAndGet);
    assertEquals(1, vtoPendingListeners.size());
    assertEquals(0, img1Releases.get());

    // Clipped-out traversal T_clipped: ViewRootImpl captures callbacks, skips view.onDraw(), and
    // commits. Firing the callback must NOT release img1 (still in RenderNode) and must re-arm it.
    captureFrameCommitCallbacks.run();
    assertEquals(1, inFlightRenderThreadCallbacks.size());
    inFlightRenderThreadCallbacks.removeFirst().run();
    assertEquals(0, img1Releases.get());
    assertTrue(view.hasRetiringDisplayedImageForTest());
    assertEquals(1, vtoPendingListeners.size());

    // T2: captureFrameCommitCallbacks() runs BEFORE view.onDraw(hwCanvas) draws img2.
    captureFrameCommitCallbacks.run();
    assertEquals(0, vtoPendingListeners.size());
    assertEquals(1, inFlightRenderThreadCallbacks.size());
    view.onDraw(hwCanvas);
    assertEquals(0, img1Releases.get());
    assertEquals(0, img2Releases.get());

    // Before CB_T2 fires, setImage(img3) arrives on main, moving img2 into retiringDisplayedImage
    // and arming CB_T3 in vtoPendingListeners.
    view.setImage(img3, img3Releases::incrementAndGet);
    assertEquals(1, vtoPendingListeners.size());
    assertEquals(0, img1Releases.get());
    assertEquals(0, img2Releases.get());
    assertEquals(0, img3Releases.get());

    // CB_T2 fires before T3 onDraw: releases img1 ONLY and preserves img2 in retiring slot.
    inFlightRenderThreadCallbacks.removeFirst().run();
    assertEquals(1, img1Releases.get());
    assertEquals(0, img2Releases.get());
    assertEquals(0, img3Releases.get());
    assertTrue(view.hasRetiringDisplayedImageForTest());
    assertTrue(view.hasCurrentDisplayedImageForTest());

    // T3 -> idle: captureFrameCommitCallbacks() -> view.onDraw(hwCanvas) -> CB_T3 fires with NO T4!
    captureFrameCommitCallbacks.run();
    view.onDraw(hwCanvas);
    assertEquals(1, inFlightRenderThreadCallbacks.size());
    inFlightRenderThreadCallbacks.removeFirst().run();
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
        new FlutterImageView(ctx, FlutterImageView.SurfaceKind.background) {
          @Override
          boolean registerFrameCommitCallback(Runnable callback) {
            pendingCommitCallbacks.addLast(callback);
            return true;
          }
        };

    final AtomicInteger liveImages = new AtomicInteger(0);
    final Image initialDrawnImage = createMockApi29Image();
    liveImages.incrementAndGet();
    view.setImage(initialDrawnImage, liveImages::decrementAndGet);
    view.onDraw(createHardwareCanvasMock());
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

    // Only the drawn image (retiring) + the most recent undrawn image (current) remain held, and
    // only 1 FrameCommitCallback was registered across the entire burst.
    assertEquals(2, liveImages.get());
    assertEquals(1, pendingCommitCallbacks.size());

    view.releaseDisplayedImages();
    assertEquals(0, liveImages.get());
  }

  @Test
  @SuppressLint("WrongCall")
  @Config(sdk = API_LEVELS.API_33)
  public void onDraw_api29NullHardwareBufferClearsStaleBitmapAndSoftwareCanvasReleasesImages() {
    final android.graphics.Bitmap softwareCopyBitmap =
        android.graphics.Bitmap.createBitmap(
            TEST_DIMENSION_PX, TEST_DIMENSION_PX, android.graphics.Bitmap.Config.ARGB_8888);
    final android.graphics.Bitmap mockHardwareBitmap = mock(android.graphics.Bitmap.class);
    when(mockHardwareBitmap.getConfig()).thenReturn(android.graphics.Bitmap.Config.HARDWARE);
    when(mockHardwareBitmap.copy(android.graphics.Bitmap.Config.ARGB_8888, false))
        .thenReturn(softwareCopyBitmap);

    final FlutterImageView view =
        new FlutterImageView(ctx, FlutterImageView.SurfaceKind.background) {
          @Override
          public boolean isAttachedToWindow() {
            return true;
          }

          @Override
          public boolean isHardwareAccelerated() {
            return false;
          }

          @Override
          android.graphics.Bitmap wrapHardwareBuffer(HardwareBuffer buffer) {
            return mockHardwareBitmap;
          }
        };

    // Non-hardware-accelerated window on API 29+: registerFrameCommitCallback returns false, and
    // onDraw onto a real software Canvas copies to ARGB_8888 without throwing and immediately
    // releases DisplayedImages while keeping softwareCopyBitmap for redraws.
    assertFalse(view.registerFrameCommitCallback(() -> {}));
    final AtomicInteger swReleases = new AtomicInteger(0);
    final android.graphics.Bitmap targetBitmap =
        android.graphics.Bitmap.createBitmap(
            TEST_DIMENSION_PX, TEST_DIMENSION_PX, android.graphics.Bitmap.Config.ARGB_8888);
    final Canvas softwareCanvas = new Canvas(targetBitmap);
    assertFalse(softwareCanvas.isHardwareAccelerated());

    view.setImage(createMockApi29Image(), swReleases::incrementAndGet);
    view.onDraw(softwareCanvas);
    assertEquals(1, swReleases.get());
    assertEquals(softwareCopyBitmap, view.getCurrentBitmapForTest());
    assertFalse(view.hasCurrentDisplayedImageForTest());
    assertFalse(view.hasRetiringDisplayedImageForTest());

    // Now test getHardwareBuffer() == null on a hardware-accelerated view: clears stale
    // currentBitmap so retiringDisplayedImage is never drawn after release, and drawing onto a
    // one-off software Canvas copies HARDWARE -> ARGB_8888 while keeping currentBitmap HARDWARE.
    final Deque<Runnable> vtoQueue = new ArrayDeque<>();
    final FlutterImageView hwView =
        new FlutterImageView(ctx, FlutterImageView.SurfaceKind.background) {
          @Override
          boolean registerFrameCommitCallback(Runnable callback) {
            vtoQueue.addLast(callback);
            return true;
          }

          @Override
          android.graphics.Bitmap wrapHardwareBuffer(HardwareBuffer buffer) {
            return mockHardwareBitmap;
          }
        };
    final Canvas hwCanvas = createHardwareCanvasMock();
    hwView.setImage(createMockApi29Image(), null);
    hwView.onDraw(hwCanvas);
    assertEquals(mockHardwareBitmap, hwView.getCurrentBitmapForTest());

    final Canvas oneOffSoftwareCanvas = mock(Canvas.class);
    when(oneOffSoftwareCanvas.isHardwareAccelerated()).thenReturn(false);
    hwView.onDraw(oneOffSoftwareCanvas);
    verify(oneOffSoftwareCanvas, times(1)).drawBitmap(softwareCopyBitmap, 0, 0, null);
    assertEquals(mockHardwareBitmap, hwView.getCurrentBitmapForTest());

    final Image nullBufferImage = mock(Image.class);
    when(nullBufferImage.getHardwareBuffer()).thenReturn(null);
    hwView.setImage(nullBufferImage, null);
    hwView.onDraw(hwCanvas);
    assertNull(hwView.getCurrentBitmapForTest());
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

  @Test
  @SuppressLint("WrongCall")
  @Config(sdk = API_LEVELS.API_33)
  public void setImage_boundsRetiringFrameCommitCallbackRearmsWhenOffscreen() {
    final Deque<Runnable> pendingCommitCallbacks = new ArrayDeque<>();
    final android.graphics.Bitmap mockHardwareBitmap = mock(android.graphics.Bitmap.class);
    when(mockHardwareBitmap.getConfig()).thenReturn(android.graphics.Bitmap.Config.HARDWARE);

    final FlutterImageView view =
        new FlutterImageView(ctx, FlutterImageView.SurfaceKind.background) {
          @Override
          boolean registerFrameCommitCallback(Runnable callback) {
            pendingCommitCallbacks.addLast(callback);
            return true;
          }

          @Override
          android.graphics.Bitmap wrapHardwareBuffer(HardwareBuffer buffer) {
            return mockHardwareBitmap;
          }
        };

    final Canvas hwCanvas = mock(Canvas.class);
    when(hwCanvas.isHardwareAccelerated()).thenReturn(true);
    final AtomicInteger img1Releases = new AtomicInteger(0);
    final AtomicInteger img2Releases = new AtomicInteger(0);

    // Draw image 1, then replace it with image 2 without drawing image 2 (simulating a clipped or
    // offscreen view that skips onDraw across unrelated window traversals).
    view.setImage(createMockApi29Image(), img1Releases::incrementAndGet);
    view.onDraw(hwCanvas);
    view.setImage(createMockApi29Image(), img2Releases::incrementAndGet);
    assertEquals(1, pendingCommitCallbacks.size());

    // First MAX_RETIRING_FRAME_COMMIT_REARMS traversals re-arm and retain image 1.
    for (int i = 0; i < FlutterImageView.MAX_RETIRING_FRAME_COMMIT_REARMS; i++) {
      pendingCommitCallbacks.removeFirst().run();
      assertEquals(0, img1Releases.get());
      assertEquals(1, pendingCommitCallbacks.size());
    }

    // The next traversal hits the re-arm bound and releases image 1 instead of spinning forever.
    pendingCommitCallbacks.removeFirst().run();
    assertEquals(1, img1Releases.get());
    assertTrue(pendingCommitCallbacks.isEmpty());
    assertFalse(view.hasRetiringDisplayedImageForTest());

    view.releaseDisplayedImages();
    assertEquals(1, img2Releases.get());
  }
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import static io.flutter.Build.API_LEVELS;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.ColorSpace;
import android.graphics.PixelFormat;
import android.hardware.HardwareBuffer;
import android.media.Image;
import android.media.ImageReader;
import android.os.Handler;
import android.os.Looper;
import android.util.AttributeSet;
import android.view.Surface;
import android.view.View;
import android.view.ViewTreeObserver;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.annotation.VisibleForTesting;
import io.flutter.Log;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.renderer.RenderSurface;
import java.nio.ByteBuffer;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Locale;

/**
 * Paints a Flutter UI provided by an {@link android.media.ImageReader} or an externally supplied
 * {@link android.media.Image} onto a {@link android.graphics.Canvas}.
 *
 * <p>A {@code FlutterImageView} is intended for situations where a developer needs to render a
 * Flutter UI, but also needs to render an interactive {@link
 * io.flutter.plugin.platform.PlatformView}.
 *
 * <p>This {@code View} can either own an internal {@link android.media.ImageReader} (for {@link
 * RenderMode#image}) or operate in display-only mode for Hybrid Composition Frame Packets via
 * {@link #setImage(Image, Runnable)}.
 */
public class FlutterImageView extends View implements RenderSurface {
  private static final String TAG = "FlutterImageView";

  // 1 displayed + 1 retiring + 3 maximum FIFO pipeline draws ahead of a platform latch + 1 scratch.
  @VisibleForTesting static final int MAX_IMAGES = 6;

  // Minimum valid pixel dimension accepted by Android ImageReader.newInstance.
  private static final int MIN_IMAGE_DIMENSION_PX = 1;

  private static final class DisplayedImage {
    @NonNull final Image image;
    @Nullable final Runnable releaseCallback;
    boolean commitCallbackRegistered = false;
    boolean supersededByDraw = false;
    private boolean released = false;

    DisplayedImage(@NonNull Image image, @Nullable Runnable releaseCallback) {
      this.image = image;
      this.releaseCallback = releaseCallback;
    }

    void releaseOnce() {
      if (released) {
        return;
      }
      released = true;
      if (releaseCallback != null) {
        releaseCallback.run();
      } else {
        image.close();
      }
    }
  }

  @Nullable private ImageReader imageReader;
  @Nullable private Image currentImage;
  @Nullable private DisplayedImage currentDisplayedImage;
  @Nullable private DisplayedImage retiringDisplayedImage;
  private final Deque<DisplayedImage> pendingCommitDisplayedImages = new ArrayDeque<>();
  private boolean currentDisplayedImageDrawn = false;
  private boolean hasUnconsumedAutoAcquiredImage = false;
  @Nullable private Bitmap currentBitmap;
  @Nullable private FlutterRenderer flutterRenderer;

  private final Handler mainHandler = new Handler(Looper.getMainLooper());

  private boolean isContentSizingEnabled = false;

  @Nullable
  public ImageReader getImageReader() {
    return imageReader;
  }

  public enum SurfaceKind {
    /** Displays the background canvas. */
    background,

    /** Displays the overlay surface canvas. */
    overlay,
  }

  /** The kind of surface. */
  private SurfaceKind kind;

  /** Whether the view is attached to the Flutter render. */
  private boolean isAttachedToFlutterRenderer = false;

  /**
   * Whether rendering to this {@code FlutterImageView} has been paused (for example, while {@link
   * FlutterView#revertImageView} waits for the first frame on the restored surface before removing
   * this view).
   */
  private boolean isPaused = false;

  /** Whether {@link #imageReader} has already been closed (or was never allocated). */
  private boolean isImageReaderClosed = false;

  private final ImageReader.OnImageAvailableListener onImageAvailableListener =
      reader -> {
        if (isActiveBackgroundSurface() && reader == imageReader && !isImageReaderClosed) {
          try {
            acquireLatestImage();
          } catch (IllegalStateException ex) {
            Log.w(TAG, "Failed to auto-acquire image in FlutterImageView", ex);
          }
        }
      };

  /**
   * Constructs a {@code FlutterImageView} with an {@link android.media.ImageReader} that provides
   * the Flutter UI.
   */
  public FlutterImageView(@NonNull Context context, int width, int height, SurfaceKind kind) {
    this(context, createImageReader(width, height), kind);
  }

  public FlutterImageView(@NonNull Context context) {
    this(context, MIN_IMAGE_DIMENSION_PX, MIN_IMAGE_DIMENSION_PX, SurfaceKind.background);
  }

  public FlutterImageView(@NonNull Context context, @NonNull AttributeSet attrs) {
    this(context, MIN_IMAGE_DIMENSION_PX, MIN_IMAGE_DIMENSION_PX, SurfaceKind.background);
  }

  /**
   * Constructs a display-only {@code FlutterImageView} that presents {@link Image} buffers supplied
   * via {@link #setImage(Image, Runnable)} without allocating an internal {@link ImageReader}.
   */
  public FlutterImageView(@NonNull Context context, @NonNull SurfaceKind kind) {
    super(context, null);
    this.imageReader = null;
    this.isImageReaderClosed = true;
    this.kind = kind;
    init();
  }

  @VisibleForTesting
  /*package*/ FlutterImageView(
      @NonNull Context context, @NonNull ImageReader imageReader, SurfaceKind kind) {
    super(context, null);
    this.imageReader = imageReader;
    this.kind = kind;
    init();
  }

  private void init() {
    setAlpha(0.0f);
    isContentSizingEnabled = ContentSizingFlag.isEnabled(getContext());
  }

  @Override
  protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
    if (isContentSizingEnabled) {
      FlutterMeasureSpec.onMeasure(widthMeasureSpec, heightMeasureSpec, this::setMeasuredDimension);
    } else {
      super.onMeasure(widthMeasureSpec, heightMeasureSpec);
    }
  }

  private static void logW(String format, Object... args) {
    Log.w(TAG, String.format(Locale.US, format, args));
  }

  @SuppressLint("WrongConstant") // RGBA_8888 is a valid constant.
  @NonNull
  private static ImageReader createImageReader(int width, int height) {
    if (width < MIN_IMAGE_DIMENSION_PX) {
      logW(
          "ImageReader width must be greater than 0, but given width=%d, set width=%d",
          width, MIN_IMAGE_DIMENSION_PX);
      width = MIN_IMAGE_DIMENSION_PX;
    }
    if (height < MIN_IMAGE_DIMENSION_PX) {
      logW(
          "ImageReader height must be greater than 0, but given height=%d, set height=%d",
          height, MIN_IMAGE_DIMENSION_PX);
      height = MIN_IMAGE_DIMENSION_PX;
    }
    if (android.os.Build.VERSION.SDK_INT >= API_LEVELS.API_29) {
      return ImageReader.newInstance(
          width,
          height,
          PixelFormat.RGBA_8888,
          MAX_IMAGES,
          HardwareBuffer.USAGE_GPU_SAMPLED_IMAGE | HardwareBuffer.USAGE_GPU_COLOR_OUTPUT);
    } else {
      return ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, MAX_IMAGES);
    }
  }

  @Nullable
  public Surface getSurface() {
    return imageReader != null ? imageReader.getSurface() : null;
  }

  @Nullable
  @Override
  public FlutterRenderer getAttachedRenderer() {
    return flutterRenderer;
  }

  /**
   * Invoked by the owner of this {@code FlutterImageView} when it wants to begin rendering a
   * Flutter UI to this {@code FlutterImageView}.
   */
  @Override
  public void attachToRenderer(@NonNull FlutterRenderer flutterRenderer) {
    switch (kind) {
      case background:
        if (imageReader != null && !isImageReaderClosed) {
          imageReader.setOnImageAvailableListener(onImageAvailableListener, mainHandler);
          flutterRenderer.swapSurface(imageReader.getSurface());
        }
        break;
      case overlay:
        // Do nothing since the attachment is done by the handler of
        // `FlutterJNI#createOverlaySurface()` in the native side.
        break;
    }
    setAlpha(1.0f);
    this.flutterRenderer = flutterRenderer;
    isAttachedToFlutterRenderer = true;
    isPaused = false;
  }

  /**
   * Invoked by the owner of this {@code FlutterImageView} when it no longer wants to render a
   * Flutter UI to this {@code FlutterImageView}.
   */
  public void detachFromRenderer() {
    if (!isAttachedToFlutterRenderer) {
      return;
    }
    if (imageReader != null && !isImageReaderClosed) {
      imageReader.setOnImageAvailableListener(null, null);
    }
    setAlpha(0.0f);
    // Drop the latest image as it shouldn't render this image if this view is
    // attached to the renderer again.
    acquireLatestImage();
    // Clear drawings.
    currentBitmap = null;

    // Close and clear the current image if any.
    closeCurrentImage();
    releaseDisplayedImages();
    hasUnconsumedAutoAcquiredImage = false;
    invalidate();
    isAttachedToFlutterRenderer = false;
    isPaused = false;
  }

  public void pause() {
    if (!isAttachedToFlutterRenderer) {
      return;
    }
    isPaused = true;
  }

  @Override
  public void resume() {
    if (!isAttachedToFlutterRenderer) {
      return;
    }
    isPaused = false;
  }

  private boolean isActiveBackgroundSurface() {
    return kind == SurfaceKind.background && isAttachedToFlutterRenderer && !isPaused;
  }

  /**
   * Acquires the next image to be drawn to the {@link android.graphics.Canvas}. Returns true if
   * there's an image available in the queue.
   */
  public boolean acquireLatestImage() {
    if (!isAttachedToFlutterRenderer || isImageReaderClosed || imageReader == null) {
      return false;
    }
    // 1. `acquireLatestImage()` may return null if no new image is available.
    // 2. There's no guarantee that `onDraw()` is called after `invalidate()`.
    // For example, the device may not produce new frames if it's in sleep mode
    // or some special Android devices so the calls to `invalidate()` queued up
    // until the device produces a new frame.
    // 3. While the engine will also stop producing frames, there is a race condition.
    final Image newImage = imageReader.acquireLatestImage();
    if (newImage != null) {
      // Only close current image after acquiring valid new image
      closeCurrentImage();
      currentImage = newImage;
      hasUnconsumedAutoAcquiredImage = true;
      invalidate();
    }
    return newImage != null;
  }

  /**
   * Polls whether a new frame has been acquired (either via {@link #acquireLatestImage()}, the
   * main-Looper {@link ImageReader.OnImageAvailableListener}, or {@link #setImage(Image,
   * Runnable)}) since the previous poll.
   */
  boolean pollLatestImageViewFrame() {
    final boolean acquiredNow = acquireLatestImage();
    final boolean hadUnconsumed = hasUnconsumedAutoAcquiredImage;
    hasUnconsumedAutoAcquiredImage = false;
    return acquiredNow || hadUnconsumed;
  }

  /**
   * Presents an externally acquired {@link Image} on the next {@link #onDraw(Canvas)} traversal and
   * invokes {@code releaseCallback} (or {@link Image#close()} when {@code null}) exactly once after
   * the buffer is superseded and no longer referenced by HWUI.
   */
  public void setImage(@NonNull Image image, @Nullable Runnable releaseCallback) {
    closeCurrentImage();
    setAlpha(1.0f);
    hasUnconsumedAutoAcquiredImage = true;
    if (currentDisplayedImage != null) {
      if (!currentDisplayedImageDrawn) {
        currentDisplayedImage.releaseOnce();
      } else {
        if (retiringDisplayedImage != null && !retiringDisplayedImage.commitCallbackRegistered) {
          retiringDisplayedImage.releaseOnce();
        }
        retiringDisplayedImage = currentDisplayedImage;
        if (android.os.Build.VERSION.SDK_INT >= API_LEVELS.API_29) {
          // Arm FrameCommitCallback BEFORE invalidate() because ViewRootImpl.performDraw() calls
          // ViewTreeObserver.captureFrameCommitCallbacks() at the start of performDraw(), prior to
          // invoking View.onDraw(Canvas).
          armRetiringFrameCommitCallback(retiringDisplayedImage);
        }
      }
    }
    currentDisplayedImage = new DisplayedImage(image, releaseCallback);
    currentDisplayedImageDrawn = false;
    invalidate();
  }

  private void releasePendingAndRetiringDisplayedImages() {
    while (!pendingCommitDisplayedImages.isEmpty()) {
      pendingCommitDisplayedImages.removeFirst().releaseOnce();
    }
    if (retiringDisplayedImage != null) {
      retiringDisplayedImage.releaseOnce();
      retiringDisplayedImage = null;
    }
  }

  /**
   * Immediately releases any displayed, retiring, or commit-pending {@link Image} instances
   * supplied via {@link #setImage(Image, Runnable)} and clears the cached bitmap when no
   * reader-backed image is active.
   */
  public void releaseDisplayedImages() {
    releasePendingAndRetiringDisplayedImages();
    if (currentDisplayedImage != null) {
      currentDisplayedImage.releaseOnce();
      currentDisplayedImage = null;
    }
    currentDisplayedImageDrawn = false;
    if (currentImage == null) {
      currentBitmap = null;
    }
    hasUnconsumedAutoAcquiredImage = false;
  }

  @Override
  protected void onWindowVisibilityChanged(int visibility) {
    super.onWindowVisibilityChanged(visibility);
    if (visibility != View.VISIBLE) {
      releasePendingAndRetiringDisplayedImages();
    }
  }

  @Override
  protected void onDetachedFromWindow() {
    releaseDisplayedImages();
    super.onDetachedFromWindow();
  }

  /**
   * Drains and closes any pending images currently queued in {@link #imageReader} before
   * reattaching a reused {@code FlutterImageView} to the renderer.
   */
  void drainPendingImages() {
    if (isImageReaderClosed || imageReader == null) {
      return;
    }
    final Image droppedImage = imageReader.acquireLatestImage();
    if (droppedImage != null) {
      droppedImage.close();
    }
    hasUnconsumedAutoAcquiredImage = false;
  }

  /** Creates a new image reader with the provided size. */
  public void resizeIfNeeded(int width, int height) {
    if (flutterRenderer == null || imageReader == null) {
      return;
    }
    if (!isImageReaderClosed
        && width == imageReader.getWidth()
        && height == imageReader.getHeight()) {
      return;
    }

    // ImageReaders cannot be resized once created. Allocate the replacement first and, when active
    // as the background surface, move FlutterRenderer onto the new Surface before closing the old
    // ImageReader so the raster thread is never left bound to a closed BufferQueue. Convert any
    // pending Image to currentBitmap before closing its reader, while letting acquireLatestImage()
    // return false until the resized ImageReader receives a matching-size frame.
    final ImageReader oldImageReader = imageReader;
    final boolean oldReaderWasClosed = isImageReaderClosed;
    if (!oldReaderWasClosed) {
      oldImageReader.setOnImageAvailableListener(null, null);
    }
    imageReader = createImageReader(width, height);
    isImageReaderClosed = false;
    if (isAttachedToFlutterRenderer && kind == SurfaceKind.background) {
      imageReader.setOnImageAvailableListener(onImageAvailableListener, mainHandler);
    }
    if (isActiveBackgroundSurface()) {
      flutterRenderer.swapSurface(imageReader.getSurface());
    }
    if (!oldReaderWasClosed) {
      final Image latest = oldImageReader.acquireLatestImage();
      if (latest != null && latest != currentImage) {
        closeCurrentImage();
        currentImage = latest;
      }
      if (currentImage != null) {
        updateCurrentBitmap();
        closeCurrentImage();
      }
      oldImageReader.close();
    }
    hasUnconsumedAutoAcquiredImage = false;
  }

  /**
   * Closes the image reader associated with the current {@code FlutterImageView}.
   *
   * <p>Once the image reader is closed, calling {@code acquireLatestImage} will result in an {@code
   * IllegalStateException}.
   */
  public void closeImageReader() {
    if (imageReader != null && !isImageReaderClosed) {
      imageReader.setOnImageAvailableListener(null, null);
      imageReader.close();
      isImageReaderClosed = true;
    }
    hasUnconsumedAutoAcquiredImage = false;
  }

  @RequiresApi(API_LEVELS.API_29)
  @VisibleForTesting
  boolean registerFrameCommitCallback(@NonNull Runnable callback) {
    if (!isHardwareAccelerated()
        || !isAttachedToWindow()
        || getWindowVisibility() != View.VISIBLE) {
      return false;
    }
    final View rootView = getRootView();
    final ViewTreeObserver vto = rootView != null ? rootView.getViewTreeObserver() : null;
    if (vto == null || !vto.isAlive()) {
      return false;
    }
    vto.registerFrameCommitCallback(callback);
    return true;
  }

  @RequiresApi(API_LEVELS.API_29)
  private void armRetiringFrameCommitCallback(@NonNull DisplayedImage retiringAtArm) {
    if (retiringAtArm.released || retiringAtArm.commitCallbackRegistered) {
      return;
    }
    retiringAtArm.commitCallbackRegistered = true;
    if (!pendingCommitDisplayedImages.contains(retiringAtArm)) {
      pendingCommitDisplayedImages.addLast(retiringAtArm);
    }
    final Runnable releaseRetiringCallback =
        () -> {
          if (retiringAtArm.released) {
            pendingCommitDisplayedImages.remove(retiringAtArm);
            return;
          }
          if (!retiringAtArm.supersededByDraw && this.retiringDisplayedImage == retiringAtArm) {
            // A window traversal captured FrameCommitCallbacks while this view was clipped out or
            // skipped onDraw, so its RenderNode may still reference retiringAtArm. Re-arm for the
            // next hardware-accelerated traversal, or release immediately if no longer active.
            retiringAtArm.commitCallbackRegistered = false;
            pendingCommitDisplayedImages.remove(retiringAtArm);
            armRetiringFrameCommitCallback(retiringAtArm);
            return;
          }
          retiringAtArm.releaseOnce();
          pendingCommitDisplayedImages.remove(retiringAtArm);
          if (this.retiringDisplayedImage == retiringAtArm) {
            this.retiringDisplayedImage = null;
          }
        };
    if (!registerFrameCommitCallback(releaseRetiringCallback)) {
      retiringAtArm.commitCallbackRegistered = false;
      pendingCommitDisplayedImages.remove(retiringAtArm);
      retiringAtArm.releaseOnce();
      if (this.retiringDisplayedImage == retiringAtArm) {
        this.retiringDisplayedImage = null;
      }
    }
  }

  @Override
  protected void onDraw(Canvas canvas) {
    super.onDraw(canvas);
    if (currentDisplayedImage != null) {
      if (!currentDisplayedImageDrawn) {
        updateBitmapFromImage(currentDisplayedImage.image);
        currentDisplayedImageDrawn = true;
      }
      if (retiringDisplayedImage != null) {
        retiringDisplayedImage.supersededByDraw = true;
      }
      final boolean softwareWindowOnApi29Plus =
          android.os.Build.VERSION.SDK_INT >= API_LEVELS.API_29
              && isAttachedToWindow()
              && !isHardwareAccelerated();
      if (android.os.Build.VERSION.SDK_INT < API_LEVELS.API_29 || softwareWindowOnApi29Plus) {
        // Below API 29 or on a software-rendered window, convert/retain an ARGB_8888 software
        // Bitmap so neither retiringDisplayedImage nor currentDisplayedImage remains pinned.
        if (softwareWindowOnApi29Plus
            && currentBitmap != null
            && currentBitmap.getConfig() == Bitmap.Config.HARDWARE) {
          currentBitmap = currentBitmap.copy(Bitmap.Config.ARGB_8888, false);
        }
        releasePendingAndRetiringDisplayedImages();
        currentDisplayedImage.releaseOnce();
        currentDisplayedImage = null;
        currentDisplayedImageDrawn = false;
      }
    } else if (currentImage != null) {
      updateCurrentBitmap();
    }
    if (currentBitmap != null) {
      if (android.os.Build.VERSION.SDK_INT >= API_LEVELS.API_29
          && !canvas.isHardwareAccelerated()
          && currentBitmap.getConfig() == Bitmap.Config.HARDWARE) {
        final Bitmap softwareBitmap = currentBitmap.copy(Bitmap.Config.ARGB_8888, false);
        if (softwareBitmap != null) {
          canvas.drawBitmap(softwareBitmap, 0, 0, null);
        }
        return;
      }
      canvas.drawBitmap(currentBitmap, 0, 0, null);
    }
  }

  private void closeCurrentImage() {
    // Close and clear the current image if any.
    if (currentImage != null) {
      currentImage.close();
      currentImage = null;
    }
  }

  private void updateCurrentBitmap() {
    if (currentImage == null) {
      return;
    }
    updateBitmapFromImage(currentImage);
  }

  @RequiresApi(API_LEVELS.API_29)
  @VisibleForTesting
  @Nullable
  Bitmap wrapHardwareBuffer(@NonNull HardwareBuffer buffer) {
    return Bitmap.wrapHardwareBuffer(buffer, ColorSpace.get(ColorSpace.Named.SRGB));
  }

  private void updateBitmapFromImage(@NonNull Image image) {
    if (android.os.Build.VERSION.SDK_INT >= API_LEVELS.API_29) {
      currentBitmap = null;
      final HardwareBuffer buffer = image.getHardwareBuffer();
      if (buffer == null) {
        return;
      }
      try {
        currentBitmap = wrapHardwareBuffer(buffer);
      } finally {
        buffer.close();
      }
    } else {
      final Image.Plane[] imagePlanes = image.getPlanes();
      if (imagePlanes == null || imagePlanes.length != 1) {
        currentBitmap = null;
        return;
      }

      final Image.Plane imagePlane = imagePlanes[0];
      final int desiredWidth = imagePlane.getRowStride() / imagePlane.getPixelStride();
      final int desiredHeight = image.getHeight();

      if (currentBitmap == null
          || currentBitmap.getWidth() != desiredWidth
          || currentBitmap.getHeight() != desiredHeight) {
        currentBitmap =
            Bitmap.createBitmap(
                desiredWidth, desiredHeight, android.graphics.Bitmap.Config.ARGB_8888);
      }
      ByteBuffer buffer = imagePlane.getBuffer();
      buffer.rewind();
      currentBitmap.copyPixelsFromBuffer(buffer);
    }
  }

  @VisibleForTesting
  @Nullable
  Bitmap getCurrentBitmapForTest() {
    return currentBitmap;
  }

  @VisibleForTesting
  boolean hasCurrentDisplayedImageForTest() {
    return currentDisplayedImage != null;
  }

  @VisibleForTesting
  boolean hasRetiringDisplayedImageForTest() {
    return retiringDisplayedImage != null;
  }

  @Override
  protected void onSizeChanged(int width, int height, int oldWidth, int oldHeight) {
    if (imageReader == null) {
      return;
    }
    if (!isImageReaderClosed
        && width == imageReader.getWidth()
        && height == imageReader.getHeight()) {
      return;
    }
    // `SurfaceKind.overlay` isn't resized. Instead, the `FlutterImageView` instance
    // is destroyed. As a result, an instance with the new size is created by the surface
    // pool in the native side.
    if (isActiveBackgroundSurface()) {
      resizeIfNeeded(width, height);
    }
  }
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import android.annotation.TargetApi;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.ColorSpace;
import android.graphics.PixelFormat;
import android.hardware.HardwareBuffer;
import android.media.Image;
import android.media.Image.Plane;
import android.media.ImageReader;
import android.util.AttributeSet;
import android.view.Surface;
import android.view.View;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.renderer.RenderSurface;
import java.util.LinkedList;
import java.util.Queue;

/**
 * Paints a Flutter UI provided by an {@link android.media.ImageReader} onto a {@link
 * android.graphics.Canvas}.
 *
 * <p>A {@code FlutterImageView} is intended for situations where a developer needs to render a
 * Flutter UI, but also needs to render an interactive {@link
 * io.flutter.plugin.platform.PlatformView}.
 *
 * <p>This {@code View} takes an {@link android.media.ImageReader} that provides the Flutter UI in
 * an {@link android.media.Image} and renders it to the {@link android.graphics.Canvas} in {@code
 * onDraw}.
 */
@TargetApi(19)
public class FlutterImageView extends View implements RenderSurface {
  @NonNull private ImageReader imageReader;
  @Nullable private Queue<Image> imageQueue;
  @Nullable private Image currentImage;
  @Nullable private Bitmap currentBitmap;
  @Nullable private FlutterRenderer flutterRenderer;

  public enum SurfaceKind {
    /** Displays the background canvas. */
    background,

    /** Displays the overlay surface canvas. */
    overlay,
  }

  /** The kind of surface. */
  private SurfaceKind kind;

  /**
   * The number of images acquired from the current {@link android.media.ImageReader} that are
   * waiting to be painted. This counter is decreased after calling {@link
   * android.media.Image#close()}.
   */
  private int pendingImages = 0;

  /** Whether the view is attached to the Flutter render. */
  private boolean isAttachedToFlutterRenderer = false;

  /**
   * Constructs a {@code FlutterImageView} with an {@link android.media.ImageReader} that provides
   * the Flutter UI.
   */
  public FlutterImageView(@NonNull Context context, int width, int height, SurfaceKind kind) {
    this(context, createImageReader(width, height), kind);
  }

  public FlutterImageView(@NonNull Context context) {
    this(context, 1, 1, SurfaceKind.background);
  }

  public FlutterImageView(@NonNull Context context, @NonNull AttributeSet attrs) {
    this(context, 1, 1, SurfaceKind.background);
  }

  @VisibleForTesting
  /*package*/ FlutterImageView(
      @NonNull Context context, @NonNull ImageReader imageReader, SurfaceKind kind) {
    super(context, null);
    this.imageReader = imageReader;
    this.kind = kind;
    this.imageQueue = new LinkedList<>();
    init();
  }

  private void init() {
    setAlpha(0.0f);
  }

  @TargetApi(19)
  @NonNull
  private static ImageReader createImageReader(int width, int height) {
    if (android.os.Build.VERSION.SDK_INT >= 29) {
      return ImageReader.newInstance(
          width,
          height,
          PixelFormat.RGBA_8888,
          3,
          HardwareBuffer.USAGE_GPU_SAMPLED_IMAGE | HardwareBuffer.USAGE_GPU_COLOR_OUTPUT);
    } else {
      return ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 3);
    }
  }

  @NonNull
  public Surface getSurface() {
    return imageReader.getSurface();
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
    if (isAttachedToFlutterRenderer) {
      return;
    }
    switch (kind) {
      case background:
        flutterRenderer.swapSurface(imageReader.getSurface());
        break;
      case overlay:
        // Do nothing since the attachment is done by the handler of
        // `FlutterJNI#createOverlaySurface()` in the native side.
        break;
    }
    setAlpha(1.0f);
    this.flutterRenderer = flutterRenderer;
    isAttachedToFlutterRenderer = true;
  }

  /**
   * Invoked by the owner of this {@code FlutterImageView} when it no longer wants to render a
   * Flutter UI to this {@code FlutterImageView}.
   */
  public void detachFromRenderer() {
    if (!isAttachedToFlutterRenderer) {
      return;
    }
    setAlpha(0.0f);
    // Drop the lastest image as it shouldn't render this image if this view is
    // attached to the renderer again.
    acquireLatestImage();
    // Clear drawings.
    currentBitmap = null;

    // Close the images in the queue and clear the queue.
    for (final Image image : imageQueue) {
      image.close();
    }
    imageQueue.clear();
    // Close and clear the current image if any.
    if (currentImage != null) {
      currentImage.close();
      currentImage = null;
    }
    invalidate();
    isAttachedToFlutterRenderer = false;
  }

  public void pause() {
    // Not supported.
  }

  /**
   * Acquires the next image to be drawn to the {@link android.graphics.Canvas}. Returns true if
   * there's an image available in the queue.
   */
  @TargetApi(19)
  public boolean acquireLatestImage() {
    if (!isAttachedToFlutterRenderer) {
      return false;
    }
    // There's no guarantee that the image will be closed before the next call to
    // `acquireLatestImage()`. For example, the device may not produce new frames if
    // it's in sleep mode, so the calls to `invalidate()` will be queued up
    // until the device produces a new frame.
    //
    // While the engine will also stop producing frames, there is a race condition.
    //
    // To avoid exceptions, check if a new image can be acquired.
    int imageOpenedCount = imageQueue.size();
    if (currentImage != null) {
      imageOpenedCount++;
    }
    if (imageOpenedCount < imageReader.getMaxImages()) {
      final Image image = imageReader.acquireLatestImage();
      if (image != null) {
        imageQueue.add(image);
      }
    }
    invalidate();
    return !imageQueue.isEmpty();
  }

  /** Creates a new image reader with the provided size. */
  public void resizeIfNeeded(int width, int height) {
    if (flutterRenderer == null) {
      return;
    }
    if (width == imageReader.getWidth() && height == imageReader.getHeight()) {
      return;
    }
    imageQueue.clear();
    currentImage = null;
    // Close all the resources associated with the image reader,
    // including the images.
    imageReader.close();
    // Image readers cannot be resized once created.
    imageReader = createImageReader(width, height);
    pendingImages = 0;
  }

  @Override
  protected void onDraw(Canvas canvas) {
    super.onDraw(canvas);

    if (!imageQueue.isEmpty()) {
      if (currentImage != null) {
        currentImage.close();
      }
      currentImage = imageQueue.poll();
      updateCurrentBitmap();
    }
    if (currentBitmap != null) {
      canvas.drawBitmap(currentBitmap, 0, 0, null);
    }
  }

  @TargetApi(29)
  private void updateCurrentBitmap() {
    if (android.os.Build.VERSION.SDK_INT >= 29) {
      final HardwareBuffer buffer = currentImage.getHardwareBuffer();
      currentBitmap = Bitmap.wrapHardwareBuffer(buffer, ColorSpace.get(ColorSpace.Named.SRGB));
      buffer.close();
    } else {
      final Plane[] imagePlanes = currentImage.getPlanes();
      if (imagePlanes.length != 1) {
        return;
      }

      final Plane imagePlane = imagePlanes[0];
      final int desiredWidth = imagePlane.getRowStride() / imagePlane.getPixelStride();
      final int desiredHeight = currentImage.getHeight();

      if (currentBitmap == null
          || currentBitmap.getWidth() != desiredWidth
          || currentBitmap.getHeight() != desiredHeight) {
        currentBitmap =
            Bitmap.createBitmap(
                desiredWidth, desiredHeight, android.graphics.Bitmap.Config.ARGB_8888);
      }
      currentBitmap.copyPixelsFromBuffer(imagePlane.getBuffer());
    }
  }

  @Override
  protected void onSizeChanged(int width, int height, int oldWidth, int oldHeight) {
    if (width == imageReader.getWidth() && height == imageReader.getHeight()) {
      return;
    }
    // `SurfaceKind.overlay` isn't resized. Instead, the `FlutterImageView` instance
    // is destroyed. As a result, an instance with the new size is created by the surface
    // pool in the native side.
    if (kind == SurfaceKind.background && isAttachedToFlutterRenderer) {
      resizeIfNeeded(width, height);
      // Bind native window to the new surface, and create a new onscreen surface
      // with the new size in the native side.
      flutterRenderer.swapSurface(imageReader.getSurface());
    }
  }
}

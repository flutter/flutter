// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.ColorSpace;
import android.hardware.HardwareBuffer;
import android.media.Image;
import android.media.Image.Plane;
import android.media.ImageReader;
import android.view.View;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.renderer.RenderSurface;

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
@SuppressLint("ViewConstructor")
@TargetApi(19)
public class FlutterImageView extends View implements RenderSurface {
  private final ImageReader imageReader;
  @Nullable private Image nextImage;
  @Nullable private Image currentImage;
  @Nullable private Bitmap currentBitmap;
  @Nullable private FlutterRenderer flutterRenderer;

  /**
   * Constructs a {@code FlutterImageView} with an {@link android.media.ImageReader} that provides
   * the Flutter UI.
   */
  public FlutterImageView(@NonNull Context context, @NonNull ImageReader imageReader) {
    super(context, null);
    this.imageReader = imageReader;
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
    if (this.flutterRenderer != null) {
      this.flutterRenderer.stopRenderingToSurface();
    }

    this.flutterRenderer = flutterRenderer;
    flutterRenderer.startRenderingToSurface(imageReader.getSurface());
  }

  /**
   * Invoked by the owner of this {@code FlutterImageView} when it no longer wants to render a
   * Flutter UI to this {@code FlutterImageView}.
   */
  public void detachFromRenderer() {
    if (flutterRenderer != null) {
      flutterRenderer.stopRenderingToSurface();
      flutterRenderer = null;
    }
  }

  /** Acquires the next image to be drawn to the {@link android.graphics.Canvas}. */
  @TargetApi(19)
  public void acquireLatestImage() {
    nextImage = imageReader.acquireLatestImage();
    invalidate();
  }

  @Override
  protected void onDraw(Canvas canvas) {
    super.onDraw(canvas);
    if (nextImage != null) {
      if (currentImage != null) {
        currentImage.close();
      }
      currentImage = nextImage;
      nextImage = null;
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
}

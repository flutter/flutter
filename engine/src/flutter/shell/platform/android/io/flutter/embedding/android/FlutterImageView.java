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
public class FlutterImageView extends View {
  private final ImageReader imageReader;
  @Nullable private Image nextImage;
  @Nullable private Image currentImage;

  /**
   * Constructs a {@code FlutterImageView} with an {@link android.media.ImageReader} that provides
   * the Flutter UI.
   */
  public FlutterImageView(@NonNull Context context, @NonNull ImageReader imageReader) {
    super(context, null);
    this.imageReader = imageReader;
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
    if (nextImage == null) {
      return;
    }

    if (currentImage != null) {
      currentImage.close();
    }
    currentImage = nextImage;
    nextImage = null;

    if (android.os.Build.VERSION.SDK_INT >= 29) {
      drawImageBuffer(canvas);
      return;
    }

    drawImagePlane(canvas);
  }

  @TargetApi(29)
  private void drawImageBuffer(@NonNull Canvas canvas) {
    final HardwareBuffer buffer = currentImage.getHardwareBuffer();

    final Bitmap bitmap = Bitmap.wrapHardwareBuffer(buffer, ColorSpace.get(ColorSpace.Named.SRGB));
    canvas.drawBitmap(bitmap, 0, 0, null);
  }

  private void drawImagePlane(@NonNull Canvas canvas) {
    if (currentImage == null) {
      return;
    }

    final Plane[] imagePlanes = currentImage.getPlanes();
    if (imagePlanes.length != 1) {
      return;
    }

    final Plane imagePlane = imagePlanes[0];
    final int desiredWidth = imagePlane.getRowStride() / imagePlane.getPixelStride();
    final int desiredHeight = currentImage.getHeight();

    final Bitmap bitmap =
        android.graphics.Bitmap.createBitmap(
            desiredWidth, desiredHeight, android.graphics.Bitmap.Config.ARGB_8888);

    bitmap.copyPixelsFromBuffer(imagePlane.getBuffer());
    canvas.drawBitmap(bitmap, 0, 0, null);
  }
}

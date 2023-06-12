// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera;

import android.graphics.Rect;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.math.MathUtils;

public final class CameraZoom {
  public static final float DEFAULT_ZOOM_FACTOR = 1.0f;

  @NonNull private final Rect cropRegion = new Rect();
  @Nullable private final Rect sensorSize;

  public final float maxZoom;
  public final boolean hasSupport;

  public CameraZoom(@Nullable final Rect sensorArraySize, final Float maxZoom) {
    this.sensorSize = sensorArraySize;

    if (this.sensorSize == null) {
      this.maxZoom = DEFAULT_ZOOM_FACTOR;
      this.hasSupport = false;
      return;
    }

    this.maxZoom =
        ((maxZoom == null) || (maxZoom < DEFAULT_ZOOM_FACTOR)) ? DEFAULT_ZOOM_FACTOR : maxZoom;

    this.hasSupport = (Float.compare(this.maxZoom, DEFAULT_ZOOM_FACTOR) > 0);
  }

  public Rect computeZoom(final float zoom) {
    if (sensorSize == null || !this.hasSupport) {
      return null;
    }

    final float newZoom = MathUtils.clamp(zoom, DEFAULT_ZOOM_FACTOR, this.maxZoom);

    final int centerX = this.sensorSize.width() / 2;
    final int centerY = this.sensorSize.height() / 2;
    final int deltaX = (int) ((0.5f * this.sensorSize.width()) / newZoom);
    final int deltaY = (int) ((0.5f * this.sensorSize.height()) / newZoom);

    this.cropRegion.set(centerX - deltaX, centerY - deltaY, centerX + deltaX, centerY + deltaY);

    return cropRegion;
  }
}

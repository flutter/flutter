// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.renderer;

import android.graphics.SurfaceTexture;
import androidx.annotation.Keep;
import androidx.annotation.NonNull;

/**
 * A wrapper for a SurfaceTexture that tracks whether the texture has been released.
 *
 * <p>The engine calls {@code SurfaceTexture.release} on the platform thread, but {@code
 * updateTexImage} is called on the raster thread. This wrapper will prevent {@code updateTexImage}
 * calls on an abandoned texture.
 */
@Keep
public class SurfaceTextureWrapper {
  private SurfaceTexture surfaceTexture;
  private boolean released;

  public SurfaceTextureWrapper(@NonNull SurfaceTexture surfaceTexture) {
    this.surfaceTexture = surfaceTexture;
    this.released = false;
  }

  @NonNull
  public SurfaceTexture surfaceTexture() {
    return surfaceTexture;
  }

  // Called by native.
  @SuppressWarnings("unused")
  public void updateTexImage() {
    synchronized (this) {
      if (!released) {
        surfaceTexture.updateTexImage();
      }
    }
  }

  public void release() {
    synchronized (this) {
      if (!released) {
        surfaceTexture.release();
        released = true;
      }
    }
  }

  // Called by native.
  @SuppressWarnings("unused")
  public void attachToGLContext(int texName) {
    surfaceTexture.attachToGLContext(texName);
  }

  // Called by native.
  @SuppressWarnings("unused")
  public void detachFromGLContext() {
    surfaceTexture.detachFromGLContext();
  }

  // Called by native.
  @SuppressWarnings("unused")
  public void getTransformMatrix(float[] mtx) {
    surfaceTexture.getTransformMatrix(mtx);
  }
}

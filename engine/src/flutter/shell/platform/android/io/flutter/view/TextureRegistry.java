// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.graphics.SurfaceTexture;
import android.media.Image;
import androidx.annotation.Keep;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

// TODO(mattcarroll): re-evalute docs in this class and add nullability annotations.
/**
 * Registry of backend textures used with a single {@link FlutterView} instance. Entries may be
 * embedded into the Flutter view using the <a
 * href="https://api.flutter.dev/flutter/widgets/Texture-class.html">Texture</a> widget.
 */
public interface TextureRegistry {
  /**
   * Creates and registers a SurfaceTexture managed by the Flutter engine.
   *
   * @return A SurfaceTextureEntry.
   */
  @NonNull
  SurfaceTextureEntry createSurfaceTexture();

  /**
   * Registers a SurfaceTexture managed by the Flutter engine.
   *
   * @return A SurfaceTextureEntry.
   */
  @NonNull
  SurfaceTextureEntry registerSurfaceTexture(@NonNull SurfaceTexture surfaceTexture);

  /**
   * Creates and registers a texture managed by the Flutter engine.
   *
   * @return a ImageTextureEntry.
   */
  @NonNull
  ImageTextureEntry createImageTexture();

  /**
   * Callback invoked when memory is low.
   *
   * <p>Invoke this from {@link android.app.Activity#onTrimMemory(int)}.
   */
  default void onTrimMemory(int level) {}

  /** An entry in the texture registry. */
  interface TextureEntry {
    /** @return The identity of this texture. */
    long id();

    /** Deregisters and releases all resources . */
    void release();
  }

  /** A registry entry for a managed SurfaceTexture. */
  interface SurfaceTextureEntry extends TextureEntry {
    /** @return The identity of this texture. */
    long id();

    /** Deregisters and releases all resources . */
    void release();

    /** @return The managed SurfaceTexture. */
    @NonNull
    SurfaceTexture surfaceTexture();

    /** Set a listener that will be notified when the most recent image has been consumed. */
    default void setOnFrameConsumedListener(@Nullable OnFrameConsumedListener listener) {}

    /** Set a listener that will be notified when a memory pressure warning was forward. */
    default void setOnTrimMemoryListener(@Nullable OnTrimMemoryListener listener) {}
  }

  @Keep
  interface ImageTextureEntry extends TextureEntry {
    /** @return the identity of this ImageTextureEntry */
    long id();

    /** Deregisters and releases all resources. */
    void release();

    /**
     * Next paint will update texture to use the contents of image.
     *
     * <p>NOTE: Caller should not call Image.close() on the pushed image.
     *
     * <p>NOTE: In the case that multiple calls to PushFrame occur before the next paint only the
     * last frame pushed will be used (dropping the missed frames).
     */
    void pushImage(Image image);

    /**
     * Retrieve the last Image pushed.
     *
     * <p>NOTE: Caller must call Image.close() on returned image.
     *
     * @return Image or null.
     */
    Image acquireLatestImage();
  }

  /** Listener invoked when the most recent image has been consumed. */
  interface OnFrameConsumedListener {
    /**
     * This method will to be invoked when the most recent image from the image stream has been
     * consumed.
     */
    void onFrameConsumed();
  }

  /** Listener invoked when a memory pressure warning was forward. */
  interface OnTrimMemoryListener {
    /** This method will be invoked when a memory pressure warning was forward. */
    void onTrimMemory(int level);
  }
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.graphics.SurfaceTexture;

// TODO(mattcarroll): re-evalute docs in this class and add nullability annotations.
/**
 * Registry of backend textures used with a single {@link FlutterView} instance.
 * Entries may be embedded into the Flutter view using the
 * <a href="https://docs.flutter.io/flutter/widgets/Texture-class.html">Texture</a>
 * widget.
 */
public interface TextureRegistry {
   /**
    * Creates and registers a SurfaceTexture managed by the Flutter engine.
    *
    * @return A SurfaceTextureEntry.
    */
    SurfaceTextureEntry createSurfaceTexture();

    /**
     * A registry entry for a managed SurfaceTexture.
     */
    interface SurfaceTextureEntry {
        /**
         * @return The managed SurfaceTexture.
         */
        SurfaceTexture surfaceTexture();

        /**
         * @return The identity of this SurfaceTexture.
         */
        long id();

        /**
         * Deregisters and releases this SurfaceTexture.
         */
        void release();
    }
}

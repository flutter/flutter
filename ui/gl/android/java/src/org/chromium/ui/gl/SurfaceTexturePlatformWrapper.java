// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui.gl;

import android.graphics.SurfaceTexture;
import android.os.Build;
import android.util.Log;

import org.chromium.base.CalledByNative;
import org.chromium.base.JNINamespace;

/**
 * Wrapper class for the underlying platform's SurfaceTexture in order to
 * provide a stable JNI API.
 */
@JNINamespace("gfx")
class SurfaceTexturePlatformWrapper {

    private static final String TAG = "SurfaceTexturePlatformWrapper";

    @CalledByNative
    private static SurfaceTexture create(int textureId) {
        return new SurfaceTexture(textureId);
    }

    @CalledByNative
    private static SurfaceTexture createSingleBuffered(int textureId) {
        assert Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT;
        return new SurfaceTexture(textureId, true);
    }

    @CalledByNative
    private static void destroy(SurfaceTexture surfaceTexture) {
        surfaceTexture.setOnFrameAvailableListener(null);
        surfaceTexture.release();
    }

    @CalledByNative
    private static void setFrameAvailableCallback(SurfaceTexture surfaceTexture,
            long nativeSurfaceTextureListener) {
        surfaceTexture.setOnFrameAvailableListener(
                new SurfaceTextureListener(nativeSurfaceTextureListener));
    }

    @CalledByNative
    private static void updateTexImage(SurfaceTexture surfaceTexture) {
        try {
            surfaceTexture.updateTexImage();
        } catch (RuntimeException e) {
            Log.e(TAG, "Error calling updateTexImage", e);
        }
    }

    @CalledByNative
    private static void releaseTexImage(SurfaceTexture surfaceTexture) {
        assert Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT;
        surfaceTexture.releaseTexImage();
    }

    @CalledByNative
    private static void getTransformMatrix(SurfaceTexture surfaceTexture, float[] matrix) {
        surfaceTexture.getTransformMatrix(matrix);
    }

    @CalledByNative
    private static void attachToGLContext(SurfaceTexture surfaceTexture, int texName) {
        assert Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN;
        surfaceTexture.attachToGLContext(texName);
    }

    @CalledByNative
    private static void detachFromGLContext(SurfaceTexture surfaceTexture) {
        assert Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN;
        surfaceTexture.detachFromGLContext();
    }
}

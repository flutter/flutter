// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui.gl;

import android.graphics.SurfaceTexture;

import org.chromium.base.JNINamespace;

/**
 * Listener to an android SurfaceTexture object for frame availability.
 */
@JNINamespace("gfx")
class SurfaceTextureListener implements SurfaceTexture.OnFrameAvailableListener {
    // Used to determine the class instance to dispatch the native call to.
    private final long mNativeSurfaceTextureListener;

    SurfaceTextureListener(long nativeSurfaceTextureListener) {
        assert nativeSurfaceTextureListener != 0;
        mNativeSurfaceTextureListener = nativeSurfaceTextureListener;
    }

    @Override
    public void onFrameAvailable(SurfaceTexture surfaceTexture) {
        nativeFrameAvailable(mNativeSurfaceTextureListener);
    }

    @Override
    protected void finalize() throws Throwable {
        try {
            nativeDestroy(mNativeSurfaceTextureListener);
        } finally {
            super.finalize();
        }
    }

    private native void nativeFrameAvailable(long nativeSurfaceTextureListener);
    private native void nativeDestroy(long nativeSurfaceTextureListener);
}

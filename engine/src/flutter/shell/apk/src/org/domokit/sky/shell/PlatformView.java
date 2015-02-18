// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.content.Context;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;

import org.chromium.base.JNINamespace;

/**
 * A view containing Sky
 */
@JNINamespace("sky::shell")
public class PlatformView extends SurfaceView {
    private long mNativePlatformView;
    private final SurfaceHolder.Callback mSurfaceCallback;

    public PlatformView(Context context) {
        super(context);

        setFocusable(true);
        setFocusableInTouchMode(true);

        mNativePlatformView = nativeAttach();
        assert mNativePlatformView != 0;

        final float density = context.getResources().getDisplayMetrics().density;

        mSurfaceCallback = new SurfaceHolder.Callback() {
            @Override
            public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
                assert mNativePlatformView != 0;
                nativeSurfaceSetSize(mNativePlatformView, width, height, density);
            }

            @Override
            public void surfaceCreated(SurfaceHolder holder) {
                assert mNativePlatformView != 0;
                nativeSurfaceCreated(mNativePlatformView, holder.getSurface());
            }

            @Override
            public void surfaceDestroyed(SurfaceHolder holder) {
                assert mNativePlatformView != 0;
                nativeSurfaceDestroyed(mNativePlatformView);
            }
        };
        getHolder().addCallback(mSurfaceCallback);
    }

    @Override
    protected void onDetachedFromWindow() {
        getHolder().removeCallback(mSurfaceCallback);
        nativeDetach(mNativePlatformView);
        mNativePlatformView = 0;
    }

    @Override
    protected void onWindowVisibilityChanged(int visibility) {
        super.onWindowVisibilityChanged(visibility);
        if (visibility == View.VISIBLE) {
            requestFocusFromTouch();
            requestFocus();
        }
    }

    private static native long nativeAttach();
    private static native void nativeDetach(long nativePlatformView);
    private static native void nativeSurfaceCreated(long nativePlatformView, Surface surface);
    private static native void nativeSurfaceDestroyed(long nativePlatformView);
    private static native void nativeSurfaceSetSize(
            long nativePlatformView, int width, int height, float density);
}

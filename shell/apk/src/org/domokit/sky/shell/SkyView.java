// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.app.Activity;
import android.content.Context;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;

import org.chromium.base.CalledByNative;
import org.chromium.base.JNINamespace;

/**
 * A view containing Sky
 */
@JNINamespace("sky::shell")
public class SkyView extends SurfaceView {
    private long mNativeSkyView;
    private final SurfaceHolder.Callback mSurfaceCallback;

    @SuppressWarnings("unused")
    @CalledByNative
    public static void createForActivity(Activity activity, long nativeSkyView) {
        activity.setContentView(new SkyView(activity, nativeSkyView));
    }

    public SkyView(Context context, long nativeSkyView) {
        super(context);

        setFocusable(true);
        setFocusableInTouchMode(true);

        mNativeSkyView = nativeSkyView;
        assert mNativeSkyView != 0;

        final float density = context.getResources().getDisplayMetrics().density;

        mSurfaceCallback = new SurfaceHolder.Callback() {
            @Override
            public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
                assert mNativeSkyView != 0;
                nativeSurfaceSetSize(mNativeSkyView, width, height, density);
            }

            @Override
            public void surfaceCreated(SurfaceHolder holder) {
                assert mNativeSkyView != 0;
                nativeSurfaceCreated(mNativeSkyView, holder.getSurface());
            }

            @Override
            public void surfaceDestroyed(SurfaceHolder holder) {
                assert mNativeSkyView != 0;
                nativeSurfaceDestroyed(mNativeSkyView);
            }
        };
        getHolder().addCallback(mSurfaceCallback);
    }

    public void destroy() {
        getHolder().removeCallback(mSurfaceCallback);
        nativeDestroy(mNativeSkyView);
        mNativeSkyView = 0;
    }

    @Override
    protected void onWindowVisibilityChanged(int visibility) {
        super.onWindowVisibilityChanged(visibility);
        if (visibility == View.VISIBLE) {
            requestFocusFromTouch();
            requestFocus();
        }
    }

    private static native void nativeDestroy(long nativeSkyView);
    private static native void nativeSurfaceCreated(long nativeSkyView, Surface surface);
    private static native void nativeSurfaceDestroyed(long nativeSkyView);
    private static native void nativeSurfaceSetSize(
            long nativeSkyView, int width, int height, float density);
}

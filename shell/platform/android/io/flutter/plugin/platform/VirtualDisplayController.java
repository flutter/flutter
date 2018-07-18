// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import android.annotation.TargetApi;
import android.content.Context;
import android.graphics.SurfaceTexture;
import android.hardware.display.DisplayManager;
import android.hardware.display.VirtualDisplay;
import android.os.Build;
import android.view.Surface;
import android.view.View;

@TargetApi(Build.VERSION_CODES.KITKAT_WATCH)
class VirtualDisplayController {

    public static VirtualDisplayController create(
            Context context,
            PlatformViewFactory viewFactory,
            SurfaceTexture surfaceTexture,
            int width,
            int height,
            int viewId
    ) {
        surfaceTexture.setDefaultBufferSize(width, height);
        Surface surface = new Surface(surfaceTexture);
        DisplayManager displayManager = (DisplayManager) context.getSystemService(Context.DISPLAY_SERVICE);

        int densityDpi = context.getResources().getDisplayMetrics().densityDpi;
        VirtualDisplay virtualDisplay = displayManager.createVirtualDisplay(
                "flutter-vd",
                width,
                height,
                densityDpi,
                surface,
                0
        );

        if (virtualDisplay == null) {
            return null;
        }

        return new VirtualDisplayController(context, virtualDisplay, viewFactory, surface, surfaceTexture, viewId);
    }

    private final Context mContext;
    private final int mDensityDpi;
    private final SurfaceTexture mSurfaceTexture;
    private VirtualDisplay mVirtualDisplay;
    private SingleViewPresentation mPresentation;
    private Surface mSurface;


    private VirtualDisplayController(
            Context context,
            VirtualDisplay virtualDisplay,
            PlatformViewFactory viewFactory,
            Surface surface,
            SurfaceTexture surfaceTexture,
            int viewId
    ) {
        mSurfaceTexture = surfaceTexture;
        mSurface = surface;
        mContext = context;
        mVirtualDisplay = virtualDisplay;
        mDensityDpi = context.getResources().getDisplayMetrics().densityDpi;
        mPresentation = new SingleViewPresentation(context, mVirtualDisplay.getDisplay(), viewFactory, viewId);
        mPresentation.show();
    }

    public void resize(int width, int height) {
        PlatformView view = mPresentation.detachView();
        mPresentation.hide();
        // We detach the surface to prevent it being destroyed when releasing the vd.
        //
        // setSurface is only available starting API 20. We could support API 19 by re-creating a new
        // SurfaceTexture here. This will require refactoring the TextureRegistry to allow recycling texture
        // entry IDs.
        mVirtualDisplay.setSurface(null);
        mVirtualDisplay.release();

        mSurfaceTexture.setDefaultBufferSize(width, height);
        DisplayManager displayManager = (DisplayManager) mContext.getSystemService(Context.DISPLAY_SERVICE);
        mVirtualDisplay = displayManager.createVirtualDisplay(
                "flutter-vd",
                width,
                height,
                mDensityDpi,
                mSurface,
                0
        );
        mPresentation = new SingleViewPresentation(mContext, mVirtualDisplay.getDisplay(), view);
        mPresentation.show();
    }

    public void dispose() {
        mPresentation.detachView().dispose();
        mVirtualDisplay.release();
    }

    public View getView() {
        if (mPresentation == null)
            return null;
        return mPresentation.getView();
    }
}

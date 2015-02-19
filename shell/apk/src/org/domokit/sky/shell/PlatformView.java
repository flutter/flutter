// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.content.Context;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;

import org.chromium.base.JNINamespace;
import org.chromium.mojo.bindings.InterfaceRequest;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.Pair;
import org.chromium.mojo.system.impl.CoreImpl;
import org.chromium.mojom.sky.EventType;
import org.chromium.mojom.sky.InputEvent;
import org.chromium.mojom.sky.PointerData;
import org.chromium.mojom.sky.PointerKind;
import org.chromium.mojom.sky.ViewportObserver;

/**
 * A view containing Sky
 */
@JNINamespace("sky::shell")
public class PlatformView extends SurfaceView {
    private long mNativePlatformView;
    private ViewportObserver.Proxy mViewportObserver;
    private final SurfaceHolder.Callback mSurfaceCallback;

    public PlatformView(Context context) {
        super(context);

        setFocusable(true);
        setFocusableInTouchMode(true);

        attach();
        assert mNativePlatformView != 0;

        final float density = context.getResources().getDisplayMetrics().density;

        mSurfaceCallback = new SurfaceHolder.Callback() {
            @Override
            public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
                assert mViewportObserver != null;
                mViewportObserver.onViewportMetricsChanged(width, height, density);
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

    private int getTypeForAction(int maskedAction) {
        if (maskedAction == MotionEvent.ACTION_DOWN)
            return EventType.POINTER_DOWN;
        if (maskedAction == MotionEvent.ACTION_UP)
            return EventType.POINTER_UP;
        if (maskedAction == MotionEvent.ACTION_MOVE)
            return EventType.POINTER_MOVE;
        if (maskedAction == MotionEvent.ACTION_CANCEL)
            return EventType.POINTER_CANCEL;
        return EventType.UNKNOWN;
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        PointerData pointerData = new PointerData();
        pointerData.pointer = event.getPointerId(0);
        pointerData.kind = PointerKind.TOUCH;
        pointerData.x = event.getX();
        pointerData.y = event.getY();

        InputEvent inputEvent = new InputEvent();
        inputEvent.type = getTypeForAction(event.getActionMasked());
        inputEvent.timeStamp = event.getEventTime();
        inputEvent.pointerData = pointerData;

        mViewportObserver.onInputEvent(inputEvent);
        return true;
    }

    private void attach() {
        Core core = CoreImpl.getInstance();
        Pair<ViewportObserver.Proxy, InterfaceRequest<ViewportObserver>> result =
                ViewportObserver.MANAGER.getInterfaceRequest(core);
        mViewportObserver = result.first;
        mNativePlatformView = nativeAttach(result.second.passHandle().releaseNativeHandle());
    }

    private static native long nativeAttach(int inputObserverHandle);
    private static native void nativeDetach(long nativePlatformView);
    private static native void nativeSurfaceCreated(long nativePlatformView, Surface surface);
    private static native void nativeSurfaceDestroyed(long nativePlatformView);
}

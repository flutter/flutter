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
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;

import org.chromium.base.JNINamespace;
import org.chromium.mojo.bindings.InterfaceRequest;
import org.chromium.mojo.keyboard.KeyboardServiceImpl;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.Pair;
import org.chromium.mojo.system.impl.CoreImpl;
import org.chromium.mojom.sky.EventType;
import org.chromium.mojom.sky.InputEvent;
import org.chromium.mojom.sky.PointerData;
import org.chromium.mojom.sky.PointerKind;
import org.chromium.mojom.sky.SkyEngine;
import org.chromium.mojom.sky.ViewportMetrics;

/**
 * A view containing Sky
 */
@JNINamespace("sky::shell")
public class PlatformViewAndroid extends SurfaceView
        implements GestureProvider.OnGestureListener {
    private static final String TAG = "PlatformViewAndroid";

    private long mNativePlatformView;
    private SkyEngine.Proxy mSkyEngine;
    private final SurfaceHolder.Callback mSurfaceCallback;
    private GestureProvider mGestureProvider;
    private final EdgeDims mPadding;

    /**
     * Dimensions in each of the four cardinal directions.
     */
    public static class EdgeDims {
        public double top = 0.0;
        public double right = 0.0;
        public double bottom = 0.0;
        public double left = 0.0;
    }

    public PlatformViewAndroid(Context context, EdgeDims padding) {
        super(context);
        mPadding = padding;

        setFocusable(true);
        setFocusableInTouchMode(true);

        attach();
        assert mNativePlatformView != 0;

        final float density = context.getResources().getDisplayMetrics().density;

        mSurfaceCallback = new SurfaceHolder.Callback() {
            @Override
            public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
                assert mSkyEngine != null;
                ViewportMetrics metrics = new ViewportMetrics();
                metrics.physicalWidth = width;
                metrics.physicalHeight = height;
                metrics.devicePixelRatio = density;
                if (mPadding != null) {
                    metrics.paddingTop = mPadding.top;
                    metrics.paddingRight = mPadding.right;
                    metrics.paddingBottom = mPadding.bottom;
                    metrics.paddingLeft = mPadding.left;
                }
                mSkyEngine.onViewportMetricsChanged(metrics);
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

        mGestureProvider = new GestureProvider(context, this);
        KeyboardServiceImpl.setActiveView(this);
    }

    SkyEngine getEngine() {
        return mSkyEngine;
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

    @Override
    public boolean onCheckIsTextEditor() {
        return true;
    }

    @Override
    public InputConnection onCreateInputConnection(EditorInfo outAttrs) {
        return KeyboardServiceImpl.createInputConnection(outAttrs);
    }

    private int getTypeForAction(int maskedAction) {
        // Primary pointer:
        if (maskedAction == MotionEvent.ACTION_DOWN) {
            return EventType.POINTER_DOWN;
        }
        if (maskedAction == MotionEvent.ACTION_UP) {
            return EventType.POINTER_UP;
        }
        // Secondary pointer:
        if (maskedAction == MotionEvent.ACTION_POINTER_DOWN) {
            return EventType.POINTER_DOWN;
        }
        if (maskedAction == MotionEvent.ACTION_POINTER_UP) {
            return EventType.POINTER_UP;
        }
        // All pointers:
        if (maskedAction == MotionEvent.ACTION_MOVE) {
            return EventType.POINTER_MOVE;
        }
        if (maskedAction == MotionEvent.ACTION_CANCEL) {
            return EventType.POINTER_CANCEL;
        }
        return EventType.UNKNOWN;
    }

    private void sendInputEventForIndex(MotionEvent event, int pointerIndex) {
        PointerData pointerData = new PointerData();
        pointerData.pointer = event.getPointerId(pointerIndex);
        pointerData.kind = PointerKind.TOUCH;
        pointerData.x = event.getX(pointerIndex);
        pointerData.y = event.getY(pointerIndex);

        pointerData.pressure = event.getPressure(pointerIndex);
        // TODO(eseidel): Could get the calibrated range if necessary:
        // event.getDevice().getMotionRange(MotionEvent.AXIS_PRESSURE)
        pointerData.pressureMin = 0.0f;
        pointerData.pressureMax = 1.0f;

        InputEvent inputEvent = new InputEvent();
        inputEvent.type = getTypeForAction(event.getActionMasked());
        inputEvent.timeStamp = event.getEventTime();
        inputEvent.pointerData = pointerData;



        mSkyEngine.onInputEvent(inputEvent);
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        mGestureProvider.onTouchEvent(event);

        int maskedAction = event.getActionMasked();
        // ACTION_UP, ACTION_POINTER_UP, ACTION_DOWN, and ACTION_POINTER_DOWN
        // only apply to a single pointer, other events apply to all pointers.
        if (maskedAction == MotionEvent.ACTION_UP
                || maskedAction == MotionEvent.ACTION_POINTER_UP
                || maskedAction == MotionEvent.ACTION_DOWN
                || maskedAction == MotionEvent.ACTION_POINTER_DOWN) {
            sendInputEventForIndex(event, event.getActionIndex());
        } else {
            // ACTION_MOVE may not actually mean all pointers have moved
            // but it's the responsibility of a later part of the system to
            // ignore 0-deltas if desired.
            for (int p = 0; p < event.getPointerCount(); p++) {
                sendInputEventForIndex(event, p);
            }
        }
        return true;
    }

    @Override
    public void onGestureEvent(InputEvent event) {
        mSkyEngine.onInputEvent(event);
    }

    private void attach() {
        Core core = CoreImpl.getInstance();
        Pair<SkyEngine.Proxy, InterfaceRequest<SkyEngine>> result =
                SkyEngine.MANAGER.getInterfaceRequest(core);
        mSkyEngine = result.first;
        mNativePlatformView = nativeAttach(result.second.passHandle().releaseNativeHandle());
    }

    private static native long nativeAttach(int inputObserverHandle);
    private static native void nativeDetach(long nativePlatformViewAndroid);
    private static native void nativeSurfaceCreated(long nativePlatformViewAndroid,
                                                    Surface surface);
    private static native void nativeSurfaceDestroyed(long nativePlatformViewAndroid);
}

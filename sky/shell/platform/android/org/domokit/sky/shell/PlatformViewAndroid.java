// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.content.Context;
import android.os.Build;
import android.view.KeyEvent;
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
import org.chromium.mojo.keyboard.KeyboardServiceState;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojo.system.Pair;
import org.chromium.mojo.system.impl.CoreImpl;
import org.chromium.mojom.keyboard.KeyboardService;
import org.chromium.mojom.pointer.Pointer;
import org.chromium.mojom.pointer.PointerKind;
import org.chromium.mojom.pointer.PointerPacket;
import org.chromium.mojom.pointer.PointerType;
import org.chromium.mojom.raw_keyboard.RawKeyboardService;
import org.chromium.mojom.sky.SkyEngine;
import org.chromium.mojom.sky.ViewportMetrics;
import org.chromium.mojom.sky.ServicesData;
import org.chromium.mojom.mojo.ServiceProvider;

import java.util.ArrayList;
import java.util.List;

import org.domokit.raw_keyboard.RawKeyboardServiceImpl;
import org.domokit.raw_keyboard.RawKeyboardServiceState;

/**
 * A view containing Sky
 */
@JNINamespace("sky::shell")
public class PlatformViewAndroid extends SurfaceView {
    private static final String TAG = "PlatformViewAndroid";

    private long mNativePlatformView;
    private SkyEngine.Proxy mSkyEngine;
    private PlatformServiceProvider mServiceProvider;
    private final SurfaceHolder.Callback mSurfaceCallback;
    private final EdgeDims mPadding;
    private final KeyboardServiceState mKeyboardState;
    private final RawKeyboardServiceState mRawKeyboardState;

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

        mKeyboardState = new KeyboardServiceState(this);

        mRawKeyboardState = new RawKeyboardServiceState();
    }

    @Override
    public boolean onKeyUp(int keyCode, KeyEvent event) {
        if (mRawKeyboardState.onKey(this, keyCode, event))
            return true;
        return super.onKeyUp(keyCode, event);
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (mRawKeyboardState.onKey(this, keyCode, event))
            return true;
        return super.onKeyDown(keyCode, event);
    }

    SkyEngine getEngine() {
        return mSkyEngine;
    }

    void destroy() {
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
    public InputConnection onCreateInputConnection(EditorInfo outAttrs) {
        return mKeyboardState.createInputConnection(outAttrs);
    }

    private Integer getPointerTypeForAction(int maskedAction) {
        // Primary pointer:
        if (maskedAction == MotionEvent.ACTION_DOWN) {
            return PointerType.DOWN;
        }
        if (maskedAction == MotionEvent.ACTION_UP) {
            return PointerType.UP;
        }
        // Secondary pointer:
        if (maskedAction == MotionEvent.ACTION_POINTER_DOWN) {
            return PointerType.DOWN;
        }
        if (maskedAction == MotionEvent.ACTION_POINTER_UP) {
            return PointerType.UP;
        }
        // All pointers:
        if (maskedAction == MotionEvent.ACTION_MOVE) {
            return PointerType.MOVE;
        }
        if (maskedAction == MotionEvent.ACTION_CANCEL) {
            return PointerType.CANCEL;
        }
        return null;
    }

    private void addPointerForIndex(MotionEvent event, int pointerIndex,
                                    List<Pointer> result) {
        Integer pointerType = getPointerTypeForAction(event.getActionMasked());
        if (pointerType == null) {
            return;
        }

        Pointer pointer = new Pointer();

        pointer.timeStamp = event.getEventTime() * 1000; // Convert from milliseconds to microseconds.
        pointer.pointer = event.getPointerId(pointerIndex);
        pointer.type = pointerType;
        pointer.kind = PointerKind.TOUCH;
        pointer.x = event.getX(pointerIndex);
        pointer.y = event.getY(pointerIndex);

        pointer.buttons = 0;
        pointer.down = false;
        pointer.primary = false;
        pointer.obscured = false;

        // TODO(eseidel): Could get the calibrated range if necessary:
        // event.getDevice().getMotionRange(MotionEvent.AXIS_PRESSURE)
        pointer.pressure = event.getPressure(pointerIndex);
        pointer.pressureMin = 0.0f;
        pointer.pressureMax = 1.0f;

        pointer.distance = 0.0f;
        pointer.distanceMin = 0.0f;
        pointer.distanceMax = 0.0f;

        pointer.radiusMajor = 0.0f;
        pointer.radiusMinor = 0.0f;
        pointer.radiusMin = 0.0f;
        pointer.radiusMax = 0.0f;

        pointer.orientation = 0.0f;
        pointer.tilt = 0.0f;

        result.add(pointer);
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        // TODO(abarth): This version check might not be effective in some
        // versions of Android that statically compile code and will be upset
        // at the lack of |requestUnbufferedDispatch|. Instead, we should factor
        // version-dependent code into separate classes for each supported
        // version and dispatch dynamically.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            requestUnbufferedDispatch(event);
        }

        ArrayList<Pointer> pointers = new ArrayList<Pointer>();

        // TODO(abarth): Rather than unpacking these events here, we should
        // probably send them in one packet to the engine.
        int maskedAction = event.getActionMasked();
        // ACTION_UP, ACTION_POINTER_UP, ACTION_DOWN, and ACTION_POINTER_DOWN
        // only apply to a single pointer, other events apply to all pointers.
        if (maskedAction == MotionEvent.ACTION_UP
                || maskedAction == MotionEvent.ACTION_POINTER_UP
                || maskedAction == MotionEvent.ACTION_DOWN
                || maskedAction == MotionEvent.ACTION_POINTER_DOWN) {
            addPointerForIndex(event, event.getActionIndex(), pointers);
        } else {
            // ACTION_MOVE may not actually mean all pointers have moved
            // but it's the responsibility of a later part of the system to
            // ignore 0-deltas if desired.
            for (int p = 0; p < event.getPointerCount(); p++) {
                addPointerForIndex(event, p, pointers);
            }
        }

        PointerPacket packet = new PointerPacket();
        packet.pointers = pointers.toArray(new Pointer[0]);
        mSkyEngine.onPointerPacket(packet);

        return true;
    }

    private void configureLocalServices(ServiceRegistry registry) {
        registry.register(KeyboardService.MANAGER.getName(), new ServiceFactory() {
            @Override
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                KeyboardService.MANAGER.bind(new KeyboardServiceImpl(context, mKeyboardState), pipe);
            }
        });

        registry.register(RawKeyboardService.MANAGER.getName(), new ServiceFactory() {
            @Override
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                RawKeyboardService.MANAGER.bind(new RawKeyboardServiceImpl(mRawKeyboardState), pipe);
            }
        });
    }

    private void attach() {
        Core core = CoreImpl.getInstance();
        Pair<SkyEngine.Proxy, InterfaceRequest<SkyEngine>> engine =
                SkyEngine.MANAGER.getInterfaceRequest(core);
        mSkyEngine = engine.first;
        mNativePlatformView = nativeAttach(engine.second.passHandle().releaseNativeHandle());

        ServiceRegistry localRegistry = new ServiceRegistry();
        configureLocalServices(localRegistry);

        Pair<ServiceProvider.Proxy, InterfaceRequest<ServiceProvider>> serviceProvider =
                ServiceProvider.MANAGER.getInterfaceRequest(core);
        mServiceProvider = new PlatformServiceProvider(core, getContext(), localRegistry);
        ServiceProvider.MANAGER.bind(mServiceProvider, serviceProvider.second);

        ServicesData services = new ServicesData();
        services.servicesProvidedByEmbedder = serviceProvider.first;
        mSkyEngine.setServices(services);
    }

    private static native long nativeAttach(int inputObserverHandle);
    private static native void nativeDetach(long nativePlatformViewAndroid);
    private static native void nativeSurfaceCreated(long nativePlatformViewAndroid,
                                                    Surface surface);
    private static native void nativeSurfaceDestroyed(long nativePlatformViewAndroid);
}

// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.ApplicationInfo;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.Rect;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Matrix;
import android.os.Build;
import android.util.AttributeSet;
import android.util.Log;
import android.util.TypedValue;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.WindowInsets;
import android.view.accessibility.AccessibilityManager;
import android.view.accessibility.AccessibilityNodeProvider;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.*;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.editing.TextInputPlugin;
import io.flutter.plugin.platform.PlatformPlugin;

import org.json.JSONException;
import org.json.JSONObject;

import java.net.URI;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * An Android view containing a Flutter app.
 */
public class FlutterView extends SurfaceView
    implements BinaryMessenger, AccessibilityManager.AccessibilityStateChangeListener {

    /**
     * Interface for those objects that maintain and expose a reference to a
     * {@code FlutterView} (such as a full-screen Flutter activity).
     *
     * <p>This indirection is provided to support applications that use an
     * activity other than {@link io.flutter.app.FlutterActivity} (e.g. Android
     * v4 support library's {@code FragmentActivity}). It allows Flutter plugins
     * to deal in this interface and not require that the activity be a subclass
     * of {@code FlutterActivity}.</p>
     */
    public interface Provider {
        /**
         * Returns a reference to the Flutter view maintained by this object.
         * This may be {@code null}.
         */
        FlutterView getFlutterView();
    }

    private static final String TAG = "FlutterView";

    private static final String ACTION_DISCOVER = "io.flutter.view.DISCOVER";

    static final class ViewportMetrics {

        float devicePixelRatio = 1.0f;
        int physicalWidth = 0;
        int physicalHeight = 0;
        int physicalPaddingTop = 0;
        int physicalPaddingRight = 0;
        int physicalPaddingBottom = 0;
        int physicalPaddingLeft = 0;
    }

    private final TextInputPlugin mTextInputPlugin;
    private final Map<String, BinaryMessageHandler> mMessageHandlers;
    private final SurfaceHolder.Callback mSurfaceCallback;
    private final ViewportMetrics mMetrics;
    private final AccessibilityManager mAccessibilityManager;
    private final MethodChannel mFlutterLocalizationChannel;
    private final MethodChannel mFlutterNavigationChannel;
    private final BasicMessageChannel<Object> mFlutterKeyEventChannel;
    private final BasicMessageChannel<String> mFlutterLifecycleChannel;
    private final BasicMessageChannel<Object> mFlutterSystemChannel;
    private final BroadcastReceiver mDiscoveryReceiver;
    private final List<ActivityLifecycleListener> mActivityLifecycleListeners;
    private final List<FirstFrameListener> mFirstFrameListeners;
    private long mNativePlatformView;
    private boolean mIsSoftwareRenderingEnabled = false; // using the software renderer or not

    public FlutterView(Context context) {
        this(context, null);
    }

    public FlutterView(Context context, AttributeSet attrs) {
        super(context, attrs);

        mIsSoftwareRenderingEnabled = nativeGetIsSoftwareRenderingEnabled();

        mMetrics = new ViewportMetrics();
        mMetrics.devicePixelRatio = context.getResources().getDisplayMetrics().density;
        setFocusable(true);
        setFocusableInTouchMode(true);

        attach();
        assert mNativePlatformView != 0;

        int color = 0xFF000000;
        TypedValue typedValue = new TypedValue();
        context.getTheme().resolveAttribute(android.R.attr.colorBackground, typedValue, true);
        if (typedValue.type >= TypedValue.TYPE_FIRST_COLOR_INT
            && typedValue.type <= TypedValue.TYPE_LAST_COLOR_INT) {
            color = typedValue.data;
        }
        // TODO(abarth): Consider letting the developer override this color.
        final int backgroundColor = color;

        mSurfaceCallback = new SurfaceHolder.Callback() {
            @Override
            public void surfaceCreated(SurfaceHolder holder) {
                assert mNativePlatformView != 0;
                nativeSurfaceCreated(mNativePlatformView, holder.getSurface(), backgroundColor);
            }

            @Override
            public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
                assert mNativePlatformView != 0;
                nativeSurfaceChanged(mNativePlatformView, width, height);
            }

            @Override
            public void surfaceDestroyed(SurfaceHolder holder) {
                assert mNativePlatformView != 0;
                nativeSurfaceDestroyed(mNativePlatformView);
            }
        };
        getHolder().addCallback(mSurfaceCallback);

        mAccessibilityManager = (AccessibilityManager) getContext()
            .getSystemService(Context.ACCESSIBILITY_SERVICE);

        mMessageHandlers = new HashMap<>();
        mActivityLifecycleListeners = new ArrayList<>();
        mFirstFrameListeners = new ArrayList<>();

        // Configure the platform plugins and flutter channels.
        mFlutterLocalizationChannel = new MethodChannel(this, "flutter/localization",
            JSONMethodCodec.INSTANCE);
        mFlutterNavigationChannel = new MethodChannel(this, "flutter/navigation",
            JSONMethodCodec.INSTANCE);
        mFlutterKeyEventChannel = new BasicMessageChannel<>(this, "flutter/keyevent",
            JSONMessageCodec.INSTANCE);
        mFlutterLifecycleChannel = new BasicMessageChannel<>(this, "flutter/lifecycle",
            StringCodec.INSTANCE);
        mFlutterSystemChannel = new BasicMessageChannel<>(this, "flutter/system",
            JSONMessageCodec.INSTANCE);
        PlatformPlugin platformPlugin = new PlatformPlugin((Activity) getContext());
        MethodChannel flutterPlatformChannel = new MethodChannel(this,
            "flutter/platform", JSONMethodCodec.INSTANCE);
        flutterPlatformChannel.setMethodCallHandler(platformPlugin);
        addActivityLifecycleListener(platformPlugin);
        mTextInputPlugin = new TextInputPlugin(this);

        setLocale(getResources().getConfiguration().locale);

        if ((context.getApplicationInfo().flags & ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
            mDiscoveryReceiver = new DiscoveryReceiver();
            context.registerReceiver(mDiscoveryReceiver, new IntentFilter(ACTION_DISCOVER));
        } else {
            mDiscoveryReceiver = null;
        }
    }

    private void encodeKeyEvent(KeyEvent event, Map<String, Object> message) {
        message.put("flags", event.getFlags());
        message.put("codePoint", event.getUnicodeChar());
        message.put("keyCode", event.getKeyCode());
        message.put("scanCode", event.getScanCode());
        message.put("metaState", event.getMetaState());
    }

    @Override
    public boolean onKeyUp(int keyCode, KeyEvent event) {
        if (!isAttached()) {
            return super.onKeyUp(keyCode, event);
        }

        Map<String, Object> message = new HashMap<>();
        message.put("type", "keyup");
        message.put("keymap", "android");
        encodeKeyEvent(event, message);
        mFlutterKeyEventChannel.send(message);
        return super.onKeyUp(keyCode, event);
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (!isAttached()) {
            return super.onKeyDown(keyCode, event);
        }

        Map<String, Object> message = new HashMap<>();
        message.put("type", "keydown");
        message.put("keymap", "android");
        encodeKeyEvent(event, message);
        mFlutterKeyEventChannel.send(message);
        return super.onKeyDown(keyCode, event);
    }

    public void addActivityLifecycleListener(ActivityLifecycleListener listener) {
        mActivityLifecycleListeners.add(listener);
    }

    public void onPause() {
        mFlutterLifecycleChannel.send("AppLifecycleState.paused");
    }

    public void onPostResume() {
        for (ActivityLifecycleListener listener : mActivityLifecycleListeners) {
            listener.onPostResume();
        }
        mFlutterLifecycleChannel.send("AppLifecycleState.resumed");
    }

    public void onStop() {
        mFlutterLifecycleChannel.send("AppLifecycleState.suspending");
    }

    public void onMemoryPressure() {
        Map<String, Object> message = new HashMap<>(1);
        message.put("type", "memoryPressure");
        mFlutterSystemChannel.send(message);
    }

    /**
     * Provide a listener that will be called once when the FlutterView renders its first frame
     * to the underlaying SurfaceView.
     */
    public void addFirstFrameListener(FirstFrameListener listener) {
        mFirstFrameListeners.add(listener);
    }

    /**
     * Remove an existing first frame listener.
     */
    public void removeFirstFrameListener(FirstFrameListener listener) {
        mFirstFrameListeners.remove(listener);
    }

    public void setInitialRoute(String route) {
        mFlutterNavigationChannel.invokeMethod("setInitialRoute", route);
    }

    public void pushRoute(String route) {
        mFlutterNavigationChannel.invokeMethod("pushRoute", route);
    }

    public void popRoute() {
        mFlutterNavigationChannel.invokeMethod("popRoute", null);
    }

    private void setLocale(Locale locale) {
        mFlutterLocalizationChannel.invokeMethod("setLocale",
            Arrays.asList(locale.getLanguage(), locale.getCountry()));
    }

    @Override
    protected void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        setLocale(newConfig.locale);
    }

    float getDevicePixelRatio() {
        return mMetrics.devicePixelRatio;
    }

    public void destroy() {
        if (mDiscoveryReceiver != null) {
            getContext().unregisterReceiver(mDiscoveryReceiver);
        }

        getHolder().removeCallback(mSurfaceCallback);
        nativeDetach(mNativePlatformView);
        mNativePlatformView = 0;
    }

    @Override
    public InputConnection onCreateInputConnection(EditorInfo outAttrs) {
        try {
            return mTextInputPlugin.createInputConnection(this, outAttrs);
        } catch (JSONException e) {
            Log.e(TAG, "Failed to create input connection", e);
            return null;
        }
    }

    // Must match the PointerChange enum in pointer.dart.
    private static final int kPointerChangeCancel = 0;
    private static final int kPointerChangeAdd = 1;
    private static final int kPointerChangeRemove = 2;
    private static final int kPointerChangeHover = 3;
    private static final int kPointerChangeDown = 4;
    private static final int kPointerChangeMove = 5;
    private static final int kPointerChangeUp = 6;

    // Must match the PointerDeviceKind enum in pointer.dart.
    private static final int kPointerDeviceKindTouch = 0;
    private static final int kPointerDeviceKindMouse = 1;
    private static final int kPointerDeviceKindStylus = 2;
    private static final int kPointerDeviceKindInvertedStylus = 3;

    private int getPointerChangeForAction(int maskedAction) {
        // Primary pointer:
        if (maskedAction == MotionEvent.ACTION_DOWN) {
            return kPointerChangeDown;
        }
        if (maskedAction == MotionEvent.ACTION_UP) {
            return kPointerChangeUp;
        }
        // Secondary pointer:
        if (maskedAction == MotionEvent.ACTION_POINTER_DOWN) {
            return kPointerChangeDown;
        }
        if (maskedAction == MotionEvent.ACTION_POINTER_UP) {
            return kPointerChangeUp;
        }
        // All pointers:
        if (maskedAction == MotionEvent.ACTION_MOVE) {
            return kPointerChangeMove;
        }
        if (maskedAction == MotionEvent.ACTION_CANCEL) {
            return kPointerChangeCancel;
        }
        return -1;
    }

    private int getPointerDeviceTypeForToolType(int toolType) {
        switch (toolType) {
            case MotionEvent.TOOL_TYPE_FINGER:
                return kPointerDeviceKindTouch;
            case MotionEvent.TOOL_TYPE_STYLUS:
                return kPointerDeviceKindStylus;
            case MotionEvent.TOOL_TYPE_MOUSE:
                return kPointerDeviceKindMouse;
            default:
                // MotionEvent.TOOL_TYPE_UNKNOWN will reach here.
                return -1;
        }
    }

    private void addPointerForIndex(MotionEvent event, int pointerIndex,
        ByteBuffer packet) {
        int pointerChange = getPointerChangeForAction(event.getActionMasked());
        if (pointerChange == -1) {
            return;
        }

        int pointerKind = event.getToolType(pointerIndex);
        if (pointerKind == -1) {
            return;
        }

        long timeStamp = event.getEventTime() * 1000; // Convert from milliseconds to microseconds.

        packet.putLong(timeStamp); // time_stamp
        packet.putLong(pointerChange); // change
        packet.putLong(pointerKind); // kind
        packet.putLong(event.getPointerId(pointerIndex)); // device
        packet.putDouble(event.getX(pointerIndex)); // physical_x
        packet.putDouble(event.getY(pointerIndex)); // physical_y

        if (pointerKind == kPointerDeviceKindMouse) {
            packet.putLong(event.getButtonState() & 0x1F); // buttons
        } else if (pointerKind == kPointerDeviceKindStylus) {
            packet.putLong((event.getButtonState() >> 4) & 0xF); // buttons
        } else {
            packet.putLong(0); // buttons
        }

        packet.putLong(0); // obscured

        // TODO(eseidel): Could get the calibrated range if necessary:
        // event.getDevice().getMotionRange(MotionEvent.AXIS_PRESSURE)
        packet.putDouble(event.getPressure(pointerIndex)); // pressure
        packet.putDouble(0.0); // pressure_min
        packet.putDouble(1.0); // pressure_max

        if (pointerKind == kPointerDeviceKindStylus) {
            packet
                .putDouble(event.getAxisValue(MotionEvent.AXIS_DISTANCE, pointerIndex)); // distance
            packet.putDouble(0.0); // distance_max
        } else {
            packet.putDouble(0.0); // distance
            packet.putDouble(0.0); // distance_max
        }

        packet.putDouble(event.getToolMajor(pointerIndex)); // radius_major
        packet.putDouble(event.getToolMinor(pointerIndex)); // radius_minor

        packet.putDouble(0.0); // radius_min
        packet.putDouble(0.0); // radius_max

        packet.putDouble(
            event.getAxisValue(MotionEvent.AXIS_ORIENTATION, pointerIndex)); // orientation

        if (pointerKind == kPointerDeviceKindStylus) {
            packet.putDouble(event.getAxisValue(MotionEvent.AXIS_TILT, pointerIndex)); // tilt
        } else {
            packet.putDouble(0.0); // tilt
        }
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        if (!isAttached()) {
            return false;
        }

        // TODO(abarth): This version check might not be effective in some
        // versions of Android that statically compile code and will be upset
        // at the lack of |requestUnbufferedDispatch|. Instead, we should factor
        // version-dependent code into separate classes for each supported
        // version and dispatch dynamically.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            requestUnbufferedDispatch(event);
        }

        // These values must match the unpacking code in hooks.dart.
        final int kPointerDataFieldCount = 19;
        final int kBytePerField = 8;

        int pointerCount = event.getPointerCount();

        ByteBuffer packet = ByteBuffer
            .allocateDirect(pointerCount * kPointerDataFieldCount * kBytePerField);
        packet.order(ByteOrder.LITTLE_ENDIAN);

        int maskedAction = event.getActionMasked();
        // ACTION_UP, ACTION_POINTER_UP, ACTION_DOWN, and ACTION_POINTER_DOWN
        // only apply to a single pointer, other events apply to all pointers.
        if (maskedAction == MotionEvent.ACTION_UP
            || maskedAction == MotionEvent.ACTION_POINTER_UP
            || maskedAction == MotionEvent.ACTION_DOWN
            || maskedAction == MotionEvent.ACTION_POINTER_DOWN) {
            addPointerForIndex(event, event.getActionIndex(), packet);
        } else {
            // ACTION_MOVE may not actually mean all pointers have moved
            // but it's the responsibility of a later part of the system to
            // ignore 0-deltas if desired.
            for (int p = 0; p < pointerCount; p++) {
                addPointerForIndex(event, p, packet);
            }
        }

        assert packet.position() % (kPointerDataFieldCount * kBytePerField) == 0;
        nativeDispatchPointerDataPacket(mNativePlatformView, packet, packet.position());
        return true;
    }

    @Override
    public boolean onHoverEvent(MotionEvent event) {
        if (!isAttached()) {
            return false;
        }

        boolean handled = handleAccessibilityHoverEvent(event);
        if (!handled) {
            // TODO(ianh): Expose hover events to the platform,
            // implementing ADD, REMOVE, etc.
        }
        return handled;
    }

    @Override
    protected void onSizeChanged(int width, int height, int oldWidth, int oldHeight) {
        mMetrics.physicalWidth = width;
        mMetrics.physicalHeight = height;
        updateViewportMetrics();
        super.onSizeChanged(width, height, oldWidth, oldHeight);
    }

    @Override
    public final WindowInsets onApplyWindowInsets(WindowInsets insets) {
        mMetrics.physicalPaddingTop = insets.getSystemWindowInsetTop();
        mMetrics.physicalPaddingRight = insets.getSystemWindowInsetRight();
        mMetrics.physicalPaddingBottom = insets.getSystemWindowInsetBottom();
        mMetrics.physicalPaddingLeft = insets.getSystemWindowInsetLeft();
        updateViewportMetrics();
        return super.onApplyWindowInsets(insets);
    }

    @Override
    @SuppressWarnings("deprecation")
    protected boolean fitSystemWindows(Rect insets) {
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.KITKAT) {
            mMetrics.physicalPaddingTop = insets.top;
            mMetrics.physicalPaddingRight = insets.right;
            mMetrics.physicalPaddingBottom = insets.bottom;
            mMetrics.physicalPaddingLeft = insets.left;
            updateViewportMetrics();
            return true;
        } else {
            return super.fitSystemWindows(insets);
        }
    }

    private void attach() {
        mNativePlatformView = nativeAttach(this);
    }

    private boolean isAttached() {
        return mNativePlatformView != 0;
    }

    private void preRun() {
        resetAccessibilityTree();
    }

    private void postRun() {
    }

    public void runFromBundle(String bundlePath, String snapshotOverride) {
        preRun();
        nativeRunBundleAndSnapshot(mNativePlatformView, bundlePath, snapshotOverride);
        postRun();
    }

    private void runFromSource(final String assetsDirectory,
        final String main,
        final String packages) {
        Runnable runnable = new Runnable() {
            public void run() {
                preRun();
                nativeRunBundleAndSource(mNativePlatformView, assetsDirectory, main, packages);
                postRun();
                synchronized (this) {
                    notify();
                }
            }
        };

        try {
            synchronized (runnable) {
                // Post to the Android UI thread and wait for the response.
                post(runnable);
                runnable.wait();
            }
        } catch (InterruptedException e) {
            Log.e(TAG, "Thread got interrupted waiting for " +
                "RunFromSourceRunnable to finish", e);
        }
    }

    /**
     * Return the most recent frame as a bitmap.
     *
     * @return A bitmap.
     */
    public Bitmap getBitmap() {
        return nativeGetBitmap(mNativePlatformView);
    }

    private static native long nativeAttach(FlutterView view);

    private static native String nativeGetObservatoryUri();

    private static native void nativeDetach(long nativePlatformViewAndroid);

    private static native void nativeSurfaceCreated(long nativePlatformViewAndroid,
        Surface surface,
        int backgroundColor);

    private static native void nativeSurfaceChanged(long nativePlatformViewAndroid,
        int width,
        int height);

    private static native void nativeSurfaceDestroyed(long nativePlatformViewAndroid);

    private static native void nativeRunBundleAndSnapshot(long nativePlatformViewAndroid,
        String bundlePath,
        String snapshotOverride);

    private static native void nativeRunBundleAndSource(long nativePlatformViewAndroid,
        String bundlePath,
        String main,
        String packages);

    private static native void nativeSetViewportMetrics(long nativePlatformViewAndroid,
        float devicePixelRatio,
        int physicalWidth,
        int physicalHeight,
        int physicalPaddingTop,
        int physicalPaddingRight,
        int physicalPaddingBottom,
        int physicalPaddingLeft);

    private static native Bitmap nativeGetBitmap(long nativePlatformViewAndroid);

    // Send a data-carrying platform message to Dart.
    private static native void nativeDispatchPlatformMessage(long nativePlatformViewAndroid,
        String channel, ByteBuffer message, int position, int responseId);

    // Send an empty platform message to Dart.
    private static native void nativeDispatchEmptyPlatformMessage(long nativePlatformViewAndroid,
        String channel, int responseId);

    private static native void nativeDispatchPointerDataPacket(long nativePlatformViewAndroid,
        ByteBuffer buffer, int position);

    private static native void nativeDispatchSemanticsAction(long nativePlatformViewAndroid, int id,
        int action);

    private static native void nativeSetSemanticsEnabled(long nativePlatformViewAndroid,
        boolean enabled);

    // Send a data-carrying response to a platform message received from Dart.
    private static native void nativeInvokePlatformMessageResponseCallback(
        long nativePlatformViewAndroid, int responseId, ByteBuffer message, int position);

    // Send an empty response to a platform message received from Dart.
    private static native void nativeInvokePlatformMessageEmptyResponseCallback(
        long nativePlatformViewAndroid, int responseId);

    private static native boolean nativeGetIsSoftwareRenderingEnabled();

    private void updateViewportMetrics() {
        nativeSetViewportMetrics(mNativePlatformView,
            mMetrics.devicePixelRatio,
            mMetrics.physicalWidth,
            mMetrics.physicalHeight,
            mMetrics.physicalPaddingTop,
            mMetrics.physicalPaddingRight,
            mMetrics.physicalPaddingBottom,
            mMetrics.physicalPaddingLeft);
    }

    // Called by native to send us a platform message.
    private void handlePlatformMessage(String channel, byte[] message, final int replyId) {
        BinaryMessageHandler handler = mMessageHandlers.get(channel);
        if (handler != null) {
            try {
                final ByteBuffer buffer = (message == null ? null : ByteBuffer.wrap(message));
                handler.onMessage(buffer,
                    new BinaryReply() {
                        private final AtomicBoolean done = new AtomicBoolean(false);
                        @Override
                        public void reply(ByteBuffer reply) {
                            if (done.getAndSet(true)) {
                                throw new IllegalStateException("Reply already submitted");
                            }
                            if (reply == null) {
                                nativeInvokePlatformMessageEmptyResponseCallback(mNativePlatformView,
                                    replyId);
                            } else {
                                nativeInvokePlatformMessageResponseCallback(mNativePlatformView,
                                    replyId, reply, reply.position());
                            }
                        }
                    });
            } catch (Exception ex) {
                Log.e(TAG, "Uncaught exception in binary message listener", ex);
                nativeInvokePlatformMessageEmptyResponseCallback(mNativePlatformView, replyId);
            }
            return;
        }
        nativeInvokePlatformMessageEmptyResponseCallback(mNativePlatformView, replyId);
    }

    private int mNextReplyId = 1;
    private final Map<Integer, BinaryReply> mPendingReplies = new HashMap<>();

    // Called by native to respond to a platform message that we sent.
    private void handlePlatformMessageResponse(int replyId, byte[] reply) {
        BinaryReply callback = mPendingReplies.remove(replyId);
        if (callback != null) {
            try {
                callback.reply(reply == null ? null : ByteBuffer.wrap(reply));
            } catch (Exception ex) {
                Log.e(TAG, "Uncaught exception in binary message reply handler", ex);
            }
        }
    }

    // Called by native to update the semantics/accessibility tree.
    private void updateSemantics(ByteBuffer buffer, String[] strings) {
        try {
            if (mAccessibilityNodeProvider != null) {
                buffer.order(ByteOrder.LITTLE_ENDIAN);
                mAccessibilityNodeProvider.updateSemantics(buffer, strings);
            }
        } catch (Exception ex) {
            Log.e(TAG, "Uncaught exception while updating semantics", ex);
        }
    }

    // Called by native to notify first Flutter frame rendered.
    private void onFirstFrame() {
        for (FirstFrameListener listener : mFirstFrameListeners) {
            listener.onFirstFrame();
        }
    }

    // ACCESSIBILITY

    private boolean mAccessibilityEnabled = false;
    private boolean mTouchExplorationEnabled = false;
    private TouchExplorationListener mTouchExplorationListener;

    protected void dispatchSemanticsAction(int id, int action) {
        nativeDispatchSemanticsAction(mNativePlatformView, id, action);
    }

    @Override
    protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        mAccessibilityEnabled = mAccessibilityManager.isEnabled();
        mTouchExplorationEnabled = mAccessibilityManager.isTouchExplorationEnabled();
        if (mAccessibilityEnabled || mTouchExplorationEnabled) {
            ensureAccessibilityEnabled();
        }
        resetWillNotDraw();
        mAccessibilityManager.addAccessibilityStateChangeListener(this);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            if (mTouchExplorationListener == null) {
                mTouchExplorationListener = new TouchExplorationListener();
            }
            mAccessibilityManager.addTouchExplorationStateChangeListener(mTouchExplorationListener);
        }
    }

    @Override
    protected void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        mAccessibilityManager.removeAccessibilityStateChangeListener(this);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            mAccessibilityManager
                .removeTouchExplorationStateChangeListener(mTouchExplorationListener);
        }
    }

    private void resetWillNotDraw() {
        if (!mIsSoftwareRenderingEnabled) {
            setWillNotDraw(!(mAccessibilityEnabled || mTouchExplorationEnabled));
        } else {
            setWillNotDraw(false);
        }
    }

    @Override
    public void onAccessibilityStateChanged(boolean enabled) {
        if (enabled) {
            ensureAccessibilityEnabled();
        } else {
            mAccessibilityEnabled = false;
            if (mAccessibilityNodeProvider != null) {
                mAccessibilityNodeProvider.setAccessibilityEnabled(false);
            }
        }
        resetWillNotDraw();
    }

    class TouchExplorationListener
        implements AccessibilityManager.TouchExplorationStateChangeListener {

        @Override
        public void onTouchExplorationStateChanged(boolean enabled) {
            if (enabled) {
                mTouchExplorationEnabled = true;
                ensureAccessibilityEnabled();
            } else {
                mTouchExplorationEnabled = false;
                if (mAccessibilityNodeProvider != null) {
                    mAccessibilityNodeProvider.handleTouchExplorationExit();
                }
            }
            resetWillNotDraw();
        }
    }

    @Override
    public AccessibilityNodeProvider getAccessibilityNodeProvider() {
        ensureAccessibilityEnabled();
        return mAccessibilityNodeProvider;
    }

    private AccessibilityBridge mAccessibilityNodeProvider;

    void ensureAccessibilityEnabled() {
        mAccessibilityEnabled = true;
        if (mAccessibilityNodeProvider == null) {
            mAccessibilityNodeProvider = new AccessibilityBridge(this);
            nativeSetSemanticsEnabled(mNativePlatformView, true);
        }
        mAccessibilityNodeProvider.setAccessibilityEnabled(true);
    }

    void resetAccessibilityTree() {
        if (mAccessibilityNodeProvider != null) {
            mAccessibilityNodeProvider.reset();
        }
    }

    private boolean handleAccessibilityHoverEvent(MotionEvent event) {
        if (!mTouchExplorationEnabled) {
            return false;
        }
        if (event.getAction() == MotionEvent.ACTION_HOVER_ENTER ||
            event.getAction() == MotionEvent.ACTION_HOVER_MOVE) {
            mAccessibilityNodeProvider.handleTouchExploration(event.getX(), event.getY());
        } else if (event.getAction() == MotionEvent.ACTION_HOVER_EXIT) {
            mAccessibilityNodeProvider.handleTouchExplorationExit();
        } else {
            Log.d("flutter", "unexpected accessibility hover event: " + event);
            return false;
        }
        return true;
    }

    @Override
    public void send(String channel, ByteBuffer message) {
      send(channel, message, null);
    }

    @Override
    public void send(String channel, ByteBuffer message, BinaryReply callback) {
        if (!isAttached()) {
            Log.d("flutter", "FlutterView.send called on a detached view, channel=" + channel);
            return;
        }

        int replyId = 0;
        if (callback != null) {
            replyId = mNextReplyId++;
            mPendingReplies.put(replyId, callback);
        }
        if (message == null) {
            nativeDispatchEmptyPlatformMessage(mNativePlatformView, channel, replyId);
        } else {
            nativeDispatchPlatformMessage(mNativePlatformView, channel, message,
                message.position(), replyId);
        }
    }

    @Override
    public void setMessageHandler(String channel, BinaryMessageHandler handler) {
        if (handler == null) {
            mMessageHandlers.remove(channel);
        } else {
            mMessageHandlers.put(channel, handler);
        }
    }

    /**
     * Broadcast receiver used to discover active Flutter instances.
     *
     * This is used by the `flutter` tool to find the observatory ports
     * for all the active Flutter views. We dump the data to the logs
     * and the tool scrapes the log lines for the data.
     */
    private class DiscoveryReceiver extends BroadcastReceiver {

        @Override
        public void onReceive(Context context, Intent intent) {
            URI observatoryUri = URI.create(nativeGetObservatoryUri());
            JSONObject discover = new JSONObject();
            try {
                discover.put("id", getContext().getPackageName());
                discover.put("observatoryPort", observatoryUri.getPort());
                Log.i(TAG, "DISCOVER: " + discover); // The tool looks for this data. See android_device.dart.
            } catch (JSONException e) {
            }
        }
    }

    /**
     * Listener will be called on the Android UI thread once when Flutter renders the first frame.
     */
    public interface FirstFrameListener {
        void onFirstFrame();
    }
}

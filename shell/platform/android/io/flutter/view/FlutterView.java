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

import io.flutter.plugin.common.ActivityLifecycleListener;
import io.flutter.plugin.common.FlutterMessageChannel;
import io.flutter.plugin.common.FlutterMethodChannel;
import io.flutter.plugin.common.JSONMessageCodec;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.StringCodec;
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

/**
 * An Android view containing a Flutter app.
 */
public class FlutterView extends SurfaceView
    implements AccessibilityManager.AccessibilityStateChangeListener {

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
    private final Map<String, OnBinaryMessageListenerAsync> mMessageListeners;
    private final SurfaceHolder.Callback mSurfaceCallback;
    private final ViewportMetrics mMetrics;
    private final AccessibilityManager mAccessibilityManager;
    private final FlutterMethodChannel mFlutterLocalizationChannel;
    private final FlutterMethodChannel mFlutterNavigationChannel;
    private final FlutterMessageChannel<Object> mFlutterKeyEventChannel;
    private final FlutterMessageChannel<String> mFlutterLifecycleChannel;
    private final FlutterMessageChannel<Object> mFlutterSystemChannel;
    private final BroadcastReceiver mDiscoveryReceiver;
    private final List<ActivityLifecycleListener> mActivityLifecycleListeners;
    private long mNativePlatformView;

    public FlutterView(Context context) {
        this(context, null);
    }

    public FlutterView(Context context, AttributeSet attrs) {
        super(context, attrs);

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

        mMessageListeners = new HashMap<>();
        mActivityLifecycleListeners = new ArrayList<>();

        // Configure the platform plugins and flutter channels.
        mFlutterLocalizationChannel = new FlutterMethodChannel(this, "flutter/localization",
            JSONMethodCodec.INSTANCE);
        mFlutterNavigationChannel = new FlutterMethodChannel(this, "flutter/navigation",
            JSONMethodCodec.INSTANCE);
        mFlutterKeyEventChannel = new FlutterMessageChannel<>(this, "flutter/keyevent",
            JSONMessageCodec.INSTANCE);
        mFlutterLifecycleChannel = new FlutterMessageChannel<>(this, "flutter/lifecycle",
            StringCodec.INSTANCE);
        mFlutterSystemChannel = new FlutterMessageChannel<>(this, "flutter/system",
            JSONMessageCodec.INSTANCE);
        PlatformPlugin platformPlugin = new PlatformPlugin((Activity) getContext());
        FlutterMethodChannel flutterPlatformChannel = new FlutterMethodChannel(this,
            "flutter/platform", JSONMethodCodec.INSTANCE);
        flutterPlatformChannel.setMethodCallHandler(platformPlugin);
        addActivityLifecycleListener(platformPlugin);
        mTextInputPlugin = new TextInputPlugin((Activity) getContext(), this);

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

    public void onMemoryPressure() {
        Map<String, Object> message = new HashMap<>(1);
        message.put("type", "memoryPressure");
        mFlutterSystemChannel.send(message);
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

    // Send a platform message to Dart.
    private static native void nativeDispatchPlatformMessage(long nativePlatformViewAndroid,
        String channel, ByteBuffer message, int position, int responseId);

    private static native void nativeDispatchPointerDataPacket(long nativePlatformViewAndroid,
        ByteBuffer buffer, int position);

    private static native void nativeDispatchSemanticsAction(long nativePlatformViewAndroid, int id,
        int action);

    private static native void nativeSetSemanticsEnabled(long nativePlatformViewAndroid,
        boolean enabled);

    // Send a response to a platform message received from Dart.
    private static native void nativeInvokePlatformMessageResponseCallback(
        long nativePlatformViewAndroid, int responseId, ByteBuffer message, int position);

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
    private void handlePlatformMessage(String channel, ByteBuffer message, final int responseId) {
        OnBinaryMessageListenerAsync listener = mMessageListeners.get(channel);
        if (listener != null) {
            try {
                listener.onMessage(this, message,
                    new BinaryMessageResponse() {
                        @Override
                        public void send(ByteBuffer response) {
                            nativeInvokePlatformMessageResponseCallback(mNativePlatformView,
                                responseId, response, response == null ? 0 : response.position());
                        }
                    });
            } catch (Exception ex) {
                Log.e(TAG, "Uncaught exception in binary message listener", ex);
                nativeInvokePlatformMessageResponseCallback(mNativePlatformView, responseId,
                    null, 0);
            }
            return;
        }
        nativeInvokePlatformMessageResponseCallback(mNativePlatformView, responseId, null, 0);
    }

    private int mNextResponseId = 1;
    private final Map<Integer, BinaryMessageReplyCallback> mPendingResponses = new HashMap<>();

    // Called by native to respond to a platform message that we sent.
    private void handlePlatformMessageResponse(int responseId, ByteBuffer response) {
        BinaryMessageReplyCallback callback = mPendingResponses.remove(responseId);
        if (callback != null) {
            try {
                callback.onReply(response);
            } catch (Exception ex) {
                Log.e(TAG, "Uncaught exception in binary message listener reply", ex);
            }
        }
    }

    private void updateSemantics(ByteBuffer buffer, String[] strings) {
        if (mAccessibilityNodeProvider != null) {
            buffer.order(ByteOrder.LITTLE_ENDIAN);
            mAccessibilityNodeProvider.updateSemantics(buffer, strings);
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
        setWillNotDraw(!(mAccessibilityEnabled || mTouchExplorationEnabled));
    }

    @Override
    public void onAccessibilityStateChanged(boolean enabled) {
        if (enabled) {
            mAccessibilityEnabled = true;
            ensureAccessibilityEnabled();
        } else {
            mAccessibilityEnabled = false;
        }
        if (mAccessibilityNodeProvider != null) {
            mAccessibilityNodeProvider.setAccessibilityEnabled(mAccessibilityEnabled);
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
        if (mAccessibilityNodeProvider == null) {
            mAccessibilityNodeProvider = new AccessibilityBridge(this);
            nativeSetSemanticsEnabled(mNativePlatformView, true);
        }
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

    /**
     * Send a binary message to the Flutter application. The Flutter Dart code can register a
     * platform message handler that will receive these messages.
     *
     * @param channel Name of the channel that will receive this message.
     * @param message Message payload, a {@link ByteBuffer} with the message bytes between position
     * zero and current position, or null.
     * @param callback Callback that receives a reply from the Flutter application.
     */
    public void sendBinaryMessage(String channel, ByteBuffer message,
        BinaryMessageReplyCallback callback) {
        int responseId = 0;
        if (callback != null) {
            responseId = mNextResponseId++;
            mPendingResponses.put(responseId, callback);
        }
        nativeDispatchPlatformMessage(mNativePlatformView, channel, message,
            message == null ? 0 : message.position(), responseId);
    }

    /**
     * Callback invoked when the app replies to a binary message sent with sendBinaryMessage.
     */
    public interface BinaryMessageReplyCallback {

        void onReply(ByteBuffer reply);
    }

    /**
     * Register a callback to be invoked when the Flutter application sends a message
     * to its host.  The reply to the message can be provided asynchronously.
     *
     * @param channel Name of the channel used by the application.
     * @param listener Called when messages arrive.
     */
    public void addOnBinaryMessageListenerAsync(String channel,
        OnBinaryMessageListenerAsync listener) {
        if (listener == null) {
            mMessageListeners.remove(channel);
        } else {
            mMessageListeners.put(channel, listener);
        }
    }

    public interface OnBinaryMessageListenerAsync {

        /**
         * Called when a message is received from the Flutter app.
         *
         * @param view The Flutter view hosting the app.
         * @param message Message payload.
         * @param response Used to send a reply back to the app.
         */
        void onMessage(FlutterView view, ByteBuffer message, BinaryMessageResponse response);
    }

    public interface BinaryMessageResponse {

        void send(ByteBuffer reply);
    }

    /**
     * Broadcast receiver used to discover active Flutter instances.
     */
    private class DiscoveryReceiver extends BroadcastReceiver {

        @Override
        public void onReceive(Context context, Intent intent) {
            URI observatoryUri = URI.create(nativeGetObservatoryUri());
            JSONObject discover = new JSONObject();
            try {
                discover.put("id", getContext().getPackageName());
                discover.put("observatoryPort", observatoryUri.getPort());
                Log.i(TAG, "DISCOVER: " + discover);
            } catch (JSONException e) {
            }
        }
    }
}

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
import android.graphics.SurfaceTexture;
import android.os.Build;
import android.text.format.DateFormat;
import android.util.AttributeSet;
import android.util.Log;
import android.util.TypedValue;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.WindowInsets;
import android.view.WindowManager;
import android.view.accessibility.AccessibilityManager;
import android.view.accessibility.AccessibilityNodeProvider;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import io.flutter.app.FlutterActivity;
import io.flutter.app.FlutterPluginRegistry;
import io.flutter.plugin.common.*;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.editing.TextInputPlugin;
import io.flutter.plugin.platform.PlatformPlugin;
import io.flutter.view.VsyncWaiter;

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
import java.util.concurrent.atomic.AtomicLong;

/**
 * An Android view containing a Flutter app.
 */
public class FlutterView extends SurfaceView
    implements BinaryMessenger, TextureRegistry, AccessibilityManager.AccessibilityStateChangeListener {

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
        int physicalViewInsetTop = 0;
        int physicalViewInsetRight = 0;
        int physicalViewInsetBottom = 0;
        int physicalViewInsetLeft = 0;
    }

    private final TextInputPlugin mTextInputPlugin;
    private final SurfaceHolder.Callback mSurfaceCallback;
    private final ViewportMetrics mMetrics;
    private final AccessibilityManager mAccessibilityManager;
    private final MethodChannel mFlutterLocalizationChannel;
    private final MethodChannel mFlutterNavigationChannel;
    private final BasicMessageChannel<Object> mFlutterKeyEventChannel;
    private final BasicMessageChannel<String> mFlutterLifecycleChannel;
    private final BasicMessageChannel<Object> mFlutterSystemChannel;
    private final BasicMessageChannel<Object> mFlutterSettingsChannel;
    private final BroadcastReceiver mDiscoveryReceiver;
    private final List<ActivityLifecycleListener> mActivityLifecycleListeners;
    private final List<FirstFrameListener> mFirstFrameListeners;
    private final AtomicLong nextTextureId = new AtomicLong(0L);
    private FlutterNativeView mNativeView;
    private boolean mIsSoftwareRenderingEnabled = false; // using the software renderer or not

    public FlutterView(Context context) {
        this(context, null);
    }

    public FlutterView(Context context, AttributeSet attrs) {
        this(context, attrs, null);
    }

    public FlutterView(Context context, AttributeSet attrs, FlutterNativeView nativeView) {
        super(context, attrs);

        mIsSoftwareRenderingEnabled = nativeGetIsSoftwareRenderingEnabled();

        mMetrics = new ViewportMetrics();
        mMetrics.devicePixelRatio = context.getResources().getDisplayMetrics().density;
        setFocusable(true);
        setFocusableInTouchMode(true);

        Activity activity = (Activity) getContext();
        if (nativeView == null) {
            mNativeView = new FlutterNativeView(activity.getApplicationContext());
        } else {
            mNativeView = nativeView;
        }
        mNativeView.attachViewAndActivity(this, activity);

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
                assertAttached();
                nativeSurfaceCreated(mNativeView.get(), holder.getSurface(), backgroundColor);
            }

            @Override
            public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
                assertAttached();
                nativeSurfaceChanged(mNativeView.get(), width, height);
            }

            @Override
            public void surfaceDestroyed(SurfaceHolder holder) {
                assertAttached();
                nativeSurfaceDestroyed(mNativeView.get());
            }
        };
        getHolder().addCallback(mSurfaceCallback);

        mAccessibilityManager = (AccessibilityManager) getContext()
            .getSystemService(Context.ACCESSIBILITY_SERVICE);

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
        mFlutterSettingsChannel = new BasicMessageChannel<>(this, "flutter/settings",
            JSONMessageCodec.INSTANCE);

        PlatformPlugin platformPlugin = new PlatformPlugin(activity);
        MethodChannel flutterPlatformChannel = new MethodChannel(this,
            "flutter/platform", JSONMethodCodec.INSTANCE);
        flutterPlatformChannel.setMethodCallHandler(platformPlugin);
        addActivityLifecycleListener(platformPlugin);
        mTextInputPlugin = new TextInputPlugin(this);

        setLocale(getResources().getConfiguration().locale);
        setUserSettings();

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

    public FlutterNativeView getFlutterNativeView() {
        return mNativeView;
    }

    public FlutterPluginRegistry getPluginRegistry() {
        return mNativeView.getPluginRegistry();
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

    private void setUserSettings() {
      Map<String, Object> message = new HashMap<>();
      message.put("textScaleFactor", getResources().getConfiguration().fontScale);
      message.put("alwaysUse24HourFormat", DateFormat.is24HourFormat(getContext()));
      mFlutterSettingsChannel.send(message);
    }

    private void setLocale(Locale locale) {
        mFlutterLocalizationChannel.invokeMethod("setLocale",
            Arrays.asList(locale.getLanguage(), locale.getCountry()));
    }

    @Override
    protected void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        setLocale(newConfig.locale);
        setUserSettings();
    }

    float getDevicePixelRatio() {
        return mMetrics.devicePixelRatio;
    }

    public FlutterNativeView detach() {
        if (!isAttached())
            return null;
        if (mDiscoveryReceiver != null) {
            getContext().unregisterReceiver(mDiscoveryReceiver);
        }
        getHolder().removeCallback(mSurfaceCallback);
        mNativeView.detach();

        FlutterNativeView view = mNativeView;
        mNativeView = null;
        return view;
    }

    public void destroy() {
        if (!isAttached())
            return;

        if (mDiscoveryReceiver != null) {
            getContext().unregisterReceiver(mDiscoveryReceiver);
        }

        getHolder().removeCallback(mSurfaceCallback);

        mNativeView.destroy();
        mNativeView = null;
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
        nativeDispatchPointerDataPacket(mNativeView.get(), packet, packet.position());
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
        // On Android, we do not differentiate between 'safe areas' and view insets.
        mMetrics.physicalPaddingTop = insets.getSystemWindowInsetTop();
        mMetrics.physicalPaddingRight = insets.getSystemWindowInsetRight();
        mMetrics.physicalPaddingBottom = insets.getSystemWindowInsetBottom();
        mMetrics.physicalPaddingLeft = insets.getSystemWindowInsetLeft();
        mMetrics.physicalViewInsetTop = insets.getSystemWindowInsetTop();
        mMetrics.physicalViewInsetRight = insets.getSystemWindowInsetRight();
        mMetrics.physicalViewInsetBottom = insets.getSystemWindowInsetBottom();
        mMetrics.physicalViewInsetLeft = insets.getSystemWindowInsetLeft();
        updateViewportMetrics();
        return super.onApplyWindowInsets(insets);
    }

    @Override
    @SuppressWarnings("deprecation")
    protected boolean fitSystemWindows(Rect insets) {
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.KITKAT) {
            // On Android, we do not differentiate between 'safe areas' and view insets.
            mMetrics.physicalPaddingTop = insets.top;
            mMetrics.physicalPaddingRight = insets.right;
            mMetrics.physicalPaddingBottom = insets.bottom;
            mMetrics.physicalPaddingLeft = insets.left;
            mMetrics.physicalViewInsetTop = insets.top;
            mMetrics.physicalViewInsetRight = insets.right;
            mMetrics.physicalViewInsetBottom = insets.bottom;
            mMetrics.physicalViewInsetLeft = insets.left;
            updateViewportMetrics();
            return true;
        } else {
            return super.fitSystemWindows(insets);
        }
    }

    private boolean isAttached() {
        return mNativeView.isAttached();
    }

    void assertAttached() {
        mNativeView.assertAttached();
    }

    private void preRun() {
        resetAccessibilityTree();
    }

    private void postRun() {
    }

    public void runFromBundle(String bundlePath, String snapshotOverride) {
        runFromBundle(bundlePath, snapshotOverride, "main", false);
    }

    public void runFromBundle(String bundlePath, String snapshotOverride, String entrypoint) {
        runFromBundle(bundlePath, snapshotOverride, entrypoint, false);
    }

    public void runFromBundle(String bundlePath, String snapshotOverride, String entrypoint, boolean reuseRuntimeController) {
        assertAttached();
        preRun();
        mNativeView.runFromBundle(bundlePath, snapshotOverride, entrypoint, reuseRuntimeController);
        postRun();
    }

    private void runFromSource(final String assetsDirectory, final String main, final String packages) {
        Runnable runnable = new Runnable() {
            public void run() {
                assertAttached();
                preRun();
                mNativeView.runFromSource(assetsDirectory, main, packages);
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
        assertAttached();
        return nativeGetBitmap(mNativeView.get());
    }

    private static native void nativeSurfaceCreated(long nativePlatformViewAndroid,
        Surface surface,
        int backgroundColor);

    private static native void nativeSurfaceChanged(long nativePlatformViewAndroid,
        int width,
        int height);

    private static native void nativeSurfaceDestroyed(long nativePlatformViewAndroid);

    private static native void nativeSetViewportMetrics(long nativePlatformViewAndroid,
        float devicePixelRatio,
        int physicalWidth,
        int physicalHeight,
        int physicalPaddingTop,
        int physicalPaddingRight,
        int physicalPaddingBottom,
        int physicalPaddingLeft,
        int physicalViewInsetTop,
        int physicalViewInsetRight,
        int physicalViewInsetBottom,
        int physicalViewInsetLeft);

    private static native Bitmap nativeGetBitmap(long nativePlatformViewAndroid);

    private static native void nativeDispatchPointerDataPacket(long nativePlatformViewAndroid,
        ByteBuffer buffer, int position);

    private static native void nativeDispatchSemanticsAction(long nativePlatformViewAndroid, int id,
        int action);

    private static native void nativeSetSemanticsEnabled(long nativePlatformViewAndroid,
        boolean enabled);

    private static native boolean nativeGetIsSoftwareRenderingEnabled();

    private static native void nativeRegisterTexture(long nativePlatformViewAndroid, long textureId, SurfaceTexture surfaceTexture);

    private static native void nativeMarkTextureFrameAvailable(long nativePlatformViewAndroid, long textureId);

    private static native void nativeUnregisterTexture(long nativePlatformViewAndroid, long textureId);

    private void updateViewportMetrics() {
        if (!isAttached())
            return;
        nativeSetViewportMetrics(mNativeView.get(),
            mMetrics.devicePixelRatio,
            mMetrics.physicalWidth,
            mMetrics.physicalHeight,
            mMetrics.physicalPaddingTop,
            mMetrics.physicalPaddingRight,
            mMetrics.physicalPaddingBottom,
            mMetrics.physicalPaddingLeft,
            mMetrics.physicalViewInsetTop,
            mMetrics.physicalViewInsetRight,
            mMetrics.physicalViewInsetBottom,
            mMetrics.physicalViewInsetLeft);

        WindowManager wm = (WindowManager) getContext()
            .getSystemService(Context.WINDOW_SERVICE);
        float fps = wm.getDefaultDisplay().getRefreshRate();
        VsyncWaiter.refreshPeriodNanos = (long)(1000000000.0 / fps);
    }

    // Called by native to update the semantics/accessibility tree.
    public void updateSemantics(ByteBuffer buffer, String[] strings) {
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
    public void onFirstFrame() {
        for (FirstFrameListener listener : mFirstFrameListeners) {
            listener.onFirstFrame();
        }
    }

    // ACCESSIBILITY

    private boolean mAccessibilityEnabled = false;
    private boolean mTouchExplorationEnabled = false;
    private TouchExplorationListener mTouchExplorationListener;

    protected void dispatchSemanticsAction(int id, int action) {
        if (!isAttached())
            return;
        nativeDispatchSemanticsAction(mNativeView.get(), id, action);
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
        if (!isAttached())
            return;
        mAccessibilityEnabled = true;
        if (mAccessibilityNodeProvider == null) {
            mAccessibilityNodeProvider = new AccessibilityBridge(this);
            nativeSetSemanticsEnabled(mNativeView.get(), true);
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
        mNativeView.send(channel, message);
    }

    @Override
    public void send(String channel, ByteBuffer message, BinaryReply callback) {
        mNativeView.send(channel, message, callback);
    }

    @Override
    public void setMessageHandler(String channel, BinaryMessageHandler handler) {
        mNativeView.setMessageHandler(channel, handler);
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
            URI observatoryUri = URI.create(FlutterNativeView.getObservatoryUri());
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

    @Override
    public TextureRegistry.SurfaceTextureEntry createSurfaceTexture() {
        final SurfaceTexture surfaceTexture = new SurfaceTexture(0);
        surfaceTexture.detachFromGLContext();
        final SurfaceTextureRegistryEntry entry = new SurfaceTextureRegistryEntry(
            nextTextureId.getAndIncrement(), surfaceTexture);
        nativeRegisterTexture(mNativeView.get(), entry.id(), surfaceTexture);
        return entry;
    }

    final class SurfaceTextureRegistryEntry implements TextureRegistry.SurfaceTextureEntry {
        private final long id;
        private final SurfaceTexture surfaceTexture;
        private boolean released;

        SurfaceTextureRegistryEntry(long id, SurfaceTexture surfaceTexture) {
            this.id = id;
            this.surfaceTexture = surfaceTexture;
            this.surfaceTexture.setOnFrameAvailableListener(new SurfaceTexture.OnFrameAvailableListener() {
                @Override
                public void onFrameAvailable(SurfaceTexture texture) {
                    nativeMarkTextureFrameAvailable(mNativeView.get(), SurfaceTextureRegistryEntry.this.id);
                }
            });
        }

        @Override
        public SurfaceTexture surfaceTexture() {
          return surfaceTexture;
        }

        @Override
        public long id() {
            return id;
        }

        @Override
        public void release() {
            if (released) {
                return;
            }
            released = true;
            nativeUnregisterTexture(mNativeView.get(), id);
            surfaceTexture.release();
        }
    }
}

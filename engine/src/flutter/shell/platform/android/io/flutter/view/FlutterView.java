// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.app.Activity;
import android.content.Context;
import android.content.res.Configuration;
import android.database.ContentObserver;
import android.graphics.Bitmap;
import android.graphics.PixelFormat;
import android.graphics.Rect;
import android.graphics.SurfaceTexture;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.provider.Settings;
import android.text.format.DateFormat;
import android.util.AttributeSet;
import android.util.Log;
import android.view.*;
import android.view.accessibility.AccessibilityManager;
import android.view.accessibility.AccessibilityNodeProvider;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import android.view.inputmethod.InputMethodManager;
import io.flutter.app.FlutterPluginRegistry;
import io.flutter.plugin.common.*;
import io.flutter.plugin.editing.TextInputPlugin;
import io.flutter.plugin.platform.PlatformPlugin;
import org.json.JSONException;

import java.lang.reflect.Method;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.*;
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
     * <p>
     * This indirection is provided to support applications that use an activity
     * other than {@link io.flutter.app.FlutterActivity} (e.g. Android v4 support
     * library's {@code FragmentActivity}). It allows Flutter plugins to deal in
     * this interface and not require that the activity be a subclass of
     * {@code FlutterActivity}.
     * </p>
     */
    public interface Provider {
        /**
         * Returns a reference to the Flutter view maintained by this object. This may
         * be {@code null}.
         */
        FlutterView getFlutterView();
    }

    private static final String TAG = "FlutterView";

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

    private final InputMethodManager mImm;
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
    private final List<ActivityLifecycleListener> mActivityLifecycleListeners;
    private final List<FirstFrameListener> mFirstFrameListeners;
    private final AtomicLong nextTextureId = new AtomicLong(0L);
    private FlutterNativeView mNativeView;
    private final AnimationScaleObserver mAnimationScaleObserver;
    private boolean mIsSoftwareRenderingEnabled = false; // using the software renderer or not
    private InputConnection mLastInputConnection;

    public FlutterView(Context context) {
        this(context, null);
    }

    public FlutterView(Context context, AttributeSet attrs) {
        this(context, attrs, null);
    }

    public FlutterView(Context context, AttributeSet attrs, FlutterNativeView nativeView) {
        super(context, attrs);

        mIsSoftwareRenderingEnabled = nativeGetIsSoftwareRenderingEnabled();
        mAnimationScaleObserver = new AnimationScaleObserver(new Handler());
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

        mSurfaceCallback = new SurfaceHolder.Callback() {
            @Override
            public void surfaceCreated(SurfaceHolder holder) {
                assertAttached();
                nativeSurfaceCreated(mNativeView.get(), holder.getSurface());
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

        mAccessibilityManager = (AccessibilityManager) getContext().getSystemService(Context.ACCESSIBILITY_SERVICE);

        mActivityLifecycleListeners = new ArrayList<>();
        mFirstFrameListeners = new ArrayList<>();

        // Configure the platform plugins and flutter channels.
        mFlutterLocalizationChannel = new MethodChannel(this, "flutter/localization", JSONMethodCodec.INSTANCE);
        mFlutterNavigationChannel = new MethodChannel(this, "flutter/navigation", JSONMethodCodec.INSTANCE);
        mFlutterKeyEventChannel = new BasicMessageChannel<>(this, "flutter/keyevent", JSONMessageCodec.INSTANCE);
        mFlutterLifecycleChannel = new BasicMessageChannel<>(this, "flutter/lifecycle", StringCodec.INSTANCE);
        mFlutterSystemChannel = new BasicMessageChannel<>(this, "flutter/system", JSONMessageCodec.INSTANCE);
        mFlutterSettingsChannel = new BasicMessageChannel<>(this, "flutter/settings", JSONMessageCodec.INSTANCE);

        PlatformPlugin platformPlugin = new PlatformPlugin(activity);
        MethodChannel flutterPlatformChannel = new MethodChannel(this, "flutter/platform", JSONMethodCodec.INSTANCE);
        flutterPlatformChannel.setMethodCallHandler(platformPlugin);
        addActivityLifecycleListener(platformPlugin);
        mImm = (InputMethodManager) getContext().getSystemService(Context.INPUT_METHOD_SERVICE);
        mTextInputPlugin = new TextInputPlugin(this);


        setLocales(getResources().getConfiguration());
        setUserSettings();
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

        if (event.getDeviceId() != KeyCharacterMap.VIRTUAL_KEYBOARD) {
            if (mLastInputConnection != null && mImm.isAcceptingText()) {
                mLastInputConnection.sendKeyEvent(event);
            }
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

    public String getLookupKeyForAsset(String asset) {
        return FlutterMain.getLookupKeyForAsset(asset);
    }

    public String getLookupKeyForAsset(String asset, String packageName) {
        return FlutterMain.getLookupKeyForAsset(asset, packageName);
    }

    public void addActivityLifecycleListener(ActivityLifecycleListener listener) {
        mActivityLifecycleListeners.add(listener);
    }

    public void onStart() {
        mFlutterLifecycleChannel.send("AppLifecycleState.inactive");
    }

    public void onPause() {
        mFlutterLifecycleChannel.send("AppLifecycleState.inactive");
    }

    public void onPostResume() {
        updateAccessibilityFeatures();
        for (ActivityLifecycleListener listener : mActivityLifecycleListeners) {
            listener.onPostResume();
        }
        mFlutterLifecycleChannel.send("AppLifecycleState.resumed");
    }

    public void onStop() {
        mFlutterLifecycleChannel.send("AppLifecycleState.paused");
    }

    public void onMemoryPressure() {
        Map<String, Object> message = new HashMap<>(1);
        message.put("type", "memoryPressure");
        mFlutterSystemChannel.send(message);
    }

    /**
     * Provide a listener that will be called once when the FlutterView renders its
     * first frame to the underlaying SurfaceView.
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

    /**
     * Updates this to support rendering as a transparent {@link SurfaceView}.
     *
     * Sets it on top of its window. The background color still needs to be
     * controlled from within the Flutter UI itself.
     */
    public void enableTransparentBackground() {
        setZOrderOnTop(true);
        getHolder().setFormat(PixelFormat.TRANSPARENT);
    }

    /**
     * Reverts this back to the {@link SurfaceView} defaults, at the back of its
     * window and opaque.
     */
    public void disableTransparentBackground() {
        setZOrderOnTop(false);
        getHolder().setFormat(PixelFormat.OPAQUE);
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

    private void setLocales(Configuration config) {
        if (Build.VERSION.SDK_INT >= 24) {
            try {
                // Passes the full list of locales for android API >= 24 with reflection.
                Object localeList = config.getClass().getDeclaredMethod("getLocales").invoke(config);
                Method localeListGet = localeList.getClass().getDeclaredMethod("get", int.class);
                Method localeListSize = localeList.getClass().getDeclaredMethod("size");
                int localeCount = (int)localeListSize.invoke(localeList);
                List<String> data = new ArrayList<String>();
                for (int index = 0; index < localeCount; ++index) {
                    Locale locale = (Locale)localeListGet.invoke(localeList, index);
                    data.add(locale.getLanguage());
                    data.add(locale.getCountry());
                    data.add(locale.getScript());
                    data.add(locale.getVariant());
                }
                mFlutterLocalizationChannel.invokeMethod("setLocale", data);
                return;
            } catch (Exception exception) {
                // Any exception is a failure. Resort to fallback of sending only one locale.
            }
        }
        // Fallback single locale passing for android API < 24. Should work always.
        Locale locale = config.locale;
        // getScript() is gated because it is added in API 21.
        mFlutterLocalizationChannel.invokeMethod("setLocale", Arrays.asList(locale.getLanguage(), locale.getCountry(), Build.VERSION.SDK_INT >= 21 ? locale.getScript() : "", locale.getVariant()));

    }

    @Override
    protected void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        setLocales(newConfig);
        setUserSettings();
    }

    float getDevicePixelRatio() {
        return mMetrics.devicePixelRatio;
    }

    public FlutterNativeView detach() {
        if (!isAttached())
            return null;
        getHolder().removeCallback(mSurfaceCallback);
        mNativeView.detach();

        FlutterNativeView view = mNativeView;
        mNativeView = null;
        return view;
    }

    public void destroy() {
        if (!isAttached())
            return;

        getHolder().removeCallback(mSurfaceCallback);

        mNativeView.destroy();
        mNativeView = null;
    }

    @Override
    public InputConnection onCreateInputConnection(EditorInfo outAttrs) {
        try {
            mLastInputConnection = mTextInputPlugin.createInputConnection(this, outAttrs);
            return mLastInputConnection;
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
    private static final int kPointerDeviceKindUnknown = 4;

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
        case MotionEvent.TOOL_TYPE_ERASER:
            return kPointerDeviceKindInvertedStylus;
        default:
            // MotionEvent.TOOL_TYPE_UNKNOWN will reach here.
            return kPointerDeviceKindUnknown;
        }
    }

    private void addPointerForIndex(MotionEvent event, int pointerIndex, int pointerChange,
                                    int pointerData, ByteBuffer packet) {
        if (pointerChange == -1) {
            return;
        }

        int pointerKind = getPointerDeviceTypeForToolType(event.getToolType(pointerIndex));

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
            packet.putDouble(event.getAxisValue(MotionEvent.AXIS_DISTANCE, pointerIndex)); // distance
            packet.putDouble(0.0); // distance_max
        } else {
            packet.putDouble(0.0); // distance
            packet.putDouble(0.0); // distance_max
        }

        packet.putDouble(event.getSize(pointerIndex)); // size

        packet.putDouble(event.getToolMajor(pointerIndex)); // radius_major
        packet.putDouble(event.getToolMinor(pointerIndex)); // radius_minor

        packet.putDouble(0.0); // radius_min
        packet.putDouble(0.0); // radius_max

        packet.putDouble(event.getAxisValue(MotionEvent.AXIS_ORIENTATION, pointerIndex)); // orientation

        if (pointerKind == kPointerDeviceKindStylus) {
            packet.putDouble(event.getAxisValue(MotionEvent.AXIS_TILT, pointerIndex)); // tilt
        } else {
            packet.putDouble(0.0); // tilt
        }

        packet.putLong(pointerData); // platformData
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
        final int kPointerDataFieldCount = 21;
        final int kBytePerField = 8;

        // This value must match the value in framework's platform_view.dart.
        // This flag indicates whether the original Android pointer events were batched together.
        final int kPointerDataFlagBatched = 1;

        int pointerCount = event.getPointerCount();

        ByteBuffer packet = ByteBuffer.allocateDirect(pointerCount * kPointerDataFieldCount * kBytePerField);
        packet.order(ByteOrder.LITTLE_ENDIAN);

        int maskedAction = event.getActionMasked();
        int pointerChange = getPointerChangeForAction(event.getActionMasked());
        if (maskedAction == MotionEvent.ACTION_DOWN || maskedAction == MotionEvent.ACTION_POINTER_DOWN) {
            // ACTION_DOWN and ACTION_POINTER_DOWN always apply to a single pointer only.
            addPointerForIndex(event, event.getActionIndex(), pointerChange, 0, packet);
        } else if (maskedAction == MotionEvent.ACTION_UP || maskedAction == MotionEvent.ACTION_POINTER_UP) {
            // ACTION_UP and ACTION_POINTER_UP may contain position updates for other pointers.
            // We are converting these updates to move events here in order to preserve this data.
            // We also mark these events with a flag in order to help the framework reassemble
            // the original Android event later, should it need to forward it to a PlatformView.
            for (int p = 0; p < pointerCount; p++) {
                if (p != event.getActionIndex()) {
                    if (event.getToolType(p) == MotionEvent.TOOL_TYPE_FINGER) {
                        addPointerForIndex(event, p, kPointerChangeMove, kPointerDataFlagBatched, packet);
                    }
                }
            }
            // It's important that we're sending the UP event last. This allows PlatformView
            // to correctly batch everything back into the original Android event if needed.
            addPointerForIndex(event, event.getActionIndex(), pointerChange, 0, packet);
        } else {
            // ACTION_MOVE may not actually mean all pointers have moved
            // but it's the responsibility of a later part of the system to
            // ignore 0-deltas if desired.
            for (int p = 0; p < pointerCount; p++) {
                addPointerForIndex(event, p, pointerChange, 0, packet);
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

    // TODO(garyq): Add support for notch cutout API
    // Decide if we want to zero the padding of the sides. When in Landscape orientation,
    // android may decide to place the software navigation bars on the side. When the nav
    // bar is hidden, the reported insets should be removed to prevent extra useless space
    // on the sides.
    enum ZeroSides { NONE, LEFT, RIGHT, BOTH }
    ZeroSides calculateShouldZeroSides() {
        // We get both orientation and rotation because rotation is all 4
        // rotations relative to default rotation while orientation is portrait
        // or landscape. By combining both, we can obtain a more precise measure
        // of the rotation.
        Activity activity = (Activity)getContext();
        int orientation = activity.getResources().getConfiguration().orientation;
        int rotation = activity.getWindowManager().getDefaultDisplay().getRotation();

        if (orientation == Configuration.ORIENTATION_LANDSCAPE) {
            if (rotation == Surface.ROTATION_90) {
                return ZeroSides.RIGHT;
            }
            else if (rotation == Surface.ROTATION_270) {
                // In android API >= 23, the nav bar always appears on the "bottom" (USB) side.
                return Build.VERSION.SDK_INT >= 23 ? ZeroSides.LEFT : ZeroSides.RIGHT;
            }
            // Ambiguous orientation due to landscape left/right default. Zero both sides.
            else if (rotation == Surface.ROTATION_0 || rotation == Surface.ROTATION_180) {
                return ZeroSides.BOTH;
            }
        }
        // Square orientation deprecated in API 16, we will not check for it and return false
        // to be safe and not remove any unique padding for the devices that do use it.
        return ZeroSides.NONE;
    }

    // TODO(garyq): Use clean ways to detect keyboard instead of heuristics if possible
    // TODO(garyq): The keyboard detection may interact strangely with
    //   https://github.com/flutter/flutter/issues/22061

    // Uses inset heights and screen heights as a heuristic to determine if the insets should
    // be padded. When the on-screen keyboard is detected, we want to include the full inset
    // but when the inset is just the hidden nav bar, we want to provide a zero inset so the space
    // can be used.
    int calculateBottomKeyboardInset(WindowInsets insets) {
        int screenHeight = getRootView().getHeight();
        // Magic number due to this being a heuristic. This should be replaced, but we have not
        // found a clean way to do it yet (Sept. 2018)
        final double keyboardHeightRatioHeuristic = 0.18;
        if (insets.getSystemWindowInsetBottom() < screenHeight * keyboardHeightRatioHeuristic) {
            // Is not a keyboard, so return zero as inset.
            return 0;
        }
        else {
            // Is a keyboard, so return the full inset.
            return insets.getSystemWindowInsetBottom();
        }
    }

    // This callback is not present in API < 20, which means lower API devices will see
    // the wider than expected padding when the status and navigation bars are hidden.
    @Override
    public final WindowInsets onApplyWindowInsets(WindowInsets insets) {
        boolean statusBarHidden =
            (SYSTEM_UI_FLAG_FULLSCREEN & getWindowSystemUiVisibility()) != 0;
        boolean navigationBarHidden =
            (SYSTEM_UI_FLAG_HIDE_NAVIGATION & getWindowSystemUiVisibility()) != 0;

        // We zero the left and/or right sides to prevent the padding the
        // navigation bar would have caused.
        ZeroSides zeroSides = ZeroSides.NONE;
        if (navigationBarHidden) {
            zeroSides = calculateShouldZeroSides();
        }

        // The padding on top should be removed when the statusbar is hidden.
        mMetrics.physicalPaddingTop = statusBarHidden ? 0 : insets.getSystemWindowInsetTop();
        mMetrics.physicalPaddingRight =
            zeroSides == ZeroSides.RIGHT || zeroSides == ZeroSides.BOTH ? 0 : insets.getSystemWindowInsetRight();
        mMetrics.physicalPaddingBottom = 0;
        mMetrics.physicalPaddingLeft =
            zeroSides == ZeroSides.LEFT || zeroSides == ZeroSides.BOTH ? 0 : insets.getSystemWindowInsetLeft();

        // Bottom system inset (keyboard) should adjust scrollable bottom edge (inset).
        mMetrics.physicalViewInsetTop = 0;
        mMetrics.physicalViewInsetRight = 0;
        // We perform hidden navbar and keyboard handling if the navbar is set to hidden. Otherwise,
        // the navbar padding should always be provided.
        mMetrics.physicalViewInsetBottom =
            navigationBarHidden ? calculateBottomKeyboardInset(insets) : insets.getSystemWindowInsetBottom();
        mMetrics.physicalViewInsetLeft = 0;
        updateViewportMetrics();
        return super.onApplyWindowInsets(insets);
    }

    @Override
    @SuppressWarnings("deprecation")
    protected boolean fitSystemWindows(Rect insets) {
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.KITKAT) {
            // Status bar, left/right system insets partially obscure content (padding).
            mMetrics.physicalPaddingTop = insets.top;
            mMetrics.physicalPaddingRight = insets.right;
            mMetrics.physicalPaddingBottom = 0;
            mMetrics.physicalPaddingLeft = insets.left;

            // Bottom system inset (keyboard) should adjust scrollable bottom edge (inset).
            mMetrics.physicalViewInsetTop = 0;
            mMetrics.physicalViewInsetRight = 0;
            mMetrics.physicalViewInsetBottom = insets.bottom;
            mMetrics.physicalViewInsetLeft = 0;
            updateViewportMetrics();
            return true;
        } else {
            return super.fitSystemWindows(insets);
        }
    }

    private boolean isAttached() {
        return mNativeView != null && mNativeView.isAttached();
    }

    void assertAttached() {
        if (!isAttached())
            throw new AssertionError("Platform view is not attached");
    }

    private void preRun() {
        resetAccessibilityTree();
    }

    private void postRun() {
    }

    public void runFromBundle(FlutterRunArguments args) {
      assertAttached();
      preRun();
      mNativeView.runFromBundle(args);
      postRun();
    }

    /**
     * @deprecated
     * Please use runFromBundle with `FlutterRunArguments`.
     */
    @Deprecated
    public void runFromBundle(String bundlePath, String defaultPath) {
        runFromBundle(bundlePath, defaultPath, "main", false);
    }

    /**
     * @deprecated
     * Please use runFromBundle with `FlutterRunArguments`.
     */
    @Deprecated
    public void runFromBundle(String bundlePath, String defaultPath, String entrypoint) {
        runFromBundle(bundlePath, defaultPath, entrypoint, false);
    }

    /**
     * @deprecated
     * Please use runFromBundle with `FlutterRunArguments`.
     * Parameter `reuseRuntimeController` has no effect.
     */
    @Deprecated
    public void runFromBundle(String bundlePath, String defaultPath, String entrypoint, boolean reuseRuntimeController) {
        FlutterRunArguments args = new FlutterRunArguments();
        args.bundlePath = bundlePath;
        args.entrypoint = entrypoint;
        args.defaultPath = defaultPath;
        runFromBundle(args);
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

    private static native void nativeSurfaceCreated(long nativePlatformViewAndroid, Surface surface);

    private static native void nativeSurfaceChanged(long nativePlatformViewAndroid, int width, int height);

    private static native void nativeSurfaceDestroyed(long nativePlatformViewAndroid);

    private static native void nativeSetViewportMetrics(long nativePlatformViewAndroid, float devicePixelRatio,
            int physicalWidth, int physicalHeight, int physicalPaddingTop, int physicalPaddingRight,
            int physicalPaddingBottom, int physicalPaddingLeft, int physicalViewInsetTop, int physicalViewInsetRight,
            int physicalViewInsetBottom, int physicalViewInsetLeft);

    private static native Bitmap nativeGetBitmap(long nativePlatformViewAndroid);

    private static native void nativeDispatchPointerDataPacket(long nativePlatformViewAndroid, ByteBuffer buffer,
            int position);

    private static native void nativeDispatchSemanticsAction(long nativePlatformViewAndroid, int id, int action,
            ByteBuffer args, int argsPosition);

    private static native void nativeSetSemanticsEnabled(long nativePlatformViewAndroid, boolean enabled);

    private static native void nativeSetAccessibilityFeatures(long nativePlatformViewAndroid, int flags);

    private static native boolean nativeGetIsSoftwareRenderingEnabled();

    private static native void nativeRegisterTexture(long nativePlatformViewAndroid, long textureId,
            SurfaceTexture surfaceTexture);

    private static native void nativeMarkTextureFrameAvailable(long nativePlatformViewAndroid, long textureId);

    private static native void nativeUnregisterTexture(long nativePlatformViewAndroid, long textureId);

    private void updateViewportMetrics() {
        if (!isAttached())
            return;
        nativeSetViewportMetrics(mNativeView.get(), mMetrics.devicePixelRatio, mMetrics.physicalWidth,
                mMetrics.physicalHeight, mMetrics.physicalPaddingTop, mMetrics.physicalPaddingRight,
                mMetrics.physicalPaddingBottom, mMetrics.physicalPaddingLeft, mMetrics.physicalViewInsetTop,
                mMetrics.physicalViewInsetRight, mMetrics.physicalViewInsetBottom, mMetrics.physicalViewInsetLeft);

        WindowManager wm = (WindowManager) getContext().getSystemService(Context.WINDOW_SERVICE);
        float fps = wm.getDefaultDisplay().getRefreshRate();
        VsyncWaiter.refreshPeriodNanos = (long) (1000000000.0 / fps);
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

    public void updateCustomAccessibilityActions(ByteBuffer buffer, String[] strings) {
        try {
            if (mAccessibilityNodeProvider != null) {
                buffer.order(ByteOrder.LITTLE_ENDIAN);
                mAccessibilityNodeProvider.updateCustomAccessibilityActions(buffer, strings);
            }
        } catch (Exception ex) {
            Log.e(TAG, "Uncaught exception while updating local context actions", ex);
        }
    }

    // Called by native to notify first Flutter frame rendered.
    public void onFirstFrame() {
        // Allow listeners to remove themselves when they are called.
        List<FirstFrameListener> listeners = new ArrayList<>(mFirstFrameListeners);
        for (FirstFrameListener listener : listeners) {
            listener.onFirstFrame();
        }
    }

    // ACCESSIBILITY

    private boolean mAccessibilityEnabled = false;
    private boolean mTouchExplorationEnabled = false;
    private int mAccessibilityFeatureFlags = 0;
    private TouchExplorationListener mTouchExplorationListener;

    protected void dispatchSemanticsAction(int id, AccessibilityBridge.Action action) {
        dispatchSemanticsAction(id, action, null);
    }

    protected void dispatchSemanticsAction(int id, AccessibilityBridge.Action action, Object args) {
        if (!isAttached())
            return;
        ByteBuffer encodedArgs = null;
        int position = 0;
        if (args != null) {
            encodedArgs = StandardMessageCodec.INSTANCE.encodeMessage(args);
            position = encodedArgs.position();
        }
        nativeDispatchSemanticsAction(mNativeView.get(), id, action.value, encodedArgs, position);
    }

    @Override
    protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        mAccessibilityEnabled = mAccessibilityManager.isEnabled();
        mTouchExplorationEnabled = mAccessibilityManager.isTouchExplorationEnabled();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            Uri transitionUri = Settings.Global.getUriFor(Settings.Global.TRANSITION_ANIMATION_SCALE);
            getContext().getContentResolver().registerContentObserver(transitionUri, false, mAnimationScaleObserver);
        }

        if (mAccessibilityEnabled || mTouchExplorationEnabled) {
            ensureAccessibilityEnabled();
        }
        if (mTouchExplorationEnabled) {
            mAccessibilityFeatureFlags |= AccessibilityFeature.ACCESSIBLE_NAVIGATION.value;
        } else {
            mAccessibilityFeatureFlags &= ~AccessibilityFeature.ACCESSIBLE_NAVIGATION.value;
        }
        // Apply additional accessibility settings
        updateAccessibilityFeatures();
        resetWillNotDraw();
        mAccessibilityManager.addAccessibilityStateChangeListener(this);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            if (mTouchExplorationListener == null) {
                mTouchExplorationListener = new TouchExplorationListener();
            }
            mAccessibilityManager.addTouchExplorationStateChangeListener(mTouchExplorationListener);
        }
    }

    private void updateAccessibilityFeatures() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            String transitionAnimationScale = Settings.Global.getString(getContext().getContentResolver(),
                Settings.Global.TRANSITION_ANIMATION_SCALE);
            if (transitionAnimationScale != null && transitionAnimationScale.equals("0")) {
                mAccessibilityFeatureFlags |= AccessibilityFeature.DISABLE_ANIMATIONS.value;
            } else {
                mAccessibilityFeatureFlags &= ~AccessibilityFeature.DISABLE_ANIMATIONS.value;
            }
        }
        nativeSetAccessibilityFeatures(mNativeView.get(), mAccessibilityFeatureFlags);
    }

    @Override
    protected void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        getContext().getContentResolver().unregisterContentObserver(mAnimationScaleObserver);
        mAccessibilityManager.removeAccessibilityStateChangeListener(this);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            mAccessibilityManager.removeTouchExplorationStateChangeListener(mTouchExplorationListener);
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
            nativeSetSemanticsEnabled(mNativeView.get(), false);
        }
        resetWillNotDraw();
    }

    /// Must match the enum defined in window.dart.
    private enum AccessibilityFeature {
        ACCESSIBLE_NAVIGATION(1 << 0),
        INVERT_COLORS(1 << 1), // NOT SUPPORTED
        DISABLE_ANIMATIONS(1 << 2);

        AccessibilityFeature(int value) {
            this.value = value;
        }

        final int value;
    }

    // Listens to the global TRANSITION_ANIMATION_SCALE property and notifies us so
    // that we can disable animations in Flutter.
    private class AnimationScaleObserver extends ContentObserver {
        public AnimationScaleObserver(Handler handler) {
            super(handler);
        }

        @Override
        public void onChange(boolean selfChange) {
            this.onChange(selfChange, null);
        }

        @Override
        public void onChange(boolean selfChange, Uri uri) {
            String value = Settings.Global.getString(getContext().getContentResolver(),
                    Settings.Global.TRANSITION_ANIMATION_SCALE);
            if (value != null && value.equals("0")) {
                mAccessibilityFeatureFlags |= AccessibilityFeature.DISABLE_ANIMATIONS.value;
            } else {
                mAccessibilityFeatureFlags &= ~AccessibilityFeature.DISABLE_ANIMATIONS.value;
            }
            nativeSetAccessibilityFeatures(mNativeView.get(), mAccessibilityFeatureFlags);
        }
    }

    class TouchExplorationListener implements AccessibilityManager.TouchExplorationStateChangeListener {
        @Override
        public void onTouchExplorationStateChanged(boolean enabled) {
            if (enabled) {
                mTouchExplorationEnabled = true;
                ensureAccessibilityEnabled();
                mAccessibilityFeatureFlags |= AccessibilityFeature.ACCESSIBLE_NAVIGATION.value;
                nativeSetAccessibilityFeatures(mNativeView.get(), mAccessibilityFeatureFlags);
            } else {
                mTouchExplorationEnabled = false;
                if (mAccessibilityNodeProvider != null) {
                    mAccessibilityNodeProvider.handleTouchExplorationExit();
                }
                mAccessibilityFeatureFlags &= ~AccessibilityFeature.ACCESSIBLE_NAVIGATION.value;
                nativeSetAccessibilityFeatures(mNativeView.get(), mAccessibilityFeatureFlags);
            }
            resetWillNotDraw();
        }
    }

    @Override
    public AccessibilityNodeProvider getAccessibilityNodeProvider() {
        if (mAccessibilityEnabled)
            return mAccessibilityNodeProvider;
        // TODO(goderbauer): when a11y is off this should return a one-off snapshot of
        // the a11y
        // tree.
        return null;
    }

    private AccessibilityBridge mAccessibilityNodeProvider;

    void ensureAccessibilityEnabled() {
        if (!isAttached())
            return;
        mAccessibilityEnabled = true;
        if (mAccessibilityNodeProvider == null) {
            mAccessibilityNodeProvider = new AccessibilityBridge(this);
        }
        nativeSetSemanticsEnabled(mNativeView.get(), true);
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
        if (event.getAction() == MotionEvent.ACTION_HOVER_ENTER || event.getAction() == MotionEvent.ACTION_HOVER_MOVE) {
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
            Log.d(TAG, "FlutterView.send called on a detached view, channel=" + channel);
            return;
        }
        mNativeView.send(channel, message, callback);
    }

    @Override
    public void setMessageHandler(String channel, BinaryMessageHandler handler) {
        mNativeView.setMessageHandler(channel, handler);
    }

    /**
     * Listener will be called on the Android UI thread once when Flutter renders
     * the first frame.
     */
    public interface FirstFrameListener {
        void onFirstFrame();
    }

    @Override
    public TextureRegistry.SurfaceTextureEntry createSurfaceTexture() {
        final SurfaceTexture surfaceTexture = new SurfaceTexture(0);
        surfaceTexture.detachFromGLContext();
        final SurfaceTextureRegistryEntry entry = new SurfaceTextureRegistryEntry(nextTextureId.getAndIncrement(),
                surfaceTexture);
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

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                // The callback relies on being executed on the UI thread (unsynchronised read of mNativeView
                // and also the engine code check for platform thread in Shell::OnPlatformViewMarkTextureFrameAvailable),
                // so we explicitly pass a Handler for the current thread.
                this.surfaceTexture.setOnFrameAvailableListener(onFrameListener, new Handler());
            } else {
                // Android documentation states that the listener can be called on an arbitrary thread.
                // But in practice, versions of Android that predate the newer API will call the listener
                // on the thread where the SurfaceTexture was constructed.
                this.surfaceTexture.setOnFrameAvailableListener(onFrameListener);
            }
        }

        private SurfaceTexture.OnFrameAvailableListener onFrameListener = new SurfaceTexture.OnFrameAvailableListener() {
            @Override
            public void onFrameAvailable(SurfaceTexture texture) {
                if (released) {
                    // Even though we make sure to unregister the callback before releasing, as of Android O
                    // SurfaceTexture has a data race when accessing the callback, so the callback may
                    // still be called by a stale reference after released==true and mNativeView==null.
                    return;
                }
                nativeMarkTextureFrameAvailable(mNativeView.get(), SurfaceTextureRegistryEntry.this.id);
            }
        };

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
            // Otherwise onFrameAvailableListener might be called after mNativeView==null
            // (https://github.com/flutter/flutter/issues/20951). See also the check in onFrameAvailable.
            surfaceTexture.setOnFrameAvailableListener(null);
            surfaceTexture.release();
        }
    }
}

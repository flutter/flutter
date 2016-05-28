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
import android.opengl.Matrix;
import android.graphics.Rect;
import android.os.Build;
import android.util.AttributeSet;
import android.util.Log;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.WindowInsets;
import android.view.accessibility.AccessibilityManager;
import android.view.accessibility.AccessibilityNodeInfo;
import android.view.accessibility.AccessibilityNodeProvider;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import org.json.JSONException;
import org.json.JSONObject;

import org.chromium.base.JNINamespace;
import org.chromium.mojo.bindings.Interface.Binding;
import org.chromium.mojo.bindings.InterfaceRequest;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojo.system.Pair;
import org.chromium.mojo.system.impl.CoreImpl;
import org.chromium.mojom.editing.Keyboard;
import org.chromium.mojom.flutter.platform.ApplicationMessages;
import org.chromium.mojom.mojo.ServiceProvider;
import org.chromium.mojom.pointer.Pointer;
import org.chromium.mojom.pointer.PointerKind;
import org.chromium.mojom.pointer.PointerPacket;
import org.chromium.mojom.pointer.PointerType;
import org.chromium.mojom.raw_keyboard.RawKeyboardService;
import org.chromium.mojom.semantics.SemanticsServer;
import org.chromium.mojom.sky.AppLifecycleState;
import org.chromium.mojom.sky.ServicesData;
import org.chromium.mojom.sky.SkyEngine;
import org.chromium.mojom.sky.ViewportMetrics;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import org.domokit.activity.ActivityImpl;
import org.domokit.editing.KeyboardImpl;
import org.domokit.editing.KeyboardViewState;
import org.domokit.raw_keyboard.RawKeyboardServiceImpl;
import org.domokit.raw_keyboard.RawKeyboardServiceState;

/**
 * An Android view containing a Flutter app.
 */
@JNINamespace("sky::shell")
public class FlutterView extends SurfaceView
  implements AccessibilityManager.AccessibilityStateChangeListener,
             AccessibilityManager.TouchExplorationStateChangeListener {
    private static final String TAG = "FlutterView";

    private static final String ACTION_DISCOVER = "io.flutter.view.DISCOVER";

    private long mNativePlatformView;
    private SkyEngine.Proxy mSkyEngine;
    private ServiceProviderImpl mPlatformServiceProvider;
    private Binding mPlatformServiceProviderBinding;
    private ServiceProviderImpl mViewServiceProvider;
    private Binding mViewServiceProviderBinding;
    private ServiceProvider.Proxy mDartServiceProvider;
    private ApplicationMessages.Proxy mFlutterAppMessages;
    private HashMap<String, OnMessageListener> mOnMessageListeners;
    private HashMap<String, OnMessageListenerAsync> mAsyncOnMessageListeners;
    private final SurfaceHolder.Callback mSurfaceCallback;
    private final ViewportMetrics mMetrics;
    private final KeyboardViewState mKeyboardState;
    private final RawKeyboardServiceState mRawKeyboardState;
    private final AccessibilityManager mAccessibilityManager;
    private BroadcastReceiver discoveryReceiver;

    public FlutterView(Context context) {
        this(context, null);
    }

    public FlutterView(Context context, AttributeSet attrs) {
        super(context, attrs);

        // TODO(abarth): Remove this static and instead make everything that
        // depends on it into a view-associated service.
        ActivityImpl.setCurrentActivity((Activity) context);

        mMetrics = new ViewportMetrics();
        mMetrics.devicePixelRatio = context.getResources().getDisplayMetrics().density;
        setFocusable(true);
        setFocusableInTouchMode(true);

        attach();
        assert mNativePlatformView != 0;

        mSurfaceCallback = new SurfaceHolder.Callback() {
            @Override
            public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
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

        mKeyboardState = new KeyboardViewState(this);
        mRawKeyboardState = new RawKeyboardServiceState();

        Core core = CoreImpl.getInstance();

        mPlatformServiceProvider = new ServiceProviderImpl(core, getContext(), ServiceRegistry.SHARED);

        ServiceRegistry localRegistry = new ServiceRegistry();
        configureLocalServices(localRegistry);
        mViewServiceProvider = new ServiceProviderImpl(core, getContext(), localRegistry);

        mAccessibilityManager = (AccessibilityManager)getContext().getSystemService(Context.ACCESSIBILITY_SERVICE);

        mOnMessageListeners = new HashMap<String, OnMessageListener>();
        mAsyncOnMessageListeners = new HashMap<String, OnMessageListenerAsync>();

        setLocale(getResources().getConfiguration().locale);

        if ((context.getApplicationInfo().flags & ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
            discoveryReceiver = new DiscoveryReceiver();
            context.registerReceiver(discoveryReceiver, new IntentFilter(ACTION_DISCOVER));
        }
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

    public void onPause() {
        mSkyEngine.onAppLifecycleStateChanged(AppLifecycleState.PAUSED);
    }

    public void onResume() {
    }

    public void onPostResume() {
        mSkyEngine.onAppLifecycleStateChanged(AppLifecycleState.RESUMED);
    }

    public void pushRoute(String route) {
        mSkyEngine.pushRoute(route);
    }

    public void popRoute() {
        mSkyEngine.popRoute();
    }

    private void setLocale(Locale locale) {
        mSkyEngine.onLocaleChanged(locale.getLanguage(), locale.getCountry());
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
        if (discoveryReceiver != null) {
            getContext().unregisterReceiver(discoveryReceiver);
        }

        if (mPlatformServiceProviderBinding != null) {
            mPlatformServiceProviderBinding.unbind().close();
            mPlatformServiceProvider.unbindServices();
        }

        if (mViewServiceProviderBinding != null) {
            mViewServiceProviderBinding.unbind().close();
            mViewServiceProvider.unbindServices();
        }

        getHolder().removeCallback(mSurfaceCallback);
        nativeDetach(mNativePlatformView);
        mNativePlatformView = 0;

        mSkyEngine.close();
        mDartServiceProvider.close();
        mFlutterAppMessages.close();
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

    @Override
    public boolean onHoverEvent(MotionEvent event) {
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
        mSkyEngine.onViewportMetricsChanged(mMetrics);
        super.onSizeChanged(width, height, oldWidth, oldHeight);
    }

    @Override
    public final WindowInsets onApplyWindowInsets(WindowInsets insets) {
        mMetrics.physicalPaddingTop = insets.getSystemWindowInsetTop();
        mMetrics.physicalPaddingRight = insets.getSystemWindowInsetRight();
        mMetrics.physicalPaddingBottom = insets.getSystemWindowInsetBottom();
        mMetrics.physicalPaddingLeft = insets.getSystemWindowInsetLeft();
        mSkyEngine.onViewportMetricsChanged(mMetrics);
        return super.onApplyWindowInsets(insets);
    }

    private void configureLocalServices(ServiceRegistry registry) {
        registry.register(Keyboard.MANAGER.getName(), new ServiceFactory() {
            @Override
            public Binding connectToService(Context context, Core core, MessagePipeHandle pipe) {
                return Keyboard.MANAGER.bind(new KeyboardImpl(context, mKeyboardState), pipe);
            }
        });

        registry.register(RawKeyboardService.MANAGER.getName(), new ServiceFactory() {
            @Override
            public Binding connectToService(Context context, Core core, MessagePipeHandle pipe) {
                return RawKeyboardService.MANAGER.bind(new RawKeyboardServiceImpl(mRawKeyboardState), pipe);
            }
        });

        registry.register(ApplicationMessages.MANAGER.getName(), new ServiceFactory() {
            @Override
            public Binding connectToService(Context context, Core core, MessagePipeHandle pipe) {
                return ApplicationMessages.MANAGER.bind(new ApplicationMessagesImpl(), pipe);
            }
        });
    }

    private void attach() {
        Core core = CoreImpl.getInstance();
        Pair<SkyEngine.Proxy, InterfaceRequest<SkyEngine>> engine =
                SkyEngine.MANAGER.getInterfaceRequest(core);
        mSkyEngine = engine.first;
        mNativePlatformView = nativeAttach(engine.second.passHandle().releaseNativeHandle());
    }

    public void runFromBundle(String bundlePath, String snapshotPath) {
        if (mPlatformServiceProviderBinding != null) {
            mPlatformServiceProviderBinding.unbind().close();
            mPlatformServiceProvider.unbindServices();
        }
        if (mViewServiceProviderBinding != null) {
            mViewServiceProviderBinding.unbind().close();
            mViewServiceProvider.unbindServices();
        }
        if (mDartServiceProvider != null) {
            mDartServiceProvider.close();
        }

        Core core = CoreImpl.getInstance();

        Pair<ServiceProvider.Proxy, InterfaceRequest<ServiceProvider>> dartServiceProvider =
                ServiceProvider.MANAGER.getInterfaceRequest(core);
        mDartServiceProvider = dartServiceProvider.first;

        Pair<ServiceProvider.Proxy, InterfaceRequest<ServiceProvider>> platformServiceProvider =
                ServiceProvider.MANAGER.getInterfaceRequest(core);
        mPlatformServiceProviderBinding = ServiceProvider.MANAGER.bind(
                mPlatformServiceProvider, platformServiceProvider.second);

        Pair<ServiceProvider.Proxy, InterfaceRequest<ServiceProvider>> viewServiceProvider =
                ServiceProvider.MANAGER.getInterfaceRequest(core);
        mViewServiceProviderBinding = ServiceProvider.MANAGER.bind(
                mViewServiceProvider, viewServiceProvider.second);

        ServicesData services = new ServicesData();
        services.incomingServices = platformServiceProvider.first;
        services.outgoingServices = dartServiceProvider.second;
        services.viewServices = viewServiceProvider.first;
        mSkyEngine.setServices(services);

        resetAccessibilityTree();

        if (FlutterMain.isRunningPrecompiledCode()) {
            mSkyEngine.runFromPrecompiledSnapshot(bundlePath);
        } else {
            String scriptUri = "file://" + bundlePath;
            if (snapshotPath != null) {
                mSkyEngine.runFromBundleAndSnapshot(scriptUri, bundlePath, snapshotPath);
            } else {
                mSkyEngine.runFromBundle(scriptUri, bundlePath);
            }
        }

        // Connect to the ApplicationMessages service exported by the Flutter framework
        Pair<ApplicationMessages.Proxy, InterfaceRequest<ApplicationMessages>> appMessages =
                  ApplicationMessages.MANAGER.getInterfaceRequest(core);
        mDartServiceProvider.connectToService(ApplicationMessages.MANAGER.getName(),
                                              appMessages.second.passHandle());
        mFlutterAppMessages = appMessages.first;
    }

    private static native long nativeAttach(int inputObserverHandle);
    private static native int nativeGetObservatoryPort();
    private static native void nativeDetach(long nativePlatformViewAndroid);
    private static native void nativeSurfaceCreated(long nativePlatformViewAndroid,
                                                    Surface surface);
    private static native void nativeSurfaceDestroyed(long nativePlatformViewAndroid);


    // ACCESSIBILITY

    private boolean mAccessibilityEnabled = false;
    private boolean mTouchExplorationEnabled = false;

    @Override
    protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        mAccessibilityEnabled = mAccessibilityManager.isEnabled();
        mTouchExplorationEnabled = mAccessibilityManager.isTouchExplorationEnabled();
        if (mAccessibilityEnabled || mTouchExplorationEnabled)
          ensureAccessibilityEnabled();
        resetWillNotDraw();
        mAccessibilityManager.addAccessibilityStateChangeListener(this);
        mAccessibilityManager.addTouchExplorationStateChangeListener(this);
    }

    @Override
    protected void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        mAccessibilityManager.removeAccessibilityStateChangeListener(this);
        mAccessibilityManager.removeTouchExplorationStateChangeListener(this);
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

    @Override
    public AccessibilityNodeProvider getAccessibilityNodeProvider() {
        ensureAccessibilityEnabled();
        return mAccessibilityNodeProvider;
    }

    private AccessibilityBridge mAccessibilityNodeProvider;

    void ensureAccessibilityEnabled() {
        if (mAccessibilityNodeProvider == null) {
            mAccessibilityNodeProvider = new AccessibilityBridge(this, createSemanticsServer());
        }
    }

    private SemanticsServer.Proxy createSemanticsServer() {
        Core core = CoreImpl.getInstance();
        Pair<SemanticsServer.Proxy, InterfaceRequest<SemanticsServer>> server =
                  SemanticsServer.MANAGER.getInterfaceRequest(core);
        mDartServiceProvider.connectToService(SemanticsServer.MANAGER.getName(), server.second.passHandle());
        return server.first;
    }

    void resetAccessibilityTree() {
        if (mAccessibilityNodeProvider != null) {
            mAccessibilityNodeProvider.reset(createSemanticsServer());
        }
    }

    private boolean handleAccessibilityHoverEvent(MotionEvent event) {
        if (!mTouchExplorationEnabled)
            return false;
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
     * Send a message to the Flutter application.  The Flutter Dart code can register a
     * host message handler that will receive these messages.
     */
    public void sendToFlutter(String messageName, String message,
                              final MessageReplyCallback callback) {
        mFlutterAppMessages.sendString(messageName, message,
            new ApplicationMessages.SendStringResponse() {
                @Override
                public void call(String reply) {
                    if (callback != null) {
                        callback.onReply(reply);
                    }
                }
            });
    }

    public void sendToFlutter(String messageName, String message) {
        sendToFlutter(messageName, message, null);
    }

    /** Callback invoked when the app replies to a message sent with sendToFlutter. */
    public interface MessageReplyCallback {
        void onReply(String reply);
    }

    /**
     * Register a callback to be invoked when the Flutter application sends a message
     * to its host.
     */
    public void addOnMessageListener(String messageName, OnMessageListener listener) {
        mOnMessageListeners.put(messageName, listener);
    }

    /**
     * Register a callback to be invoked when the Flutter application sends a message
     * to its host.  The reply to the message can be provided asynchronously.
     */
    public void addOnMessageListenerAsync(String messageName, OnMessageListenerAsync listener) {
        mAsyncOnMessageListeners.put(messageName, listener);
    }

    public interface OnMessageListener {
        /**
         * Called when a message is received from the Flutter app.
         * @return the reply to the message (can be null)
         */
        String onMessage(String message);
    };

    public interface OnMessageListenerAsync {
        /**
         * Called when a message is received from the Flutter app.
         * @param response Used to send a reply back to the app.
         */
        void onMessage(String message, MessageResponse response);
    }

    public interface MessageResponse {
        void send(String reply);
    }

    private class ApplicationMessagesImpl implements ApplicationMessages {
        @Override
        public void close() {}

        @Override
        public void onConnectionError(MojoException e) {}

        @Override
        public void sendString(String messageName, String message, SendStringResponse callback) {
            OnMessageListener listener = mOnMessageListeners.get(messageName);
            if (listener != null) {
                callback.call(listener.onMessage(message));
                return;
            }

            OnMessageListenerAsync asyncListener = mAsyncOnMessageListeners.get(messageName);
            if (asyncListener != null) {
                asyncListener.onMessage(message, new MessageResponseAdapter(callback));
                return;
            }

            callback.call(null);
        }
    }

    /**
     * This class wraps the raw Mojo callback object in an interface that is owned
     * by Flutter and can be safely given to host apps.
     */
    private static class MessageResponseAdapter implements MessageResponse {
        private ApplicationMessages.SendStringResponse callback;

        MessageResponseAdapter(ApplicationMessages.SendStringResponse callback) {
            this.callback = callback;
        }

        @Override
        public void send(String reply) {
            callback.call(reply);
        }
    }

    /** Broadcast receiver used to discover active Flutter instances. */
    private class DiscoveryReceiver extends BroadcastReceiver {
        @Override
        public void onReceive(Context context, Intent intent) {
            JSONObject discover = new JSONObject();
            try {
                discover.put("id", getContext().getPackageName());
                discover.put("observatoryPort", nativeGetObservatoryPort());
                Log.i(TAG, "DISCOVER: " + discover);
            } catch (JSONException e) {}
        }
    }
}

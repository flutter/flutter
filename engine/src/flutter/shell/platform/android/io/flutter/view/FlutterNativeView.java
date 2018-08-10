// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.app.Activity;
import android.content.Context;
import android.util.Log;
import io.flutter.app.FlutterPluginRegistry;
import io.flutter.plugin.common.*;
import java.nio.ByteBuffer;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.HashMap;
import java.util.Map;
import android.content.res.AssetManager;

public class FlutterNativeView implements BinaryMessenger {
    private static final String TAG = "FlutterNativeView";

    private final Map<String, BinaryMessageHandler> mMessageHandlers;
    private int mNextReplyId = 1;
    private final Map<Integer, BinaryReply> mPendingReplies = new HashMap<>();

    private final FlutterPluginRegistry mPluginRegistry;
    private long mNativePlatformView;
    private FlutterView mFlutterView;
    private final Context mContext;
    private boolean applicationIsRunning;

    public FlutterNativeView(Context context) {
        this(context, false);
    }

    public FlutterNativeView(Context context, boolean isBackgroundView) {
        mContext = context;
        mPluginRegistry = new FlutterPluginRegistry(this, context);
        attach(this, isBackgroundView);
        assertAttached();
        mMessageHandlers = new HashMap<>();
    }

    public void detach() {
        mPluginRegistry.detach();
        mFlutterView = null;
        nativeDetach(mNativePlatformView);
    }

    public void destroy() {
        mPluginRegistry.destroy();
        mFlutterView = null;
        nativeDestroy(mNativePlatformView);
        mNativePlatformView = 0;
        applicationIsRunning = false;
    }

    public FlutterPluginRegistry getPluginRegistry() {
        return mPluginRegistry;
    }

    public void attachViewAndActivity(FlutterView flutterView, Activity activity) {
        mFlutterView = flutterView;
        mPluginRegistry.attach(flutterView, activity);
    }

    public boolean isAttached() {
        return mNativePlatformView != 0;
    }

    public long get() {
        return mNativePlatformView;
    }

    public void assertAttached() {
        if (!isAttached()) throw new AssertionError("Platform view is not attached");
    }

    public void runFromBundle(FlutterRunArguments args) {
        if (args.bundlePath == null) {
          throw new AssertionError("A bundlePath must be specified");
        } else if (args.entrypoint == null) {
          throw new AssertionError("An entrypoint must be specified");
        }
      runFromBundleInternal(args.bundlePath, args.entrypoint, args.libraryPath, args.defaultPath);
    }

    /**
     * @deprecated
     * Please use runFromBundle with `FlutterRunArguments`.
     * Parameter `reuseRuntimeController` has no effect.
     */
    @Deprecated
    public void runFromBundle(String bundlePath, String defaultPath, String entrypoint,
            boolean reuseRuntimeController) {
        runFromBundleInternal(bundlePath, entrypoint, null, defaultPath);
    }

    private void runFromBundleInternal(String bundlePath, String entrypoint,
        String libraryPath, String defaultPath) {
        assertAttached();
        if (applicationIsRunning)
            throw new AssertionError(
                    "This Flutter engine instance is already running an application");
        nativeRunBundleAndSnapshotFromLibrary(mNativePlatformView, bundlePath,
            defaultPath, entrypoint, libraryPath, mContext.getResources().getAssets());

        applicationIsRunning = true;
    }

    public boolean isApplicationRunning() {
        return applicationIsRunning;
    }

    public static String getObservatoryUri() {
        return nativeGetObservatoryUri();
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

        int replyId = 0;
        if (callback != null) {
            replyId = mNextReplyId++;
            mPendingReplies.put(replyId, callback);
        }
        if (message == null) {
            nativeDispatchEmptyPlatformMessage(mNativePlatformView, channel, replyId);
        } else {
            nativeDispatchPlatformMessage(
                    mNativePlatformView, channel, message, message.position(), replyId);
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

    private void attach(FlutterNativeView view, boolean isBackgroundView) {
        mNativePlatformView = nativeAttach(view, isBackgroundView);
    }

    // Called by native to send us a platform message.
    private void handlePlatformMessage(final String channel, byte[] message, final int replyId) {
        assertAttached();
        BinaryMessageHandler handler = mMessageHandlers.get(channel);
        if (handler != null) {
            try {
                final ByteBuffer buffer = (message == null ? null : ByteBuffer.wrap(message));
                handler.onMessage(buffer, new BinaryReply() {
                    private final AtomicBoolean done = new AtomicBoolean(false);
                    @Override
                    public void reply(ByteBuffer reply) {
                        if (!isAttached()) {
                            Log.d(TAG,
                                    "handlePlatformMessage replying to a detached view, channel="
                                            + channel);
                            return;
                        }
                        if (done.getAndSet(true)) {
                            throw new IllegalStateException("Reply already submitted");
                        }
                        if (reply == null) {
                            nativeInvokePlatformMessageEmptyResponseCallback(
                                    mNativePlatformView, replyId);
                        } else {
                            nativeInvokePlatformMessageResponseCallback(
                                    mNativePlatformView, replyId, reply, reply.position());
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
        if (mFlutterView == null) return;
        mFlutterView.updateSemantics(buffer, strings);
    }

    // Called by native to update the custom accessibility actions.
    private void updateCustomAccessibilityActions(ByteBuffer buffer, String[] strings) {
        if (mFlutterView == null)
            return;
        mFlutterView.updateCustomAccessibilityActions(buffer, strings);
    }

    // Called by native to notify first Flutter frame rendered.
    private void onFirstFrame() {
        if (mFlutterView == null) return;
        mFlutterView.onFirstFrame();
    }

    // Called by native to notify when the engine is restarted (cold reload).
    @SuppressWarnings("unused")
    private void onPreEngineRestart() {
        if (mPluginRegistry == null)
            return;
        mPluginRegistry.onPreEngineRestart();
    }

    private static native long nativeAttach(FlutterNativeView view, boolean isBackgroundView);
    private static native void nativeDestroy(long nativePlatformViewAndroid);
    private static native void nativeDetach(long nativePlatformViewAndroid);

    private static native void nativeRunBundleAndSnapshotFromLibrary(
            long nativePlatformViewAndroid, String bundlePath,
            String defaultPath, String entrypoint, String libraryUrl,
            AssetManager manager);

    private static native String nativeGetObservatoryUri();

    // Send an empty platform message to Dart.
    private static native void nativeDispatchEmptyPlatformMessage(
            long nativePlatformViewAndroid, String channel, int responseId);

    // Send a data-carrying platform message to Dart.
    private static native void nativeDispatchPlatformMessage(long nativePlatformViewAndroid,
            String channel, ByteBuffer message, int position, int responseId);

    // Send an empty response to a platform message received from Dart.
    private static native void nativeInvokePlatformMessageEmptyResponseCallback(
            long nativePlatformViewAndroid, int responseId);

    // Send a data-carrying response to a platform message received from Dart.
    private static native void nativeInvokePlatformMessageResponseCallback(
            long nativePlatformViewAndroid, int responseId, ByteBuffer message, int position);
}

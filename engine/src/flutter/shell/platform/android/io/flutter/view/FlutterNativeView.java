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

    public FlutterNativeView(Context context) {
        mContext = context;
        mPluginRegistry = new FlutterPluginRegistry(this, context);
        attach(this);
        assertAttached();
        mMessageHandlers = new HashMap<>();
    }

    public void detach() {
        mPluginRegistry.detach();
        mFlutterView = null;
        nativeDetach(mNativePlatformView);
    }

    public void destroy() {
        mFlutterView = null;
        nativeDestroy(mNativePlatformView);
        mNativePlatformView = 0;
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
        if (!isAttached())
            throw new AssertionError("Platform view is not attached");
    }

    public void runFromBundle(String bundlePath, String snapshotOverride, String entrypoint, boolean reuseRuntimeController) {
        assertAttached();
        nativeRunBundleAndSnapshot(mNativePlatformView, bundlePath, snapshotOverride, entrypoint, reuseRuntimeController, mContext.getResources().getAssets());
    }

    public void runFromSource(final String assetsDirectory, final String main, final String packages) {
        assertAttached();
        nativeRunBundleAndSource(mNativePlatformView, assetsDirectory, main, packages);
    }

    public void setAssetBundlePathOnUI(final String assetsDirectory) {
        assertAttached();
        nativeSetAssetBundlePathOnUI(mNativePlatformView, assetsDirectory);
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

    private void attach(FlutterNativeView view) {
        mNativePlatformView = nativeAttach(view);
    }

    // Called by native to send us a platform message.
    private void handlePlatformMessage(final String channel, byte[] message, final int replyId) {
        // The platform may not be attached immediately in certain cases where a new bundle is run -
        // the native view is created in a separate thread. This mostly happens when the app restarts in dev
        // mode when switching into split-screen mode. Preventing app restarts on layout and density
        // changes will prevent this, and afterwards this can be changed back to an assert.
        if (!isAttached()) {
            Log.d(TAG, "PlatformView is not attached");
            return;
        }
        BinaryMessageHandler handler = mMessageHandlers.get(channel);
        if (handler != null) {
            try {
                final ByteBuffer buffer = (message == null ? null : ByteBuffer.wrap(message));
                handler.onMessage(buffer,
                    new BinaryReply() {
                        private final AtomicBoolean done = new AtomicBoolean(false);
                        @Override
                        public void reply(ByteBuffer reply) {
                            if (!isAttached()) {
                                Log.d(TAG, "handlePlatformMessage replying to a detached view, channel=" + channel);
                                return;
                            }
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
        if (mFlutterView == null)
            return;
        mFlutterView.updateSemantics(buffer, strings);
    }

    // Called by native to notify first Flutter frame rendered.
    private void onFirstFrame() {
        if (mFlutterView == null)
            return;
        mFlutterView.onFirstFrame();
    }

    private static native long nativeAttach(FlutterNativeView view);
    private static native void nativeDestroy(long nativePlatformViewAndroid);
    private static native void nativeDetach(long nativePlatformViewAndroid);

    private static native void nativeRunBundleAndSnapshot(long nativePlatformViewAndroid,
        String bundlePath,
        String snapshotOverride,
        String entrypoint,
        boolean reuseRuntimeController,
        AssetManager manager);

    private static native void nativeRunBundleAndSource(long nativePlatformViewAndroid,
        String bundlePath,
        String main,
        String packages);

    private static native void nativeSetAssetBundlePathOnUI(long nativePlatformViewAndroid,
        String bundlePath);

    private static native String nativeGetObservatoryUri();

    // Send an empty platform message to Dart.
    private static native void nativeDispatchEmptyPlatformMessage(long nativePlatformViewAndroid,
        String channel, int responseId);

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

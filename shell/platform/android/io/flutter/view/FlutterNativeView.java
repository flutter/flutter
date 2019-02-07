// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.app.Activity;
import android.content.Context;
import android.util.Log;
import io.flutter.app.FlutterPluginRegistry;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.FlutterEngine.EngineLifecycleListener;
import io.flutter.embedding.engine.renderer.FlutterRenderer.RenderSurface;
import io.flutter.plugin.common.*;
import java.nio.ByteBuffer;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.dart.PlatformMessageHandler;

public class FlutterNativeView implements BinaryMessenger {
    private static final String TAG = "FlutterNativeView";

    private final Map<String, BinaryMessageHandler> mMessageHandlers;
    private int mNextReplyId = 1;
    private final Map<Integer, BinaryReply> mPendingReplies = new HashMap<>();

    private final FlutterPluginRegistry mPluginRegistry;
    private FlutterView mFlutterView;
    private FlutterJNI mFlutterJNI;
    private final Context mContext;
    private boolean applicationIsRunning;

    public FlutterNativeView(Context context) {
        this(context, false);
    }

    public FlutterNativeView(Context context, boolean isBackgroundView) {
        mContext = context;
        mPluginRegistry = new FlutterPluginRegistry(this, context);
        mFlutterJNI = new FlutterJNI();
        mFlutterJNI.setRenderSurface(new RenderSurfaceImpl());
        mFlutterJNI.setPlatformMessageHandler(new PlatformMessageHandlerImpl());
        mFlutterJNI.addEngineLifecycleListener(new EngineLifecycleListenerImpl());
        attach(this, isBackgroundView);
        assertAttached();
        mMessageHandlers = new HashMap<>();
    }

    public void detach() {
        mPluginRegistry.detach();
        mFlutterView = null;
        mFlutterJNI.detachFromNativeButKeepNativeResources();
    }

    public void destroy() {
        mPluginRegistry.destroy();
        mFlutterView = null;
        mFlutterJNI.detachFromNativeAndReleaseResources();
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
        return mFlutterJNI.isAttached();
    }

    public void assertAttached() {
        if (!isAttached()) throw new AssertionError("Platform view is not attached");
    }

    public void runFromBundle(FlutterRunArguments args) {
        boolean hasBundlePaths = args.bundlePaths != null && args.bundlePaths.length != 0;
        if (args.bundlePath == null && !hasBundlePaths) {
            throw new AssertionError("Either bundlePath or bundlePaths must be specified");
        } else if ((args.bundlePath != null || args.defaultPath != null) &&
                hasBundlePaths) {
            throw new AssertionError("Can't specify both bundlePath and bundlePaths");
        } else if (args.entrypoint == null) {
            throw new AssertionError("An entrypoint must be specified");
        }
        if (hasBundlePaths) {
            runFromBundleInternal(args.bundlePaths, args.entrypoint, args.libraryPath);
        } else {
            runFromBundleInternal(new String[] {args.bundlePath, args.defaultPath},
                    args.entrypoint, args.libraryPath);
        }
    }

    /**
     * @deprecated
     * Please use runFromBundle with `FlutterRunArguments`.
     * Parameter `reuseRuntimeController` has no effect.
     */
    @Deprecated
    public void runFromBundle(String bundlePath, String defaultPath, String entrypoint,
            boolean reuseRuntimeController) {
        runFromBundleInternal(new String[] {bundlePath, defaultPath}, entrypoint, null);
    }

    private void runFromBundleInternal(String[] bundlePaths, String entrypoint,
        String libraryPath) {
        assertAttached();
        if (applicationIsRunning)
            throw new AssertionError(
                    "This Flutter engine instance is already running an application");
        mFlutterJNI.runBundleAndSnapshotFromLibrary(
            bundlePaths,
            entrypoint,
            libraryPath,
            mContext.getResources().getAssets()
        );

        applicationIsRunning = true;
    }

    public boolean isApplicationRunning() {
        return applicationIsRunning;
    }

    public static String getObservatoryUri() {
        return FlutterJNI.nativeGetObservatoryUri();
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
            mFlutterJNI.dispatchEmptyPlatformMessage(channel, replyId);
        } else {
            mFlutterJNI.dispatchPlatformMessage(
                channel,
                message,
                message.position(),
                replyId
            );
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

    /*package*/ FlutterJNI getFlutterJNI() {
        return mFlutterJNI;
    }

    private void attach(FlutterNativeView view, boolean isBackgroundView) {
        mFlutterJNI.attachToNative(isBackgroundView);
    }

    private final class PlatformMessageHandlerImpl implements PlatformMessageHandler {
        // Called by native to send us a platform message.
        public void handleMessageFromDart(final String channel, byte[] message, final int replyId) {
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
                                Log.d(TAG, "handleMessageFromDart replying ot a detached view, channel=" + channel);
                                return;
                            }
                            if (done.getAndSet(true)) {
                                throw new IllegalStateException("Reply already submitted");
                            }
                            if (reply == null) {
                                mFlutterJNI.invokePlatformMessageEmptyResponseCallback(replyId);
                            } else {
                                mFlutterJNI.invokePlatformMessageResponseCallback(replyId, reply, reply.position());
                            }
                        }
                    });
                } catch (Exception exception) {
                    Log.e(TAG, "Uncaught exception in binary message listener", exception);
                    mFlutterJNI.invokePlatformMessageEmptyResponseCallback(replyId);
                }
                return;
            }
            mFlutterJNI.invokePlatformMessageEmptyResponseCallback(replyId);
        }

        // Called by native to respond to a platform message that we sent.
        public void handlePlatformMessageResponse(int replyId, byte[] reply) {
            BinaryReply callback = mPendingReplies.remove(replyId);
            if (callback != null) {
                try {
                    callback.reply(reply == null ? null : ByteBuffer.wrap(reply));
                } catch (Exception ex) {
                    Log.e(TAG, "Uncaught exception in binary message reply handler", ex);
                }
            }
        }
    }

    private final class RenderSurfaceImpl implements RenderSurface {
        // Called by native to update the semantics/accessibility tree.
        public void updateSemantics(ByteBuffer buffer, String[] strings) {
            if (mFlutterView == null) {
                return;
            }
            mFlutterView.updateSemantics(buffer, strings);
        }

        // Called by native to update the custom accessibility actions.
        public void updateCustomAccessibilityActions(ByteBuffer buffer, String[] strings) {
            if (mFlutterView == null) {
                return;
            }
            mFlutterView.updateCustomAccessibilityActions(buffer, strings);
        }

        // Called by native to notify first Flutter frame rendered.
        public void onFirstFrameRendered() {
            if (mFlutterView == null) {
                return;
            }
            mFlutterView.onFirstFrame();
        }
    }

    private final class EngineLifecycleListenerImpl implements EngineLifecycleListener {
        // Called by native to notify when the engine is restarted (cold reload).
        @SuppressWarnings("unused")
        public void onPreEngineRestart() {
            if (mFlutterView != null) {
                mFlutterView.resetAccessibilityTree();
            }
            if (mPluginRegistry == null) {
                return;
            }
            mPluginRegistry.onPreEngineRestart();
        }
    }
}

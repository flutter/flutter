// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.app.Activity;
import android.content.Context;
import android.support.annotation.NonNull;
import android.support.annotation.UiThread;
import android.util.Log;
import io.flutter.app.FlutterPluginRegistry;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.FlutterEngine.EngineLifecycleListener;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.renderer.FlutterRenderer.RenderSurface;
import io.flutter.embedding.engine.renderer.OnFirstFrameRenderedListener;
import io.flutter.plugin.common.*;
import java.nio.ByteBuffer;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.dart.PlatformMessageHandler;

public class FlutterNativeView implements BinaryMessenger {
    private static final String TAG = "FlutterNativeView";

    private final FlutterPluginRegistry mPluginRegistry;
    private final DartExecutor dartExecutor;
    private FlutterView mFlutterView;
    private final FlutterJNI mFlutterJNI;
    private final Context mContext;
    private boolean applicationIsRunning;

    public FlutterNativeView(@NonNull Context context) {
        this(context, false);
    }

    public FlutterNativeView(@NonNull Context context, boolean isBackgroundView) {
        mContext = context;
        mPluginRegistry = new FlutterPluginRegistry(this, context);
        mFlutterJNI = new FlutterJNI();
        mFlutterJNI.setRenderSurface(new RenderSurfaceImpl());
        this.dartExecutor = new DartExecutor(mFlutterJNI, context.getAssets());
        mFlutterJNI.addEngineLifecycleListener(new EngineLifecycleListenerImpl());
        attach(this, isBackgroundView);
        assertAttached();
    }

    public void detachFromFlutterView() {
        mPluginRegistry.detach();
        mFlutterView = null;
    }

    public void destroy() {
        mPluginRegistry.destroy();
        dartExecutor.onDetachedFromJNI();
        mFlutterView = null;
        mFlutterJNI.detachFromNativeAndReleaseResources();
        applicationIsRunning = false;
    }

    @NonNull
    public DartExecutor getDartExecutor() {
        return dartExecutor;
    }

    @NonNull
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
        if (args.entrypoint == null) {
            throw new AssertionError("An entrypoint must be specified");
        }
        assertAttached();
        if (applicationIsRunning)
            throw new AssertionError(
                    "This Flutter engine instance is already running an application");
        mFlutterJNI.runBundleAndSnapshotFromLibrary(
            args.bundlePath,
            args.entrypoint,
            args.libraryPath,
            mContext.getResources().getAssets()
        );

        applicationIsRunning = true;
    }

    public boolean isApplicationRunning() {
        return applicationIsRunning;
    }

    public static String getObservatoryUri() {
        return FlutterJNI.getObservatoryUri();
    }

    @Override
    @UiThread
    public void send(String channel, ByteBuffer message) {
        dartExecutor.send(channel, message);
    }

    @Override
    @UiThread
    public void send(String channel, ByteBuffer message, BinaryReply callback) {
        if (!isAttached()) {
            Log.d(TAG, "FlutterView.send called on a detached view, channel=" + channel);
            return;
        }

        dartExecutor.send(channel, message, callback);
    }

    @Override
    @UiThread
    public void setMessageHandler(String channel, BinaryMessageHandler handler) {
        dartExecutor.setMessageHandler(channel, handler);
    }

    /*package*/ FlutterJNI getFlutterJNI() {
        return mFlutterJNI;
    }

    private void attach(FlutterNativeView view, boolean isBackgroundView) {
        mFlutterJNI.attachToNative(isBackgroundView);
        dartExecutor.onAttachedToJNI();
    }

    private final class RenderSurfaceImpl implements RenderSurface {
        @Override
        public void attachToRenderer(@NonNull FlutterRenderer renderer) {
            // Not relevant for v1 embedding.
        }

        @Override
        public void detachFromRenderer() {
            // Not relevant for v1 embedding.
        }

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

        @Override
        public void addOnFirstFrameRenderedListener(@NonNull OnFirstFrameRenderedListener listener) {}

        @Override
        public void removeOnFirstFrameRenderedListener(@NonNull OnFirstFrameRenderedListener listener) {}
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

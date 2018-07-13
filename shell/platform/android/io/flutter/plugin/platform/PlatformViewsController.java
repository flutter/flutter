// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import android.annotation.TargetApi;
import android.content.Context;
import android.os.Build;
import android.util.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StandardMethodCodec;
import io.flutter.view.FlutterView;
import io.flutter.view.TextureRegistry;

import java.util.HashMap;
import java.util.Map;

/**
 * Manages platform views.
 * <p>
 * Each {@link io.flutter.app.FlutterPluginRegistry} has a single platform views controller.
 * A platform views controller can be attached to at most one Flutter view.
 */
public class PlatformViewsController implements MethodChannel.MethodCallHandler {
    private static final String TAG = "PlatformViewsController";

    private static final String CHANNEL_NAME = "flutter/platform_views";

    // API level 20 is required for VirtualDisplay#setSurface which we use when resizing a platform view.
    private static final int MINIMAL_SDK = Build.VERSION_CODES.KITKAT_WATCH;

    private final PlatformViewRegistryImpl mRegistry;

    private FlutterView mFlutterView;

    private final HashMap<Integer, VirtualDisplayController> vdControllers;

    public PlatformViewsController() {
        mRegistry = new PlatformViewRegistryImpl();
        vdControllers = new HashMap<>();
    }

    public void attachFlutterView(FlutterView view) {
        if (mFlutterView != null)
            throw new AssertionError(
                    "A PlatformViewsController can only be attached to a single FlutterView.\n" +
                    "attachFlutterView was called while a FlutterView was already attached."
            );
        mFlutterView = view;
        MethodChannel channel = new MethodChannel(view, CHANNEL_NAME, StandardMethodCodec.INSTANCE);
        channel.setMethodCallHandler(this);
    }

    public void detachFlutterView() {
        mFlutterView.setMessageHandler(CHANNEL_NAME, null);
        mFlutterView = null;
    }

    public PlatformViewRegistry getRegistry() {
        return mRegistry;
    }

    public void onFlutterViewDestroyed() {
        for (VirtualDisplayController controller : vdControllers.values()) {
            controller.dispose();
        }
        vdControllers.clear();
    }

    @Override
    public void onMethodCall(final MethodCall call, final MethodChannel.Result result) {
        if (Build.VERSION.SDK_INT < MINIMAL_SDK) {
            Log.e(TAG, "Trying to use platform views with API " + Build.VERSION.SDK_INT
                    + ", required API level is: " + MINIMAL_SDK);
            return;
        }
        switch (call.method) {
            case "create":
                createPlatformView(call, result);
                return;
            case "dispose":
                disposePlatformView(call, result);
                return;
            case "resize":
                resizePlatformView(call, result);
                return;
        }
        result.notImplemented();
    }

    @TargetApi(Build.VERSION_CODES.ICE_CREAM_SANDWICH_MR1)
    private void createPlatformView(MethodCall call, MethodChannel.Result result) {
        Map<String, Object> args = call.arguments();
        int id = (int) args.get("id");
        String viewType = (String) args.get("viewType");
        double logicalWidth = (double) args.get("width");
        double logicalHeight = (double) args.get("height");

        if (vdControllers.containsKey(id)) {
            result.error(
                    "error",
                    "Trying to create an already created platform view, view id: " + id,
                    null
            );
            return;
        }

        PlatformViewFactory viewFactory = mRegistry.getFactory(viewType);
        if (viewFactory == null) {
            result.error(
                    "error",
                    "Trying to create a platform view of unregistered type: " + viewType,
                    null
            );
            return;
        }

        TextureRegistry.SurfaceTextureEntry textureEntry = mFlutterView.createSurfaceTexture();
        VirtualDisplayController vdController = VirtualDisplayController.create(
                mFlutterView.getContext(),
                viewFactory,
                textureEntry.surfaceTexture(),
                toPhysicalPixels(logicalWidth),
                toPhysicalPixels(logicalHeight),
                id
        );

        if (vdController == null) {
            result.error(
                    "error",
                    "Failed creating virtual display for a " + viewType + " with id: " + id,
                    null
            );
            return;
        }

        vdControllers.put(id, vdController);

        // TODO(amirh): copy accessibility nodes to the FlutterView's accessibility tree.

        result.success(textureEntry.id());
    }

    private void disposePlatformView(MethodCall call, MethodChannel.Result result) {
        int id = call.arguments();

        VirtualDisplayController vdController = vdControllers.get(id);
        if (vdController == null) {
            result.error(
                    "error",
                    "Trying to dispose a platform view with unknown id: " + id,
                    null
            );
            return;
        }

        vdController.dispose();
        vdControllers.remove(id);
        result.success(null);
    }

    private void resizePlatformView(MethodCall call, MethodChannel.Result result) {
        Map<String, Object> args = call.arguments();
        int id = (int) args.get("id");
        double width = (double) args.get("width");
        double height = (double) args.get("height");

        VirtualDisplayController vdController = vdControllers.get(id);
        if (vdController == null) {
            result.error(
                    "error",
                    "Trying to resize a platform view with unknown id: " + id,
                    null
            );
            return;
        }
        vdController.resize(
                toPhysicalPixels(width),
                toPhysicalPixels(height)
        );
        result.success(null);
    }

    private int toPhysicalPixels(double logicalPixels) {
        float density = mFlutterView.getContext().getResources().getDisplayMetrics().density;
        return (int) Math.round(logicalPixels * density);
    }

}

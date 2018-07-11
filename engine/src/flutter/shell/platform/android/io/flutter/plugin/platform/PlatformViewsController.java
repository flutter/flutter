// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import android.util.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StandardMethodCodec;
import io.flutter.view.FlutterView;

import java.util.HashMap;
import java.util.Map;

/**
 * Manages platform views.
 * <p>
 * Each {@link io.flutter.app.FlutterPluginRegistry} has a single platform views controller.
 * A platform views controller can be attached to at most one Flutter view.
 */
public class PlatformViewsController implements MethodChannel.MethodCallHandler {
    private static final String CHANNEL_NAME = "flutter/platform_views";

    private final PlatformViewRegistryImpl mRegistry;

    private FlutterView mFlutterView;

    public PlatformViewsController() {
        mRegistry = new PlatformViewRegistryImpl();
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
        // TODO(amirh): tear down all vd resources.
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "create":
                createPlatformView(call);
                break;
            case "dispose":
                disposePlatformView(call);
                break;
            case "resize":
                resizePlatformView(call);
                break;
        }
        result.success(null);
    }

    private void createPlatformView(MethodCall call) {
        Map<String, Object> args = call.arguments();
        int id = (int) args.get("id");
        String viewType = (String) args.get("viewType");
        double width = (double) args.get("width");
        double height = (double) args.get("height");

        // TODO(amirh): implement this.
    }

    private void disposePlatformView(MethodCall call) {
        int id = (int) call.arguments();

        // TODO(amirh): implement this.
    }

    private void resizePlatformView(MethodCall call) {
        Map<String, Object> args = call.arguments();
        int id = (int) args.get("id");
        double width = (double) args.get("width");
        double height = (double) args.get("height");

        // TODO(amirh): implement this.
    }

}

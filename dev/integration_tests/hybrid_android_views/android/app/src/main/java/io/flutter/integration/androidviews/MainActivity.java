// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.integration.platformviews;

import android.Manifest;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;

import java.lang.StringBuilder;
import java.util.HashMap;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterImageView;
import io.flutter.embedding.android.FlutterSurfaceView;
import io.flutter.embedding.android.FlutterTextureView;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity implements MethodChannel.MethodCallHandler {
    final static int STORAGE_PERMISSION_CODE = 1;

    MethodChannel mMethodChannel;

    // The method result to complete with the Android permission request result.
    // This is null when not waiting for the Android permission request;
    private MethodChannel.Result permissionResult;

    private View getFlutterView() {
      return findViewById(FLUTTER_VIEW_ID);
    }

    private String getViewName(View view) {
        if (view instanceof FlutterImageView) {
            return "FlutterImageView";
        }
        if (view instanceof FlutterSurfaceView) {
            return "FlutterSurfaceView";
        }
        if (view instanceof FlutterTextureView) {
            return "FlutterTextureView";
        }
        if (view instanceof FlutterView) {
            return "FlutterView";
        }
        if (view instanceof ViewGroup) {
            return "ViewGroup";
        }
        return "View";
    }

    private void recurseViewHierarchy(View current, String padding, StringBuilder builder) {
        if (current.getVisibility() != View.VISIBLE || current.getAlpha() == 0) {
            return;
        }
        String name = getViewName(current);
        builder.append(padding);
        builder.append("|-");
        builder.append(name);
        builder.append("\n");

        if (current instanceof ViewGroup) {
            ViewGroup viewGroup = (ViewGroup) current;
            for (int index = 0; index < viewGroup.getChildCount(); index++) {
                recurseViewHierarchy(viewGroup.getChildAt(index), padding + "  ", builder);
            }
        }
    }

    /**
     * Serializes the view hierarchy, so it can be sent to Dart over the method channel.
     *
     * Notation:
     * |- <view-name>
     *   |- ... child view ordered by z order.
     *
     * Example output:
     * |- FlutterView
     *   |- FlutterImageView
     *      |- ViewGroup
     *        |- View
     */
    private String getSerializedViewHierarchy() {
        View root = getFlutterView();
        StringBuilder builder = new StringBuilder();
        recurseViewHierarchy(root, "", builder);
        return builder.toString();
    }

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        DartExecutor executor = flutterEngine.getDartExecutor();
        flutterEngine
            .getPlatformViewsController()
            .getRegistry()
            .registerViewFactory("simple_view", new SimpleViewFactory(executor));
        mMethodChannel = new MethodChannel(executor, "android_views_integration");
        mMethodChannel.setMethodCallHandler(this);
        GeneratedPluginRegistrant.registerWith(flutterEngine);
    }

    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        switch(methodCall.method) {
            case "getStoragePermission":
                if (permissionResult != null) {
                    result.error("error", "already waiting for permissions", null);
                    return;
                }
                permissionResult = result;
                getExternalStoragePermissions();
                return;
            case "synthesizeEvent":
                synthesizeEvent(methodCall);
                result.success(null);
                return;
             case "getViewHierarchy":
                String viewHierarchy = getSerializedViewHierarchy();
                result.success(viewHierarchy);
                return;
        }
        result.notImplemented();
    }

    @SuppressWarnings("unchecked")
    public void synthesizeEvent(MethodCall methodCall) {
        MotionEvent event = MotionEventCodec.decode((HashMap<String, Object>) methodCall.arguments());
        getFlutterView().dispatchTouchEvent(event);
        // TODO(egarciad): Remove invokeMethod since it is not necessary.
        mMethodChannel.invokeMethod("onTouch", MotionEventCodec.encode(event));
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode != STORAGE_PERMISSION_CODE || permissionResult == null)
            return;
        boolean permisisonGranted = grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED;
        sendPermissionResult(permisisonGranted);
    }

    private void getExternalStoragePermissions() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M)
            return;

        if (checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE)
                == PackageManager.PERMISSION_GRANTED) {
            sendPermissionResult(true);
            return;
        }

        requestPermissions(new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE}, STORAGE_PERMISSION_CODE);
    }

    private void sendPermissionResult(boolean result) {
        if (permissionResult == null)
            return;
        permissionResult.success(result);
        permissionResult = null;
    }
}

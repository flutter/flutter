// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.integration.platformviews;

import android.app.AlertDialog;
import android.content.Context;
import android.graphics.PixelFormat;
import android.util.Log;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.TextView;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class SimplePlatformView implements PlatformView, MethodChannel.MethodCallHandler {
    private final FrameLayout view;
    private final MethodChannel methodChannel;
    private final TouchPipe touchPipe;

    SimplePlatformView(Context context, MethodChannel methodChannel) {
        this.methodChannel = methodChannel;
        view = new FrameLayout(context) {
            @Override
            public boolean onTouchEvent(MotionEvent event) {
                return true;
            }
        };
        view.setBackgroundColor(0xff0000ff);
        this.methodChannel.setMethodCallHandler(this);
        touchPipe = new TouchPipe(this.methodChannel, view);
    }

    @Override
    public View getView() {
        return view;
    }

    @Override
    public void dispose() {
    }

    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
         switch (methodCall.method) {
            case "pipeTouchEvents":
                touchPipe.enable();
                result.success(null);
                return;
            case "stopTouchEvents":
                touchPipe.disable();
                result.success(null);
                return;
            case "showAndHideAlertDialog":
                showAndHideAlertDialog(result);
                return;
            case "addWindowAndWaitForClick":
                addWindow(result);
                return;

        }
        result.notImplemented();
    }

    private void showAndHideAlertDialog(MethodChannel.Result result) {
        Context context = view.getContext();
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        TextView textView = new TextView(context);
        textView.setText("This alert dialog will close in 1 second");
        builder.setView(textView);
        final AlertDialog alertDialog = builder.show();
        result.success(null);
        view.postDelayed(new Runnable() {
            @Override
            public void run() {
                alertDialog.hide();
            }
        }, 1000);
    }

    private void addWindow(final MethodChannel.Result result) {
        Context context = view.getContext();
        final Button button = new Button(context);
        button.setText("This view is added as a window");
        final WindowManager windowManager = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
        WindowManager.LayoutParams layoutParams = new WindowManager.LayoutParams(WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY, 0, PixelFormat.OPAQUE);
        layoutParams.gravity = Gravity.FILL;
        windowManager.addView(button, layoutParams);
        button.setOnClickListener(v -> {
            windowManager.removeView(button);
            result.success(null);
        });
    }

}

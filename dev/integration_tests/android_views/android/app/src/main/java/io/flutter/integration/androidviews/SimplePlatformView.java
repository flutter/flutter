// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.integration.platformviews;

import android.app.AlertDialog;
import android.content.Context;
import android.view.MotionEvent;
import android.view.View;
import android.widget.TextView;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class SimplePlatformView implements PlatformView, MethodChannel.MethodCallHandler {
    private final View view;
    private final MethodChannel methodChannel;
    private final io.flutter.integration.platformviews.TouchPipe touchPipe;

    SimplePlatformView(Context context, MethodChannel methodChannel) {
        this.methodChannel = methodChannel;
        view = new View(context) {
            @Override
            public boolean onTouchEvent(MotionEvent event) {
                return super.onTouchEvent(event);
            }
        };
        view.setBackgroundColor(0xff0000ff);
        this.methodChannel.setMethodCallHandler(this);
        touchPipe = new io.flutter.integration.platformviews.TouchPipe(this.methodChannel, view);
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
        switch(methodCall.method) {
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

}

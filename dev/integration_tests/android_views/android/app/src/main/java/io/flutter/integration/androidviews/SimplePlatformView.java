// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.integration.androidviews;

import android.content.Context;
import android.view.MotionEvent;
import android.view.View;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class SimplePlatformView implements PlatformView, MethodChannel.MethodCallHandler {
    private final View mView;
    private final MethodChannel mMethodChannel;
    private final TouchPipe mTouchPipe;

    SimplePlatformView(Context context, MethodChannel methodChannel) {
        mMethodChannel = methodChannel;
        mView = new View(context) {
            @Override
            public boolean onTouchEvent(MotionEvent event) {
                return super.onTouchEvent(event);
            }
        };
        mView.setBackgroundColor(0xff0000ff);
        mMethodChannel.setMethodCallHandler(this);
        mTouchPipe = new TouchPipe(mMethodChannel, mView);
    }

    @Override
    public View getView() {
        return mView;
    }

    @Override
    public void dispose() {
    }

    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        switch(methodCall.method) {
            case "pipeTouchEvents":
                mTouchPipe.enable();
                result.success(null);
                return;
            case "stopTouchEvents":
                mTouchPipe.disable();
                result.success(null);
                return;
        }
        result.notImplemented();
    }
}

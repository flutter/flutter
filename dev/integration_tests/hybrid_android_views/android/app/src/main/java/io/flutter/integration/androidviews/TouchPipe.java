// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.integration.platformviews;

import android.annotation.TargetApi;
import android.os.Build;
import android.view.MotionEvent;
import android.view.View;

import io.flutter.plugin.common.MethodChannel;

@TargetApi(Build.VERSION_CODES.ICE_CREAM_SANDWICH)
class TouchPipe implements View.OnTouchListener {
    private final MethodChannel mMethodChannel;
    private final View mView;

    private boolean mEnabled;

    TouchPipe(MethodChannel methodChannel, View view) {
        mMethodChannel = methodChannel;
        mView = view;
    }

    public void enable() {
        if (mEnabled)
            return;
        mEnabled = true;
        mView.setOnTouchListener(this);
    }

    public void disable() {
        if (!mEnabled)
            return;
        mEnabled = false;
        mView.setOnTouchListener(null);
    }

    @Override
    public boolean onTouch(View v, MotionEvent event) {
        mMethodChannel.invokeMethod("onTouch", MotionEventCodec.encode(event));
        return false;
    }
}

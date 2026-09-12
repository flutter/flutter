// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.integration.platformviews;

import android.content.Context;
import android.graphics.Color;
import android.view.Gravity;
import android.view.View;
import android.widget.EditText;
import android.widget.FrameLayout;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class EditTextPlatformView implements PlatformView, MethodChannel.MethodCallHandler {
    public static EditTextPlatformView activeView;
    private final FrameLayout view;
    private final EditText editText;
    private final MethodChannel methodChannel;

    EditTextPlatformView(Context context, MethodChannel methodChannel) {
        activeView = this;
        this.methodChannel = methodChannel;
        this.methodChannel.setMethodCallHandler(this);

        editText = new EditText(context);
        editText.setHint("Enter text");
        editText.setTextColor(Color.BLACK);
        editText.setTextSize(20f);
        editText.setGravity(Gravity.CENTER);
        editText.setSingleLine(true);
        editText.setOnFocusChangeListener(new View.OnFocusChangeListener() {
            @Override
            public void onFocusChange(View v, boolean hasFocus) {
                android.util.Log.i("EditTextPlatformView", "editText hasFocus=" + hasFocus);
            }
        });

        view = new FrameLayout(context);
        view.setBackgroundColor(Color.WHITE);
        view.setFocusable(false);
        view.setFocusableInTouchMode(false);
        view.setOnFocusChangeListener(new View.OnFocusChangeListener() {
            @Override
            public void onFocusChange(View v, boolean hasFocus) {
                android.util.Log.i("EditTextPlatformView", "view hasFocus=" + hasFocus);
            }
        });
        view.addView(editText);
    }

    public String getText() {
        return editText.getText().toString();
    }

    public void requestFocus() {
        editText.requestFocus();
    }

    @Override
    public View getView() {
        return view;
    }

    @Override
    public void dispose() {
        if (activeView == this) {
            activeView = null;
        }
    }

    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        switch (methodCall.method) {
            case "getText":
                result.success(getText());
                return;
            case "requestFocus":
                requestFocus();
                result.success(null);
                return;
        }
        result.notImplemented();
    }
}

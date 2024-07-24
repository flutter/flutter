// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.integration.android_verified_input;

import android.content.Context;
import android.hardware.input.InputManager;
import android.os.Build;
import android.view.MotionEvent;
import android.view.VerifiedInputEvent;
import android.view.View;
import android.widget.Button;

import androidx.annotation.NonNull;

import java.util.Map;

import io.flutter.Log;
import io.flutter.plugin.platform.PlatformView;

class VerifiedInputView implements PlatformView {
    private static final String TAG = "VerifiedInputView";
    @NonNull
    private final Button mButton;

    VerifiedInputView(@NonNull Context context, @NonNull Map<String, Object> creationParams) {
        mButton = new Button(context);

        mButton.setText("click me");

        mButton.setOnTouchListener(
                (view, event) -> {
                    if (MotionEvent.ACTION_DOWN == event.getAction()) {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            InputManager inputManager = context.getSystemService(InputManager.class);
                            VerifiedInputEvent verify = inputManager.verifyInputEvent(event);
                            // If verifyInputEvent returns an object, the input event was verified
                            final boolean verified = (verify != null);
                            Log.i(TAG, "VerifiedInputEvent is verified : " + verified);
                            // Notify the test harness whether or not the input event was verified.
                            MainActivity.mMethodChannel.invokeMethod("notify_verified_input", verified);
                            if (verified) {
                                mButton.setBackgroundColor(context.getColor(R.color.green));
                                mButton.setText("click me (verified)");
                            } else {
                                mButton.setBackgroundColor(context.getColor(R.color.red));
                                mButton.setText("click me (verification failed)");
                            }

                        }
                        return true;
                    }
                    return false;
                });
    }

    @NonNull
    @Override
    public View getView() {
        return mButton;
    }

    @Override
    public void dispose() {
    }

}

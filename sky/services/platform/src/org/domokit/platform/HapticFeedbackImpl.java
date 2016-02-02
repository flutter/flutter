// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.platform;

import android.app.Activity;
import android.view.HapticFeedbackConstants;
import android.view.View;

import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.flutter.platform.HapticFeedback;
import org.domokit.activity.ActivityImpl;

/**
 * Android implementation of HapticFeedback.
 */
public class HapticFeedbackImpl implements HapticFeedback {
    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void vibrate(VibrateResponse callback) {
        Activity activity = ActivityImpl.getCurrentActivity();
        if (activity == null) {
            callback.call(false);
            return;
        }

        View view = activity.getWindow().getDecorView();
        view.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS);
        callback.call(true);
    }
}

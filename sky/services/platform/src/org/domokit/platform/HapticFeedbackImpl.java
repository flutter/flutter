// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.platform;

import android.app.Activity;
import android.view.HapticFeedbackConstants;
import android.view.View;

import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.flutter.platform.HapticFeedback;

/**
 * Android implementation of HapticFeedback.
 */
public class HapticFeedbackImpl implements HapticFeedback {
    private final Activity mActivity;

    public HapticFeedbackImpl(Activity activity) {
        mActivity = activity;
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void vibrate(VibrateResponse callback) {
        View view = mActivity.getWindow().getDecorView();
        view.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS);
        callback.call(true);
    }
}

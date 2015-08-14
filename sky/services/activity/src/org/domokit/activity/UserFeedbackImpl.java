// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.activity;

import android.util.Log;
import android.view.HapticFeedbackConstants;
import android.view.SoundEffectConstants;
import android.view.View;

import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.activity.AuralFeedbackType;
import org.chromium.mojom.activity.HapticFeedbackType;
import org.chromium.mojom.activity.UserFeedback;

/**
 * Android implementation of UserFeedback.
 */
public class UserFeedbackImpl implements UserFeedback {
    private static final String TAG = "UserFeedbackImpl";
    private View mView;

    public UserFeedbackImpl(View view) {
        mView = view;
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void performHapticFeedback(int type) {
        int androidType = 0;
        switch (type) {
            case HapticFeedbackType.LONG_PRESS:
                androidType = HapticFeedbackConstants.LONG_PRESS;
                break;
            case HapticFeedbackType.VIRTUAL_KEY:
                androidType = HapticFeedbackConstants.VIRTUAL_KEY;
                break;
            case HapticFeedbackType.KEYBOARD_TAP:
                androidType = HapticFeedbackConstants.KEYBOARD_TAP;
                break;
            case HapticFeedbackType.CLOCK_TICK:
                androidType = HapticFeedbackConstants.CLOCK_TICK;
                break;
            default:
                Log.e(TAG, "Unknown HapticFeedbackType " + type);
                return;
        }
        mView.performHapticFeedback(androidType, HapticFeedbackConstants.FLAG_IGNORE_VIEW_SETTING);
    }

    @Override
    public void performAuralFeedback(int type) {
        int androidType = 0;
        switch (type) {
            case AuralFeedbackType.CLICK:
                androidType = SoundEffectConstants.CLICK;
                break;
            case AuralFeedbackType.NAVIGATION_LEFT:
                androidType = SoundEffectConstants.NAVIGATION_LEFT;
                break;
            case AuralFeedbackType.NAVIGATION_UP:
                androidType = SoundEffectConstants.NAVIGATION_UP;
                break;
            case AuralFeedbackType.NAVIGATION_RIGHT:
                androidType = SoundEffectConstants.NAVIGATION_RIGHT;
                break;
            case AuralFeedbackType.NAVIGATION_DOWN:
                androidType = SoundEffectConstants.NAVIGATION_DOWN;
                break;
            default:
                Log.e(TAG, "Unknown AuralFeedbackType " + type);
                return;
        }
        mView.playSoundEffect(androidType);
    }
}

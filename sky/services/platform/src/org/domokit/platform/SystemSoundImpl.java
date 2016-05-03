// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.platform;

import android.app.Activity;
import android.view.SoundEffectConstants;
import android.view.View;

import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.flutter.platform.SystemSound;
import org.chromium.mojom.flutter.platform.SystemSoundType;

/**
 * Android implementation of SystemSound.
 */
public class SystemSoundImpl implements SystemSound {
    private final Activity mActivity;

    public SystemSoundImpl(Activity activity) {
        mActivity = activity;
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void play(int type, PlayResponse callback) {
        if (type != SystemSoundType.CLICK) {
            callback.call(false);
            return;
        }

        View view = mActivity.getWindow().getDecorView();
        view.playSoundEffect(SoundEffectConstants.CLICK);
        callback.call(true);
    }
}

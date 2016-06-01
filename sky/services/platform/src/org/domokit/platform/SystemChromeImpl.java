// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.platform;

import android.app.Activity;
import android.content.pm.ActivityInfo;
import android.view.View;

import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.flutter.platform.DeviceOrientation;
import org.chromium.mojom.flutter.platform.SystemChrome;
import org.chromium.mojom.flutter.platform.SystemUiOverlay;

/**
 * Android implementation of SystemChrome.
 */
public class SystemChromeImpl implements SystemChrome {
    private final Activity mActivity;

    public SystemChromeImpl(Activity activity) {
        mActivity = activity;
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void setPreferredOrientations(int deviceOrientationMask,
                                         SetPreferredOrientationsResponse callback) {
        // Currently the Android implementation only supports masks with zero or one
        // selected device orientations.
        int androidOrientation;
        if (deviceOrientationMask == 0) {
            androidOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED;
        } else if (deviceOrientationMask == DeviceOrientation.PORTRAIT_UP) {
            androidOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT;
        } else if (deviceOrientationMask == DeviceOrientation.LANDSCAPE_LEFT) {
            androidOrientation = ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE;
        } else if (deviceOrientationMask == DeviceOrientation.PORTRAIT_DOWN) {
            androidOrientation = ActivityInfo.SCREEN_ORIENTATION_REVERSE_PORTRAIT;
        } else if (deviceOrientationMask == DeviceOrientation.LANDSCAPE_RIGHT) {
            androidOrientation = ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE;
        } else {
            callback.call(false);
            return;
        }

        mActivity.setRequestedOrientation(androidOrientation);
        callback.call(true);
    }

    @Override
    public void setEnabledSystemUiOverlays(int overlays,
                                           SetEnabledSystemUiOverlaysResponse callback) {
        int flags = View.SYSTEM_UI_FLAG_LAYOUT_STABLE |
                    View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN;

        if ((overlays & SystemUiOverlay.TOP) == 0) {
            flags |= View.SYSTEM_UI_FLAG_FULLSCREEN;
        }
        if ((overlays & SystemUiOverlay.BOTTOM) == 0) {
            flags |= View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION |
                     View.SYSTEM_UI_FLAG_HIDE_NAVIGATION;
        }

        mActivity.getWindow().getDecorView().setSystemUiVisibility(flags);
        callback.call(true);
    }
}

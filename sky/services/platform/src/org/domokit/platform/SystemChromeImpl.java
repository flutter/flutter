// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.platform;

import android.app.Activity;
import android.content.pm.ActivityInfo;
import android.os.Build;
import android.view.View;

import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.flutter.platform.ApplicationSwitcherDescription;
import org.chromium.mojom.flutter.platform.DeviceOrientation;
import org.chromium.mojom.flutter.platform.SystemChrome;
import org.chromium.mojom.flutter.platform.SystemUiOverlay;

import org.domokit.common.ActivityLifecycleListener;

/**
 * Android implementation of SystemChrome.
 */
public class SystemChromeImpl implements SystemChrome, ActivityLifecycleListener {
    private final Activity mActivity;
    private int mEnabledOverlays;

    public SystemChromeImpl(Activity activity) {
        mActivity = activity;
        mEnabledOverlays = SystemUiOverlay.TOP | SystemUiOverlay.BOTTOM;
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
    public void setApplicationSwitcherDescription(
        ApplicationSwitcherDescription description,
        SetApplicationSwitcherDescriptionResponse callback) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            callback.call(true);
            return;
        }

        int color = description.primaryColor;
        if (color != 0) { // 0 means color isn't set, use system default
            color = color | 0xFF000000; // color must be opaque if set
        }

        mActivity.setTaskDescription(
            new android.app.ActivityManager.TaskDescription(
                description.label,
                null,
                color
            )
        );

        callback.call(true);
    }

    @Override
    public void setEnabledSystemUiOverlays(int overlays,
                                           SetEnabledSystemUiOverlaysResponse callback) {
        mEnabledOverlays = overlays;
        updateSystemUiOverlays();
        callback.call(true);
    }

    private void updateSystemUiOverlays() {
        int flags = View.SYSTEM_UI_FLAG_LAYOUT_STABLE |
                    View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN;

        if ((mEnabledOverlays & SystemUiOverlay.TOP) == 0) {
            flags |= View.SYSTEM_UI_FLAG_FULLSCREEN;
        }
        if ((mEnabledOverlays & SystemUiOverlay.BOTTOM) == 0) {
            flags |= View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION |
                     View.SYSTEM_UI_FLAG_HIDE_NAVIGATION;
        }
        if (mEnabledOverlays == 0) {
            flags |= View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY;
        }

        mActivity.getWindow().getDecorView().setSystemUiVisibility(flags);
    }

    @Override
    public void setSystemUiOverlayStyle(int style, SetSystemUiOverlayStyleResponse callback) {
        // You can change the navigation bar color (including translucent colors)
        // in Android, but you can't change the color of the navigation buttons,
        // so LIGHT vs DARK effectively isn't supported in Android.
        callback.call(true);
    }

    @Override
    public void onPostResume() {
        updateSystemUiOverlays();
    }
}

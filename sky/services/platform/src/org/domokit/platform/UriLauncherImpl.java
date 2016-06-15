// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.platform;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;

import org.chromium.mojo.system.MojoException;

import org.chromium.mojom.flutter.platform.UriLauncher;

/**
 * Android implementation of UriLauncher.
 */
public class UriLauncherImpl implements UriLauncher {
    private final Activity mActivity;

    public UriLauncherImpl(Activity activity) {
        mActivity = activity;
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void launch(String urlString, LaunchResponse callback) {
        try {
            Intent launchIntent = new Intent(Intent.ACTION_VIEW);
            launchIntent.setData(Uri.parse(urlString));
            mActivity.startActivity(launchIntent);
            callback.call(true);
        } catch (java.lang.Exception exception) {
            // In case of parsing or ActivityNotFound errors
            callback.call(false);
        }
    }
}

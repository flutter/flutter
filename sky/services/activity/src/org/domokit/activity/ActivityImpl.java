// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.activity;

import android.content.ActivityNotFoundException;
import android.content.pm.ActivityInfo;
import android.net.Uri;
import android.os.Build;
import android.util.Log;
import android.view.View;

import org.chromium.mojo.bindings.InterfaceRequest;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.activity.Activity;
import org.chromium.mojom.activity.ComponentName;
import org.chromium.mojom.activity.Intent;
import org.chromium.mojom.activity.StringExtra;
import org.chromium.mojom.activity.TaskDescription;

/**
 * Android implementation of Activity.
 */
public class ActivityImpl implements Activity {
    private static final String TAG = "ActivityImpl";
    private static android.app.Activity sCurrentActivity;

    public ActivityImpl() {
    }

    public static void setCurrentActivity(android.app.Activity activity) {
        sCurrentActivity = activity;
    }

    public static android.app.Activity getCurrentActivity() {
        return sCurrentActivity;
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void startActivity(Intent intent) {
        if (sCurrentActivity == null) {
            Log.e(TAG, "Unable to startActivity");
            return;
        }

        final android.content.Intent androidIntent = new android.content.Intent(
                intent.action, Uri.parse(intent.url));

        if (intent.component != null) {
            ComponentName component = intent.component;
            android.content.ComponentName androidComponent =
                    new android.content.ComponentName(component.packageName, component.className);
            androidIntent.setComponent(androidComponent);
        }

        if (intent.stringExtras != null) {
            for (StringExtra extra : intent.stringExtras) {
                androidIntent.putExtra(extra.name, extra.value);
            }
        }

        if (intent.flags != 0) {
            androidIntent.setFlags(intent.flags);
        }

        try {
            sCurrentActivity.startActivity(androidIntent);
        } catch (ActivityNotFoundException e) {
            Log.e(TAG, "Unable to startActivity", e);
        }
    }

    @Override
    public void finishCurrentActivity() {
        if (sCurrentActivity != null) {
            sCurrentActivity.finish();
        } else {
            Log.e(TAG, "Unable to finishCurrentActivity");
        }
    }

    @Override
    public void setTaskDescription(TaskDescription description) {
        if (sCurrentActivity == null) {
            return;
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            return;
        }
        int color = description.primaryColor;
        if (color != 0) // 0 means color isn't set, use system default
          color = color | 0xFF000000; // color must be opaque if set
        sCurrentActivity.setTaskDescription(
                new android.app.ActivityManager.TaskDescription(
                    description.label,
                    null,
                    color
                )
        );
    }
}

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.intents;

import android.content.ActivityNotFoundException;
import android.content.Context;
import android.net.Uri;
import android.util.Log;

import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.intents.ActivityManager;
import org.chromium.mojom.intents.Intent;

/**
 * Android implementation of ActivityManager.
 */
public class ActivityManagerImpl implements ActivityManager {
    private static final String TAG = "ActivityManagerImpl";
    private Context mContext;

    public ActivityManagerImpl(Context context) {
        mContext = context;
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void startActivity(Intent intent) {
        final android.content.Intent androidIntent = new android.content.Intent(
                intent.action, Uri.parse(intent.url));
        androidIntent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK);

        try {
            mContext.startActivity(androidIntent);
        } catch (ActivityNotFoundException e) {
            Log.e(TAG, "Unable to startActivity", e);
        }
    }
}

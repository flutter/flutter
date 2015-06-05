// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.util.Log;

import org.chromium.base.JNINamespace;

import java.io.File;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;

/**
 * A controller for the tracing system.
 */
@JNINamespace("sky::shell")
class TracingController {
    private static final String TAG = "TracingController";
    private static final String TRACING_START = ".TRACING_START";
    private static final String TRACING_STOP = ".TRACING_STOP";

    private final Context mContext;
    private final TracingBroadcastReceiver mBroadcastReceiver;
    private final TracingIntentFilter mIntentFilter;

    public TracingController(Context context) {
        mContext = context;
        mBroadcastReceiver = new TracingBroadcastReceiver();
        mIntentFilter = new TracingIntentFilter(context);

        mContext.registerReceiver(mBroadcastReceiver, mIntentFilter);
    }

    public void stop() {
        mContext.unregisterReceiver(mBroadcastReceiver);
    }

    private String generateTracingFilePath() {
        SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd-HHmmss", Locale.US);
        formatter.setTimeZone(TimeZone.getTimeZone("UTC"));
        File dir = mContext.getCacheDir();
        String date = formatter.format(new Date());
        File file = new File(dir, "sky-trace-" + date + ".json");
        return file.getPath();
    }

    class TracingIntentFilter extends IntentFilter {
        TracingIntentFilter(Context context) {
            Log.e(TAG, context.getPackageName() + TRACING_START);
            addAction(context.getPackageName() + TRACING_START);
            addAction(context.getPackageName() + TRACING_STOP);
        }
    }

    class TracingBroadcastReceiver extends BroadcastReceiver {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (intent.getAction().endsWith(TRACING_START)) {
                nativeStartTracing();
            } else if (intent.getAction().endsWith(TRACING_STOP)) {
                nativeStopTracing(generateTracingFilePath());
            } else {
                Log.e(TAG, "Unexpected intent: " + intent);
            }
        }
    }

    private static native void nativeStartTracing();
    private static native void nativeStopTracing(String path);
}

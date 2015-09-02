// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.app.AlarmManager;
import android.app.Service;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.IBinder;
import android.util.Log;
import java.io.File;
import org.chromium.base.CalledByNative;
import org.chromium.base.JNINamespace;
import org.chromium.base.PathUtils;

/**
 * A class that schedules and runs periodic autoupdate checks.
 */
@JNINamespace("sky::shell")
public class UpdateService extends Service {
    private static final String TAG = "UpdateService";
    private static final int REQUEST_CODE = 0;  // Not sure why this is needed.
    private static final boolean ENABLED = false;

    private long mNativePtr = 0;

    public static void init(Context context) {
        if (ENABLED)
            maybeScheduleUpdateCheck(context);
    }

    private static void maybeScheduleUpdateCheck(Context context) {
        Intent alarm = new Intent(context, UpdateService.class);
        PendingIntent existingIntent = PendingIntent.getService(
                context, REQUEST_CODE, alarm, PendingIntent.FLAG_NO_CREATE);
        if (existingIntent != null) {
          Log.i(TAG, "Update alarm exists: " + PathUtils.getDataDirectory(context));
          return;
        }

        PendingIntent pendingIntent = PendingIntent.getService(
                context, REQUEST_CODE, alarm, PendingIntent.FLAG_UPDATE_CURRENT);
        AlarmManager manager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
        manager.setInexactRepeating(AlarmManager.RTC, System.currentTimeMillis(),
                AlarmManager.INTERVAL_DAY, pendingIntent);

        Log.i(TAG, "Update scheduled: " + PathUtils.getDataDirectory(context));
    }

    @Override
    public void onCreate() {
        super.onCreate();
        SkyMain.ensureInitialized(getApplicationContext(), null);
    }

    @Override
    public void onDestroy() {
        if (mNativePtr != 0)
            nativeDetach(mNativePtr);
        mNativePtr = 0;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        final File dataDir = new File(PathUtils.getDataDirectory(this));
        mNativePtr = nativeCheckForUpdates(dataDir.getPath());
        return START_NOT_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) {
      return null;
    }

    @SuppressWarnings("unused")
    @CalledByNative
    public void onUpdateFinished() {
        stopSelf();
    }

    private native long nativeCheckForUpdates(String dataDir);
    private native void nativeDetach(long nativeUpdateTask);
}

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.shortcuts;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;

/**
 * Receives broadcast when device is rebooted or through the {@link AlarmManager}.
 */
public class AlarmReceiver extends BroadcastReceiver {
    private static final ScheduledExecutorService EXECUTOR =
            Executors.newSingleThreadScheduledExecutor();

    public static void setupAlarm(Context context) {
        AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
        Intent intent = new Intent(context, AlarmReceiver.class);
        PendingIntent alarmIntent = PendingIntent.getBroadcast(context, 0, intent, 0);
        alarmManager.cancel(alarmIntent);
        alarmManager.setInexactRepeating(AlarmManager.ELAPSED_REALTIME_WAKEUP,
                AlarmManager.INTERVAL_DAY, AlarmManager.INTERVAL_DAY, alarmIntent);
    }

    /**
     * @see android.content.BroadcastReceiver#onReceive(android.content.Context,
     *      android.content.Intent)
     */
    @Override
    public void onReceive(final Context context, Intent intent) {
        // This receiver listen to android.intent.action.BOOT_COMPLETED through the application
        // manifest. When this happens, register the alarm.
        if (intent.getAction() != null
                && intent.getAction().equals("android.intent.action.BOOT_COMPLETED")) {
            setupAlarm(context);
        }
        // In all cases, whether this is called through the alarm or at boot, check for applications
        // to update.
        EXECUTOR.execute(new Runnable() {

            @Override
            public void run() {
                ApplicationUpdater.checkAndUpdateApplications(context);
            }
        });
    }
}

// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.memconsumer;

import android.app.Notification;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.os.Binder;
import android.os.IBinder;

public class ResidentService extends Service {
    static {
        // Loading the native library.
        System.loadLibrary("memconsumer");
    }

    public class ServiceBinder extends Binder {
        ResidentService getService() {
            return ResidentService.this;
        }
    }

    private static final int RESIDENT_NOTIFICATION_ID = 1;

    private final IBinder mBinder = new ServiceBinder();
    private boolean mIsInForeground = false;

    @Override
    public IBinder onBind(Intent intent) {
        return mBinder;
    }

    public void useMemory(long memory) {
        if (memory > 0) {
            Intent notificationIntent = new Intent(this, MemConsumer.class);
            notificationIntent.setAction(MemConsumer.NOTIFICATION_ACTION);
            PendingIntent pendingIntent =
                    PendingIntent.getActivity(this, 0, notificationIntent, 0);
            Notification notification =
                    new Notification.Builder(getApplicationContext())
                            .setContentTitle("MC running (" + memory + "Mb)")
                            .setSmallIcon(R.drawable.notification_icon)
                            .setDeleteIntent(pendingIntent)
                            .setContentIntent(pendingIntent)
                            .build();
            startForeground(RESIDENT_NOTIFICATION_ID, notification);
            mIsInForeground = true;
        }
        if (mIsInForeground && memory == 0) {
            stopForeground(true);
            mIsInForeground = false;
        }
        nativeUseMemory(memory * 1024 * 1024);
    }

    // Allocate the amount of memory in native code. Otherwise the memory
    // allocation is limited by the framework.
    private native void nativeUseMemory(long memory);
}

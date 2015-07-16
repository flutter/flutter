// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.BatteryManager;
import android.os.Handler;
import android.os.Looper;


/**
 * Integrates native PowerMonitor with the java side.
 */
@JNINamespace("base::android")
public class PowerMonitor implements ApplicationStatus.ApplicationStateListener {
    private static final long SUSPEND_DELAY_MS = 1 * 60 * 1000;  // 1 minute.
    private static class LazyHolder {
        private static final PowerMonitor INSTANCE = new PowerMonitor();
    }
    private static PowerMonitor sInstance;

    private boolean mIsBatteryPower;
    private final Handler mHandler = new Handler(Looper.getMainLooper());

    // Asynchronous task used to fire the "paused" event to the native side 1 minute after the main
    // activity transitioned to the "paused" state. This event is not sent immediately because it
    // would be too aggressive. An Android activity can be in the "paused" state quite often. This
    // can happen when a dialog window shows up for instance.
    private static final Runnable sSuspendTask = new Runnable() {
        @Override
        public void run() {
            nativeOnMainActivitySuspended();
        }
    };

    public static void createForTests(Context context) {
        // Applications will create this once the JNI side has been fully wired up both sides. For
        // tests, we just need native -> java, that is, we don't need to notify java -> native on
        // creation.
        sInstance = LazyHolder.INSTANCE;
    }

    /**
     * Create a PowerMonitor instance if none exists.
     * @param context The context to register broadcast receivers for.  The application context
     *                will be used from this parameter.
     */
    public static void create(Context context) {
        context = context.getApplicationContext();
        if (sInstance == null) {
            sInstance = LazyHolder.INSTANCE;
            ApplicationStatus.registerApplicationStateListener(sInstance);
            IntentFilter ifilter = new IntentFilter(Intent.ACTION_BATTERY_CHANGED);
            Intent batteryStatusIntent = context.registerReceiver(null, ifilter);
            onBatteryChargingChanged(batteryStatusIntent);
        }
    }

    private PowerMonitor() {
    }

    public static void onBatteryChargingChanged(Intent intent) {
        if (sInstance == null) {
            // We may be called by the framework intent-filter before being fully initialized. This
            // is not a problem, since our constructor will check for the state later on.
            return;
        }
        int chargePlug = intent.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1);
        // If we're not plugged, assume we're running on battery power.
        sInstance.mIsBatteryPower = chargePlug != BatteryManager.BATTERY_PLUGGED_USB
                && chargePlug != BatteryManager.BATTERY_PLUGGED_AC;
        nativeOnBatteryChargingChanged();
    }

    @Override
    public void onApplicationStateChange(int newState) {
        if (newState == ApplicationState.HAS_RUNNING_ACTIVITIES) {
            // Remove the callback from the message loop in case it hasn't been executed yet.
            mHandler.removeCallbacks(sSuspendTask);
            nativeOnMainActivityResumed();
        } else if (newState == ApplicationState.HAS_PAUSED_ACTIVITIES) {
            mHandler.postDelayed(sSuspendTask, SUSPEND_DELAY_MS);
        }
    }

    @CalledByNative
    private static boolean isBatteryPower() {
        return sInstance.mIsBatteryPower;
    }

    private static native void nativeOnBatteryChargingChanged();
    private static native void nativeOnMainActivitySuspended();
    private static native void nativeOnMainActivityResumed();
}

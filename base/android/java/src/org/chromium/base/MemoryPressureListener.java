// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import android.app.Activity;
import android.content.ComponentCallbacks2;
import android.content.Context;
import android.content.res.Configuration;


/**
 * This is an internal implementation of the C++ counterpart.
 * It registers a ComponentCallbacks2 with the system, and dispatches into
 * native for levels that are considered actionable.
 */
public class MemoryPressureListener {
    /**
     * Sending an intent with this action to Chrome will cause it to issue a call to onLowMemory
     * thus simulating a low memory situations.
     */
    private static final String ACTION_LOW_MEMORY = "org.chromium.base.ACTION_LOW_MEMORY";

    /**
     * Sending an intent with this action to Chrome will cause it to issue a call to onTrimMemory
     * thus simulating a low memory situations.
     */
    private static final String ACTION_TRIM_MEMORY = "org.chromium.base.ACTION_TRIM_MEMORY";

    /**
     * Sending an intent with this action to Chrome will cause it to issue a call to onTrimMemory
     * with notification level TRIM_MEMORY_RUNNING_CRITICAL thus simulating a low memory situation
     */
    private static final String ACTION_TRIM_MEMORY_RUNNING_CRITICAL =
            "org.chromium.base.ACTION_TRIM_MEMORY_RUNNING_CRITICAL";

    /**
     * Sending an intent with this action to Chrome will cause it to issue a call to onTrimMemory
     * with notification level TRIM_MEMORY_MODERATE thus simulating a low memory situation
     */
    private static final String ACTION_TRIM_MEMORY_MODERATE =
            "org.chromium.base.ACTION_TRIM_MEMORY_MODERATE";

    @CalledByNative
    private static void registerSystemCallback(Context context) {
        context.registerComponentCallbacks(
                new ComponentCallbacks2() {
                    @Override
                    public void onTrimMemory(int level) {
                        maybeNotifyMemoryPresure(level);
                    }

                    @Override
                    public void onLowMemory() {
                        nativeOnMemoryPressure(MemoryPressureLevel.CRITICAL);
                    }

                    @Override
                    public void onConfigurationChanged(Configuration configuration) {
                    }
                });
    }

    /**
     * Used by applications to simulate a memory pressure signal. By throwing certain intent
     * actions.
     */
    public static boolean handleDebugIntent(Activity activity, String action) {
        if (ACTION_LOW_MEMORY.equals(action)) {
            simulateLowMemoryPressureSignal(activity);
        } else if (ACTION_TRIM_MEMORY.equals(action)) {
            simulateTrimMemoryPressureSignal(activity, ComponentCallbacks2.TRIM_MEMORY_COMPLETE);
        } else if (ACTION_TRIM_MEMORY_RUNNING_CRITICAL.equals(action)) {
            simulateTrimMemoryPressureSignal(activity,
                    ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL);
        } else if (ACTION_TRIM_MEMORY_MODERATE.equals(action)) {
            simulateTrimMemoryPressureSignal(activity, ComponentCallbacks2.TRIM_MEMORY_MODERATE);
        } else {
            return false;
        }

        return true;
    }

    public static void maybeNotifyMemoryPresure(int level) {
        if (level >= ComponentCallbacks2.TRIM_MEMORY_COMPLETE) {
            nativeOnMemoryPressure(MemoryPressureLevel.CRITICAL);
        } else if (level >= ComponentCallbacks2.TRIM_MEMORY_BACKGROUND
                || level == ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL) {
            // Don't notifiy on TRIM_MEMORY_UI_HIDDEN, since this class only
            // dispatches actionable memory pressure signals to native.
            nativeOnMemoryPressure(MemoryPressureLevel.MODERATE);
        }
    }

    private static void simulateLowMemoryPressureSignal(Activity activity) {
        // The Application and the Activity each have a list of callbacks they notify when this
        // method is called.  Notifying these will simulate the event at the App/Activity level
        // as well as trigger the listener bound from native in this process.
        activity.getApplication().onLowMemory();
        activity.onLowMemory();
    }

    private static void simulateTrimMemoryPressureSignal(Activity activity, int level) {
        // The Application and the Activity each have a list of callbacks they notify when this
        // method is called.  Notifying these will simulate the event at the App/Activity level
        // as well as trigger the listener bound from native in this process.
        activity.getApplication().onTrimMemory(level);
        activity.onTrimMemory(level);
    }

    private static native void nativeOnMemoryPressure(int memoryPressureType);
}

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.test;

import android.app.Activity;
import android.content.Context;
import android.os.SystemClock;
import android.test.ActivityInstrumentationTestCase2;
import android.util.Log;

import org.chromium.base.test.util.CommandLineFlags;

/**
 * Base class for all Activity-based Instrumentation tests.
 *
 * @param <T> The Activity type.
 */
public class BaseActivityInstrumentationTestCase<T extends Activity>
        extends ActivityInstrumentationTestCase2<T> {

    private static final String TAG = "BaseActivityInstrumentationTestCase";

    private static final int SLEEP_INTERVAL = 50; // milliseconds
    private static final int WAIT_DURATION = 5000; // milliseconds

    /**
     * Creates a instance for running tests against an Activity of the given class.
     *
     * @param activityClass The type of activity that will be tested.
     */
    public BaseActivityInstrumentationTestCase(Class<T> activityClass) {
        super(activityClass);
    }

    @Override
    protected void setUp() throws Exception {
        super.setUp();
        CommandLineFlags.setUp(getTargetContext(), getClass().getMethod(getName()));
    }

    /**
     * Gets the target context.
     *
     * On older versions of Android, getTargetContext() may initially return null, so we have to
     * wait for it to become available.
     *
     * @return The target {@link android.content.Context} if available; null otherwise.
     */
    private Context getTargetContext() {
        Context targetContext = getInstrumentation().getTargetContext();
        try {
            long startTime = SystemClock.uptimeMillis();
            // TODO(jbudorick): Convert this to CriteriaHelper once that moves to base/.
            while (targetContext == null
                    && SystemClock.uptimeMillis() - startTime < WAIT_DURATION) {
                Thread.sleep(SLEEP_INTERVAL);
                targetContext = getInstrumentation().getTargetContext();
            }
        } catch (InterruptedException e) {
            Log.e(TAG, "Interrupted while attempting to initialize the command line.");
        }
        return targetContext;
    }
}

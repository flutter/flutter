// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import android.annotation.TargetApi;
import android.app.Activity;
import android.os.Build;
import android.os.SystemClock;
import android.test.InstrumentationTestCase;
import android.test.suitebuilder.annotation.SmallTest;

/**
 * Test of ApiCompatibilityUtils
 */
public class ApiCompatibilityUtilsTest extends InstrumentationTestCase {
    private static final long WAIT_TIMEOUT_IN_MS = 5000;
    private static final long SLEEP_INTERVAL_IN_MS = 50;

    static class MockActivity extends Activity {
        int mFinishAndRemoveTaskCallbackCount;
        int mFinishCallbackCount;
        boolean mIsFinishing;

        @TargetApi(Build.VERSION_CODES.LOLLIPOP)
        @Override
        public void finishAndRemoveTask() {
            mFinishAndRemoveTaskCallbackCount++;
            if (Build.VERSION.SDK_INT > Build.VERSION_CODES.LOLLIPOP) mIsFinishing = true;
        }

        @Override
        public void finish() {
            mFinishCallbackCount++;
            mIsFinishing = true;
        }

        @Override
        public boolean isFinishing() {
            return mIsFinishing;
        }
    }

    @SmallTest
    public void testFinishAndRemoveTask() throws InterruptedException {
        MockActivity activity = new MockActivity();
        ApiCompatibilityUtils.finishAndRemoveTask(activity);

        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.LOLLIPOP) {
            assertEquals(1, activity.mFinishAndRemoveTaskCallbackCount);
            assertEquals(0, activity.mFinishCallbackCount);
        } else if (Build.VERSION.SDK_INT == Build.VERSION_CODES.LOLLIPOP) {
            long startTime = SystemClock.uptimeMillis();
            while (activity.mFinishCallbackCount == 0
                    && SystemClock.uptimeMillis() - startTime < WAIT_TIMEOUT_IN_MS) {
                Thread.sleep(SLEEP_INTERVAL_IN_MS);
            }

            // MockActivity#finishAndRemoveTask() never sets isFinishing() to true for LOLLIPOP to
            // simulate an exceptional case. In that case, MockActivity#finish() should be called
            // after 3 tries.
            assertEquals(3, activity.mFinishAndRemoveTaskCallbackCount);
            assertEquals(1, activity.mFinishCallbackCount);
        } else {
            assertEquals(0, activity.mFinishAndRemoveTaskCallbackCount);
            assertEquals(1, activity.mFinishCallbackCount);
        }
        assertTrue(activity.mIsFinishing);
    }
}

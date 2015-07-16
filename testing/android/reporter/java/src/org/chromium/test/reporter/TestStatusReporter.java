// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.test.reporter;

import android.content.Context;
import android.content.Intent;

import org.chromium.base.ThreadUtils;

import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Broadcasts test status to any listening {@link org.chromium.test.reporter.TestStatusReceiver}.
 */
public class TestStatusReporter {

    public static final String ACTION_HEARTBEAT =
            "org.chromium.test.reporter.TestStatusReporter.HEARTBEAT";
    public static final String ACTION_TEST_STARTED =
            "org.chromium.test.reporter.TestStatusReporter.TEST_STARTED";
    public static final String ACTION_TEST_PASSED =
            "org.chromium.test.reporter.TestStatusReporter.TEST_PASSED";
    public static final String ACTION_TEST_FAILED =
            "org.chromium.test.reporter.TestStatusReporter.TEST_FAILED";
    public static final String DATA_TYPE_HEARTBEAT = "org.chromium.test.reporter/heartbeat";
    public static final String DATA_TYPE_RESULT = "org.chromium.test.reporter/result";
    public static final String EXTRA_TEST_CLASS =
            "org.chromium.test.reporter.TestStatusReporter.TEST_CLASS";
    public static final String EXTRA_TEST_METHOD =
            "org.chromium.test.reporter.TestStatusReporter.TEST_METHOD";

    public static final int HEARTBEAT_INTERVAL_MS = 5000;

    private final Context mContext;
    private final AtomicBoolean mKeepBeating = new AtomicBoolean(false);

    public TestStatusReporter(Context c) {
        mContext = c;
    }

    public void startHeartbeat() {
        mKeepBeating.set(true);
        Runnable heartbeat = new Runnable() {
            @Override
            public void run() {
                Intent i = new Intent(ACTION_HEARTBEAT);
                i.setType(DATA_TYPE_HEARTBEAT);
                mContext.sendBroadcast(i);
                if (mKeepBeating.get()) {
                    ThreadUtils.postOnUiThreadDelayed(this, HEARTBEAT_INTERVAL_MS);
                }
            }
        };
        ThreadUtils.postOnUiThreadDelayed(heartbeat, HEARTBEAT_INTERVAL_MS);
    }

    public void testStarted(String testClass, String testMethod) {
        sendBroadcast(testClass, testMethod, ACTION_TEST_STARTED);
    }

    public void testPassed(String testClass, String testMethod) {
        sendBroadcast(testClass, testMethod, ACTION_TEST_PASSED);
    }

    public void testFailed(String testClass, String testMethod) {
        sendBroadcast(testClass, testMethod, ACTION_TEST_FAILED);
    }

    public void stopHeartbeat() {
        mKeepBeating.set(false);
    }

    private void sendBroadcast(String testClass, String testMethod, String action) {
        Intent i = new Intent(action);
        i.setType(DATA_TYPE_RESULT);
        i.putExtra(EXTRA_TEST_CLASS, testClass);
        i.putExtra(EXTRA_TEST_METHOD, testMethod);
        mContext.sendBroadcast(i);
    }

}

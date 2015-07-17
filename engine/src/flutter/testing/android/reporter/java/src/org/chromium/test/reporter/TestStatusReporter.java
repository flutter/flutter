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
    public static final String ACTION_TEST_RUN_STARTED =
            "org.chromium.test.reporter.TestStatusReporter.TEST_RUN_STARTED";
    public static final String ACTION_TEST_RUN_FINISHED =
            "org.chromium.test.reporter.TestStatusReporter.TEST_RUN_FINISHED";
    public static final String DATA_TYPE_HEARTBEAT = "org.chromium.test.reporter/heartbeat";
    public static final String DATA_TYPE_RESULT = "org.chromium.test.reporter/result";
    public static final String EXTRA_PID =
            "org.chromium.test.reporter.TestStatusReporter.PID";
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
        sendTestBroadcast(ACTION_TEST_STARTED, testClass, testMethod);
    }

    public void testPassed(String testClass, String testMethod) {
        sendTestBroadcast(ACTION_TEST_PASSED, testClass, testMethod);
    }

    public void testFailed(String testClass, String testMethod) {
        sendTestBroadcast(ACTION_TEST_FAILED, testClass, testMethod);
    }

    private void sendTestBroadcast(String action, String testClass, String testMethod) {
        Intent i = new Intent(action);
        i.setType(DATA_TYPE_RESULT);
        i.putExtra(EXTRA_TEST_CLASS, testClass);
        i.putExtra(EXTRA_TEST_METHOD, testMethod);
        mContext.sendBroadcast(i);
    }

    public void testRunStarted(int pid) {
        sendTestRunBroadcast(ACTION_TEST_RUN_STARTED, pid);
    }

    public void testRunFinished(int pid) {
        sendTestRunBroadcast(ACTION_TEST_RUN_FINISHED, pid);
    }

    private void sendTestRunBroadcast(String action, int pid) {
        Intent i = new Intent(action);
        i.setType(DATA_TYPE_RESULT);
        i.putExtra(EXTRA_PID, pid);
        mContext.sendBroadcast(i);
    }

    public void stopHeartbeat() {
        mKeepBeating.set(false);
    }

}

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.test.reporter;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;

import org.chromium.base.Log;

import java.util.ArrayList;
import java.util.List;

/** Receives test status broadcasts send from
    {@link org.chromium.test.reporter.TestStatusReporter}.
 */
public class TestStatusReceiver extends BroadcastReceiver {

    private static final String TAG = "cr.test.reporter";

    private final List<FailCallback> mFailCallbacks = new ArrayList<FailCallback>();
    private final List<HeartbeatCallback> mHeartbeatCallbacks = new ArrayList<HeartbeatCallback>();
    private final List<PassCallback> mPassCallbacks = new ArrayList<PassCallback>();
    private final List<StartCallback> mStartCallbacks = new ArrayList<StartCallback>();
    private final List<TestRunCallback> mTestRunCallbacks = new ArrayList<TestRunCallback>();

    /** An IntentFilter that matches the intents that this class can receive. */
    private static final IntentFilter INTENT_FILTER;
    static {
        IntentFilter filter = new IntentFilter();
        filter.addAction(TestStatusReporter.ACTION_HEARTBEAT);
        filter.addAction(TestStatusReporter.ACTION_TEST_FAILED);
        filter.addAction(TestStatusReporter.ACTION_TEST_PASSED);
        filter.addAction(TestStatusReporter.ACTION_TEST_STARTED);
        filter.addAction(TestStatusReporter.ACTION_TEST_RUN_STARTED);
        filter.addAction(TestStatusReporter.ACTION_TEST_RUN_FINISHED);
        try {
            filter.addDataType(TestStatusReporter.DATA_TYPE_HEARTBEAT);
            filter.addDataType(TestStatusReporter.DATA_TYPE_RESULT);
        } catch (IntentFilter.MalformedMimeTypeException e) {
            Log.wtf(TAG, "Invalid MIME type", e);
        }
        INTENT_FILTER = filter;
    }

    /** A callback used when a test has failed. */
    public interface FailCallback {
        void testFailed(String testClass, String testMethod);
    }

    /** A callback used when a heartbeat is received. */
    public interface HeartbeatCallback {
        void heartbeat();
    }

    /** A callback used when a test has passed. */
    public interface PassCallback {
        void testPassed(String testClass, String testMethod);
    }

    /** A callback used when a test has started. */
    public interface StartCallback {
        void testStarted(String testClass, String testMethod);
    }

    /** A callback used when a test run has started or finished. */
    public interface TestRunCallback {
        void testRunStarted(int pid);
        void testRunFinished(int pid);
    }

    /** Register a callback for when a test has failed. */
    public void registerCallback(FailCallback c) {
        mFailCallbacks.add(c);
    }

    /** Register a callback for when a heartbeat is received. */
    public void registerCallback(HeartbeatCallback c) {
        mHeartbeatCallbacks.add(c);
    }

    /** Register a callback for when a test has passed. */
    public void registerCallback(PassCallback c) {
        mPassCallbacks.add(c);
    }

    /** Register a callback for when a test has started. */
    public void registerCallback(StartCallback c) {
        mStartCallbacks.add(c);
    }

    /** Register a callback for when a test run has started or finished. */
    public void registerCallback(TestRunCallback c) {
        mTestRunCallbacks.add(c);
    }

    /** Register this receiver using the provided context. */
    public void register(Context c) {
        c.registerReceiver(this, INTENT_FILTER);
    }

    /** Receive a broadcast intent.
     *
     * @param context The Context in which the receiver is running.
     * @param intent The intent received.
     */
    @Override
    public void onReceive(Context context, Intent intent) {
        int pid = intent.getIntExtra(TestStatusReporter.EXTRA_PID, 0);
        String testClass = intent.getStringExtra(TestStatusReporter.EXTRA_TEST_CLASS);
        String testMethod = intent.getStringExtra(TestStatusReporter.EXTRA_TEST_METHOD);

        switch (intent.getAction()) {
            case TestStatusReporter.ACTION_TEST_STARTED:
                for (StartCallback c : mStartCallbacks) {
                    c.testStarted(testClass, testMethod);
                }
                break;
            case TestStatusReporter.ACTION_TEST_PASSED:
                for (PassCallback c : mPassCallbacks) {
                    c.testPassed(testClass, testMethod);
                }
                break;
            case TestStatusReporter.ACTION_TEST_FAILED:
                for (FailCallback c : mFailCallbacks) {
                    c.testFailed(testClass, testMethod);
                }
                break;
            case TestStatusReporter.ACTION_HEARTBEAT:
                for (HeartbeatCallback c : mHeartbeatCallbacks) {
                    c.heartbeat();
                }
                break;
            case TestStatusReporter.ACTION_TEST_RUN_STARTED:
                for (TestRunCallback c: mTestRunCallbacks) {
                    c.testRunStarted(pid);
                }
                break;
            case TestStatusReporter.ACTION_TEST_RUN_FINISHED:
                for (TestRunCallback c: mTestRunCallbacks) {
                    c.testRunFinished(pid);
                }
                break;
            default:
                Log.e(TAG, "Unrecognized intent received: %s", intent.toString());
                break;
        }
    }

}


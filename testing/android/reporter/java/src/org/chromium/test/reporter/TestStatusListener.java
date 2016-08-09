// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.test.reporter;

import android.content.Context;
import android.util.Log;

import junit.framework.AssertionFailedError;
import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestListener;

/**
 * A TestListener that reports when tests start, pass, or fail.
 */
public class TestStatusListener implements TestListener {

    private static final String TAG = "TestStatusListener";

    private boolean mFailed;
    private final TestStatusReporter mReporter;

    public TestStatusListener(Context context) {
        mReporter = new TestStatusReporter(context);
    }

    /** Called when an error has occurred while running a test.

        Note that an error usually means a problem with the test or test harness, not with
        the code under test.

        @param test The test in which the error occurred.
        @param t The exception that was raised.
     */
    @Override
    public void addError(Test test, Throwable t) {
        Log.e(TAG, "Error while running " + test.toString(), t);
        mFailed = true;
    }

    /** Called when a test has failed.

        @param test The test in which the failure occurred.
        @param t The exception that was raised.
     */
    public void addFailure(Test test, AssertionFailedError e) {
        Log.e(TAG, "Failure while running " + test.toString(), e);
        mFailed = true;
    }

    /** Called when a test has started.
        @param test The test that started.
     */
    @Override
    public void startTest(Test test) {
        mFailed = false;
        TestCase testCase = (TestCase) test;
        mReporter.startHeartbeat();
        mReporter.testStarted(testCase.getClass().getName(), testCase.getName());
    }

    /** Called when a test has ended.
        @param test The test that ended.
     */
    @Override
    public void endTest(Test test) {
        TestCase testCase = (TestCase) test;
        if (mFailed) {
            mReporter.testFailed(testCase.getClass().getName(), testCase.getName());
        } else {
            mReporter.testPassed(testCase.getClass().getName(), testCase.getName());
        }
        mReporter.stopHeartbeat();
    }

}

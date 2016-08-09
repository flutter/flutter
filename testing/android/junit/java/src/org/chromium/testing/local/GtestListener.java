// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.testing.local;

import org.junit.runner.Description;
import org.junit.runner.Result;
import org.junit.runner.notification.Failure;
import org.junit.runner.notification.RunListener;

import java.util.HashSet;
import java.util.Set;

/** A JUnit RunListener that emulates GTest output to the extent that it can.
 */
public class GtestListener extends RunListener {

    private Set<Description> mFailedTests;
    private final GtestLogger mLogger;
    private long mRunStartTimeMillis;
    private long mTestStartTimeMillis;
    private int mTestsPassed;
    private boolean mCurrentTestPassed;

    public GtestListener(GtestLogger logger) {
        mLogger = logger;
    }

    /** Called before any tests run.
     */
    @Override
    public void testRunStarted(Description d) throws Exception {
        mLogger.testRunStarted(d.testCount());
        mRunStartTimeMillis = System.currentTimeMillis();
        mTestsPassed = 0;
        mFailedTests = new HashSet<Description>();
        mCurrentTestPassed = true;
    }

    /** Called after all tests run.
     */
    @Override
    public void testRunFinished(Result r) throws Exception {
        long elapsedTimeMillis = System.currentTimeMillis() - mRunStartTimeMillis;
        mLogger.testRunFinished(mTestsPassed, mFailedTests, elapsedTimeMillis);
    }

    /** Called when a test is about to start.
     */
    @Override
    public void testStarted(Description d) throws Exception {
        mCurrentTestPassed = true;
        mLogger.testStarted(d);
        mTestStartTimeMillis = System.currentTimeMillis();
    }

    /** Called when a test has just finished.
     */
    @Override
    public void testFinished(Description d) throws Exception {
        long testElapsedTimeMillis = System.currentTimeMillis() - mTestStartTimeMillis;
        mLogger.testFinished(d, mCurrentTestPassed, testElapsedTimeMillis);
        if (mCurrentTestPassed) {
            ++mTestsPassed;
        } else {
            mFailedTests.add(d);
        }
    }

    /** Called when a test fails.
     */
    @Override
    public void testFailure(Failure f) throws Exception {
        mCurrentTestPassed = false;
        mLogger.testFailed(f);
    }

}


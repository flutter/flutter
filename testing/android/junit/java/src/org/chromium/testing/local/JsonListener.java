// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.testing.local;

import org.junit.runner.Description;
import org.junit.runner.Result;
import org.junit.runner.notification.Failure;
import org.junit.runner.notification.RunListener;

/** A json RunListener that creates a Json file with test run information.
 */
public class JsonListener extends RunListener {

    private final JsonLogger mJsonLogger;
    private long mTestStartTimeMillis;
    private boolean mCurrentTestPassed;

    public JsonListener(JsonLogger jsonLogger) {
        mJsonLogger = jsonLogger;
    }

    /** Called after all tests run.
     */
    @Override
    public void testRunFinished(Result r) throws Exception {
        mJsonLogger.writeJsonToFile();
    }

    /** Called when a test is about to start.
     */
    @Override
    public void testStarted(Description d) throws Exception {
        mCurrentTestPassed = true;
        mTestStartTimeMillis = System.currentTimeMillis();
    }

    /** Called when a test has just finished.
     */
    @Override
    public void testFinished(Description d) throws Exception {
        long testElapsedTimeMillis = System.currentTimeMillis() - mTestStartTimeMillis;
        mJsonLogger.addTestResultInfo(d, mCurrentTestPassed, testElapsedTimeMillis);
    }

    /** Called when a test fails.
     */
    @Override
    public void testFailure(Failure f) throws Exception {
        mCurrentTestPassed = false;
    }
}


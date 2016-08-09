// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.testing.local;

import org.junit.runner.Description;
import org.junit.runner.notification.Failure;

import java.io.PrintStream;
import java.util.Set;

/**
 *  Formats and logs test status information in googletest-style.
 */
public class GtestLogger  {

    private final PrintStream mOutputStream;

    public GtestLogger(PrintStream outputStream) {
        mOutputStream = outputStream;
    }

    /**
     *  Logs the start of an individual test.
     */
    public void testStarted(Description test) {
        mOutputStream.format("[ RUN      ] %s.%s", test.getClassName(), test.getMethodName());
        mOutputStream.println();
    }

    /**
     * Logs a test failure.
     */
    public void testFailed(Failure f) {
        if (f.getException() != null) {
            f.getException().printStackTrace(mOutputStream);
        }
    }

    /**
     *  Logs the end of an individual test.
     */
    public void testFinished(Description test, boolean passed, long elapsedTimeMillis) {
        if (passed) {
            mOutputStream.format("[       OK ] %s.%s (%d ms)",
                    test.getClassName(), test.getMethodName(), elapsedTimeMillis);
        } else {
            mOutputStream.format("[   FAILED ] %s.%s (%d ms)",
                    test.getClassName(), test.getMethodName(), elapsedTimeMillis);
        }
        mOutputStream.println();
    }

    /**
     *  Logs the start of a test case.
     */
    public void testCaseStarted(Description test, int testCount) {
        mOutputStream.format("[----------] Run %d test cases from %s", testCount,
                test.getClassName());
        mOutputStream.println();
    }

    /**
     *  Logs the end of a test case.
     */
    public void testCaseFinished(Description test, int testCount,
            long elapsedTimeMillis) {
        mOutputStream.format("[----------] Run %d test cases from %s (%d ms)",
                testCount, test.getClassName(), elapsedTimeMillis);
        mOutputStream.println();
        mOutputStream.println();
    }

    /**
     *  Logs the start of a test run.
     */
    public void testRunStarted(int testCount) {
        mOutputStream.format("[==========] Running %d tests.", testCount);
        mOutputStream.println();
        mOutputStream.println("[----------] Global test environment set-up.");
        mOutputStream.println();
    }

    /**
     *  Logs the end of a test run.
     */
    public void testRunFinished(int passedTestCount, Set<Description> failedTests,
            long elapsedTimeMillis) {
        int totalTestCount = passedTestCount + failedTests.size();
        mOutputStream.println("[----------] Global test environment tear-down.");
        mOutputStream.format("[==========] %d tests ran. (%d ms total)",
                totalTestCount, elapsedTimeMillis);
        mOutputStream.println();
        mOutputStream.format("[  PASSED  ] %d tests.", passedTestCount);
        mOutputStream.println();
        if (!failedTests.isEmpty()) {
            mOutputStream.format("[  FAILED  ] %d tests.", failedTests.size());
            mOutputStream.println();
            for (Description d : failedTests) {
                mOutputStream.format("[  FAILED  ] %s.%s", d.getClassName(), d.getMethodName());
                mOutputStream.println();
            }
            mOutputStream.println();
        }
    }

}


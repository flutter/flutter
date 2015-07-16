// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.testing.local;

import org.junit.Assert;
import org.junit.Test;
import org.junit.runner.Description;
import org.junit.runner.RunWith;
import org.junit.runners.BlockJUnit4ClassRunner;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.io.Serializable;
import java.util.Comparator;
import java.util.HashSet;
import java.util.Set;
import java.util.TreeSet;

/**
 *  Unit tests for GtestLogger.
 */
@RunWith(BlockJUnit4ClassRunner.class)
public class GtestLoggerTest {

    @Test
    public void testTestStarted() {
        ByteArrayOutputStream actual = new ByteArrayOutputStream();
        GtestLogger loggerUnderTest = new GtestLogger(new PrintStream(actual));
        loggerUnderTest.testStarted(
                Description.createTestDescription(GtestLoggerTest.class, "testTestStarted"));
        Assert.assertEquals(
                "[ RUN      ] org.chromium.testing.local.GtestLoggerTest.testTestStarted\n",
                actual.toString());
    }

    @Test
    public void testTestFinishedPassed() {
        ByteArrayOutputStream actual = new ByteArrayOutputStream();
        GtestLogger loggerUnderTest = new GtestLogger(new PrintStream(actual));
        loggerUnderTest.testFinished(
                Description.createTestDescription(GtestLoggerTest.class, "testTestFinishedPassed"),
                true, 123);
        Assert.assertEquals(
                "[       OK ] org.chromium.testing.local.GtestLoggerTest.testTestFinishedPassed"
                        + " (123 ms)\n",
                actual.toString());
    }

    @Test
    public void testTestFinishedFailed() {
        ByteArrayOutputStream actual = new ByteArrayOutputStream();
        GtestLogger loggerUnderTest = new GtestLogger(new PrintStream(actual));
        loggerUnderTest.testFinished(
                Description.createTestDescription(GtestLoggerTest.class, "testTestFinishedPassed"),
                false, 123);
        Assert.assertEquals(
                "[   FAILED ] org.chromium.testing.local.GtestLoggerTest.testTestFinishedPassed"
                        + " (123 ms)\n",
                actual.toString());
    }

    @Test
    public void testTestCaseStarted() {
        ByteArrayOutputStream actual = new ByteArrayOutputStream();
        GtestLogger loggerUnderTest = new GtestLogger(new PrintStream(actual));
        loggerUnderTest.testCaseStarted(
                Description.createSuiteDescription(GtestLoggerTest.class), 456);
        Assert.assertEquals(
                "[----------] Run 456 test cases from org.chromium.testing.local.GtestLoggerTest\n",
                actual.toString());
    }

    @Test
    public void testTestCaseFinished() {
        ByteArrayOutputStream actual = new ByteArrayOutputStream();
        GtestLogger loggerUnderTest = new GtestLogger(new PrintStream(actual));
        loggerUnderTest.testCaseFinished(
                Description.createSuiteDescription(GtestLoggerTest.class), 456, 123);
        Assert.assertEquals(
                "[----------] Run 456 test cases from org.chromium.testing.local.GtestLoggerTest"
                        + " (123 ms)\n\n",
                actual.toString());
    }

    @Test
    public void testTestRunStarted() {
        ByteArrayOutputStream actual = new ByteArrayOutputStream();
        GtestLogger loggerUnderTest = new GtestLogger(new PrintStream(actual));
        loggerUnderTest.testRunStarted(1234);
        Assert.assertEquals(
                "[==========] Running 1234 tests.\n"
                        + "[----------] Global test environment set-up.\n\n",
                actual.toString());
    }

    @Test
    public void testTestRunFinishedNoFailures() {
        ByteArrayOutputStream actual = new ByteArrayOutputStream();
        GtestLogger loggerUnderTest = new GtestLogger(new PrintStream(actual));
        loggerUnderTest.testRunFinished(1234, new HashSet<Description>(), 4321);
        Assert.assertEquals(
                "[----------] Global test environment tear-down.\n"
                        + "[==========] 1234 tests ran. (4321 ms total)\n"
                        + "[  PASSED  ] 1234 tests.\n",
                actual.toString());
    }

    @Test
    public void testTestRunFinishedWithFailures() {
        ByteArrayOutputStream actual = new ByteArrayOutputStream();
        GtestLogger loggerUnderTest = new GtestLogger(new PrintStream(actual));

        Set<Description> failures = new TreeSet<Description>(new DescriptionComparator());
        failures.add(Description.createTestDescription(
                GtestLoggerTest.class, "testTestRunFinishedNoFailures"));
        failures.add(Description.createTestDescription(
                GtestLoggerTest.class, "testTestRunFinishedWithFailures"));

        loggerUnderTest.testRunFinished(1232, failures, 4312);
        Assert.assertEquals(
                "[----------] Global test environment tear-down.\n"
                        + "[==========] 1234 tests ran. (4312 ms total)\n"
                        + "[  PASSED  ] 1232 tests.\n"
                        + "[  FAILED  ] 2 tests.\n"
                        + "[  FAILED  ] org.chromium.testing.local.GtestLoggerTest"
                        + ".testTestRunFinishedNoFailures\n"
                        + "[  FAILED  ] org.chromium.testing.local.GtestLoggerTest"
                        + ".testTestRunFinishedWithFailures\n"
                        + "\n",
                actual.toString());
    }

    private static class DescriptionComparator implements Comparator<Description>, Serializable {
        @Override
        public int compare(Description o1, Description o2) {
            return toGtestStyleString(o1).compareTo(toGtestStyleString(o2));
        }

        private static String toGtestStyleString(Description d) {
            return d.getClassName() + "." + d.getMethodName();
        }
    }
}


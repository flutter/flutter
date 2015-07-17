// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.test;

import android.os.Build;
import android.os.Bundle;
import android.test.AndroidTestRunner;
import android.test.InstrumentationTestRunner;
import android.util.Log;

import junit.framework.TestCase;
import junit.framework.TestResult;

import org.chromium.base.test.util.MinAndroidSdkLevel;
import org.chromium.test.reporter.TestStatusListener;

import java.util.ArrayList;
import java.util.List;

// TODO(jbudorick): Add support for on-device handling of timeouts.
/**
 *  An Instrumentation test runner that checks SDK level for tests with specific requirements.
 */
public class BaseInstrumentationTestRunner extends InstrumentationTestRunner {

    private static final String TAG = "BaseInstrumentationTestRunner";

    /**
     * An interface for classes that check whether a test case should be skipped.
     */
    public interface SkipCheck {
        /**
         * Checks whether the given test case should be skipped.
         *
         * @param testCase The test case to check.
         * @return Whether the test case should be skipped.
         */
        public boolean shouldSkip(TestCase testCase);
    }

    /**
     * A test result that can skip tests.
     */
    public class SkippingTestResult extends TestResult {

        private final List<SkipCheck> mSkipChecks;

        /**
         * Creates an instance of SkippingTestResult.
         */
        public SkippingTestResult() {
            mSkipChecks = new ArrayList<SkipCheck>();
        }

        /**
         * Adds a check for whether a test should run.
         *
         * @param skipCheck The check to add.
         */
        public void addSkipCheck(SkipCheck skipCheck) {
            mSkipChecks.add(skipCheck);
        }

        private boolean shouldSkip(final TestCase test) {
            for (SkipCheck s : mSkipChecks) {
                if (s.shouldSkip(test)) return true;
            }
            return false;
        }

        @Override
        protected void run(final TestCase test) {
            if (shouldSkip(test)) {
                startTest(test);

                Bundle skipResult = new Bundle();
                skipResult.putString("class", test.getClass().getName());
                skipResult.putString("test", test.getName());
                skipResult.putBoolean("test_skipped", true);
                sendStatus(0, skipResult);

                endTest(test);
            } else {
                super.run(test);
            }
        }
    }

    @Override
    protected AndroidTestRunner getAndroidTestRunner() {
        AndroidTestRunner runner = new AndroidTestRunner() {
            @Override
            protected TestResult createTestResult() {
                SkippingTestResult r = new SkippingTestResult();
                addSkipChecks(r);
                return r;
            }
        };
        runner.addTestListener(new TestStatusListener(getContext()));
        return runner;
    }

    /**
     * Adds the desired SkipChecks to result. Subclasses can add additional SkipChecks.
     */
    protected void addSkipChecks(SkippingTestResult result) {
        result.addSkipCheck(new MinAndroidSdkLevelSkipCheck());
    }

    /**
     * Checks the device's SDK level against any specified minimum requirement.
     */
    public static class MinAndroidSdkLevelSkipCheck implements SkipCheck {

        /**
         * If {@link org.chromium.base.test.util.MinAndroidSdkLevel} is present, checks its value
         * against the device's SDK level.
         *
         * @param testCase The test to check.
         * @return true if the device's SDK level is below the specified minimum.
         */
        @Override
        public boolean shouldSkip(TestCase testCase) {
            Class<?> testClass = testCase.getClass();
            if (testClass.isAnnotationPresent(MinAndroidSdkLevel.class)) {
                MinAndroidSdkLevel v = testClass.getAnnotation(MinAndroidSdkLevel.class);
                if (Build.VERSION.SDK_INT < v.value()) {
                    Log.i(TAG, "Test " + testClass.getName() + "#" + testCase.getName()
                            + " is not enabled at SDK level " + Build.VERSION.SDK_INT
                            + ".");
                    return true;
                }
            }
            return false;
        }
    }

}

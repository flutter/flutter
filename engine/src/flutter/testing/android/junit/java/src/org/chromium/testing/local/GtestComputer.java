// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.testing.local;

import org.junit.runner.Computer;
import org.junit.runner.Description;
import org.junit.runner.Runner;
import org.junit.runner.manipulation.Filter;
import org.junit.runner.manipulation.Filterable;
import org.junit.runner.manipulation.NoTestsRemainException;
import org.junit.runner.notification.RunNotifier;
import org.junit.runners.model.InitializationError;
import org.junit.runners.model.RunnerBuilder;

/**
 *  A Computer that logs the start and end of test cases googletest-style.
 */
public class GtestComputer extends Computer {

    private final GtestLogger mLogger;

    public GtestComputer(GtestLogger logger) {
        mLogger = logger;
    }

    /**
     *  A wrapping Runner that logs the start and end of each test case.
     */
    private class GtestSuiteRunner extends Runner implements Filterable {
        private final Runner mRunner;

        public GtestSuiteRunner(Runner contained) {
            mRunner = contained;
        }

        public Description getDescription() {
            return mRunner.getDescription();
        }

        public void run(RunNotifier notifier) {
            long startTimeMillis = System.currentTimeMillis();
            mLogger.testCaseStarted(mRunner.getDescription(),
                    mRunner.getDescription().testCount());
            mRunner.run(notifier);
            mLogger.testCaseFinished(mRunner.getDescription(),
                    mRunner.getDescription().testCount(),
                    System.currentTimeMillis() - startTimeMillis);
        }

        public void filter(Filter filter) throws NoTestsRemainException {
            if (mRunner instanceof Filterable) {
                ((Filterable) mRunner).filter(filter);
            }
        }
    }

    /**
     *  Returns a suite of unit tests with each class runner wrapped by a
     *  GtestSuiteRunner.
     */
    @Override
    public Runner getSuite(final RunnerBuilder builder, Class<?>[] classes)
            throws InitializationError {
        return super.getSuite(
                new RunnerBuilder() {
                    @Override
                    public Runner runnerForClass(Class<?> testClass) throws Throwable {
                        return new GtestSuiteRunner(builder.runnerForClass(testClass));
                    }
                }, classes);
    }

}


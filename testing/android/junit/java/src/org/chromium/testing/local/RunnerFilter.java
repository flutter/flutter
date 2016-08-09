// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.testing.local;

import org.junit.runner.Description;
import org.junit.runner.RunWith;
import org.junit.runner.manipulation.Filter;

/**
 *  Filters tests based on the Runner class annotating the test class.
 */
class RunnerFilter extends Filter {

    private final Class<?> mRunnerClass;

    /**
     *  Creates the filter.
     */
    public RunnerFilter(Class<?> runnerClass) {
        mRunnerClass = runnerClass;
    }

    /**
     *  Determines whether or not a test with the provided description should
     *  run based on the Runner class annotating the test class.
     */
    @Override
    public boolean shouldRun(Description description) {
        Class<?> c = description.getTestClass();
        return c != null && c.isAnnotationPresent(RunWith.class)
                && c.getAnnotation(RunWith.class).value() == mRunnerClass;
    }

    /**
     *  Returns a description of this filter.
     */
    @Override
    public String describe() {
        return "runner-filter: " + mRunnerClass.getName();
    }

}


// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.testing.local;

import org.junit.runner.Description;
import org.junit.runner.manipulation.Filter;

/**
 *  Filters tests based on the package.
 */
class PackageFilter extends Filter {

    private final String mFilterString;

    /**
     *  Creates the filter.
     */
    public PackageFilter(String filterString) {
        mFilterString = filterString;
    }

    /**
     *  Determines whether or not a test with the provided description should
     *  run based on its package.
     */
    @Override
    public boolean shouldRun(Description description) {
        return description.getTestClass().getPackage().getName().equals(mFilterString);
    }

    /**
     *  Returns a description of this filter.
     */
    @Override
    public String describe() {
        return "package-filter: " + mFilterString;
    }

}

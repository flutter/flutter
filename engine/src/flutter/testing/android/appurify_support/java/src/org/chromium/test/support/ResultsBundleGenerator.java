// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.test.support;

import android.os.Bundle;

import java.util.Map;

/**
 * Creates a results Bundle.
 */
public interface ResultsBundleGenerator {

    /** Indicates the state of a test.
     */
    static enum TestResult {
        PASSED, FAILED, ERROR, UNKNOWN
    }

    /** Creates a bundle of test results from the provided raw results.

        Note: actual bundle content and format may vary.

        @param rawResults A map between test names and test results.
     */
    Bundle generate(Map<String, TestResult> rawResults);
}


// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.test.support;

import android.app.Instrumentation;
import android.os.Bundle;
import android.util.Log;

import java.util.Map;

/**
 * Creates a results bundle that emulates the one created by Robotium.
 */
public class RobotiumBundleGenerator implements ResultsBundleGenerator {

    private static final String TAG = "RobotiumBundleGenerator";

    public Bundle generate(Map<String, ResultsBundleGenerator.TestResult> rawResults) {
        int testsPassed = 0;
        int testsFailed = 0;
        int testsErrored = 0;

        for (Map.Entry<String, ResultsBundleGenerator.TestResult> entry : rawResults.entrySet()) {
            switch (entry.getValue()) {
                case PASSED:
                    ++testsPassed;
                    break;
                case FAILED:
                    // TODO(jbudorick): Remove this log message once AMP execution and
                    // results handling has been stabilized.
                    Log.d(TAG, "FAILED: " + entry.getKey());
                    ++testsFailed;
                    break;
                case UNKNOWN:
                    ++testsErrored;
                    break;
                default:
                    Log.w(TAG, "Unhandled: " + entry.getKey() + ", "
                            + entry.getValue().toString());
                    break;
            }
        }

        StringBuilder resultBuilder = new StringBuilder();
        if (testsFailed > 0 || testsErrored > 0) {
            resultBuilder.append("\nFAILURES!!! ")
                    .append("Tests run: ").append(Integer.toString(rawResults.size()))
                    .append(", Failures: ").append(Integer.toString(testsFailed))
                    .append(", Errors: ").append(Integer.toString(testsErrored));
        } else {
            resultBuilder.append("\nOK (" + Integer.toString(testsPassed) + " tests)");
        }

        Bundle resultsBundle = new Bundle();
        resultsBundle.putString(Instrumentation.REPORT_KEY_STREAMRESULT,
                resultBuilder.toString());
        return resultsBundle;
    }
}

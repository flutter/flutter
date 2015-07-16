// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.native_test;

import android.app.Activity;
import android.app.Instrumentation;
import android.content.ComponentName;
import android.content.Intent;
import android.os.Bundle;
import android.os.Environment;

import org.chromium.base.Log;
import org.chromium.test.support.ResultsBundleGenerator;
import org.chromium.test.support.RobotiumBundleGenerator;

import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 *  An Instrumentation that runs tests based on NativeTestActivity.
 */
public class NativeTestInstrumentationTestRunner extends Instrumentation {

    public static final String EXTRA_NATIVE_TEST_ACTIVITY =
            "org.chromium.native_test.NativeTestInstrumentationTestRunner."
                    + "NativeTestActivity";

    private static final String TAG = "cr.native_test";

    private static final int ACCEPT_TIMEOUT_MS = 5000;
    private static final String DEFAULT_NATIVE_TEST_ACTIVITY =
            "org.chromium.native_test.NativeUnitTestActivity";
    private static final Pattern RE_TEST_OUTPUT = Pattern.compile("\\[ *([^ ]*) *\\] ?([^ ]+) .*");

    private ResultsBundleGenerator mBundleGenerator = new RobotiumBundleGenerator();
    private String mCommandLineFile;
    private String mCommandLineFlags;
    private String mNativeTestActivity;
    private Bundle mLogBundle = new Bundle();
    private File mStdoutFile;

    @Override
    public void onCreate(Bundle arguments) {
        mCommandLineFile = arguments.getString(NativeTestActivity.EXTRA_COMMAND_LINE_FILE);
        mCommandLineFlags = arguments.getString(NativeTestActivity.EXTRA_COMMAND_LINE_FLAGS);
        mNativeTestActivity = arguments.getString(EXTRA_NATIVE_TEST_ACTIVITY);
        if (mNativeTestActivity == null) mNativeTestActivity = DEFAULT_NATIVE_TEST_ACTIVITY;

        try {
            mStdoutFile = File.createTempFile(
                    ".temp_stdout_", ".txt", Environment.getExternalStorageDirectory());
            Log.i(TAG, "stdout file created: %s", mStdoutFile.getAbsolutePath());
        } catch (IOException e) {
            Log.e(TAG, "Unable to create temporary stdout file.", e);
            finish(Activity.RESULT_CANCELED, new Bundle());
            return;
        }
        start();
    }

    @Override
    public void onStart() {
        super.onStart();
        Bundle results = runTests();
        finish(Activity.RESULT_OK, results);
    }

    /** Runs the tests in the NativeTestActivity and returns a Bundle containing the results.
     */
    private Bundle runTests() {
        Log.i(TAG, "Creating activity.");
        Activity activityUnderTest = startNativeTestActivity();

        Log.i(TAG, "Waiting for tests to finish.");
        try {
            while (!activityUnderTest.isFinishing()) {
                Thread.sleep(100);
            }
        } catch (InterruptedException e) {
            Log.e(TAG, "Interrupted while waiting for activity to be destroyed: ", e);
        }

        Log.i(TAG, "Getting results.");
        Map<String, ResultsBundleGenerator.TestResult> results = parseResults(activityUnderTest);

        Log.i(TAG, "Parsing results and generating output.");
        return mBundleGenerator.generate(results);
    }

    /** Starts the NativeTestActivty.
     */
    private Activity startNativeTestActivity() {
        Intent i = new Intent(Intent.ACTION_MAIN);
        i.setComponent(new ComponentName(getContext().getPackageName(), mNativeTestActivity));
        i.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        if (mCommandLineFile != null) {
            Log.i(TAG, "Passing command line file extra: %s", mCommandLineFile);
            i.putExtra(NativeTestActivity.EXTRA_COMMAND_LINE_FILE, mCommandLineFile);
        }
        if (mCommandLineFlags != null) {
            Log.i(TAG, "Passing command line flag extra: %s", mCommandLineFlags);
            i.putExtra(NativeTestActivity.EXTRA_COMMAND_LINE_FLAGS, mCommandLineFlags);
        }
        i.putExtra(NativeTestActivity.EXTRA_STDOUT_FILE, mStdoutFile.getAbsolutePath());
        return startActivitySync(i);
    }

    /**
     *  Generates a map between test names and test results from the instrumented Activity's
     *  output.
     */
    private Map<String, ResultsBundleGenerator.TestResult> parseResults(
            Activity activityUnderTest) {
        Map<String, ResultsBundleGenerator.TestResult> results =
                new HashMap<String, ResultsBundleGenerator.TestResult>();

        BufferedReader r = null;

        try {
            if (mStdoutFile == null || !mStdoutFile.exists()) {
                Log.e(TAG, "Unable to find stdout file.");
                return results;
            }

            r = new BufferedReader(new InputStreamReader(
                    new BufferedInputStream(new FileInputStream(mStdoutFile))));

            for (String l = r.readLine(); l != null && !l.equals("<<ScopedMainEntryLogger");
                    l = r.readLine()) {
                Matcher m = RE_TEST_OUTPUT.matcher(l);
                if (m.matches()) {
                    if (m.group(1).equals("RUN")) {
                        results.put(m.group(2), ResultsBundleGenerator.TestResult.UNKNOWN);
                    } else if (m.group(1).equals("FAILED")) {
                        results.put(m.group(2), ResultsBundleGenerator.TestResult.FAILED);
                    } else if (m.group(1).equals("OK")) {
                        results.put(m.group(2), ResultsBundleGenerator.TestResult.PASSED);
                    }
                }
                mLogBundle.putString(Instrumentation.REPORT_KEY_STREAMRESULT, l + "\n");
                sendStatus(0, mLogBundle);
                Log.i(TAG, l);
            }
        } catch (FileNotFoundException e) {
            Log.e(TAG, "Couldn't find stdout file file: ", e);
        } catch (IOException e) {
            Log.e(TAG, "Error handling stdout file: ", e);
        } finally {
            if (r != null) {
                try {
                    r.close();
                } catch (IOException e) {
                    Log.e(TAG, "Error while closing stdout reader.", e);
                }
            }
            if (mStdoutFile != null) {
                if (!mStdoutFile.delete()) {
                    Log.e(TAG, "Unable to delete %s", mStdoutFile.getAbsolutePath());
                }
            }
        }
        return results;
    }

}

// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.native_test;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Process;

import org.chromium.base.CommandLine;
import org.chromium.base.JNINamespace;
import org.chromium.base.Log;
import org.chromium.test.reporter.TestStatusReporter;

import java.io.File;
import java.util.ArrayList;
import java.util.Iterator;

/**
 *  Android's NativeActivity is mostly useful for pure-native code.
 *  Our tests need to go up to our own java classes, which is not possible using
 *  the native activity class loader.
 */
@JNINamespace("testing::android")
public class NativeTestActivity extends Activity {
    public static final String EXTRA_COMMAND_LINE_FILE =
            "org.chromium.native_test.NativeTestActivity.CommandLineFile";
    public static final String EXTRA_COMMAND_LINE_FLAGS =
            "org.chromium.native_test.NativeTestActivity.CommandLineFlags";
    public static final String EXTRA_SHARD =
            "org.chromium.native_test.NativeTestActivity.Shard";
    public static final String EXTRA_STDOUT_FILE =
            "org.chromium.native_test.NativeTestActivity.StdoutFile";

    private static final String TAG = "cr.native_test";
    private static final String EXTRA_RUN_IN_SUB_THREAD = "RunInSubThread";

    private String mCommandLineFilePath;
    private StringBuilder mCommandLineFlags = new StringBuilder();
    private TestStatusReporter mReporter;
    private boolean mRunInSubThread = false;
    private boolean mStdoutFifo = false;
    private String mStdoutFilePath;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        CommandLine.init(new String[]{});

        parseArgumentsFromIntent(getIntent());
        mReporter = new TestStatusReporter(this);
    }

    private void parseArgumentsFromIntent(Intent intent) {
        mCommandLineFilePath = intent.getStringExtra(EXTRA_COMMAND_LINE_FILE);
        if (mCommandLineFilePath == null) {
            mCommandLineFilePath = "";
        } else {
            File commandLineFile = new File(mCommandLineFilePath);
            if (!commandLineFile.isAbsolute()) {
                mCommandLineFilePath = Environment.getExternalStorageDirectory() + "/"
                        + mCommandLineFilePath;
            }
            Log.i(TAG, "command line file path: %s", mCommandLineFilePath);
        }

        String commandLineFlags = intent.getStringExtra(EXTRA_COMMAND_LINE_FLAGS);
        if (commandLineFlags != null) mCommandLineFlags.append(commandLineFlags);

        mRunInSubThread = intent.hasExtra(EXTRA_RUN_IN_SUB_THREAD);

        ArrayList<String> shard = intent.getStringArrayListExtra(EXTRA_SHARD);
        if (shard != null) {
            StringBuilder filterFlag = new StringBuilder();
            filterFlag.append("--gtest_filter=");
            for (Iterator<String> test_iter = shard.iterator(); test_iter.hasNext();) {
                filterFlag.append(test_iter.next());
                if (test_iter.hasNext()) {
                    filterFlag.append(":");
                }
            }
            appendCommandLineFlags(filterFlag.toString());
        }

        mStdoutFilePath = intent.getStringExtra(EXTRA_STDOUT_FILE);
        if (mStdoutFilePath == null) {
            mStdoutFilePath = new File(getFilesDir(), "test.fifo").getAbsolutePath();
            mStdoutFifo = true;
        }
    }

    protected void appendCommandLineFlags(String flags) {
        mCommandLineFlags.append(" ").append(flags);
    }

    @Override
    public void onStart() {
        super.onStart();

        if (mRunInSubThread) {
            // Create a new thread and run tests on it.
            new Thread() {
                @Override
                public void run() {
                    runTests();
                }
            }.start();
        } else {
            // Post a task to run the tests. This allows us to not block
            // onCreate and still run tests on the main thread.
            new Handler().post(new Runnable() {
                @Override
                public void run() {
                    runTests();
                }
            });
        }
    }

    private void runTests() {
        mReporter.testRunStarted(Process.myPid());
        nativeRunTests(mCommandLineFlags.toString(), mCommandLineFilePath, mStdoutFilePath,
                mStdoutFifo, getApplicationContext());
        finish();
        mReporter.testRunFinished(Process.myPid());
    }

    // Signal a failure of the native test loader to python scripts
    // which run tests.  For example, we look for
    // RUNNER_FAILED build/android/test_package.py.
    private void nativeTestFailed() {
        Log.e(TAG, "[ RUNNER_FAILED ] could not load native library");
    }

    private native void nativeRunTests(String commandLineFlags, String commandLineFilePath,
            String stdoutFilePath, boolean stdoutFifo, Context appContext);
}

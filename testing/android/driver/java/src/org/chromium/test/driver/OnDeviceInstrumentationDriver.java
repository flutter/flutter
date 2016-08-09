// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.test.driver;

import android.app.Activity;
import android.app.Instrumentation;
import android.content.ComponentName;
import android.content.Intent;
import android.os.Bundle;
import android.os.Environment;
import android.test.InstrumentationTestRunner;
import android.util.Log;

import org.chromium.test.broker.OnDeviceInstrumentationBroker;
import org.chromium.test.reporter.TestStatusReceiver;
import org.chromium.test.reporter.TestStatusReporter;
import org.chromium.test.support.ResultsBundleGenerator;
import org.chromium.test.support.RobotiumBundleGenerator;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.regex.Pattern;

/**
 * An Instrumentation that drives instrumentation tests from outside the app.
 */
public class OnDeviceInstrumentationDriver extends Instrumentation {

    private static final String TAG = "OnDeviceInstrumentationDriver";

    private static final String EXTRA_TEST_LIST =
            "org.chromium.test.driver.OnDeviceInstrumentationDriver.TestList";
    private static final String EXTRA_TEST_LIST_FILE =
            "org.chromium.test.driver.OnDeviceInstrumentationDriver.TestListFile";
    private static final String EXTRA_TARGET_PACKAGE =
            "org.chromium.test.driver.OnDeviceInstrumentationDriver.TargetPackage";
    private static final String EXTRA_TARGET_CLASS =
            "org.chromium.test.driver.OnDeviceInstrumentationDriver.TargetClass";

    private static final Pattern COMMA = Pattern.compile(",");
    private static final int TEST_WAIT_TIMEOUT = 5 * TestStatusReporter.HEARTBEAT_INTERVAL_MS;

    private boolean mDriverStarted;
    private Thread mDriverThread;
    private Bundle mTargetArgs;
    private String mTargetClass;
    private String mTargetPackage;
    private List<String> mTestClasses;

    /** Parse any arguments and prepare to run tests.

        @param arguments The arguments to parse.
     */
    @Override
    public void onCreate(Bundle arguments) {
        mTargetArgs = new Bundle(arguments);
        mTargetPackage = arguments.getString(EXTRA_TARGET_PACKAGE);
        if (mTargetPackage == null) {
            fail("No target package.");
            return;
        }
        mTargetArgs.remove(EXTRA_TARGET_PACKAGE);

        mTargetClass = arguments.getString(EXTRA_TARGET_CLASS);
        if (mTargetClass == null) {
            fail("No target class.");
            return;
        }
        mTargetArgs.remove(EXTRA_TARGET_CLASS);

        mTestClasses = new ArrayList<String>();
        String testList = arguments.getString(EXTRA_TEST_LIST);
        if (testList != null) {
            mTestClasses.addAll(Arrays.asList(COMMA.split(testList)));
            mTargetArgs.remove(EXTRA_TEST_LIST);
        }

        String testListFilePath = arguments.getString(EXTRA_TEST_LIST_FILE);
        if (testListFilePath != null) {
            File testListFile = new File(Environment.getExternalStorageDirectory(),
                    testListFilePath);
            try {
                BufferedReader testListFileReader =
                        new BufferedReader(new FileReader(testListFile));
                String test;
                while ((test = testListFileReader.readLine()) != null) {
                    mTestClasses.add(test);
                }
                testListFileReader.close();
            } catch (IOException e) {
                Log.e(TAG, "Error reading " + testListFile.getAbsolutePath(), e);
            }
            mTargetArgs.remove(EXTRA_TEST_LIST_FILE);
        }

        if (mTestClasses.isEmpty()) {
            fail("No tests.");
            return;
        }

        mDriverThread = new Thread(
                new Driver(mTargetPackage, mTargetClass, mTargetArgs, mTestClasses));

        start();
    }

    /** Start running tests. */
    @Override
    public void onStart() {
        super.onStart();

        // Start the driver on its own thread s.t. it can block while the main thread's
        // Looper receives and handles messages.
        if (!mDriverStarted) {
            mDriverThread.start();
            mDriverStarted = true;
        }
    }

    /** Clean up the reporting service. */
    @Override
    public void onDestroy() {
        super.onDestroy();
    }

    private class Driver implements Runnable {

        private static final String TAG = OnDeviceInstrumentationDriver.TAG + ".Driver";

        private Bundle mTargetArgs;
        private String mTargetClass;
        private String mTargetPackage;
        private List<String> mTestClasses;

        public Driver(String targetPackage, String targetClass, Bundle targetArgs,
                List<String> testClasses) {
            mTargetPackage = targetPackage;
            mTargetClass = targetClass;
            mTargetArgs = targetArgs;
            mTestClasses = testClasses;
        }

        private void sendTestStatus(int status, String testClass, String testMethod) {
            Bundle statusBundle = new Bundle();
            statusBundle.putString(InstrumentationTestRunner.REPORT_KEY_NAME_CLASS, testClass);
            statusBundle.putString(InstrumentationTestRunner.REPORT_KEY_NAME_TEST, testMethod);
            sendStatus(status, statusBundle);
        }

        /** Run the tests. */
        @Override
        public void run() {
            final HashMap<String, ResultsBundleGenerator.TestResult> finished =
                    new HashMap<String, ResultsBundleGenerator.TestResult>();
            final Object statusLock = new Object();

            try {
                TestStatusReceiver r = new TestStatusReceiver();
                r.registerCallback(new TestStatusReceiver.StartCallback() {
                    @Override
                    public void testStarted(String testClass, String testMethod) {
                        sendTestStatus(InstrumentationTestRunner.REPORT_VALUE_RESULT_START,
                                testClass, testMethod);
                        synchronized (statusLock) {
                            statusLock.notify();
                        }
                    }
                });
                r.registerCallback(new TestStatusReceiver.PassCallback() {
                    @Override
                    public void testPassed(String testClass, String testMethod) {
                        sendTestStatus(InstrumentationTestRunner.REPORT_VALUE_RESULT_OK, testClass,
                                testMethod);
                        synchronized (statusLock) {
                            finished.put(testClass + "#" + testMethod,
                                    ResultsBundleGenerator.TestResult.PASSED);
                            statusLock.notify();
                        }
                    }
                });
                r.registerCallback(new TestStatusReceiver.FailCallback() {
                    @Override
                    public void testFailed(String testClass, String testMethod) {
                        sendTestStatus(InstrumentationTestRunner.REPORT_VALUE_RESULT_ERROR,
                                testClass, testMethod);
                        synchronized (statusLock) {
                            finished.put(testClass + "#" + testMethod,
                                    ResultsBundleGenerator.TestResult.FAILED);
                            statusLock.notify();
                        }
                    }
                });
                r.registerCallback(new TestStatusReceiver.HeartbeatCallback() {
                    @Override
                    public void heartbeat() {
                        Log.i(TAG, "Heartbeat received.");
                        synchronized (statusLock) {
                            statusLock.notify();
                        }
                    }
                });
                r.register(getContext());

                for (String t : mTestClasses) {
                    Intent slaveIntent = new Intent();
                    slaveIntent.setComponent(new ComponentName(
                            mTargetPackage, OnDeviceInstrumentationBroker.class.getName()));
                    slaveIntent.putExtra(
                            OnDeviceInstrumentationBroker.EXTRA_INSTRUMENTATION_PACKAGE,
                            mTargetPackage);
                    slaveIntent.putExtra(
                            OnDeviceInstrumentationBroker.EXTRA_INSTRUMENTATION_CLASS,
                            mTargetClass);
                    slaveIntent.putExtra(OnDeviceInstrumentationBroker.EXTRA_TEST, t);
                    slaveIntent.putExtra(OnDeviceInstrumentationBroker.EXTRA_TARGET_ARGS,
                            mTargetArgs);
                    slaveIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

                    getContext().startActivity(slaveIntent);

                    synchronized (statusLock) {
                        while (!finished.containsKey(t)) {
                            long waitStart = System.currentTimeMillis();
                            statusLock.wait(TEST_WAIT_TIMEOUT);
                            if (System.currentTimeMillis() - waitStart > TEST_WAIT_TIMEOUT) {
                                Log.e(TAG, t + " has gone missing and is assumed to be dead.");
                                finished.put(t, ResultsBundleGenerator.TestResult.FAILED);
                                break;
                            }
                        }
                    }
                }
                getContext().unregisterReceiver(r);

            } catch (InterruptedException e) {
                fail("Interrupted while running tests.", e);
                return;
            }
            pass(new RobotiumBundleGenerator().generate(finished));
        }

    }

    private void fail(String reason) {
        Log.e(TAG, reason);
        failImpl(reason);
    }

    private void fail(String reason, Exception e) {
        Log.e(TAG, reason, e);
        failImpl(reason);
    }

    private void failImpl(String reason) {
        Bundle b = new Bundle();
        b.putString("reason", reason);
        finish(Activity.RESULT_CANCELED, b);
    }

    private void pass(Bundle results) {
        finish(Activity.RESULT_OK, results);
    }
}

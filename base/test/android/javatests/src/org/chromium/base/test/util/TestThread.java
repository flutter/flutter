// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.test.util;

import android.os.Handler;
import android.os.Looper;

import java.util.concurrent.atomic.AtomicBoolean;

/**
 * This class is usefull when writing instrumentation tests that exercise code that posts tasks
 * (to the same thread).
 * Since the test code is run in a single thread, the posted tasks are never executed.
 * The TestThread class lets you run that code on a specific thread synchronously and flush the
 * message loop on that thread.
 *
 * Example of test using this:
 *
 * public void testMyAwesomeClass() {
 *   TestThread testThread = new TestThread();
 *   testThread.startAndWaitForReadyState();
 *
 *   testThread.runOnTestThreadSyncAndProcessPendingTasks(new Runnable() {
 *       @Override
 *       public void run() {
 *           MyAwesomeClass.doStuffAsync();
 *       }
 *   });
 *   // Once we get there we know doStuffAsync has been executed and all the tasks it posted.
 *   assertTrue(MyAwesomeClass.stuffWasDone());
 * }
 *
 * Notes:
 * - this is only for tasks posted to the same thread. Anyway if you were posting to a different
 *   thread, you'd probably need to set that other thread up.
 * - this only supports tasks posted using Handler.post(), it won't work with postDelayed and
 *   postAtTime.
 * - if your test instanciates an object and that object is the one doing the posting of tasks, you
 *   probably want to instanciate it on the test thread as it might create the Handler it posts
 *   tasks to in the constructor.
 */

public class TestThread extends Thread {
    private Object mThreadReadyLock;
    private AtomicBoolean mThreadReady;
    private Handler mMainThreadHandler;
    private Handler mTestThreadHandler;

    public TestThread() {
        mMainThreadHandler = new Handler();
        // We can't use the AtomicBoolean as the lock or findbugs will freak out...
        mThreadReadyLock = new Object();
        mThreadReady = new AtomicBoolean();
    }

    @Override
    public void run() {
        Looper.prepare();
        mTestThreadHandler = new Handler();
        mTestThreadHandler.post(new Runnable() {
            @Override
            public void run() {
                synchronized (mThreadReadyLock) {
                    mThreadReady.set(true);
                    mThreadReadyLock.notify();
                }
            }
        });
        Looper.loop();
    }

    /**
     * Starts this TestThread and blocks until it's ready to accept calls.
     */
    public void startAndWaitForReadyState() {
        checkOnMainThread();
        start();
        synchronized (mThreadReadyLock) {
            try {
                // Note the mThreadReady and while are not really needed.
                // There are there so findbugs don't report warnings.
                while (!mThreadReady.get()) {
                    mThreadReadyLock.wait();
                }
            } catch (InterruptedException ie) {
                System.err.println("Error starting TestThread.");
                ie.printStackTrace();
            }
        }
    }

    /**
     * Runs the passed Runnable synchronously on the TestThread and returns when all pending
     * runnables have been excuted.
     * Should be called from the main thread.
     */
    public void runOnTestThreadSyncAndProcessPendingTasks(Runnable r) {
        checkOnMainThread();

        runOnTestThreadSync(r);

        // Run another task, when it's done it means all pendings tasks have executed.
        runOnTestThreadSync(null);
    }

    /**
     * Runs the passed Runnable on the test thread and blocks until it has finished executing.
     * Should be called from the main thread.
     * @param r The runnable to be executed.
     */
    public void runOnTestThreadSync(final Runnable r) {
        checkOnMainThread();
        final Object lock = new Object();
        // Task executed is not really needed since we are only on one thread, it is here to appease
        // findbugs.
        final AtomicBoolean taskExecuted = new AtomicBoolean();
        mTestThreadHandler.post(new Runnable() {
            @Override
            public void run() {
                if (r != null) r.run();
                synchronized (lock) {
                    taskExecuted.set(true);
                    lock.notify();
                }
            }
        });
        synchronized (lock) {
            try {
                while (!taskExecuted.get()) {
                    lock.wait();
                }
            } catch (InterruptedException ie) {
                ie.printStackTrace();
            }
        }
    }

    private void checkOnMainThread() {
        assert Looper.myLooper() == mMainThreadHandler.getLooper();
    }
}

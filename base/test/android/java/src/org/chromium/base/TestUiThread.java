// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import android.os.Looper;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicBoolean;

import javax.annotation.concurrent.ThreadSafe;

/**
 * Set up a thread as the Chromium UI Thread, and run its looper. This is is intended for C++ unit
 * tests (e.g. the net unit tests) that don't run with the UI thread as their main looper, but test
 * code that, on Android, uses UI thread events, so need a running UI thread.
 */
@ThreadSafe
public class TestUiThread {
    private static final AtomicBoolean sStarted = new AtomicBoolean(false);
    private static final String TAG = "cr.TestUiThread";

    @CalledByNative
    private static void loop() {
        // @{link ThreadUtils#setUiThread(Looper)} can only be called once in a test run, so do this
        // once, and leave it running.
        if (sStarted.getAndSet(true)) return;

        final CountDownLatch startLatch = new CountDownLatch(1);
        new Thread(new Runnable() {

            @Override
            public void run() {
                Looper.prepare();
                ThreadUtils.setUiThread(Looper.myLooper());
                startLatch.countDown();
                Looper.loop();
            }

        }).start();

        try {
            startLatch.await();
        } catch (InterruptedException e) {
            Log.e(TAG, "Failed to set UI Thread");
        }
    }
}

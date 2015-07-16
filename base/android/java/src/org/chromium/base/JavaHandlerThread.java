// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import android.annotation.TargetApi;
import android.os.Build;
import android.os.Handler;
import android.os.HandlerThread;

/**
 * This class is an internal detail of the native counterpart.
 * It is instantiated and owned by the native object.
 */
@JNINamespace("base::android")
class JavaHandlerThread {
    final HandlerThread mThread;

    private JavaHandlerThread(String name) {
        mThread = new HandlerThread(name);
    }

    @CalledByNative
    private static JavaHandlerThread create(String name) {
        return new JavaHandlerThread(name);
    }

    @CalledByNative
    private void start(final long nativeThread, final long nativeEvent) {
        mThread.start();
        new Handler(mThread.getLooper()).post(new Runnable() {
            @Override
            public void run() {
                nativeInitializeThread(nativeThread, nativeEvent);
            }
        });
    }

    @TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
    @CalledByNative
    private void stop(final long nativeThread, final long nativeEvent) {
        final boolean quitSafely = Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2;
        new Handler(mThread.getLooper()).post(new Runnable() {
            @Override
            public void run() {
                nativeStopThread(nativeThread, nativeEvent);
                if (!quitSafely) mThread.quit();
            }
        });
        if (quitSafely) mThread.quitSafely();
    }

    private native void nativeInitializeThread(long nativeJavaHandlerThread, long nativeEvent);
    private native void nativeStopThread(long nativeJavaHandlerThread, long nativeEvent);
}

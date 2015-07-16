// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.test.util;

import android.app.Instrumentation;

import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.FutureTask;

/**
 * Utility methods built around the android.app.Instrumentation class.
 */
public final class InstrumentationUtils {

    private InstrumentationUtils() {
    }

    public static <R> R runOnMainSyncAndGetResult(Instrumentation instrumentation,
            Callable<R> callable) throws Throwable {
        FutureTask<R> task = new FutureTask<R>(callable);
        instrumentation.runOnMainSync(task);
        try {
            return task.get();
        } catch (ExecutionException e) {
            // Unwrap the cause of the exception and re-throw it.
            throw e.getCause();
        }
    }
}

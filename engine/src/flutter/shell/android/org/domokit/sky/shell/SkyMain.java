// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.content.Context;
import android.util.Log;

import org.chromium.base.JNINamespace;

/**
 * A class to intialize the native code.
 **/
@JNINamespace("sky::shell")
public class SkyMain {
    private static final String TAG = "SkyMain";

    /**
     * A guard flag for calling nativeInit() only once.
     **/
    private static boolean sInitialized = false;

    /**
     * Initializes the native system.
     **/
    public static void ensureInitialized(Context applicationContext) {
        if (sInitialized) {
            return;
        }
        try {
            SkyApplication app = (SkyApplication) applicationContext;
            app.getResourceExtractor().waitForCompletion();
            nativeInit(applicationContext);
            sInitialized = true;
        } catch (Exception e) {
            Log.e(TAG, "SkyMain initialization failed.", e);
            throw new RuntimeException(e);
        }
    }

    private static native void nativeInit(Context context);
}

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.native_test;

import android.os.Bundle;

/**
 * An {@link android.app.Activity} for running native browser tests.
 */
public abstract class NativeBrowserTestActivity extends NativeTestActivity {

    private static final String BROWSER_TESTS_FLAGS[] = {
        // content::kSingleProcessTestsFlag
        "--single_process",

        // switches::kUseFakeDeviceForMediaStream
        "--use-fake-device-for-media-stream",

        // switches::kUseFakeUIForMediaStream
        "--use-fake-ui-for-media-stream"
    };

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        for (String flag : BROWSER_TESTS_FLAGS) {
            appendCommandLineFlags(flag);
        }
    }

    @Override
    public void onStart() {
        initializeBrowserProcess();
        super.onStart();
    }

    /** Initializes the browser process.
     *
     *  This generally includes loading native libraries and switching to the native command line,
     *  among other things.
     */
    protected abstract void initializeBrowserProcess();

}

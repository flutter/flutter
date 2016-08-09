// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.native_test;

import android.os.Bundle;

import org.chromium.base.Log;
import org.chromium.base.PathUtils;
import org.chromium.base.PowerMonitor;
import org.chromium.base.library_loader.NativeLibraries;

/**
 * An {@link android.app.Activity} for running native unit tests.
 * (i.e., not browser tests)
 */
public class NativeUnitTestActivity extends NativeTestActivity {

    private static final String TAG = "cr.native_test";

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Needed by path_utils_unittest.cc
        PathUtils.setPrivateDataDirectorySuffix("chrome", getApplicationContext());

        // Needed by system_monitor_unittest.cc
        PowerMonitor.createForTests(this);

        loadLibraries();
    }

    private void loadLibraries() {
        for (String library : NativeLibraries.LIBRARIES) {
            Log.i(TAG, "loading: %s", library);
            System.loadLibrary(library);
            Log.i(TAG, "loaded: %s", library);
        }
    }
}

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.util.Log;

import org.chromium.base.BaseChromiumApplication;
import org.chromium.base.PathUtils;
import org.chromium.base.library_loader.LibraryLoader;
import org.chromium.base.library_loader.ProcessInitException;

/**
 * MojoShell implementation of {@link android.app.Application}, managing application-level global
 * state and initializations.
 */
public class SkyShellApplication extends BaseChromiumApplication {
    private static final String TAG = "SkyShellApplication";
    private static final String PRIVATE_DATA_DIRECTORY_SUFFIX = "sky_shell";

    @Override
    public void onCreate() {
        super.onCreate();
        initializeJavaUtils();
        initializeNative();
    }

    /**
     * Initializes Java-side utils.
     */
    private void initializeJavaUtils() {
        PathUtils.setPrivateDataDirectorySuffix(PRIVATE_DATA_DIRECTORY_SUFFIX);
    }

    /**
     * Loads the native library.
     */
    private void initializeNative() {
        try {
            LibraryLoader.ensureInitialized();
        } catch (ProcessInitException e) {
            Log.e(TAG, "sky_shell initialization failed.", e);
            throw new RuntimeException(e);
        }
    }
}

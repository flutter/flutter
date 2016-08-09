// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.native_test;

import android.os.Bundle;

import org.chromium.base.Log;

import java.io.File;

/**
 * An {@link android.app.Activity} for running native browser tests.
 */
public abstract class NativeBrowserTestActivity extends NativeTestActivity {

    private static final String TAG = "cr.native_test";

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
        deletePrivateDataDirectory();
        initializeBrowserProcess();
        super.onStart();
    }

    /** Deletes a file or directory along with any of its children.
     *
     *  Note that, like File.delete(), this returns false if the file or directory couldn't be
     *  fully deleted. This means that, in the directory case, some files may be deleted even if
     *  the entire directory couldn't be.
     *
     *  @param file The file or directory to delete.
     *  @return Whether or not the file or directory was deleted.
     */
    private static boolean deleteRecursive(File file) {
        if (file == null) return true;

        File[] children = file.listFiles();
        if (children != null) {
            for (File child : children) {
                if (!deleteRecursive(child)) {
                    return false;
                }
            }
        }
        return file.delete();
    }

    private void deletePrivateDataDirectory() {
        File privateDataDirectory = getPrivateDataDirectory();
        if (!deleteRecursive(privateDataDirectory)) {
            Log.e(TAG, "Failed to remove %s", privateDataDirectory.getAbsolutePath());
        }
    }

    /** Returns the test suite's private data directory. */
    protected abstract File getPrivateDataDirectory();

    /** Initializes the browser process.
     *
     *  This generally includes loading native libraries and switching to the native command line,
     *  among other things.
     */
    protected abstract void initializeBrowserProcess();
}

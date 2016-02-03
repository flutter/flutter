// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.content.Context;
import android.os.AsyncTask;
import android.os.Handler;
import android.util.Log;

import java.io.File;
import java.io.FilenameFilter;
import java.io.IOException;

import org.domokit.common.ResourcePaths;

/**
 * A class to clean up orphaned resource directories after unclean shutdowns.
 **/
public class ResourceCleaner {
    private static final String TAG = "ResourceCleaner";
    private static final long DELAY_MS = 5000;

    private class CleanTask extends AsyncTask<Void, Void, Void> {
        private final File[] mFilesToDelete;

        public CleanTask(File[] filesToDelete) {
            mFilesToDelete = filesToDelete;
        }

        public boolean hasFilesToDelete() {
            return mFilesToDelete.length > 0;
        }

        @Override
        protected Void doInBackground(Void... unused) {
            Log.i(TAG, "Cleaning " + mFilesToDelete.length + " resources.");
            for (File file : mFilesToDelete) {
                if (file.exists()) {
                    deleteRecursively(file);
                }
            }
            return null;
        }

        private void deleteRecursively(File parent) {
            if (parent.isDirectory()) {
                for (File child : parent.listFiles()) {
                    deleteRecursively(child);
                }
            }
            parent.delete();
        }
    }

    private final Context mContext;

    public ResourceCleaner(Context context) {
        mContext = context;
    }

    public void start() {
        File cacheDir = mContext.getCacheDir();
        if (cacheDir == null) {
            return;
        }

        final CleanTask task = new CleanTask(cacheDir.listFiles(new FilenameFilter() {
            @Override
            public boolean accept(File dir, String name) {
                boolean result = name.startsWith(ResourcePaths.TEMPORARY_RESOURCE_PREFIX);
                return result;
            }
        }));

        if (!task.hasFilesToDelete()) {
            return;
        }

        new Handler().postDelayed(new Runnable() {
            @Override
            public void run() {
                task.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
            }
        }, DELAY_MS);
    }
}

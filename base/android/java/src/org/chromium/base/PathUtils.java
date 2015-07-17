// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.os.AsyncTask;
import android.os.Environment;

import java.io.File;
import java.util.concurrent.ExecutionException;

/**
 * This class provides the path related methods for the native library.
 */
public abstract class PathUtils {
    private static final String THUMBNAIL_DIRECTORY = "textures";

    private static final int DATA_DIRECTORY = 0;
    private static final int DATABASE_DIRECTORY = 1;
    private static final int CACHE_DIRECTORY = 2;
    private static final int NUM_DIRECTORIES = 3;
    private static AsyncTask<String, Void, String[]> sDirPathFetchTask;

    private static File sThumbnailDirectory;

    // Prevent instantiation.
    private PathUtils() {}

    /**
     * Starts an asynchronous task to fetch the path of the directory where private data is to be
     * stored by the application.
     *
     * @param suffix The private data directory suffix.
     * @see Context#getDir(String, int)
     */
    public static void setPrivateDataDirectorySuffix(String suffix, Context context) {
        final Context appContext = context.getApplicationContext();
        sDirPathFetchTask = new AsyncTask<String, Void, String[]>() {
            @Override
            protected String[] doInBackground(String... dataDirectorySuffix) {
                String[] paths = new String[NUM_DIRECTORIES];
                paths[DATA_DIRECTORY] =
                        appContext.getDir(dataDirectorySuffix[0], Context.MODE_PRIVATE).getPath();
                paths[DATABASE_DIRECTORY] = appContext.getDatabasePath("foo").getParent();
                // TODO(wnwen): Find a way to avoid calling this function in renderer process.
                if (appContext.getCacheDir() != null) {
                    paths[CACHE_DIRECTORY] = appContext.getCacheDir().getPath();
                }
                return paths;
            }
        }.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR, suffix);
    }

    /**
     * @param index The index of the cached directory path.
     * @return The directory path requested, or null if not available.
     */
    private static String getDirectoryPath(int index) {
        try {
            return sDirPathFetchTask.get()[index];
        } catch (InterruptedException e) {
        } catch (ExecutionException e) {
        }
        return null;
    }

    /**
     * @return the private directory that is used to store application data.
     */
    @CalledByNative
    public static String getDataDirectory(Context appContext) {
        assert sDirPathFetchTask != null : "setDataDirectorySuffix must be called first.";
        return getDirectoryPath(DATA_DIRECTORY);
    }

    /**
     * @return the private directory that is used to store application database.
     */
    @CalledByNative
    public static String getDatabaseDirectory(Context appContext) {
        assert sDirPathFetchTask != null : "setDataDirectorySuffix must be called first.";
        return getDirectoryPath(DATABASE_DIRECTORY);
    }

    /**
     * @return the cache directory.
     */
    @SuppressWarnings("unused")
    @CalledByNative
    public static String getCacheDirectory(Context appContext) {
        assert sDirPathFetchTask != null : "setDataDirectorySuffix must be called first.";
        return getDirectoryPath(CACHE_DIRECTORY);
    }

    public static File getThumbnailCacheDirectory(Context appContext) {
        if (sThumbnailDirectory == null) {
            sThumbnailDirectory = appContext.getDir(THUMBNAIL_DIRECTORY, Context.MODE_PRIVATE);
        }
        return sThumbnailDirectory;
    }

    @CalledByNative
    public static String getThumbnailCacheDirectoryPath(Context appContext) {
        return getThumbnailCacheDirectory(appContext).getAbsolutePath();
    }

    /**
     * @return the public downloads directory.
     */
    @SuppressWarnings("unused")
    @CalledByNative
    private static String getDownloadsDirectory(Context appContext) {
        return Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS).getPath();
    }

    /**
     * @return the path to native libraries.
     */
    @SuppressWarnings("unused")
    @CalledByNative
    private static String getNativeLibraryDirectory(Context appContext) {
        ApplicationInfo ai = appContext.getApplicationInfo();
        if ((ai.flags & ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
                || (ai.flags & ApplicationInfo.FLAG_SYSTEM) == 0) {
            return ai.nativeLibraryDir;
        }

        return "/system/lib/";
    }

    /**
     * @return the external storage directory.
     */
    @SuppressWarnings("unused")
    @CalledByNative
    public static String getExternalStorageDirectory() {
        return Environment.getExternalStorageDirectory().getAbsolutePath();
    }
}

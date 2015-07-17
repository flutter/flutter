// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import android.annotation.TargetApi;
import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.Trace;
import android.util.Log;

import org.chromium.base.annotations.SuppressFBWarnings;

import java.io.File;
import java.io.FileOutputStream;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CancellationException;
import java.util.concurrent.ExecutionException;

/**
 * Handles extracting the necessary resources bundled in an APK and moving them to a location on
 * the file system accessible from the native code.
 */
public class ResourceExtractor {

    private static final String LOGTAG = "ResourceExtractor";
    private static final String ICU_DATA_FILENAME = "icudtl.dat";
    private static final String V8_NATIVES_DATA_FILENAME = "natives_blob.bin";
    private static final String V8_SNAPSHOT_DATA_FILENAME = "snapshot_blob.bin";

    private static ResourceEntry[] sResourcesToExtract = new ResourceEntry[0];

    /**
     * Holds information about a res/raw file (e.g. locale .pak files).
     */
    public static final class ResourceEntry {
        public final int resourceId;
        public final String pathWithinApk;
        public final String extractedFileName;

        public ResourceEntry(int resourceId, String pathWithinApk, String extractedFileName) {
            this.resourceId = resourceId;
            this.pathWithinApk = pathWithinApk;
            this.extractedFileName = extractedFileName;
        }
    }

    private class ExtractTask extends AsyncTask<Void, Void, Void> {
        private static final int BUFFER_SIZE = 16 * 1024;

        private final List<Runnable> mCompletionCallbacks = new ArrayList<Runnable>();

        private void extractResourceHelper(InputStream is, File outFile, byte[] buffer)
                throws IOException {
            OutputStream os = null;
            try {
                os = new FileOutputStream(outFile);
                Log.i(LOGTAG, "Extracting resource " + outFile);

                int count = 0;
                while ((count = is.read(buffer, 0, BUFFER_SIZE)) != -1) {
                    os.write(buffer, 0, count);
                }
                os.flush();

                // Ensure something reasonable was written.
                if (outFile.length() == 0) {
                    throw new IOException(outFile + " extracted with 0 length!");
                }
            } finally {
                try {
                    if (is != null) {
                        is.close();
                    }
                } finally {
                    if (os != null) {
                        os.close();
                    }
                }
            }
        }

        private void doInBackgroundImpl() {
            final File outputDir = getOutputDir();
            if (!outputDir.exists() && !outputDir.mkdirs()) {
                Log.e(LOGTAG, "Unable to create pak resources directory!");
                return;
            }

            String timestampFile = null;
            beginTraceSection("checkPakTimeStamp");
            try {
                timestampFile = checkPakTimestamp(outputDir);
            } finally {
                endTraceSection();
            }
            if (timestampFile != null) {
                deleteFiles();
            }

            beginTraceSection("WalkAssets");
            byte[] buffer = new byte[BUFFER_SIZE];
            try {
                // Extract all files that don't already exist.
                for (ResourceEntry entry : sResourcesToExtract) {
                    File output = new File(outputDir, entry.extractedFileName);
                    if (output.exists()) {
                        continue;
                    }
                    beginTraceSection("ExtractResource");
                    InputStream inputStream = mContext.getResources().openRawResource(
                            entry.resourceId);
                    try {
                        extractResourceHelper(inputStream, output, buffer);
                    } finally {
                        endTraceSection(); // ExtractResource
                    }
                }
            } catch (IOException e) {
                // TODO(benm): See crbug/152413.
                // Try to recover here, can we try again after deleting files instead of
                // returning null? It might be useful to gather UMA here too to track if
                // this happens with regularity.
                Log.w(LOGTAG, "Exception unpacking required pak resources: " + e.getMessage());
                deleteFiles();
                return;
            } finally {
                endTraceSection(); // WalkAssets
            }

            // Finished, write out a timestamp file if we need to.
            if (timestampFile != null) {
                try {
                    new File(outputDir, timestampFile).createNewFile();
                } catch (IOException e) {
                    // Worst case we don't write a timestamp, so we'll re-extract the resource
                    // paks next start up.
                    Log.w(LOGTAG, "Failed to write resource pak timestamp!");
                }
            }
        }

        @Override
        protected Void doInBackground(Void... unused) {
            // TODO(lizeb): Use chrome tracing here (and above in
            // doInBackgroundImpl) when it will be possible. This is currently
            // not doable since the native library is not loaded yet, and the
            // TraceEvent calls are dropped before this point.
            beginTraceSection("ResourceExtractor.ExtractTask.doInBackground");
            try {
                doInBackgroundImpl();
            } finally {
                endTraceSection();
            }
            return null;
        }

        private void onPostExecuteImpl() {
            for (int i = 0; i < mCompletionCallbacks.size(); i++) {
                mCompletionCallbacks.get(i).run();
            }
            mCompletionCallbacks.clear();
        }

        @Override
        protected void onPostExecute(Void result) {
            beginTraceSection("ResourceExtractor.ExtractTask.onPostExecute");
            try {
                onPostExecuteImpl();
            } finally {
                endTraceSection();
            }
        }

        // Looks for a timestamp file on disk that indicates the version of the APK that
        // the resource paks were extracted from. Returns null if a timestamp was found
        // and it indicates that the resources match the current APK. Otherwise returns
        // a String that represents the filename of a timestamp to create.
        // Note that we do this to avoid adding a BroadcastReceiver on
        // android.content.Intent#ACTION_PACKAGE_CHANGED as that causes process churn
        // on (re)installation of *all* APK files.
        private String checkPakTimestamp(File outputDir) {
            final String timestampPrefix = "pak_timestamp-";
            PackageManager pm = mContext.getPackageManager();
            PackageInfo pi = null;

            try {
                pi = pm.getPackageInfo(mContext.getPackageName(), 0);
            } catch (PackageManager.NameNotFoundException e) {
                return timestampPrefix;
            }

            if (pi == null) {
                return timestampPrefix;
            }

            String expectedTimestamp = timestampPrefix + pi.versionCode + "-" + pi.lastUpdateTime;

            String[] timestamps = outputDir.list(new FilenameFilter() {
                @Override
                public boolean accept(File dir, String name) {
                    return name.startsWith(timestampPrefix);
                }
            });

            if (timestamps.length != 1) {
                // If there's no timestamp, nuke to be safe as we can't tell the age of the files.
                // If there's multiple timestamps, something's gone wrong so nuke.
                return expectedTimestamp;
            }

            if (!expectedTimestamp.equals(timestamps[0])) {
                return expectedTimestamp;
            }

            // timestamp file is already up-to date.
            return null;
        }

        @TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
        private void beginTraceSection(String section) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.JELLY_BEAN_MR2) return;
            Trace.beginSection(section);
        }

        @TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
        private void endTraceSection() {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.JELLY_BEAN_MR2) return;
            Trace.endSection();
        }
    }

    private final Context mContext;
    private ExtractTask mExtractTask;

    private static ResourceExtractor sInstance;

    public static ResourceExtractor get(Context context) {
        if (sInstance == null) {
            sInstance = new ResourceExtractor(context);
        }
        return sInstance;
    }

    /**
     * Specifies the files that should be extracted from the APK.
     * and moved to {@link #getOutputDir()}.
     */
    @SuppressFBWarnings("EI_EXPOSE_STATIC_REP2")
    public static void setResourcesToExtract(ResourceEntry[] entries) {
        assert (sInstance == null || sInstance.mExtractTask == null)
                : "Must be called before startExtractingResources is called";
        sResourcesToExtract = entries;
    }

    // TODO(agrieve): Delete this method ones all usages of it are updated.
    public static void setMandatoryPaksToExtract(String... paths) {
        assert paths.length == 1 && "".equals(paths[0]);
    }

    private ResourceExtractor(Context context) {
        mContext = context.getApplicationContext();
    }

    /**
     * Synchronously wait for the resource extraction to be completed.
     * <p>
     * This method is bad and you should feel bad for using it.
     *
     * @see #addCompletionCallback(Runnable)
     */
    public void waitForCompletion() {
        if (shouldSkipPakExtraction()) {
            return;
        }

        assert mExtractTask != null;

        try {
            mExtractTask.get();
        } catch (CancellationException e) {
            // Don't leave the files in an inconsistent state.
            deleteFiles();
        } catch (ExecutionException e2) {
            deleteFiles();
        } catch (InterruptedException e3) {
            deleteFiles();
        }
    }

    /**
     * Adds a callback to be notified upon the completion of resource extraction.
     * <p>
     * If the resource task has already completed, the callback will be posted to the UI message
     * queue.  Otherwise, it will be executed after all the resources have been extracted.
     * <p>
     * This must be called on the UI thread.  The callback will also always be executed on
     * the UI thread.
     *
     * @param callback The callback to be enqueued.
     */
    public void addCompletionCallback(Runnable callback) {
        ThreadUtils.assertOnUiThread();

        Handler handler = new Handler(Looper.getMainLooper());
        if (shouldSkipPakExtraction()) {
            handler.post(callback);
            return;
        }

        assert mExtractTask != null;
        assert !mExtractTask.isCancelled();
        if (mExtractTask.getStatus() == AsyncTask.Status.FINISHED) {
            handler.post(callback);
        } else {
            mExtractTask.mCompletionCallbacks.add(callback);
        }
    }

    /**
     * This will extract the application pak resources in an
     * AsyncTask. Call waitForCompletion() at the point resources
     * are needed to block until the task completes.
     */
    public void startExtractingResources() {
        if (mExtractTask != null) {
            return;
        }

        // If a previous release extracted resources, and the current release does not,
        // deleteFiles() will not run and some files will be left. This currently
        // can happen for ContentShell, but not for Chrome proper, since we always extract
        // locale pak files.
        if (shouldSkipPakExtraction()) {
            return;
        }

        mExtractTask = new ExtractTask();
        mExtractTask.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
    }

    private File getAppDataDir() {
        return new File(PathUtils.getDataDirectory(mContext));
    }

    private File getOutputDir() {
        return new File(getAppDataDir(), "paks");
    }

    /**
     * Pak files (UI strings and other resources) should be updated along with
     * Chrome. A version mismatch can lead to a rather broken user experience.
     * Failing to update the V8 snapshot files will lead to a version mismatch
     * between V8 and the loaded snapshot which will cause V8 to crash, so this
     * is treated as an error. The ICU data (icudtl.dat) is less
     * version-sensitive, but still can lead to malfunction/UX misbehavior. So,
     * we regard failing to update them as an error.
     */
    private void deleteFiles() {
        File icudata = new File(getAppDataDir(), ICU_DATA_FILENAME);
        if (icudata.exists() && !icudata.delete()) {
            Log.e(LOGTAG, "Unable to remove the icudata " + icudata.getName());
        }
        File v8_natives = new File(getAppDataDir(), V8_NATIVES_DATA_FILENAME);
        if (v8_natives.exists() && !v8_natives.delete()) {
            Log.e(LOGTAG,
                    "Unable to remove the v8 data " + v8_natives.getName());
        }
        File v8_snapshot = new File(getAppDataDir(), V8_SNAPSHOT_DATA_FILENAME);
        if (v8_snapshot.exists() && !v8_snapshot.delete()) {
            Log.e(LOGTAG,
                    "Unable to remove the v8 data " + v8_snapshot.getName());
        }
        File dir = getOutputDir();
        if (dir.exists()) {
            File[] files = dir.listFiles();
            for (File file : files) {
                if (!file.delete()) {
                    Log.e(LOGTAG, "Unable to remove existing resource " + file.getName());
                }
            }
        }
    }

    /**
     * Pak extraction not necessarily required by the embedder.
     */
    private static boolean shouldSkipPakExtraction() {
        return sResourcesToExtract.length == 0;
    }
}

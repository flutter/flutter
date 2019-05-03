// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import static java.util.Arrays.asList;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.res.AssetManager;
import android.os.AsyncTask;
import android.os.Build;
import android.util.Log;

import io.flutter.BuildConfig;
import io.flutter.util.BSDiff;
import io.flutter.util.PathUtils;

import org.json.JSONObject;

import java.io.*;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.concurrent.CancellationException;
import java.util.concurrent.ExecutionException;
import java.util.zip.GZIPInputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

/**
 * A class to initialize the native code.
 **/
class ResourceExtractor {
    private static final String TAG = "ResourceExtractor";
    private static final String TIMESTAMP_PREFIX = "res_timestamp-";
    private static final String[] SUPPORTED_ABIS = getSupportedAbis();

    @SuppressWarnings("deprecation")
    static long getVersionCode(PackageInfo packageInfo) {
        // Linter needs P (28) hardcoded or else it will fail these lines.
        if (Build.VERSION.SDK_INT >= 28) {
            return packageInfo.getLongVersionCode();
        } else {
            return packageInfo.versionCode;
        }
    }

    private class ExtractTask extends AsyncTask<Void, Void, Void> {
        ExtractTask() { }

        @Override
        protected Void doInBackground(Void... unused) {
            final File dataDir = new File(PathUtils.getDataDirectory(mContext));

            final String timestamp = checkTimestamp(dataDir);
            if (timestamp == null) {
                return null;
            }

            deleteFiles();

            if (!extractAPK(dataDir)) {
                return null;
            }

            if (timestamp != null) {
                try {
                    new File(dataDir, timestamp).createNewFile();
                } catch (IOException e) {
                    Log.w(TAG, "Failed to write resource timestamp");
                }
            }

            return null;
        }
    }

    private final Context mContext;
    private final HashSet<String> mResources;
    private ExtractTask mExtractTask;

    ResourceExtractor(Context context) {
        mContext = context;
        mResources = new HashSet<>();
    }

    ResourceExtractor addResource(String resource) {
        mResources.add(resource);
        return this;
    }

    ResourceExtractor addResources(Collection<String> resources) {
        mResources.addAll(resources);
        return this;
    }

    ResourceExtractor start() {
        if (BuildConfig.DEBUG && mExtractTask != null) {
            throw new AssertionError("Attempted to start resource extraction while another extraction was in progress.");
        }
        mExtractTask = new ExtractTask();
        mExtractTask.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
        return this;
    }

    void waitForCompletion() {
        if (mExtractTask == null) {
            return;
        }

        try {
            mExtractTask.get();
        } catch (CancellationException | ExecutionException | InterruptedException e) {
            deleteFiles();
        }
    }

    private String[] getExistingTimestamps(File dataDir) {
        return dataDir.list(new FilenameFilter() {
            @Override
            public boolean accept(File dir, String name) {
                return name.startsWith(TIMESTAMP_PREFIX);
            }
        });
    }

    private void deleteFiles() {
        final File dataDir = new File(PathUtils.getDataDirectory(mContext));
        for (String resource : mResources) {
            final File file = new File(dataDir, resource);
            if (file.exists()) {
                file.delete();
            }
        }
        final String[] existingTimestamps = getExistingTimestamps(dataDir);
        if (existingTimestamps == null) {
            return;
        }
        for (String timestamp : existingTimestamps) {
            new File(dataDir, timestamp).delete();
        }
    }

    /// Returns true if successfully unpacked APK resources,
    /// otherwise deletes all resources and returns false.
    private boolean extractAPK(File dataDir) {
        final AssetManager manager = mContext.getResources().getAssets();

        for (String asset : mResources) {
            try {
                final String resource = "assets/" + asset;
                final File output = new File(dataDir, asset);
                if (output.exists()) {
                    continue;
                }
                if (output.getParentFile() != null) {
                    output.getParentFile().mkdirs();
                }

                try (InputStream is = manager.open(asset);
                     OutputStream os = new FileOutputStream(output)) {
                    copy(is, os);
                }
                if (BuildConfig.DEBUG) {
                    Log.i(TAG, "Extracted baseline resource " + resource);
                }
            } catch (FileNotFoundException fnfe) {
                continue;

            } catch (IOException ioe) {
                Log.w(TAG, "Exception unpacking resources: " + ioe.getMessage());
                deleteFiles();
                return false;
            }
        }

        return true;
    }

    // Returns null if extracted resources are found and match the current APK version
    // and update version if any, otherwise returns the current APK and update version.
    private String checkTimestamp(File dataDir) {
        PackageManager packageManager = mContext.getPackageManager();
        PackageInfo packageInfo = null;

        try {
            packageInfo = packageManager.getPackageInfo(mContext.getPackageName(), 0);
        } catch (PackageManager.NameNotFoundException e) {
            return TIMESTAMP_PREFIX;
        }

        if (packageInfo == null) {
            return TIMESTAMP_PREFIX;
        }

        String expectedTimestamp =
                TIMESTAMP_PREFIX + getVersionCode(packageInfo) + "-" + packageInfo.lastUpdateTime;

        final String[] existingTimestamps = getExistingTimestamps(dataDir);

        if (existingTimestamps == null) {
            if (BuildConfig.DEBUG) {
                Log.i(TAG, "No extracted resources found");
            }
            return expectedTimestamp;
        }

        if (existingTimestamps.length == 1) {
            if (BuildConfig.DEBUG) {
                Log.i(TAG, "Found extracted resources " + existingTimestamps[0]);
            }
        }

        if (existingTimestamps.length != 1
                || !expectedTimestamp.equals(existingTimestamps[0])) {
            if (BuildConfig.DEBUG) {
                Log.i(TAG, "Resource version mismatch " + expectedTimestamp);
            }
            return expectedTimestamp;
        }

        return null;
    }

    private static void copy(InputStream in, OutputStream out) throws IOException {
        byte[] buf = new byte[16 * 1024];
        for (int i; (i = in.read(buf)) >= 0; ) {
            out.write(buf, 0, i);
        }
    }

    private String getAPKPath() {
        try {
            return mContext.getPackageManager().getApplicationInfo(
                mContext.getPackageName(), 0).publicSourceDir;
        } catch (Exception e) {
            return null;
        }
    }

    @SuppressWarnings("deprecation")
    private static String[] getSupportedAbis() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            return Build.SUPPORTED_ABIS;
        } else {
            ArrayList<String> cpuAbis = new ArrayList<String>(asList(Build.CPU_ABI, Build.CPU_ABI2));
            cpuAbis.removeAll(asList(null, ""));
            return cpuAbis.toArray(new String[0]);
        }
    }
}

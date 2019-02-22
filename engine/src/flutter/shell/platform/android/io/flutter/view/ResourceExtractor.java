// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.res.AssetManager;
import android.os.AsyncTask;
import android.os.Build;
import android.util.Log;
import io.flutter.util.BSDiff;
import io.flutter.util.PathUtils;
import org.json.JSONObject;

import java.io.*;
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

    @SuppressWarnings("deprecation")
    static long getVersionCode(PackageInfo packageInfo) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
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

            ResourceUpdater resourceUpdater = FlutterMain.getResourceUpdater();
            if (resourceUpdater != null) {
                // Protect patch file from being overwritten by downloader while
                // it's being extracted since downloading happens asynchronously.
                resourceUpdater.getInstallationLock().lock();
            }

            try {
                if (resourceUpdater != null) {
                    File updateFile = resourceUpdater.getDownloadedPatch();
                    File activeFile = resourceUpdater.getInstalledPatch();

                    if (updateFile.exists()) {
                        JSONObject manifest = resourceUpdater.readManifest(updateFile);
                        if (resourceUpdater.validateManifest(manifest)) {
                            // Graduate patch file as active for asset manager.
                            if (activeFile.exists() && !activeFile.delete()) {
                                Log.w(TAG, "Could not delete file " + activeFile);
                                return null;
                            }
                            if (!updateFile.renameTo(activeFile)) {
                                Log.w(TAG, "Could not create file " + activeFile);
                                return null;
                            }
                        }
                    }
                }

                final String timestamp = checkTimestamp(dataDir);
                if (timestamp == null) {
                    return null;
                }

                deleteFiles();

                if (!extractUpdate(dataDir)) {
                    return null;
                }

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

            } finally {
              if (resourceUpdater != null) {
                  resourceUpdater.getInstallationLock().unlock();
              }
          }
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
        assert mExtractTask == null;
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

                Log.i(TAG, "Extracted baseline resource " + resource);

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

    /// Returns true if successfully unpacked update resources or if there is no update,
    /// otherwise deletes all resources and returns false.
    private boolean extractUpdate(File dataDir) {
        final AssetManager manager = mContext.getResources().getAssets();

        ResourceUpdater resourceUpdater = FlutterMain.getResourceUpdater();
        if (resourceUpdater == null) {
            return true;
        }

        File updateFile = resourceUpdater.getInstalledPatch();
        if (!updateFile.exists()) {
            return true;
        }

        JSONObject manifest = resourceUpdater.readManifest(updateFile);
        if (!resourceUpdater.validateManifest(manifest)) {
            // Obsolete patch file, nothing to install.
            return true;
        }

        ZipFile zipFile;
        try {
            zipFile = new ZipFile(updateFile);

        } catch (IOException e) {
            Log.w(TAG, "Exception unpacking resources: " + e.getMessage());
            deleteFiles();
            return false;
        }

        for (String asset : mResources) {
            final String resource = "assets/" + asset;
            ZipEntry entry = zipFile.getEntry(resource);
            if (entry == null) {
                entry = zipFile.getEntry(resource + ".bzdiff40");
                if (entry == null) {
                    continue;
                }
            }

            final File output = new File(dataDir, asset);
            if (output.exists()) {
                continue;
            }
            if (output.getParentFile() != null) {
                output.getParentFile().mkdirs();
            }

            try {
                if (entry.getName().endsWith(".bzdiff40")) {
                    ByteArrayOutputStream diff = new ByteArrayOutputStream();
                    try (InputStream is = zipFile.getInputStream(entry)) {
                        copy(is, diff);
                    }

                    ByteArrayOutputStream orig = new ByteArrayOutputStream();
                    try (InputStream is = manager.open(asset)) {
                        copy(is, orig);
                    } catch (FileNotFoundException e) {
                        throw new IOException("Could not find APK resource " + resource);
                    }

                    try (OutputStream os = new FileOutputStream(output)) {
                        os.write(BSDiff.bspatch(orig.toByteArray(), diff.toByteArray()));
                    }

                } else {
                    try (InputStream is = zipFile.getInputStream(entry);
                         OutputStream os = new FileOutputStream(output)) {
                        copy(is, os);
                    }
                }

                Log.i(TAG, "Extracted override resource " + entry.getName());

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

        ResourceUpdater resourceUpdater = FlutterMain.getResourceUpdater();
        if (resourceUpdater != null) {
            File patchFile = resourceUpdater.getInstalledPatch();
            JSONObject manifest = resourceUpdater.readManifest(patchFile);
            if (resourceUpdater.validateManifest(manifest)) {
                String patchNumber = manifest.optString("patchNumber", null);
                if (patchNumber != null) {
                    expectedTimestamp += "-" + patchNumber + "-" + patchFile.lastModified();
                } else {
                    expectedTimestamp += "-" + patchFile.lastModified();
                }
            }
        }

        final String[] existingTimestamps = getExistingTimestamps(dataDir);

        if (existingTimestamps == null) {
            Log.i(TAG, "No extracted resources found");
            return expectedTimestamp;
        }

        if (existingTimestamps.length == 1) {
            Log.i(TAG, "Found extracted resources " + existingTimestamps[0]);
        }

        if (existingTimestamps.length != 1
                || !expectedTimestamp.equals(existingTimestamps[0])) {
            Log.i(TAG, "Resource version mismatch " + expectedTimestamp);
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
}

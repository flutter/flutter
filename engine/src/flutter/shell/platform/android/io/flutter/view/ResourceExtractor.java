// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.res.AssetManager;
import android.os.AsyncTask;
import android.util.Log;
import io.flutter.util.PathUtils;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.*;
import java.util.Collection;
import java.util.HashSet;
import java.util.Scanner;
import java.util.concurrent.CancellationException;
import java.util.concurrent.ExecutionException;
import java.util.zip.CRC32;
import java.util.zip.ZipEntry;
import java.util.zip.ZipException;
import java.util.zip.ZipFile;

/**
 * A class to initialize the native code.
 **/
class ResourceExtractor {
    private static final String TAG = "ResourceExtractor";
    private static final String TIMESTAMP_PREFIX = "res_timestamp-";

    private class ExtractTask extends AsyncTask<Void, Void, Void> {
        private static final int BUFFER_SIZE = 16 * 1024;

        ExtractTask() { }

        private void extractResources() {
            final File dataDir = new File(PathUtils.getDataDirectory(mContext));

            JSONObject updateManifest = readUpdateManifest();
            if (!validateUpdateManifest(updateManifest)) {
                updateManifest = null;
            }

            final String timestamp = checkTimestamp(dataDir, updateManifest);
            if (timestamp == null) {
                return;
            }

            deleteFiles();

            if (updateManifest != null) {
                if (!extractUpdate(dataDir)) {
                    return;
                }
            }

            if (!extractAPK(dataDir)) {
                return;
            }

            if (timestamp != null) {
                try {
                    new File(dataDir, timestamp).createNewFile();
                } catch (IOException e) {
                    Log.w(TAG, "Failed to write resource timestamp");
                }
            }
        }

        /// Returns true if successfully unpacked APK resources,
        /// otherwise deletes all resources and returns false.
        private boolean extractAPK(File dataDir) {
            final AssetManager manager = mContext.getResources().getAssets();

            byte[] buffer = null;
            for (String asset : mResources) {
                try {
                    final File output = new File(dataDir, asset);
                    if (output.exists()) {
                        continue;
                    }
                    if (output.getParentFile() != null) {
                        output.getParentFile().mkdirs();
                    }

                    try (InputStream is = manager.open(asset);
                         OutputStream os = new FileOutputStream(output)) {
                        if (buffer == null) {
                            buffer = new byte[BUFFER_SIZE];
                        }

                        int count = 0;
                        while ((count = is.read(buffer, 0, BUFFER_SIZE)) != -1) {
                            os.write(buffer, 0, count);
                        }

                        os.flush();
                        Log.i(TAG, "Extracted baseline resource " + asset);
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

        /// Returns true if successfully unpacked update resources or if there is no update,
        /// otherwise deletes all resources and returns false.
        private boolean extractUpdate(File dataDir) {
            if (FlutterMain.getUpdateInstallationPath() == null) {
                return true;
            }

            final File updateFile = new File(FlutterMain.getUpdateInstallationPath());
            if (!updateFile.exists()) {
                return true;
            }

            ZipFile zipFile;
            try {
                zipFile = new ZipFile(updateFile);

            } catch (ZipException e) {
                Log.w(TAG, "Exception unpacking resources: " + e.getMessage());
                deleteFiles();
                return false;

            } catch (IOException e) {
                Log.w(TAG, "Exception unpacking resources: " + e.getMessage());
                deleteFiles();
                return false;
            }

            byte[] buffer = null;
            for (String asset : mResources) {
                ZipEntry entry = zipFile.getEntry(asset);
                if (entry == null) {
                    continue;
                }

                final File output = new File(dataDir, asset);
                if (output.exists()) {
                    continue;
                }
                if (output.getParentFile() != null) {
                    output.getParentFile().mkdirs();
                }

                try (InputStream is = zipFile.getInputStream(entry);
                     OutputStream os = new FileOutputStream(output)) {
                    if (buffer == null) {
                        buffer = new byte[BUFFER_SIZE];
                    }

                    int count = 0;
                    while ((count = is.read(buffer, 0, BUFFER_SIZE)) != -1) {
                        os.write(buffer, 0, count);
                    }

                    os.flush();
                    Log.i(TAG, "Extracted override resource " + asset);

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
        private String checkTimestamp(File dataDir, JSONObject updateManifest) {

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
                    TIMESTAMP_PREFIX + packageInfo.versionCode + "-" + packageInfo.lastUpdateTime;

            if (updateManifest != null) {
                String buildNumber = updateManifest.optString("buildNumber", null);
                if (buildNumber == null) {
                    Log.w(TAG, "Invalid update manifest: buildNumber");
                }

                String patchNumber = updateManifest.optString("patchNumber", null);
                if (patchNumber == null) {
                    Log.w(TAG, "Invalid update manifest: patchNumber");
                }

                if (buildNumber != null && patchNumber != null) {
                    if (!buildNumber.equals(Integer.toString(packageInfo.versionCode))) {
                        Log.w(TAG, "Outdated update file for " + packageInfo.versionCode);
                    } else {
                        final File updateFile = new File(FlutterMain.getUpdateInstallationPath());
                        expectedTimestamp += "-" + patchNumber + "-" + updateFile.lastModified();
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

        /// Returns true if the downloaded update file was indeed built for this APK.
        private boolean validateUpdateManifest(JSONObject updateManifest) {
            if (updateManifest == null) {
                return false;
            }

            String baselineChecksum = updateManifest.optString("baselineChecksum", null);
            if (baselineChecksum == null) {
                Log.w(TAG, "Invalid update manifest: baselineChecksum");
                return false;
            }

            final AssetManager manager = mContext.getResources().getAssets();
            try (InputStream is = manager.open("flutter_assets/isolate_snapshot_data")) {
                CRC32 checksum = new CRC32();

                int count = 0;
                byte[] buffer = new byte[BUFFER_SIZE];
                while ((count = is.read(buffer, 0, BUFFER_SIZE)) != -1) {
                    checksum.update(buffer, 0, count);
                }

                if (!baselineChecksum.equals(String.valueOf(checksum.getValue()))) {
                    Log.w(TAG, "Mismatched update file for APK");
                    return false;
                }

                return true;

            } catch (IOException e) {
                Log.w(TAG, "Could not read APK: " + e);
                return false;
            }
        }

        /// Returns null if no update manifest is found.
        private JSONObject readUpdateManifest() {
            if (FlutterMain.getUpdateInstallationPath() == null) {
                return null;
            }

            File updateFile = new File(FlutterMain.getUpdateInstallationPath());
            if (!updateFile.exists()) {
                return null;
            }

            try {
                ZipFile zipFile = new ZipFile(updateFile);
                ZipEntry entry = zipFile.getEntry("manifest.json");
                if (entry == null) {
                    Log.w(TAG, "Invalid update file: " + updateFile);
                    return null;
                }

                // Read and parse the entire JSON file as single operation.
                Scanner scanner = new Scanner(zipFile.getInputStream(entry));
                return new JSONObject(scanner.useDelimiter("\\A").next());

            } catch (ZipException e) {
                Log.w(TAG, "Invalid update file: " + e);
                return null;

            } catch (IOException e) {
                Log.w(TAG, "Invalid update file: " + e);
                return null;

            } catch (JSONException e) {
                Log.w(TAG, "Invalid update file: " + e);
                return null;
            }
        }

        @Override
        protected Void doInBackground(Void... unused) {
            extractResources();
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
        assert mExtractTask == null;
        mExtractTask = new ExtractTask();
        mExtractTask.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
        return this;
    }

    void waitForCompletion() {
        assert mExtractTask != null;

        try {
            mExtractTask.get();
        } catch (CancellationException e) {
            deleteFiles();
        } catch (ExecutionException e2) {
            deleteFiles();
        } catch (InterruptedException e3) {
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
}

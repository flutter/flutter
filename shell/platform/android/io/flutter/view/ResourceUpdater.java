// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Log;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.lang.Math;
import java.net.HttpURLConnection;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import java.util.Date;
import java.util.concurrent.CancellationException;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public final class ResourceUpdater {
    private static final String TAG = "ResourceUpdater";

    // Controls when to check if a new patch is available for download, and start downloading.
    // Note that by default the application will not block to wait for the download to finish.
    // Patches are downloaded in the background, but the developer can also use [InstallMode]
    // to control whether to block on download completion, in order to install patches sooner.
    enum DownloadMode {
        // Check for and download patch on application restart (but not necessarily apply it).
        // This is the default setting which will also check for new patches least frequently.
        ON_RESTART,

        // Check for and download patch on application resume (but not necessarily apply it).
        // By definition, this setting will check for new patches both on restart and resume.
        ON_RESUME
    }

    // Controls when to check that a new patch has been downloaded and needs to be applied.
    enum InstallMode {
        // Wait for next application restart before applying downloaded patch. With this
        // setting, the application will not block to wait for patch download to finish.
        // The application can be restarted later either by the user, or by the system,
        // for any reason, at which point the newly downloaded patch will get applied.
        // This is the default setting, and is the least disruptive way to apply patches.
        ON_NEXT_RESTART,

        // Apply patch as soon as it's downloaded. This will block to wait for new patch
        // download to finish, and will immediately apply it. This setting increases the
        // urgency with which patches are installed, but may also affect startup latency.
        // For now, this setting is only effective when download happens during restart.
        // Patches downloaded during resume will not get installed immediately as that
        // requires force restarting the app (which might be implemented in the future).
        IMMEDIATE
    }

    /// Lock that prevents replacement of the install file by the downloader
    /// while this file is being extracted, since these can happen in parallel.
    Lock getInstallationLock() {
        return installationLock;
    }

    // Patch file that's fully installed and is ready to serve assets.
    // This file represents the final stage in the installation process.
    public File getInstalledPatch() {
        return new File(context.getFilesDir().toString() + "/patch.zip");
    }

    // Patch file that's finished downloading and is ready to be installed.
    // This is a separate file in order to prevent serving assets from patch
    // that failed installing for any reason, such as mismatched APK version.
    File getDownloadedPatch() {
        return new File(getInstalledPatch().getPath() + ".install");
    }

    private class DownloadTask extends AsyncTask<String, String, Void> {
        @Override
        protected Void doInBackground(String... unused) {
            try {
                URL unresolvedURL = new URL(buildUpdateDownloadURL());

                // Download to transient file to avoid extracting incomplete download.
                File localFile = new File(getInstalledPatch().getPath() + ".download");

                long startMillis = new Date().getTime();
                Log.i(TAG, "Checking for updates at " + unresolvedURL);

                HttpURLConnection connection =
                        (HttpURLConnection)unresolvedURL.openConnection();

                long lastDownloadTime = Math.max(
                        getDownloadedPatch().lastModified(),
                        getInstalledPatch().lastModified());

                if (lastDownloadTime != 0) {
                    Log.i(TAG, "Active update timestamp " + lastDownloadTime);
                    connection.setIfModifiedSince(lastDownloadTime);
                }

                URL resolvedURL = connection.getURL();
                Log.i(TAG, "Resolved update URL " + resolvedURL);

                int responseCode = connection.getResponseCode();
                Log.i(TAG, "HTTP response code " + responseCode);

                if (responseCode == HttpURLConnection.HTTP_NOT_FOUND) {
                    Log.i(TAG, "Latest update not found");
                    return null;
                }

                if (responseCode == HttpURLConnection.HTTP_NOT_MODIFIED) {
                    Log.i(TAG, "Already have latest update");
                    return null;
                }

                try (InputStream input = connection.getInputStream()) {
                    Log.i(TAG, "Downloading update " + unresolvedURL);
                    try (OutputStream output = new FileOutputStream(localFile)) {
                        int count;
                        byte[] data = new byte[1024];
                        while ((count = input.read(data)) != -1) {
                            output.write(data, 0, count);
                        }

                        long totalMillis = new Date().getTime() - startMillis;
                        Log.i(TAG, "Update downloaded in " + totalMillis / 100 / 10. + "s");
                    }
                }

                // Wait renaming the file if extraction is in progress.
                installationLock.lock();

                try {
                    File updateFile = getDownloadedPatch();

                    // Graduate downloaded file as ready for installation.
                    if (updateFile.exists() && !updateFile.delete()) {
                        Log.w(TAG, "Could not delete file " + updateFile);
                        return null;
                    }
                    if (!localFile.renameTo(updateFile)) {
                        Log.w(TAG, "Could not create file " + updateFile);
                        return null;
                    }

                    return null;

                } finally {
                    installationLock.unlock();
                }

            } catch (IOException e) {
                Log.w(TAG, "Could not download update " + e.getMessage());
                return null;
            }
        }
    }

    private final Context context;
    private DownloadTask downloadTask;
    private final Lock installationLock = new ReentrantLock();

    public ResourceUpdater(Context context) {
        this.context = context;
    }

    private String getAPKVersion() {
        try {
            PackageManager packageManager = context.getPackageManager();
            PackageInfo packageInfo = packageManager.getPackageInfo(context.getPackageName(), 0);
            return packageInfo == null ? null : Long.toString(ResourceExtractor.getVersionCode(packageInfo));

        } catch (PackageManager.NameNotFoundException e) {
            return null;
        }
    }

    private String buildUpdateDownloadURL() {
        Bundle metaData;
        try {
            metaData = context.getPackageManager().getApplicationInfo(
                    context.getPackageName(), PackageManager.GET_META_DATA).metaData;

        } catch (PackageManager.NameNotFoundException e) {
            throw new RuntimeException(e);
        }

        if (metaData == null || metaData.getString("PatchServerURL") == null) {
            return null;
        }

        URI uri;
        try {
            uri = new URI(metaData.getString("PatchServerURL") + "/" + getAPKVersion() + ".zip");

        } catch (URISyntaxException e) {
            Log.w(TAG, "Invalid AndroidManifest.xml PatchServerURL: " + e.getMessage());
            return null;
        }

        return uri.normalize().toString();
    }

    DownloadMode getDownloadMode() {
        Bundle metaData;
        try {
            metaData = context.getPackageManager().getApplicationInfo(
                    context.getPackageName(), PackageManager.GET_META_DATA).metaData;

        } catch (PackageManager.NameNotFoundException e) {
            throw new RuntimeException(e);
        }

        if (metaData == null) {
            return DownloadMode.ON_RESTART;
        }

        String patchDownloadMode = metaData.getString("PatchDownloadMode");
        if (patchDownloadMode == null) {
            return DownloadMode.ON_RESTART;
        }

        try {
            return DownloadMode.valueOf(patchDownloadMode);
        } catch (IllegalArgumentException e) {
            Log.e(TAG, "Invalid PatchDownloadMode " + patchDownloadMode);
            return DownloadMode.ON_RESTART;
        }
    }

    InstallMode getInstallMode() {
        Bundle metaData;
        try {
            metaData = context.getPackageManager().getApplicationInfo(
                    context.getPackageName(), PackageManager.GET_META_DATA).metaData;

        } catch (PackageManager.NameNotFoundException e) {
            throw new RuntimeException(e);
        }

        if (metaData == null) {
            return InstallMode.ON_NEXT_RESTART;
        }

        String patchInstallMode = metaData.getString("PatchInstallMode");
        if (patchInstallMode == null) {
            return InstallMode.ON_NEXT_RESTART;
        }

        try {
            return InstallMode.valueOf(patchInstallMode);
        } catch (IllegalArgumentException e) {
            Log.e(TAG, "Invalid PatchInstallMode " + patchInstallMode);
            return InstallMode.ON_NEXT_RESTART;
        }
    }

    void startUpdateDownloadOnce() {
        if (downloadTask != null ) {
            return;
        }
        downloadTask = new DownloadTask();
        downloadTask.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
    }

    void waitForDownloadCompletion() {
        if (downloadTask == null) {
            return;
        }
        try {
            downloadTask.get();
            downloadTask = null;
        } catch (CancellationException e) {
            Log.w(TAG, "Download cancelled: " + e.getMessage());
            return;
        } catch (ExecutionException e) {
            Log.w(TAG, "Download exception: " + e.getMessage());
            return;
        } catch (InterruptedException e) {
            Log.w(TAG, "Download interrupted: " + e.getMessage());
            return;
        }
    }
}

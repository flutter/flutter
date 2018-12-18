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
import java.net.HttpURLConnection;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import java.util.Date;
import java.util.concurrent.CancellationException;
import java.util.concurrent.ExecutionException;

public final class ResourceUpdater {
    private static final String TAG = "ResourceUpdater";

    private static class DownloadTask extends AsyncTask<String, String, Void> {
        @Override
        protected Void doInBackground(String... args) {
            try {
                URL unresolvedURL = new URL(args[0]);
                File localFile = new File(args[1]);

                long startMillis = new Date().getTime();
                Log.i(TAG, "Checking for updates at " + unresolvedURL);

                HttpURLConnection connection =
                        (HttpURLConnection)unresolvedURL.openConnection();

                long lastModified = localFile.lastModified();
                if (lastModified != 0) {
                    Log.i(TAG, "Active update timestamp " + lastModified);
                    connection.setIfModifiedSince(lastModified);
                }

                try (InputStream input = connection.getInputStream()) {
                    URL resolvedURL = connection.getURL();
                    Log.i(TAG, "Resolved update URL " + resolvedURL);

                    if (connection.getResponseCode() == HttpURLConnection.HTTP_NOT_FOUND) {
                        if (resolvedURL.equals(unresolvedURL)) {
                            Log.i(TAG, "Rolled back all updates");
                            localFile.delete();
                            return null;
                        } else {
                            Log.i(TAG, "Latest update not found");
                            return null;
                        }
                    }

                    if (connection.getResponseCode() == HttpURLConnection.HTTP_NOT_MODIFIED) {
                        Log.i(TAG, "Already have latest update");
                        return null;
                    }

                    Log.i(TAG, "Downloading update " + unresolvedURL);
                    try (OutputStream output = new FileOutputStream(localFile)) {
                        int count;
                        byte[] data = new byte[1024];
                        while ((count = input.read(data)) != -1) {
                            output.write(data, 0, count);
                        }

                        long totalMillis = new Date().getTime() - startMillis;
                        Log.i(TAG, "Update downloaded in " + totalMillis / 100 / 10. + "s");

                        output.flush();
                        return null;
                    }
                }

            } catch (IOException e) {
                Log.w(TAG, "Could not download update " + e.getMessage());
                return null;
            }
        }
    }

    private final Context context;
    private DownloadTask downloadTask;

    public ResourceUpdater(Context context) {
        this.context = context;
    }

    public String getAPKVersion() {
        try {
            PackageManager packageManager = context.getPackageManager();
            PackageInfo packageInfo = packageManager.getPackageInfo(context.getPackageName(), 0);
            return packageInfo == null ? null : Integer.toString(packageInfo.versionCode);

        } catch (PackageManager.NameNotFoundException e) {
            return null;
        }
    }

    public String getUpdateInstallationPath() {
        return context.getFilesDir().toString() + "/update.zip";
    }

    public String buildUpdateDownloadURL() {
        Bundle metaData;
        try {
            metaData = context.getPackageManager().getApplicationInfo(
                    context.getPackageName(), PackageManager.GET_META_DATA).metaData;

        } catch (PackageManager.NameNotFoundException e) {
            throw new RuntimeException(e);
        }

        if (metaData == null || metaData.getString("UpdateServerURL") == null) {
            return null;
        }

        URI uri;
        try {
            uri = new URI(metaData.getString("UpdateServerURL") + "/" + getAPKVersion());

        } catch (URISyntaxException e) {
            Log.w(TAG, "Invalid AndroidManifest.xml UpdateServerURL: " + e.getMessage());
            return null;
        }

        return uri.normalize().toString();
    }

    public void startUpdateDownloadOnce() {
        assert downloadTask == null;
        downloadTask = new DownloadTask();
        downloadTask.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR,
                buildUpdateDownloadURL(), getUpdateInstallationPath());
    }

    public void waitForDownloadCompletion() {
        assert downloadTask != null;
        try {
            downloadTask.get();
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

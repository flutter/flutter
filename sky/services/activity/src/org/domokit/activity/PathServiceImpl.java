// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.activity;

import android.content.Context;
import org.chromium.base.PathUtils;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.activity.PathService;

/**
 * Android implementation of PathService.
 */
public class PathServiceImpl implements PathService {
    private static final String TAG = "PathServiceImpl";
    private static android.content.Context context;

    public PathServiceImpl(android.content.Context context) {
      this.context = context;
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void getAppDataDir(GetAppDataDirResponse callback) {
        callback.call(PathUtils.getDataDirectory(context));
    }

    @Override
    public void getFilesDir(GetFilesDirResponse callback) {
        callback.call(context.getFilesDir().getPath());
    }

    @Override
    public void getCacheDir(GetCacheDirResponse callback) {
        callback.call(context.getCacheDir().getPath());
    }
}

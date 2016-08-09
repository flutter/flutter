// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.platform;

import android.content.Context;

import org.chromium.base.PathUtils;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.flutter.platform.PathProvider;

/**
 * Android implementation of PathProvider.
 */
public class PathProviderImpl implements PathProvider {
    private final Context mContext;

    public PathProviderImpl(Context context) {
        mContext = context;
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void temporaryDirectory(TemporaryDirectoryResponse callback) {
        callback.call(mContext.getCacheDir().getPath());
    }

    @Override
    public void applicationDocumentsDirectory(ApplicationDocumentsDirectoryResponse callback) {
        callback.call(PathUtils.getDataDirectory(mContext));
    }
}

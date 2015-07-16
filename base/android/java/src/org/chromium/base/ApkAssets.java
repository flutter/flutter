// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.util.Log;

import java.io.IOException;

/**
 * A utility class to retrieve references to uncompressed assets insides the apk. A reference is
 * defined as tuple (file descriptor, offset, size) enabling direct mapping without deflation.
 * This can be used even within the renderer process, since it just dup's the apk's fd.
 */
@JNINamespace("base::android")
public class ApkAssets {
    private static final String LOGTAG = "ApkAssets";

    @CalledByNative
    public static long[] open(Context context, String fileName) {
        AssetFileDescriptor afd = null;
        try {
            AssetManager manager = context.getAssets();
            afd = manager.openNonAssetFd(fileName);
            return new long[] { afd.getParcelFileDescriptor().detachFd(),
                                afd.getStartOffset(),
                                afd.getLength() };
        } catch (IOException e) {
            Log.e(LOGTAG, "Error while loading asset " + fileName + ": " + e);
            return new long[] {-1, -1, -1};
        } finally {
            try {
                if (afd != null) {
                    afd.close();
                }
            } catch (IOException e2) {
                Log.e(LOGTAG, "Unable to close AssetFileDescriptor", e2);
            }
        }
    }
}

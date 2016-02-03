// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.common;

import android.content.Context;

import java.io.File;
import java.io.IOException;

public class ResourcePaths {
    // The filename prefix used by Chromium temporary file APIs.
    public static final String TEMPORARY_RESOURCE_PREFIX = ".org.chromium.Chromium.";

    // Return a temporary file that will be cleaned up by the ResourceCleaner.
    public static File createTempFile(Context context, String suffix) throws IOException {
        return File.createTempFile(TEMPORARY_RESOURCE_PREFIX, "_" + suffix,
                                   context.getCacheDir());
    }
}

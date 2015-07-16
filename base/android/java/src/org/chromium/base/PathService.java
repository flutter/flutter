// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

/**
 * This class provides java side access to the native PathService.
 */
@JNINamespace("base::android")
public abstract class PathService {

    // Must match the value of DIR_MODULE in base/base_paths.h!
    public static final int DIR_MODULE = 3;

    // Prevent instantiation.
    private PathService() {}

    public static void override(int what, String path) {
        nativeOverride(what, path);
    }

    private static native void nativeOverride(int what, String path);
}
